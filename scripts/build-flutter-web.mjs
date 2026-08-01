import { spawn } from "node:child_process";
import {
  access,
  cp,
  mkdir,
  readFile,
  readdir,
  rename,
  rm,
} from "node:fs/promises";
import { dirname, relative, resolve } from "node:path";
import { homedir } from "node:os";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const flutterRoot = resolve(root, "flutter_app");
const buildOutput = resolve(flutterRoot, "build", "web");
const publicRoot = resolve(root, "public");
const target = resolve(publicRoot, "play");
const nonce = `${process.pid}-${Date.now()}`;
const staging = resolve(publicRoot, `.play-next-${nonce}`);
const backup = resolve(publicRoot, `.play-previous-${nonce}`);

for (const path of [flutterRoot, buildOutput, publicRoot, target, staging, backup]) {
  const fromRoot = relative(root, path);
  if (!fromRoot || fromRoot.startsWith("..")) {
    throw new Error(`Refusing to operate outside the repository: ${path}`);
  }
}

function run(command, args, cwd) {
  return new Promise((resolveRun, rejectRun) => {
    const executable = process.platform === "win32"
      ? (process.env.ComSpec ?? "cmd.exe")
      : command;
    const executableArgs = process.platform === "win32"
      ? ["/d", "/s", "/c", command, ...args]
      : args;
    const child = spawn(executable, executableArgs, {
      cwd,
      stdio: "inherit",
    });
    child.once("error", rejectRun);
    child.once("exit", (code, signal) => {
      if (code === 0) resolveRun();
      else rejectRun(new Error(`${command} failed (${signal ?? `exit ${code}`})`));
    });
  });
}

async function findFlutterUnder(searchRoot, maxDepth = 6) {
  const queue = [{ path: searchRoot, depth: 0 }];
  const skipped = new Set([
    ".git",
    ".next",
    ".vinext",
    "build",
    "node_modules",
    "public",
  ]);
  let visited = 0;

  while (queue.length && visited < 5000) {
    const current = queue.shift();
    if (!current) break;
    let entries;
    try {
      entries = await readdir(current.path, { withFileTypes: true });
    } catch {
      continue;
    }
    visited += entries.length;
    for (const entry of entries) {
      if (!entry.isDirectory() || skipped.has(entry.name)) continue;
      const child = resolve(current.path, entry.name);
      if (entry.name.toLowerCase() === "flutter") {
        const executable = resolve(
          child,
          "bin",
          process.platform === "win32" ? "flutter.bat" : "flutter",
        );
        if (await exists(executable)) return executable;
      }
      if (current.depth < maxDepth) {
        queue.push({ path: child, depth: current.depth + 1 });
      }
    }
  }
  return null;
}

async function resolveFlutterCommand() {
  const executableName = process.platform === "win32" ? "flutter.bat" : "flutter";
  const configured = [
    process.env.FLUTTER_BIN,
    process.env.FLUTTER_ROOT
      ? resolve(process.env.FLUTTER_ROOT, "bin", executableName)
      : null,
    resolve(homedir(), "flutter", "bin", executableName),
    resolve(homedir(), "development", "flutter", "bin", executableName),
  ].filter(Boolean);
  for (const candidate of configured) {
    if (await exists(candidate)) return candidate;
  }

  if (process.platform === "win32") {
    const codexFlutter = await findFlutterUnder(resolve(homedir(), "Documents", "Codex"));
    if (codexFlutter) return codexFlutter;
  }
  return "flutter";
}

async function exists(path) {
  try {
    await access(path);
    return true;
  } catch {
    return false;
  }
}

async function validateBuild() {
  for (const name of ["index.html", "flutter_bootstrap.js", "main.dart.js"]) {
    await access(resolve(buildOutput, name));
  }
  const index = await readFile(resolve(buildOutput, "index.html"), "utf8");
  const bootstrap = await readFile(resolve(buildOutput, "flutter_bootstrap.js"), "utf8");
  if (!index.includes('<base href="/play/">')) {
    throw new Error("Flutter build does not use the required /play/ base href.");
  }
  if (!index.includes('id="legacy-save-bridge"')) {
    throw new Error("Flutter build is missing the legacy localStorage bridge.");
  }
  if (!index.includes('id="flutter_host"') || !index.includes('id="mobile-viewport-lock"')) {
    throw new Error("Flutter build is missing the fixed mobile viewport host.");
  }
  if (
    !bootstrap.includes("hostElement:") ||
    !bootstrap.includes("document.getElementById('flutter_host')")
  ) {
    throw new Error("Flutter bootstrap is not attached to the fixed host element.");
  }
}

async function syncDirectoryContents(source, destination) {
  await mkdir(destination, { recursive: true });

  const [sourceEntries, destinationEntries] = await Promise.all([
    readdir(source, { withFileTypes: true }),
    readdir(destination, { withFileTypes: true }),
  ]);
  const sourceNames = new Set(sourceEntries.map((entry) => entry.name));

  for (const entry of destinationEntries) {
    if (!sourceNames.has(entry.name)) {
      await rm(resolve(destination, entry.name), {
        recursive: true,
        force: true,
      });
    }
  }

  const destinationKinds = new Map(
    destinationEntries.map((entry) => [entry.name, entry.isDirectory()]),
  );
  for (const entry of sourceEntries) {
    const sourcePath = resolve(source, entry.name);
    const destinationPath = resolve(destination, entry.name);
    const destinationIsDirectory = destinationKinds.get(entry.name);

    if (entry.isDirectory()) {
      if (destinationIsDirectory === false) {
        await rm(destinationPath, { recursive: true, force: true });
      }
      await syncDirectoryContents(sourcePath, destinationPath);
      continue;
    }

    if (destinationIsDirectory === true) {
      await rm(destinationPath, { recursive: true, force: true });
    }
    await cp(sourcePath, destinationPath, { force: true });
  }
}

async function syncBuild() {
  await mkdir(publicRoot, { recursive: true });
  await rm(staging, { recursive: true, force: true });
  await cp(buildOutput, staging, { recursive: true, errorOnExist: true });

  const hadTarget = await exists(target);
  try {
    if (hadTarget) await rename(target, backup);
    await rename(staging, target);
    if (hadTarget) await rm(backup, { recursive: true, force: true });
  } catch (error) {
    const targetWasNotMoved =
      hadTarget &&
      (error?.code === "EPERM" || error?.code === "EACCES") &&
      (await exists(target)) &&
      !(await exists(backup));
    if (targetWasNotMoved) {
      // Windows development servers can keep a directory handle open, which
      // prevents renaming the root even though replacing its files is safe.
      await syncDirectoryContents(staging, target);
      console.warn(
        "public/play was locked; synced its contents without renaming the directory.",
      );
      return;
    }

    await rm(staging, { recursive: true, force: true });
    if (hadTarget && (await exists(backup)) && !(await exists(target))) {
      await rename(backup, target);
    }
    throw error;
  }
}

try {
  const flutterCommand = await resolveFlutterCommand();
  console.log(`Using Flutter: ${flutterCommand}`);
  await run(
    flutterCommand,
    ["build", "web", "--release", "--base-href", "/play/"],
    flutterRoot,
  );
  await validateBuild();
  await syncBuild();
  console.log("Flutter Web build synced to public/play.");
} finally {
  await rm(staging, { recursive: true, force: true });
}
