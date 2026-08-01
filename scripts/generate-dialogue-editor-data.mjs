import fs from "node:fs";
import path from "node:path";

const project = process.cwd();
const sourcePath = path.join(project, "flutter_app/lib/visual_novel_onboarding.dart");
const outputPath = path.join(project, "app/editor/dialogue-data.ts");
const source = fs.readFileSync(sourcePath, "utf8");
const stringConstants = new Map(
  Array.from(
    source.matchAll(/const\s+([A-Za-z_]\w*)\s*=\s*'((?:\\.|[^'])*)';/gs),
    (match) => [match[1], decodeDartString(match[2])],
  ),
);

function between(startMarker, endMarker) {
  const start = source.indexOf(startMarker);
  const end = source.indexOf(endMarker, start + startMarker.length);
  if (start < 0 || end < 0) throw new Error(`Missing story block: ${startMarker}`);
  return source.slice(start, end);
}

function decodeDartString(value) {
  return value
    .replaceAll("\\n", "\n")
    .replaceAll("\\\\'", "'")
    .replaceAll("\\\\", "\\");
}

function normalizeDialogueText(value) {
  return typeof value === "string"
    ? value
        .replaceAll("\\r\\n", "\n")
        .replaceAll("\\n", "\n")
        .replaceAll("\\r", "\n")
    : value;
}

function parseRules(text) {
  const rules = [];
  const pattern =
    /^\s*(<=\s*\d+|\d+(?:\s*\|\|\s*\d+)*|_)\s*=>\s*(?:\r?\n\s*)?(?:'((?:\\.|[^'])*)'|([A-Za-z_]\w*)),?\s*$/gm;
  for (const match of text.matchAll(pattern)) {
    const value = match[2] === undefined
      ? stringConstants.get(match[3])
      : decodeDartString(match[2]);
    if (value === undefined) continue;
    rules.push({ condition: match[1].replaceAll(/\s/g, ""), value });
  }
  return rules;
}

function resolveRule(rules, beat, fallback = "") {
  for (const rule of rules) {
    if (rule.condition === "_") return rule.value;
    if (rule.condition.startsWith("<=")) {
      if (beat <= Number(rule.condition.slice(2))) return rule.value;
      continue;
    }
    if (rule.condition.split("||").map(Number).includes(beat)) return rule.value;
  }
  return fallback;
}

function constant(name) {
  const match = source.match(new RegExp(`const ${name} = (\\d+);`));
  if (!match) throw new Error(`Missing story constant: ${name}`);
  return Number(match[1]);
}

const beatCount = constant("_onboardingBeatCount");
const speakerRules = parseRules(between("  String get _speaker", "  String get _line"));
const lineRules = parseRules(between("  String get _line", "  String? get _stageDirection"));
const directionSource = between(
  "  String? get _stageDirection",
  "  String get _historyLine",
);
const directionRules = parseRules(directionSource);
const backgroundRules = parseRules(between("  String get _background", "  String get _location"));
const locationRules = parseRules(between("  String get _location", "  String get _dateLabel"));
const dateRules = parseRules(between("  String get _dateLabel", "  String? get _character"));
const characterRules = parseRules(between("  String? get _character", "  bool get _isAcademyTeacherBeat"));
const teacherBeats = Array.from(
  between("  bool get _isAcademyTeacherBeat", "  String get _teacherPoseAsset").matchAll(
    /_beat == (\d+)/g,
  ),
  (match) => Number(match[1]),
);

function teacherPoseForBeat(beat) {
  if ([34, 42, 51, 55, 63, 67].includes(beat)) {
    return "assets/images/주식선생님/22_포즈1_주인공그림체_공통슬롯_투명.png";
  }
  if ([37, 44, 59, 71].includes(beat)) {
    return "assets/images/주식선생님/23_포즈2_주인공그림체_공통슬롯_투명.png";
  }
  if ([35, 43, 49, 57, 61, 69].includes(beat)) {
    return "assets/images/주식선생님/24_포즈3_주인공그림체_공통슬롯_투명.png";
  }
  if ([45, 53, 64, 72].includes(beat)) {
    return "assets/images/주식선생님/26_포즈5_주인공그림체_공통슬롯_투명.png";
  }
  return "assets/images/주식선생님/22_포즈1_주인공그림체_공통슬롯_투명.png";
}

function webAsset(asset) {
  return asset ? `/play/assets/${asset}` : "";
}

function chapterFor(beat, location) {
  if (beat <= 15) return "1장 · 사람을 자본으로 만드는 밤";
  if (beat <= 22) return "2장 · 한 손으로 드는 전부";
  if (beat <= 31) return "3장 · 설명서 학준";
  if (beat <= 53) return "4장 · 왜 하필 너였을까";
  if (beat <= 65) return "5장 · 열 명이 쓰는 한 방";
  if (beat <= 72) return "6장 · PC 열 대가 켜지는 아침";
  return `추가 장면 · ${location || "새 장소"}`;
}

let scenes = Array.from({ length: beatCount }, (_, beat) => {
  const location = resolveRule(locationRules, beat, "새 장소");
  let speaker = resolveRule(speakerRules, beat, "이야기");
  let line = resolveRule(lineRules, beat, "");
  let direction = resolveRule(directionRules, beat, "");
  let character = resolveRule(characterRules, beat, "");
  if (teacherBeats.includes(beat)) {
    character = teacherPoseForBeat(beat);
  }
  return {
    id: `scene-${String(beat + 1).padStart(2, "0")}`,
    order: beat + 1,
    chapter: chapterFor(beat, location),
    date: resolveRule(dateRules, beat, ""),
    location,
    speaker,
    direction,
    line,
    background: webAsset(resolveRule(backgroundRules, beat, "")),
    character: webAsset(character),
  };
});

// The bundled override is the canonical authored story once it exists. The
// Dart source remains a safe fallback, but editor regeneration must not throw
// away scenes that were added after the original source beats.
const overridePath = path.join(
  project,
  "flutter_app/assets/dialogue/dialogue-editor-override.json",
);
if (fs.existsSync(overridePath)) {
  try {
    const originalOverride = fs.readFileSync(overridePath, "utf8");
    const override = JSON.parse(originalOverride);
    if (Array.isArray(override.scenes) && override.scenes.length > 0) {
      const upgradeAppearance = override.appearanceVersion !== 11;
      const defaultById = new Map(scenes.map((scene) => [scene.id, scene]));
      override.scenes = override.scenes
        .map((scene) => ({
          ...scene,
          direction: normalizeDialogueText(scene.direction),
          line: normalizeDialogueText(scene.line),
          background: upgradeAppearance
            ? defaultById.get(scene.id)?.background ?? scene.background ?? ""
            : scene.background ?? "",
          character: upgradeAppearance
            ? defaultById.get(scene.id)?.character ?? scene.character ?? ""
            : scene.character ?? "",
        }))
        .sort((left, right) => left.order - right.order);
      override.appearanceVersion = 11;
      const normalizedOverride = `${JSON.stringify(override, null, 2)}\n`;
      if (normalizedOverride !== originalOverride) {
        fs.writeFileSync(overridePath, normalizedOverride, "utf8");
      }
      scenes = override.scenes;
    }
  } catch {
    // A damaged local override falls back to the source dialogue.
  }
}

const output = `export type DialogueScene = {
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

export const initialDialogue: DialogueScene[] = ${JSON.stringify(scenes, null, 2)};
`;

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(outputPath, output, "utf8");
console.log(`Dialogue editor synced: ${scenes.length} scenes`);
