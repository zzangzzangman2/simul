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
const defaultDirecting = {
  characters: [],
  dialogueMode: "dialogue",
  textSpeed: 32,
  autoAdvanceMs: 0,
  transition: "fade",
  transitionDurationMs: 700,
  cameraX: 0,
  cameraY: 0,
  cameraZoom: 1,
  cameraShake: 0,
  ambientEffect: "none",
  lighting: 1,
  bgm: "",
  soundEffect: "",
  voice: "",
  audioVolume: 0.8,
  nextSceneId: "",
  condition: "",
  effects: "",
  choices: [],
  tags: [],
  notes: "",
};

function loadCanonicalDialogue() {
  const raw = fs.readFileSync(canonicalPath, "utf8");
  const decoded = JSON.parse(raw);
  if (decoded.contentVersion !== 4 || decoded.appearanceVersion !== 19) {
    throw new Error("Canonical dialogue versions must be content 4 / appearance 19.");
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
    const numberField = (key, fallback, minimum, maximum) => {
      const value = scene[key] ?? fallback;
      if (typeof value !== "number" || !Number.isFinite(value)) {
        throw new Error(`Scene ${index + 1} ${key} must be a finite number.`);
      }
      if (value < minimum || value > maximum) {
        throw new Error(
          `Scene ${index + 1} ${key} must be between ${minimum} and ${maximum}.`,
        );
      }
      return value;
    };
    const characterX = numberField("characterX", 0, -60, 60);
    const characterY = numberField("characterY", 0, -40, 80);
    const characterScale = numberField("characterScale", 1, 0.45, 1.8);
    return {
      ...defaultDirecting,
      ...scene,
      id,
      order: index + 1,
      characterX,
      characterY,
      characterScale,
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
const editorOutput = `import type { DialogueScene } from "./dialogue-types";
export type { DialogueScene } from "./dialogue-types";

export const initialDialogue: DialogueScene[] = ${JSON.stringify(scenes, null, 2)};
`;

const dartString = (value) => JSON.stringify(String(value)).replaceAll("$", "\\$");
const dartStageCharacters = (characters) => `<Map<String, Object>>[
${characters.map((character) => `      <String, Object>{
        "id": ${dartString(character.id)},
        "speaker": ${dartString(character.speaker)},
        "asset": ${dartString(character.asset)},
        "x": ${character.x},
        "y": ${character.y},
        "scale": ${character.scale},
        "opacity": ${character.opacity},
        "flipX": ${character.flipX},
        "zIndex": ${character.zIndex},
        "enter": ${dartString(character.enter)},
        "exit": ${dartString(character.exit)},
        "motion": ${dartString(character.motion)},
      }`).join(",\n")}
    ]`;
const dartChoices = (choices) => `<Map<String, Object>>[
${choices.map((choice) => `      <String, Object>{
        "id": ${dartString(choice.id)},
        "label": ${dartString(choice.label)},
        "targetSceneId": ${dartString(choice.targetSceneId)},
        "condition": ${dartString(choice.condition)},
        "effects": ${dartString(choice.effects)},
      }`).join(",\n")}
    ]`;
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
    "characterX": ${scene.characterX},
    "characterY": ${scene.characterY},
    "characterScale": ${scene.characterScale},
    "characters": ${dartStageCharacters(scene.characters)},
    "dialogueMode": ${dartString(scene.dialogueMode)},
    "textSpeed": ${scene.textSpeed},
    "autoAdvanceMs": ${scene.autoAdvanceMs},
    "transition": ${dartString(scene.transition)},
    "transitionDurationMs": ${scene.transitionDurationMs},
    "cameraX": ${scene.cameraX},
    "cameraY": ${scene.cameraY},
    "cameraZoom": ${scene.cameraZoom},
    "cameraShake": ${scene.cameraShake},
    "ambientEffect": ${dartString(scene.ambientEffect)},
    "lighting": ${scene.lighting},
    "bgm": ${dartString(scene.bgm)},
    "soundEffect": ${dartString(scene.soundEffect)},
    "voice": ${dartString(scene.voice)},
    "audioVolume": ${scene.audioVolume},
    "nextSceneId": ${dartString(scene.nextSceneId)},
    "condition": ${dartString(scene.condition)},
    "effects": ${dartString(scene.effects)},
    "choices": ${dartChoices(scene.choices)},
    "tags": <String>[${scene.tags.map(dartString).join(", ")}],
    "notes": ${dartString(scene.notes)},
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
