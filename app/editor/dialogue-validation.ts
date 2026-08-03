import {
  DEFAULT_SCENE_DIRECTING,
  type AmbientEffect,
  type CharacterEntrance,
  type CharacterMotion,
  type DialogueChoice,
  type DialogueMode,
  type DialogueScene,
  type DialogueStageCharacter,
  type SceneTransition,
} from "./dialogue-types";

export const DIALOGUE_MAX_SCENES = 320;
export const DIALOGUE_MAX_TEXT_LENGTH = 6000;
export const DIALOGUE_MAX_STAGE_CHARACTERS = 6;
export const DIALOGUE_MAX_CHOICES = 6;
export const CHARACTER_X_MIN = -60;
export const CHARACTER_X_MAX = 60;
export const CHARACTER_Y_MIN = -40;
export const CHARACTER_Y_MAX = 80;
export const CHARACTER_SCALE_MIN = 0.45;
export const CHARACTER_SCALE_MAX = 1.8;

export type ValidatedDialogueScene = DialogueScene;

export type DialogueValidationResult =
  | { ok: true; scenes: ValidatedDialogueScene[] }
  | { ok: false; message: string };

const sceneTextFields = [
  "id",
  "chapter",
  "date",
  "location",
  "speaker",
  "direction",
  "line",
  "background",
  "character",
  "bgm",
  "soundEffect",
  "voice",
  "nextSceneId",
  "condition",
  "effects",
  "notes",
] as const;
const sceneTextFallbacks: Partial<Record<(typeof sceneTextFields)[number], string>> = {
  bgm: DEFAULT_SCENE_DIRECTING.bgm,
  soundEffect: DEFAULT_SCENE_DIRECTING.soundEffect,
  voice: DEFAULT_SCENE_DIRECTING.voice,
  nextSceneId: DEFAULT_SCENE_DIRECTING.nextSceneId,
  condition: DEFAULT_SCENE_DIRECTING.condition,
  effects: DEFAULT_SCENE_DIRECTING.effects,
  notes: DEFAULT_SCENE_DIRECTING.notes,
};

const dialogueModes: DialogueMode[] = ["dialogue", "narration", "thought", "system"];
const transitions: SceneTransition[] = [
  "cut",
  "fade",
  "dissolve",
  "slide-left",
  "slide-right",
  "flash",
];
const ambientEffects: AmbientEffect[] = ["none", "rain", "snow", "dust", "flicker"];
const characterEntrances: CharacterEntrance[] = [
  "none",
  "fade",
  "slide-left",
  "slide-right",
  "pop",
];
const characterMotions: CharacterMotion[] = ["none", "idle", "breathing", "shake", "float"];

function normalizedText(value: unknown, fallback = "") {
  const source = value === undefined || value === null ? fallback : value;
  return typeof source === "string"
    ? source
        .replaceAll("\\r\\n", "\n")
        .replaceAll("\\n", "\n")
        .replaceAll("\\r", "\n")
    : null;
}

function validAssetPath(value: string) {
  if (!value) return true;
  return (
    value.startsWith("/play/assets/assets/") &&
    !value.includes("..") &&
    !value.includes("\\") &&
    !value.includes("?") &&
    !value.includes("#") &&
    !value.includes("\0")
  );
}

function optionalFiniteNumber(value: unknown, fallback: number) {
  if (value === undefined || value === null) return fallback;
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

function enumValue<T extends string>(value: unknown, allowed: T[], fallback: T): T | null {
  if (value === undefined || value === null) return fallback;
  return typeof value === "string" && allowed.includes(value as T) ? (value as T) : null;
}

function normalizedStringList(value: unknown, maximum: number) {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value) || value.length > maximum) return null;
  const result: string[] = [];
  for (const item of value) {
    const text = normalizedText(item)?.trim();
    if (text == null || text.length > 80) return null;
    if (text && !result.includes(text)) result.push(text);
  }
  return result;
}

