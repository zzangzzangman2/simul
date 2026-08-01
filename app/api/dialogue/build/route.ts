import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

type DialogueScenePayload = {
  id: string;
  order: number;
  chapter: string;
  date: string;
  location: string;
  speaker: string;
  direction: string;
  line: string;
  background: string;
  character: string;
};

type BuildResult = {
  builtAt: string;
  durationMs: number;
  logTail: string;
};

type DialogueBuildGlobal = typeof globalThis & {
  __dialogueBuildPromise?: Promise<BuildResult>;
};

const buildGlobal = globalThis as DialogueBuildGlobal;
const MAX_SCENES = 240;
const MAX_TEXT_LENGTH = 6000;

function localBuildAvailable() {
  return process.env.NODE_ENV !== "production";
}

function textValue(value: unknown) {
  return typeof value === "string" ? value.slice(0, MAX_TEXT_LENGTH) : "";
}

function dialogueTextValue(value: unknown) {
  return textValue(value)
    .replaceAll("\\r\\n", "\n")
    .replaceAll("\\n", "\n")
    .replaceAll("\\r", "\n");
}

function normalizeScenes(value: unknown): DialogueScenePayload[] | null {
  if (!Array.isArray(value) || value.length === 0 || value.length > MAX_SCENES) {
    return null;
  }

  const seenIds = new Set<string>();
  const scenes: DialogueScenePayload[] = [];
  for (const [index, raw] of value.entries()) {
    if (!raw || typeof raw !== "object") return null;
    const source = raw as Record<string, unknown>;
    const id = textValue(source.id).trim();
    if (!id || seenIds.has(id)) return null;
    seenIds.add(id);
    scenes.push({
      id,
      order: index + 1,
      chapter: textValue(source.chapter),
      date: textValue(source.date),
      location: textValue(source.location),
      speaker: textValue(source.speaker),
      direction: dialogueTextValue(source.direction),
      line: dialogueTextValue(source.line),
      background: textValue(source.background),
      character: textValue(source.character),
    });
  }
  return scenes;
}

async function persistAndBuild(scenes: DialogueScenePayload[]): Promise<BuildResult> {
  const [{ mkdir, writeFile }, { spawn }, path] = await Promise.all([
    import("node:fs/promises"),
    import("node:child_process"),
    import("node:path"),
  ]);
  const projectRoot = process.cwd();
  const assetPath = path.resolve(
    projectRoot,
    "flutter_app/assets/dialogue/dialogue-editor-override.json",
  );
  const buildScript = path.resolve(projectRoot, "scripts/build-flutter-web.mjs");
  const relativeAsset = path.relative(projectRoot, assetPath);
  const relativeScript = path.relative(projectRoot, buildScript);
  if (
    !relativeAsset ||
    relativeAsset.startsWith("..") ||
    !relativeScript ||
    relativeScript.startsWith("..")
  ) {
    throw new Error("빌드 대상 경로를 확인할 수 없습니다.");
  }

  const builtAt = new Date().toISOString();
  await mkdir(path.dirname(assetPath), { recursive: true });
  await writeFile(
    assetPath,
    `${JSON.stringify(
      { version: 1, appearanceVersion: 11, updatedAt: builtAt, scenes },
      null,
      2,
    )}\n`,
    "utf8",
  );

  const startedAt = Date.now();
  const logTail = await new Promise<string>((resolveBuild, rejectBuild) => {
    const child = spawn(process.execPath, [buildScript], {
      cwd: projectRoot,
      env: process.env,
      windowsHide: true,
      stdio: ["ignore", "pipe", "pipe"],
    });
    let output = "";
    const append = (chunk: Buffer) => {
      output = `${output}${chunk.toString("utf8")}`.slice(-12000);
    };
    child.stdout.on("data", append);
    child.stderr.on("data", append);
    const timeout = setTimeout(() => {
      child.kill();
      rejectBuild(new Error("게임 빌드가 5분 안에 끝나지 않았습니다."));
    }, 5 * 60 * 1000);
    child.once("error", (error) => {
      clearTimeout(timeout);
      rejectBuild(error);
    });
    child.once("exit", (code, signal) => {
      clearTimeout(timeout);
      if (code === 0) resolveBuild(output.trim());
      else {
        console.error("Dialogue game build failed:\n", output.trim());
        rejectBuild(
          new Error(
            `게임 빌드에 실패했습니다 (${signal ?? `exit ${code}`}). 서버 터미널의 로그를 확인해주세요.`,
          ),
        );
      }
    });
  });

  return { builtAt, durationMs: Date.now() - startedAt, logTail };
}

export async function GET() {
  return NextResponse.json({
    available: localBuildAvailable(),
    building: Boolean(buildGlobal.__dialogueBuildPromise),
  });
}

export async function POST(request: Request) {
  if (!localBuildAvailable()) {
    return NextResponse.json(
      { ok: false, message: "게임 빌드는 로컬 편집기에서만 실행할 수 있습니다." },
      { status: 409 },
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
  const scenes = normalizeScenes(
    body && typeof body === "object" ? (body as Record<string, unknown>).scenes : null,
  );
  if (!scenes) {
    return NextResponse.json(
      { ok: false, message: "대사 장면의 형식이나 개수를 확인해주세요." },
      { status: 400 },
    );
  }

  buildGlobal.__dialogueBuildPromise = persistAndBuild(scenes);
  try {
    const result = await buildGlobal.__dialogueBuildPromise;
    return NextResponse.json({ ok: true, ...result });
  } catch (error) {
    const message = error instanceof Error ? error.message : "게임 빌드에 실패했습니다.";
    return NextResponse.json({ ok: false, message }, { status: 500 });
  } finally {
    buildGlobal.__dialogueBuildPromise = undefined;
  }
}
