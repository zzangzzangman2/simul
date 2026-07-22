import { spawn } from "node:child_process";
import { access, cp, mkdir, readFile, rename, rm } from "node:fs/promises";
import { dirname, relative, resolve } from "node:path";
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
    await rm(staging, { recursive: true, force: true });
    if (hadTarget && (await exists(backup)) && !(await exists(target))) {
      await rename(backup, target);
    }
    throw error;
  }
}

try {
  await run(
    "flutter",
    ["build", "web", "--release", "--base-href", "/play/"],
    flutterRoot,
  );
  await validateBuild();
  await syncBuild();
  console.log("Flutter Web build synced to public/play.");
} finally {
  await rm(staging, { recursive: true, force: true });
}
