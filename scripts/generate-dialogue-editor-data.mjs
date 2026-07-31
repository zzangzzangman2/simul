import fs from "node:fs";
import path from "node:path";

const project = process.cwd();
const sourcePath = path.join(project, "flutter_app/lib/visual_novel_onboarding.dart");
const outputPath = path.join(project, "app/editor/dialogue-data.ts");
const source = fs.readFileSync(sourcePath, "utf8");

function between(startMarker, endMarker) {
  const start = source.indexOf(startMarker);
  const end = source.indexOf(endMarker, start + startMarker.length);
  if (start < 0 || end < 0) throw new Error(`Missing story block: ${startMarker}`);
  return source.slice(start, end);
}

function decodeDartString(value) {
  return value
    .replaceAll("\\\\n", "\n")
    .replaceAll("\\\\'", "'")
    .replaceAll("\\\\", "\\");
}

function parseRules(text) {
  const rules = [];
  const pattern =
    /^\s*(<=\s*\d+|\d+(?:\s*\|\|\s*\d+)*|_)\s*=>\s*(?:\r?\n\s*)?'((?:\\.|[^'])*)',?\s*$/gm;
  for (const match of text.matchAll(pattern)) {
    rules.push({ condition: match[1].replaceAll(/\s/g, ""), value: decodeDartString(match[2]) });
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
const policyBeat = constant("_policyBriefingBeat");
const speakerRules = parseRules(between("  String get _speaker", "  String get _line"));
const lineRules = parseRules(between("  String get _line", "  String get _policyBriefingSpeaker"));
const directionSource = between(
  "  String? get _stageDirection",
  "  String get _historyLine",
);
const directionRules = parseRules(
  directionSource.replace(
    /^\s*\d+\s*=>\s*switch \(_activePolicyFile\) \{[\s\S]*?^\s*\},\s*$/m,
    "",
  ),
);
const backgroundRules = parseRules(between("  String get _background", "  String get _location"));
const locationRules = parseRules(between("  String get _location", "  String get _dateLabel"));
const dateRules = parseRules(between("  String get _dateLabel", "  String? get _character"));
const characterRules = parseRules(between("  String? get _character", "  bool get _isAcademyTeacherBeat"));
const teacherBeats = Array.from(
  between("  bool get _isAcademyTeacherBeat", "  bool get _isAcademyReceptionistBeat").matchAll(
    /_beat == (\d+)/g,
  ),
  (match) => Number(match[1]),
);

function webAsset(asset) {
  return asset ? `/play/assets/${asset}` : "";
}

function chapterFor(beat, location) {
  if (beat <= 15) return "1장 · 사람을 자본으로 만드는 밤";
  if (beat <= 22) return "2장 · 한 손으로 드는 전부";
  if (beat <= 31) return "3장 · 설명서 학준";
  if (beat <= 53) return "4장 · 왜 하필 너였을까";
  return `추가 장면 · ${location || "새 장소"}`;
}

const scenes = Array.from({ length: beatCount }, (_, beat) => {
  const location = resolveRule(locationRules, beat, "새 장소");
  let speaker = resolveRule(speakerRules, beat, "이야기");
  let line = resolveRule(lineRules, beat, "");
  let direction = resolveRule(directionRules, beat, "");
  let character = resolveRule(characterRules, beat, "");
  if (beat === policyBeat) {
    speaker = "정책 보고서";
    line = "보고서 다섯 권을 차례로 확인한다.";
    direction =
      "수출산업·인구전망·보호아동·국가계좌·특별법 보고서가 탁자 위에 놓였다.";
    character = "";
  }
  if (teacherBeats.includes(beat)) {
    character =
      "assets/images/주식선생님/22_포즈1_주인공그림체_공통슬롯_투명.png";
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