function validateStageCharacters(
  value: unknown,
  sceneId: string,
): { ok: true; characters: DialogueStageCharacter[] } | { ok: false; message: string } {
  if (value === undefined || value === null) return { ok: true, characters: [] };
  if (!Array.isArray(value) || value.length > DIALOGUE_MAX_STAGE_CHARACTERS) {
    return {
      ok: false,
      message: `${sceneId} 장면의 무대 캐릭터는 최대 ${DIALOGUE_MAX_STAGE_CHARACTERS}명까지 가능합니다.`,
    };
  }
  const ids = new Set<string>();
  const characters: DialogueStageCharacter[] = [];
  for (const [index, raw] of value.entries()) {
    if (!raw || typeof raw !== "object") {
      return { ok: false, message: `${sceneId} 장면의 ${index + 1}번째 캐릭터 형식이 잘못됐습니다.` };
    }
    const source = raw as Record<string, unknown>;
    const id = normalizedText(source.id, `layer-${index + 1}`)?.trim();
    const speaker = normalizedText(source.speaker)?.trim();
    const asset = normalizedText(source.asset)?.trim();
    if (!id || ids.has(id)) {
      return { ok: false, message: `${sceneId} 장면의 캐릭터 레이어 ID가 비었거나 중복됩니다.` };
    }
    if (speaker == null || asset == null || !validAssetPath(asset)) {
      return { ok: false, message: `${sceneId} 장면의 ${id} 캐릭터 정보 또는 자산 경로가 잘못됐습니다.` };
    }
    const x = optionalFiniteNumber(source.x, 0);
    const y = optionalFiniteNumber(source.y, 0);
    const scale = optionalFiniteNumber(source.scale, 1);
    const opacity = optionalFiniteNumber(source.opacity, 1);
    const zIndex = optionalFiniteNumber(source.zIndex, index);
    const enter = enumValue(source.enter, characterEntrances, "fade");
    const exit = enumValue(source.exit, characterEntrances, "fade");
    const motion = enumValue(source.motion, characterMotions, "none");
    if (
      x == null ||
      x < CHARACTER_X_MIN ||
      x > CHARACTER_X_MAX ||
      y == null ||
      y < CHARACTER_Y_MIN ||
      y > CHARACTER_Y_MAX ||
      scale == null ||
      scale < CHARACTER_SCALE_MIN ||
      scale > CHARACTER_SCALE_MAX ||
      opacity == null ||
      opacity < 0 ||
      opacity > 1 ||
      zIndex == null ||
      zIndex < 0 ||
      zIndex > 20 ||
      enter == null ||
      exit == null ||
      motion == null
    ) {
      return { ok: false, message: `${sceneId} 장면의 ${id} 캐릭터 배치 값이 허용 범위를 벗어났습니다.` };
    }
    ids.add(id);
    characters.push({
      id,
      speaker,
      asset,
      x: Math.round(x * 10) / 10,
      y: Math.round(y * 10) / 10,
      scale: Math.round(scale * 100) / 100,
      opacity: Math.round(opacity * 100) / 100,
      flipX: source.flipX === true,
      zIndex: Math.round(zIndex),
      enter,
      exit,
      motion,
    });
  }
  characters.sort((a, b) => a.zIndex - b.zIndex);
  return { ok: true, characters };
}

function validateChoices(
  value: unknown,
  sceneId: string,
): { ok: true; choices: DialogueChoice[] } | { ok: false; message: string } {
  if (value === undefined || value === null) return { ok: true, choices: [] };
  if (!Array.isArray(value) || value.length > DIALOGUE_MAX_CHOICES) {
    return { ok: false, message: `${sceneId} 장면의 선택지는 최대 ${DIALOGUE_MAX_CHOICES}개까지 가능합니다.` };
  }
  const ids = new Set<string>();
  const choices: DialogueChoice[] = [];
  for (const [index, raw] of value.entries()) {
    if (!raw || typeof raw !== "object") {
      return { ok: false, message: `${sceneId} 장면의 ${index + 1}번째 선택지 형식이 잘못됐습니다.` };
    }
    const source = raw as Record<string, unknown>;
    const id = normalizedText(source.id, `choice-${index + 1}`)?.trim();
    const label = normalizedText(source.label)?.trim();
    const targetSceneId = normalizedText(source.targetSceneId)?.trim();
    const condition = normalizedText(source.condition)?.trim();
    const effects = normalizedText(source.effects)?.trim();
    if (!id || ids.has(id) || label == null || !label || targetSceneId == null || condition == null || effects == null) {
      return { ok: false, message: `${sceneId} 장면의 선택지 ID·문구·이동 대상 형식을 확인해주세요.` };
    }
    if ([label, targetSceneId, condition, effects].some((text) => text.length > 500)) {
      return { ok: false, message: `${sceneId} 장면의 선택지 텍스트가 너무 깁니다.` };
    }
    ids.add(id);
    choices.push({ id, label, targetSceneId, condition, effects });
  }
  return { ok: true, choices };
}

