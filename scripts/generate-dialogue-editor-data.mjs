import fs from "node:fs";
import path from "node:path";

const project = process.cwd();
const canonicalPath = path.join(
  project,
  "flutter_app/assets/dialogue/dialogue-editor-override.json",
);
const editorOutputPath = path.join(project, "app/editor/dialogue-data.ts");
const dartOutputPath = path.join(
  project,
  "flutter_app/lib/dialogue/canonical_dialogue_data.dart",
);
const maximumScenes = 320;
const maximumTextLength = 6000;

function loadCanonicalDialogue() {
  const raw = fs.readFileSync(canonicalPath, "utf8");
  const decoded = JSON.parse(raw);
  if (decoded.contentVersion !== 3 || decoded.appearanceVersion !== 15) {
    throw new Error("Canonical dialogue versions must be content 3 / appearance 14.");
  }
  if (
    !Array.isArray(decoded.scenes) ||
    decoded.scenes.length === 0 ||
    decoded.scenes.length > maximumScenes
  ) {
    throw new Error(`Canonical dialogue must contain 1-${maximumScenes} scenes.`);
  }
  const ids = new Set();
  const textFields = [
    "id",
    "chapter",
    "date",
    "location",
    "speaker",
    "direction",
    "line",
    "background",
    "character",
  ];
  return decoded.scenes.map((scene, index) => {
    if (!scene || typeof scene !== "object") {
      throw new Error(`Scene ${index + 1} is not an object.`);
    }
    for (const field of textFields) {
      if (typeof scene[field] !== "string") {
        throw new Error(`Scene ${index + 1} ${field} must be a string.`);
      }
      if (scene[field].length > maximumTextLength) {
        throw new Error(`Scene ${index + 1} ${field} exceeds ${maximumTextLength} characters.`);
      }
    }
    const id = scene.id.trim();
    if (!id || ids.has(id)) throw new Error(`Duplicate or empty scene id: ${id}`);
    ids.add(id);
    return {
      ...scene,
      id,
      order: index + 1,
      direction: scene.direction
        .replaceAll("\\r\\n", "\n")
        .replaceAll("\\n", "\n")
        .replaceAll("\\r", "\n"),
      line: scene.line
        .replaceAll("\\r\\n", "\n")
        .replaceAll("\\n", "\n")
        .replaceAll("\\r", "\n"),
    };
  });
}

const scenes = loadCanonicalDialogue();
const editorOutput = `export type DialogueScene = {
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

const dartString = (value) => JSON.stringify(String(value)).replaceAll("$", "\\$");
const dartScenes = scenes
  .map(
    (scene) => `  <String, Object>{
    "order": ${scene.order},
    "id": ${dartString(scene.id)},
    "speaker": ${dartString(scene.speaker)},
    "line": ${dartString(scene.line)},
    "direction": ${dartString(scene.direction)},
    "date": ${dartString(scene.date)},
    "location": ${dartString(scene.location)},
    "background": ${dartString(scene.background)},
    "character": ${dartString(scene.character)},
  }`,
  )
  .join(",\n");
const dartOutput = `part of '../main.dart';

// GENERATED FILE. Edit the canonical dialogue JSON, then run npm run dialogue:sync.
const canonicalDialogueScenes = <Map<String, Object>>[
${dartScenes},
];
`;

fs.mkdirSync(path.dirname(editorOutputPath), { recursive: true });
fs.mkdirSync(path.dirname(dartOutputPath), { recursive: true });
fs.writeFileSync(editorOutputPath, editorOutput, "utf8");
fs.writeFileSync(dartOutputPath, dartOutput, "utf8");
console.log(`Dialogue editor synced from canonical JSON: ${scenes.length} scenes`);
