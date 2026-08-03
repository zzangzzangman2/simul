import { NextResponse } from "next/server";
import {
  validateDialogueScenes,
  type ValidatedDialogueScene,
} from "../../../editor/dialogue-validation";

export const dynamic = "force-dynamic";

type PublishMode = "quick" | "full";

type BuildResult = {
  builtAt: string;
  durationMs: number;
  logTail: string;
  sha256: string;
  mode: PublishMode;
  scenes: ValidatedDialogueScene[];
};

type DialogueBuildGlobal = typeof globalThis & {
  __dialogueBuildPromise?: Promise<BuildResult>;
  __dialogueBuildCompletedAt?: number;
};

const buildGlobal = globalThis as DialogueBuildGlobal;
const BUILD_COOLDOWN_MS = 5000;

function localBuildAvailable() {
  return (
    process.env.NODE_ENV !== "production" &&
    process.env.DIALOGUE_BUILD_ENABLED === "1"
  );
}

function requestHost(request: Request) {
  const header = request.headers.get("host");
  return header || new URL(request.url).host;
}

function requestIsLoopback(request: Request) {
  const hostname = new URL(`http://${requestHost(request)}`).hostname
    .replace(/^\[/, "")
    .replace(/\]$/, "");
  return hostname === "localhost" || hostname === "127.0.0.1" || hostname === "::1";
}

function sameOriginRequest(request: Request) {
  const origin = request.headers.get("origin");
  if (!origin) return requestIsLoopback(request);
  try {
    return new URL(origin).host === requestHost(request);
  } catch {
    return false;
  }
}

async function authorizedForBuild(request: Request) {
  if (!sameOriginRequest(request)) return false;
  const expected = process.env.DIALOGUE_BUILD_TOKEN ?? "";
  const supplied = request.headers.get("x-dialogue-build-token") ?? "";
  if (!expected || !supplied) return false;
  const { timingSafeEqual } = await import("node:crypto");
  const expectedBytes = Buffer.from(expected);
  const suppliedBytes = Buffer.from(supplied);
  return (
    expectedBytes.length === suppliedBytes.length &&
    timingSafeEqual(expectedBytes, suppliedBytes)
  );
}

async function persistDialogue(
  scenes: ValidatedDialogueScene[],
  mode: PublishMode,
): Promise<BuildResult> {
  const [{ access, copyFile, readFile, writeFile }, { spawn }, path, { createHash }] =
    await Promise.all([
      import("node:fs/promises"),
      import("node:child_process"),
      import("node:path"),
      import("node:crypto"),
    ]);
  const projectRoot = process.cwd();
  const flutterRoot = path.resolve(projectRoot, "flutter_app");
  const assetPath = path.resolve(
    flutterRoot,
    "assets/dialogue/dialogue-editor-override.json",
  );
  const editorDataPath = path.resolve(projectRoot, "app/editor/dialogue-data.ts");
  const dartDataPath = path.resolve(
    flutterRoot,
    "lib/dialogue/canonical_dialogue_data.dart",
  );
  const runtimeDialoguePath = path.resolve(
    projectRoot,
    "public/play/assets/assets/dialogue/dialogue-editor-override.json",
  );
  const generatorScript = path.resolve(
    projectRoot,
    "scripts/generate-dialogue-editor-data.mjs",
  );
  const buildScript = path.resolve(projectRoot, "scripts/build-flutter-web.mjs");
  for (const target of [
    assetPath,
    editorDataPath,
    dartDataPath,
    generatorScript,
    buildScript,
    runtimeDialoguePath,
  ]) {
    const relative = path.relative(projectRoot, target);
    if (!relative || relative.startsWith("..")) {
      throw new Error("빌드 대상 경로를 확인할 수 없습니다.");
    }
  }

  for (const scene of scenes) {
    for (const field of ["background", "character"] as const) {
      const asset = scene[field];
      if (!asset) continue;
      const relativeAsset = asset.slice("/play/assets/".length);
      const resolvedAsset = path.resolve(flutterRoot, relativeAsset);
      const relative = path.relative(flutterRoot, resolvedAsset);
      if (!relative || relative.startsWith("..")) {
        throw new Error(`${scene.id} 장면의 ${field} 경로가 저장소 밖을 가리킵니다.`);
      }
      try {
        await access(resolvedAsset);
      } catch {
        throw new Error(`${scene.id} 장면의 ${field} 에셋을 찾을 수 없습니다: ${asset}`);
      }
      if (mode === "quick") {
        const runtimeAsset = path.resolve(
          projectRoot,
          "public/play",
          encodeURI(asset.slice("/play/".length)),
        );
        const runtimeRelative = path.relative(path.resolve(projectRoot, "public/play"), runtimeAsset);
        if (!runtimeRelative || runtimeRelative.startsWith("..")) {
          throw new Error(`${scene.id} 장면의 ${field} 런타임 경로가 올바르지 않습니다.`);
        }
        try {
          await access(runtimeAsset);
        } catch {
          throw new Error(`새 에셋은 전체 빌드가 필요합니다: ${asset}`);
        }
      }
    }
  }

  const builtAt = new Date().toISOString();
  const payload = `${JSON.stringify(
    {
      version: 2,
      contentVersion: 3,
      appearanceVersion: 17,
      updatedAt: builtAt,
      scenes,
    },
    null,
    2,
  )}\n`;
  const sha256 = createHash("sha256").update(payload).digest("hex");
  if (mode === "quick") {
    try {
      await access(runtimeDialoguePath);
    } catch {
      throw new Error("빠른 적용 대상이 없습니다. 먼저 전체 빌드를 실행해 주세요.");
    }
  }
  const sourcePaths = [
    assetPath,
    editorDataPath,
    dartDataPath,
    ...(mode === "quick" ? [runtimeDialoguePath] : []),
  ] as const;
  const backups = await Promise.all(
    sourcePaths.map((target) => readFile(target, "utf8")),
  );
  let output = "";
  const append = (chunk: Buffer) => {
    output = `${output}${chunk.toString("utf8")}`.slice(-12000);
  };
  const runNodeScript = (script: string, label: string) =>
    new Promise<void>((resolveBuild, rejectBuild) => {
      const child = spawn(process.execPath, [script], {
        cwd: projectRoot,
        env: process.env,
        windowsHide: true,
        stdio: ["ignore", "pipe", "pipe"],
      });
      child.stdout.on("data", append);
      child.stderr.on("data", append);
      const timeout = setTimeout(() => {
        child.kill();
        rejectBuild(new Error(`${label}이 5분 안에 끝나지 않았습니다.`));
      }, 5 * 60 * 1000);
      child.once("error", (error) => {
        clearTimeout(timeout);
        rejectBuild(error);
      });
      child.once("exit", (code, signal) => {
        clearTimeout(timeout);
        if (code === 0) resolveBuild();
        else rejectBuild(new Error(`${label} 실패 (${signal ?? `exit ${code}`})`));
      });
    });

  const startedAt = Date.now();
  try {
    await writeFile(assetPath, payload, "utf8");
    await runNodeScript(generatorScript, "대사 생성");
    if (mode === "quick") {
      await copyFile(assetPath, runtimeDialoguePath);
    } else {
      await runNodeScript(buildScript, "Flutter 게임 빌드");
    }
  } catch (error) {
    await Promise.all(
      sourcePaths.map((target, index) => writeFile(target, backups[index], "utf8")),
    );
    console.error("Dialogue game build rolled back:\n", output.trim());
    throw error;
  }

  return {
    builtAt,
    durationMs: Date.now() - startedAt,
    logTail: output.trim(),
    sha256,
    mode,
    scenes,
  };
}

