import { spawn } from "node:child_process";
import { createHash } from "node:crypto";
import {
  access,
  cp,
  mkdir,
  readFile,
  readdir,
  rename,
  rm,
  writeFile,
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
  for (const name of [
    "index.html",
    "flutter_bootstrap.js",
    "main.dart.js",
    "pwa_service_worker.js",
  ]) {
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
    !index.includes('id="install-prompt"') ||
    !index.includes('id="pwa-worker-registration"') ||
    !index.includes('id="automatic-app-update"') ||
    !index.includes('content="$DECIMAL_BUILD_ID"')
  ) {
    throw new Error("Flutter build is missing the install or automatic update shell.");
  }
  if (
    !bootstrap.includes("hostElement:") ||
    !bootstrap.includes("document.getElementById('flutter_host')")
  ) {
    throw new Error("Flutter bootstrap is not attached to the fixed host element.");
  }
}

async function hashBuildOutput() {
  const files = [];
  const queue = [buildOutput];
  while (queue.length) {
    const directory = queue.shift();
    const entries = await readdir(directory, { withFileTypes: true });
    entries.sort((left, right) => left.name.localeCompare(right.name));
    for (const entry of entries) {
      const path = resolve(directory, entry.name);
      if (entry.isDirectory()) queue.push(path);
      else if (entry.isFile()) files.push(path);
    }
  }

  files.sort((left, right) => left.localeCompare(right));
  const digest = createHash("sha256");
  for (const path of files) {
    const name = relative(buildOutput, path).replaceAll("\\", "/");
    // This file receives build_id below. Excluding it keeps identical builds
    // deterministic even when an earlier stamped output remains on disk.
    if (name === "version.json") continue;
    digest.update(name);
    digest.update("\0");
    digest.update(await readFile(path));
  }
  return digest.digest("hex").slice(0, 12);
}

/**
 * Flutter Web은 `index.html`, `flutter_bootstrap.js`, `main.dart.js`를 모두 고정된
 * 파일명으로 내보내고, 최신 Flutter의 서비스워커는 캐시를 하지 않고 자기 자신을
 * 등록 해제하는 스텁이다. 그래서 갱신 여부가 전적으로 HTTP 캐시에 달려 있고,
 * 5MB짜리 `main.dart.js`가 캐시에 붙어 있으면 유저는 배포 뒤에도 옛 게임을 본다.
 *
 * 전체 Web 산출물의 내용 해시를 두 진입 스크립트 URL과 version.json에 붙인다.
 * 따라서 Dart 코드뿐 아니라 이미지·manifest·HTML만 바뀐 빌드도 설치 앱이 감지한다.
 * 타임스탬프가 아니라 내용 해시를 쓰므로 산출물이 같으면 ID도 같다.
 */
async function stampBuildId() {
  const indexPath = resolve(buildOutput, "index.html");
  const bootstrapPath = resolve(buildOutput, "flutter_bootstrap.js");

  const [indexHtml, bootstrap] = await Promise.all([
    readFile(indexPath, "utf8"),
    readFile(bootstrapPath, "utf8"),
  ]);

  const buildId = await hashBuildOutput();

  if (!indexHtml.includes('src="flutter_bootstrap.js"')) {
    throw new Error("Flutter index.html no longer loads flutter_bootstrap.js by name.");
  }
  if (!bootstrap.includes('"main.dart.js"')) {
    throw new Error("Flutter bootstrap no longer references main.dart.js by name.");
  }
  if (!indexHtml.includes('content="$DECIMAL_BUILD_ID"')) {
    throw new Error("Flutter index.html is missing the build id placeholder.");
  }
  if (!indexHtml.includes("'pwa_service_worker.js'")) {
    throw new Error("Flutter index.html no longer registers the PWA worker by name.");
  }

  await writeFile(
    indexPath,
    indexHtml
      .replaceAll(
        'src="flutter_bootstrap.js"',
        `src="flutter_bootstrap.js?v=${buildId}"`,
      )
      .replace('content="$DECIMAL_BUILD_ID"', `content="${buildId}"`)
      .replace(
        "'pwa_service_worker.js'",
        `'pwa_service_worker.js?v=${buildId}'`,
      ),
    "utf8",
  );
  await writeFile(
    bootstrapPath,
    bootstrap.replaceAll('"main.dart.js"', `"main.dart.js?v=${buildId}"`),
    "utf8",
  );

  // 배포 확인용. `version.json`은 Flutter가 pubspec 값만 담아 한 번도 바뀌지 않았다.
  const versionPath = resolve(buildOutput, "version.json");
  if (await exists(versionPath)) {
    const version = JSON.parse(await readFile(versionPath, "utf8"));
    version.build_id = buildId;
    await writeFile(versionPath, `${JSON.stringify(version)}\n`, "utf8");
  }

  return buildId;
}

async function renameWithRetry(source, destination) {
  let lastError;
  for (let attempt = 0; attempt < 10; attempt += 1) {
    try {
      await rename(source, destination);
      return;
    } catch (error) {
      lastError = error;
      if (error?.code !== "EPERM" && error?.code !== "EACCES") throw error;
      await new Promise((resolveWait) => setTimeout(resolveWait, 200));
    }
  }
  throw lastError;
}

async function syncBuild() {
  await mkdir(publicRoot, { recursive: true });
  await rm(staging, { recursive: true, force: true });
  await cp(buildOutput, staging, { recursive: true, errorOnExist: true });

  const hadTarget = await exists(target);
  try {
    if (hadTarget) await renameWithRetry(target, backup);
    await renameWithRetry(staging, target);
    if (hadTarget) await rm(backup, { recursive: true, force: true });
  } catch (error) {
    await rm(staging, { recursive: true, force: true });
    if (hadTarget && (await exists(backup)) && !(await exists(target))) {
      await renameWithRetry(backup, target);
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
  const buildId = await stampBuildId();
  await syncBuild();
  console.log(`Flutter Web build synced to public/play. build id ${buildId}`);
} finally {
  await rm(staging, { recursive: true, force: true });
}
