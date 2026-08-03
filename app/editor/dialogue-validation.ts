export const DIALOGUE_MAX_SCENES = 320;
export const DIALOGUE_MAX_TEXT_LENGTH = 6000;
export const CHARACTER_X_MIN = -60;
export const CHARACTER_X_MAX = 60;
export const CHARACTER_Y_MIN = -40;
export const CHARACTER_Y_MAX = 80;
export const CHARACTER_SCALE_MIN = 0.45;
export const CHARACTER_SCALE_MAX = 1.8;

export type ValidatedDialogueScene = {
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
  characterX: number;
  characterY: number;
  characterScale: number;
};

export type DialogueValidationResult =
  | { ok: true; scenes: ValidatedDialogueScene[] }
  | { ok: false; message: string };

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
] as const;

function normalizedText(value: unknown) {
  return typeof value === "string"
    ? value
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

export function validateDialogueScenes(value: unknown): DialogueValidationResult {
  if (!Array.isArray(value) || value.length === 0) {
    return { ok: false, message: "장면이 한 개 이상 필요합니다." };
  }
  if (value.length > DIALOGUE_MAX_SCENES) {
    return {
      ok: false,
      message: `장면은 최대 ${DIALOGUE_MAX_SCENES}개까지 저장할 수 있습니다.`,
    };
  }

  const ids = new Set<string>();
  const scenes: ValidatedDialogueScene[] = [];
  for (const [index, raw] of value.entries()) {
    if (!raw || typeof raw !== "object") {
      return { ok: false, message: `${index + 1}번 장면 형식이 올바르지 않습니다.` };
    }
    const source = raw as Record<string, unknown>;
    const normalized = Object.fromEntries(
      textFields.map((field) => [field, normalizedText(source[field])]),
    ) as Record<(typeof textFields)[number], string | null>;
    for (const field of textFields) {
      const text = normalized[field];
      if (text == null) {
        return {
          ok: false,
          message: `${index + 1}번 장면의 ${field} 값은 문자열이어야 합니다.`,
        };
      }
      if (text.length > DIALOGUE_MAX_TEXT_LENGTH) {
        return {
          ok: false,
          message: `${index + 1}번 장면의 ${field} 값이 ${DIALOGUE_MAX_TEXT_LENGTH}자를 넘었습니다.`,
        };
      }
    }
    const id = normalized.id!.trim();
    if (!id) return { ok: false, message: `${index + 1}번 장면 ID가 비어 있습니다.` };
    if (ids.has(id)) return { ok: false, message: `중복 장면 ID가 있습니다: ${id}` };
    ids.add(id);
    if (!normalized.speaker!.trim()) {
      return { ok: false, message: `${id} 장면의 화자가 비어 있습니다.` };
    }
    if (!validAssetPath(normalized.background!)) {
      return { ok: false, message: `${id} 장면의 배경 경로가 올바르지 않습니다.` };
    }
    if (!validAssetPath(normalized.character!)) {
      return { ok: false, message: `${id} 장면의 인물 경로가 올바르지 않습니다.` };
    }
    const characterX = optionalFiniteNumber(source.characterX, 0);
    const characterY = optionalFiniteNumber(source.characterY, 0);
    const characterScale = optionalFiniteNumber(source.characterScale, 1);
    if (
      characterX == null ||
      characterX < CHARACTER_X_MIN ||
      characterX > CHARACTER_X_MAX
    ) {
      return {
        ok: false,
        message: `${id} 장면의 캐릭터 가로 위치는 ${CHARACTER_X_MIN}~${CHARACTER_X_MAX} 사이여야 합니다.`,
      };
    }
    if (
      characterY == null ||
      characterY < CHARACTER_Y_MIN ||
      characterY > CHARACTER_Y_MAX
    ) {
      return {
        ok: false,
        message: `${id} 장면의 캐릭터 세로 위치는 ${CHARACTER_Y_MIN}~${CHARACTER_Y_MAX} 사이여야 합니다.`,
      };
    }
    if (
      characterScale == null ||
      characterScale < CHARACTER_SCALE_MIN ||
      characterScale > CHARACTER_SCALE_MAX
    ) {
      return {
        ok: false,
        message: `${id} 장면의 캐릭터 확대율은 ${CHARACTER_SCALE_MIN}~${CHARACTER_SCALE_MAX} 사이여야 합니다.`,
      };
    }
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
    });
  }
  return { ok: true, scenes };
}
