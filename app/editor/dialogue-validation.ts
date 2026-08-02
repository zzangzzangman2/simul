export const DIALOGUE_MAX_SCENES = 240;
export const DIALOGUE_MAX_TEXT_LENGTH = 6000;

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
    });
  }
  return { ok: true, scenes };
}