export async function GET() {
  const tokenConfigured = Boolean(process.env.DIALOGUE_BUILD_TOKEN);
  return NextResponse.json({
    available: localBuildAvailable() && tokenConfigured,
    building: Boolean(buildGlobal.__dialogueBuildPromise),
    requiresToken: true,
  });
}

export async function POST(request: Request) {
  if (!localBuildAvailable()) {
    return NextResponse.json(
      { ok: false, message: "게임 빌드는 허용된 로컬 개발 환경에서만 실행할 수 있습니다." },
      { status: 404 },
    );
  }
  if (!(await authorizedForBuild(request))) {
    return NextResponse.json(
      { ok: false, message: "빌드 요청의 출처 또는 대사 빌드 토큰을 확인해 주세요." },
      { status: 403 },
    );
  }
  if (buildGlobal.__dialogueBuildPromise) {
    return NextResponse.json(
      { ok: false, message: "이미 게임을 빌드하고 있습니다. 잠시만 기다려주세요." },
      { status: 409 },
    );
  }
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json(
      { ok: false, message: "저장할 대사 데이터를 읽지 못했습니다." },
      { status: 400 },
    );
  }
  const bodyRecord =
    body && typeof body === "object" ? (body as Record<string, unknown>) : null;
  const mode: PublishMode = bodyRecord?.mode === "full" ? "full" : "quick";
  const completedAt = buildGlobal.__dialogueBuildCompletedAt ?? 0;
  if (mode === "full" && Date.now() - completedAt < BUILD_COOLDOWN_MS) {
    return NextResponse.json(
      { ok: false, message: "연속 전체 빌드를 막기 위해 5초 뒤 다시 시도해 주세요." },
      { status: 429 },
    );
  }
  const validation = validateDialogueScenes(
    bodyRecord?.scenes,
  );
  if (!validation.ok) {
    return NextResponse.json(
      { ok: false, message: validation.message },
      { status: 400 },
    );
  }

  buildGlobal.__dialogueBuildPromise = persistDialogue(validation.scenes, mode);
  try {
    const result = await buildGlobal.__dialogueBuildPromise;
    if (result.mode === "full") {
      buildGlobal.__dialogueBuildCompletedAt = Date.now();
    }
    return NextResponse.json({
      ok: true,
      contentVersion: 3,
      appearanceVersion: 17,
      ...result,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "게임 빌드에 실패했습니다.";
    return NextResponse.json({ ok: false, message }, { status: 500 });
  } finally {
    buildGlobal.__dialogueBuildPromise = undefined;
  }
}