export function validateDialogueScenes(value: unknown): DialogueValidationResult {
  if (!Array.isArray(value) || value.length === 0) {
    return { ok: false, message: "장면이 한 개 이상 필요합니다." };
  }
  if (value.length > DIALOGUE_MAX_SCENES) {
    return { ok: false, message: `장면은 최대 ${DIALOGUE_MAX_SCENES}개까지 저장할 수 있습니다.` };
  }

  const ids = new Set<string>();
  const scenes: ValidatedDialogueScene[] = [];
  for (const [index, raw] of value.entries()) {
    if (!raw || typeof raw !== "object") {
      return { ok: false, message: `${index + 1}번 장면 형식이 올바르지 않습니다.` };
    }
    const source = raw as Record<string, unknown>;
    const normalized = Object.fromEntries(
      sceneTextFields.map((field) => [field, normalizedText(source[field], sceneTextFallbacks[field] ?? "")]),
    ) as Record<(typeof sceneTextFields)[number], string | null>;
    for (const field of sceneTextFields) {
      const text = normalized[field];
      if (text == null) return { ok: false, message: `${index + 1}번 장면의 ${field} 값은 문자열이어야 합니다.` };
      if (text.length > DIALOGUE_MAX_TEXT_LENGTH) {
        return { ok: false, message: `${index + 1}번 장면의 ${field} 값이 ${DIALOGUE_MAX_TEXT_LENGTH}자를 넘었습니다.` };
      }
    }
    const id = normalized.id!.trim();
    if (!id || ids.has(id)) return { ok: false, message: `비어 있거나 중복 장면 ID입니다: ${id}` };
    ids.add(id);
    if (!normalized.speaker!.trim()) return { ok: false, message: `${id} 장면의 화자가 비어 있습니다.` };
    for (const field of ["background", "character", "bgm", "soundEffect", "voice"] as const) {
      if (!validAssetPath(normalized[field]!)) {
        return { ok: false, message: `${id} 장면의 ${field} 자산 경로가 올바르지 않습니다.` };
      }
    }

    const characterX = optionalFiniteNumber(source.characterX, 0);
    const characterY = optionalFiniteNumber(source.characterY, 0);
    const characterScale = optionalFiniteNumber(source.characterScale, 1);
    const textSpeed = optionalFiniteNumber(source.textSpeed, DEFAULT_SCENE_DIRECTING.textSpeed);
    const autoAdvanceMs = optionalFiniteNumber(source.autoAdvanceMs, DEFAULT_SCENE_DIRECTING.autoAdvanceMs);
    const transitionDurationMs = optionalFiniteNumber(source.transitionDurationMs, DEFAULT_SCENE_DIRECTING.transitionDurationMs);
    const cameraX = optionalFiniteNumber(source.cameraX, DEFAULT_SCENE_DIRECTING.cameraX);
    const cameraY = optionalFiniteNumber(source.cameraY, DEFAULT_SCENE_DIRECTING.cameraY);
    const cameraZoom = optionalFiniteNumber(source.cameraZoom, DEFAULT_SCENE_DIRECTING.cameraZoom);
    const cameraShake = optionalFiniteNumber(source.cameraShake, DEFAULT_SCENE_DIRECTING.cameraShake);
    const lighting = optionalFiniteNumber(source.lighting, DEFAULT_SCENE_DIRECTING.lighting);
    const audioVolume = optionalFiniteNumber(source.audioVolume, DEFAULT_SCENE_DIRECTING.audioVolume);
    const dialogueMode = enumValue(source.dialogueMode, dialogueModes, normalized.speaker === "이야기" ? "narration" : "dialogue");
    const transition = enumValue(source.transition, transitions, DEFAULT_SCENE_DIRECTING.transition);
    const ambientEffect = enumValue(source.ambientEffect, ambientEffects, DEFAULT_SCENE_DIRECTING.ambientEffect);
    if (
      characterX == null || characterX < CHARACTER_X_MIN || characterX > CHARACTER_X_MAX ||
      characterY == null || characterY < CHARACTER_Y_MIN || characterY > CHARACTER_Y_MAX ||
      characterScale == null || characterScale < CHARACTER_SCALE_MIN || characterScale > CHARACTER_SCALE_MAX ||
      textSpeed == null || textSpeed < 8 || textSpeed > 120 ||
      autoAdvanceMs == null || autoAdvanceMs < 0 || autoAdvanceMs > 30000 ||
      transitionDurationMs == null || transitionDurationMs < 0 || transitionDurationMs > 5000 ||
      cameraX == null || cameraX < -50 || cameraX > 50 ||
      cameraY == null || cameraY < -50 || cameraY > 50 ||
      cameraZoom == null || cameraZoom < 0.5 || cameraZoom > 2.5 ||
      cameraShake == null || cameraShake < 0 || cameraShake > 1 ||
      lighting == null || lighting < 0.2 || lighting > 1.5 ||
      audioVolume == null || audioVolume < 0 || audioVolume > 1 ||
      dialogueMode == null || transition == null || ambientEffect == null
    ) {
      return { ok: false, message: `${id} 장면의 연출 수치가 허용 범위를 벗어났습니다.` };
    }
    const stageCharacters = validateStageCharacters(source.characters, id);
    if (!stageCharacters.ok) return stageCharacters;
    const choices = validateChoices(source.choices, id);
    if (!choices.ok) return choices;
    const tags = normalizedStringList(source.tags, 12);
    if (tags == null) return { ok: false, message: `${id} 장면의 태그 형식이 잘못됐습니다.` };

    scenes.push({
      id,
      order: index + 1,
      chapter: normalized.chapter!,
      date: normalized.date!,
      location: normalized.location!,
      speaker: normalized.speaker!,
      direction: normalized.direction!,
      line: normalized.line!,
      background: normalized.background!,
      character: normalized.character!,
      characterX: Math.round(characterX * 10) / 10,
      characterY: Math.round(characterY * 10) / 10,
      characterScale: Math.round(characterScale * 100) / 100,
      characters: stageCharacters.characters,
      dialogueMode,
      textSpeed: Math.round(textSpeed),
      autoAdvanceMs: Math.round(autoAdvanceMs),
      transition,
      transitionDurationMs: Math.round(transitionDurationMs),
      cameraX: Math.round(cameraX * 10) / 10,
      cameraY: Math.round(cameraY * 10) / 10,
      cameraZoom: Math.round(cameraZoom * 100) / 100,
      cameraShake: Math.round(cameraShake * 100) / 100,
      ambientEffect,
      lighting: Math.round(lighting * 100) / 100,
      bgm: normalized.bgm!,
      soundEffect: normalized.soundEffect!,
      voice: normalized.voice!,
      audioVolume: Math.round(audioVolume * 100) / 100,
      nextSceneId: normalized.nextSceneId!.trim(),
      condition: normalized.condition!.trim(),
      effects: normalized.effects!.trim(),
      choices: choices.choices,
      tags,
      notes: normalized.notes!,
    });
  }

  for (const scene of scenes) {
    if (scene.nextSceneId && !ids.has(scene.nextSceneId)) {
      return { ok: false, message: `${scene.id} 장면의 다음 장면 ${scene.nextSceneId}을 찾을 수 없습니다.` };
    }
    for (const choice of scene.choices) {
      if (choice.targetSceneId && !ids.has(choice.targetSceneId)) {
        return { ok: false, message: `${scene.id} 장면의 선택지 대상 ${choice.targetSceneId}을 찾을 수 없습니다.` };
      }
    }
  }
  return { ok: true, scenes };
}
