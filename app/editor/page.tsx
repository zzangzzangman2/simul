"use client";

import Image from "next/image";
import {
  ChangeEvent,
  KeyboardEvent,
  PointerEvent as ReactPointerEvent,
  WheelEvent as ReactWheelEvent,
  useEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import {
  dialogueCharacterBySpeaker,
  dialogueCharacters,
  DialoguePose,
} from "./character-catalog";
import {
  dialogueBackgroundByAsset,
  dialogueBackgrounds,
} from "./background-catalog";
import { DialogueScene, initialDialogue } from "./dialogue-data";
import DirectorStudio from "./director-studio";
import SceneToolbox from "./scene-toolbox";
import {
  DEFAULT_SCENE_DIRECTING,
  type DialogueStageCharacter,
} from "./dialogue-types";
import {
  CHARACTER_SCALE_MAX,
  CHARACTER_SCALE_MIN,
  CHARACTER_X_MAX,
  CHARACTER_X_MIN,
  CHARACTER_Y_MAX,
  CHARACTER_Y_MIN,
  validateDialogueScenes,
} from "./dialogue-validation";
import styles from "./editor.module.css";

const STORAGE_KEY = "project-decimal-dialogue-editor-v2";
const GAME_STORAGE_KEY = "project-decimal-dialogue-runtime-v2";
const FLUTTER_GAME_STORAGE_KEY = `flutter.${GAME_STORAGE_KEY}`;
const BUILD_STORAGE_KEY = "project-decimal-dialogue-built-v2";
const CONTENT_VERSION = 3;
const APPEARANCE_VERSION = 17;

const HAN_SUA_V2_FILENAME_MIGRATIONS = {
  "01_neutral_quality_v2.png": "01_neutral_wavy_v3.png",
  "02_warm_smile_quality_v2.png": "02_warm_smile_wave_v3.png",
  "03_bright_laugh_quality_v2.png": "03_bright_laugh_v3.png",
  "04_surprised_quality_v2.png": "05_surprised_v3.png",
  "05_worried_quality_v2.png": "06_worried_v3.png",
  "06_annoyed_quality_v2.png": "07_annoyed_v3.png",
  "07_determined_quality_v2.png": "08_determined_v3.png",
  "08_explaining_quality_v2.png": "09_explaining_v3.png",
} as const;
const HAN_SUA_ASSET_DIRECTORY = "production_soft_painted/han_sua/";

type PublishStatus = "idle" | "building" | "success" | "error";
type PublishMode = "quick" | "full";
type TransformScope = "scene" | "speaker";
type CharacterFramePatch = Partial<
  Pick<DialogueScene, "characterX" | "characterY" | "characterScale">
>;
type CharacterDragState = {
  pointerId: number;
  startClientX: number;
  startClientY: number;
  startX: number;
  startY: number;
  sceneId: string;
  speaker: string;
  scope: TransformScope;
  layerId?: string;
};
type SceneHistoryEntry = {
  scenes: DialogueScene[];
  selectedId: string;
};
type SceneUpdateOptions = {
  recordHistory?: boolean;
  coalesceKey?: string | null;
};
type SceneHistoryCoalesce = {
  key: string;
  at: number;
};

const HISTORY_LIMIT = 60;
const HISTORY_COALESCE_MS = 700;

const CHARACTER_FRAME_PRESETS = [
  { id: "full", label: "전신", characterX: 0, characterY: 8, characterScale: 0.62 },
  { id: "default", label: "기본", characterX: 0, characterY: 0, characterScale: 1 },
  { id: "close", label: "상반신", characterX: 0, characterY: -1, characterScale: 1.28 },
] as const;

function clampNumber(
  value: unknown,
  fallback: number,
  minimum: number,
  maximum: number,
) {
  const numeric =
    typeof value === "number" && Number.isFinite(value) ? value : fallback;
  return Math.min(maximum, Math.max(minimum, numeric));
}

function editorNow() {
  return Date.now();
}


const CHARACTER_GROUPS = [
  "주요 인물",
  "1999년 국정원",
  "프로젝트 데시멀",
  "화면 인물 없음",
] as const;

type SavedDraft = {
  version: 1;
  contentVersion?: number;
  appearanceVersion?: number;
  updatedAt: string;
  scenes: DialogueScene[];
};

function normalizeDialogueText(value: string) {
  return value
    .replaceAll("\\r\\n", "\n")
    .replaceAll("\\n", "\n")
    .replaceAll("\\r", "\n");
}

function migrateHanSuaCharacterAsset(asset: string) {
  const directoryIndex = asset.lastIndexOf(HAN_SUA_ASSET_DIRECTORY);
  if (directoryIndex < 0) return asset;
  const filenameIndex = directoryIndex + HAN_SUA_ASSET_DIRECTORY.length;
  const filename = asset.slice(filenameIndex);
  const migrated =
    HAN_SUA_V2_FILENAME_MIGRATIONS[
      filename as keyof typeof HAN_SUA_V2_FILENAME_MIGRATIONS
    ];
  return migrated ? `${asset.slice(0, filenameIndex)}${migrated}` : asset;
}

function normalizeScene(scene: DialogueScene): DialogueScene {
  return {
    ...DEFAULT_SCENE_DIRECTING,
    ...scene,
    direction: normalizeDialogueText(scene.direction),
    line: normalizeDialogueText(scene.line),
    character: migrateHanSuaCharacterAsset(scene.character),
    characterX:
      Math.round(clampNumber(scene.characterX, 0, CHARACTER_X_MIN, CHARACTER_X_MAX) * 10) /
      10,
    characterY:
      Math.round(clampNumber(scene.characterY, 0, CHARACTER_Y_MIN, CHARACTER_Y_MAX) * 10) /
      10,
    characterScale:
      Math.round(clampNumber(scene.characterScale, 1, CHARACTER_SCALE_MIN, CHARACTER_SCALE_MAX) * 100) /
      100,
    characters: (scene.characters ?? []).map((character, index) => ({
      ...character,
      id: character.id || `layer-${index + 1}`,
      speaker: character.speaker || scene.speaker,
      asset: migrateHanSuaCharacterAsset(character.asset || ""),
      x: Math.round(clampNumber(character.x, 0, CHARACTER_X_MIN, CHARACTER_X_MAX) * 10) / 10,
      y: Math.round(clampNumber(character.y, 0, CHARACTER_Y_MIN, CHARACTER_Y_MAX) * 10) / 10,
      scale: Math.round(clampNumber(character.scale, 1, CHARACTER_SCALE_MIN, CHARACTER_SCALE_MAX) * 100) / 100,
      opacity: Math.round(clampNumber(character.opacity, 1, 0, 1) * 100) / 100,
      flipX: character.flipX === true,
      zIndex: Math.round(clampNumber(character.zIndex, index, 0, 20)),
      enter: character.enter || "fade",
      exit: character.exit || "fade",
      motion: character.motion || "none",
    })),
    dialogueMode: scene.dialogueMode ?? (scene.speaker === "이야기" ? "narration" : "dialogue"),
    textSpeed: Math.round(clampNumber(scene.textSpeed, 32, 8, 120)),
    autoAdvanceMs: Math.round(clampNumber(scene.autoAdvanceMs, 0, 0, 30000)),
    transition: scene.transition ?? "fade",
    transitionDurationMs: Math.round(clampNumber(scene.transitionDurationMs, 700, 0, 5000)),
    cameraX: Math.round(clampNumber(scene.cameraX, 0, -50, 50) * 10) / 10,
    cameraY: Math.round(clampNumber(scene.cameraY, 0, -50, 50) * 10) / 10,
    cameraZoom: Math.round(clampNumber(scene.cameraZoom, 1, 0.5, 2.5) * 100) / 100,
    cameraShake: Math.round(clampNumber(scene.cameraShake, 0, 0, 1) * 100) / 100,
    ambientEffect: scene.ambientEffect ?? "none",
    lighting: Math.round(clampNumber(scene.lighting, 1, 0.2, 1.5) * 100) / 100,
    bgm: scene.bgm ?? "",
    soundEffect: scene.soundEffect ?? "",
    voice: scene.voice ?? "",
    audioVolume: Math.round(clampNumber(scene.audioVolume, 0.8, 0, 1) * 100) / 100,
    nextSceneId: scene.nextSceneId ?? "",
    condition: scene.condition ?? "",
    effects: scene.effects ?? "",
    choices: (scene.choices ?? []).map((choice) => ({ ...choice })),
    tags: [...(scene.tags ?? [])],
    notes: scene.notes ?? "",
  };
}

function cloneInitial() {
  return initialDialogue.map((scene) => normalizeScene({ ...scene }));
}

function validScenes(value: unknown): value is DialogueScene[] {
  return validateDialogueScenes(value).ok;
}

function mergeWithCurrentStory(
  saved: DialogueScene[],
  upgradeAppearance = false,
  upgradeContent = false,
) {
  const savedById = new Map(saved.map((scene) => [scene.id, scene]));
  const builtInIds = new Set(initialDialogue.map((scene) => scene.id));
  if (upgradeContent) {
    return [
      ...initialDialogue,
      ...saved.filter((scene) => !builtInIds.has(scene.id)),
    ].map((scene, index) => normalizeScene({ ...scene, order: index + 1 }));
  }
  return [
    ...initialDialogue.map((scene) => {
      const merged = { ...scene, ...(savedById.get(scene.id) ?? {}) };
      return upgradeAppearance
        ? {
            ...merged,
            background: scene.background,
            character: scene.character,
            characterX: scene.characterX,
            characterY: scene.characterY,
            characterScale: scene.characterScale,
          }
        : merged;
    }),
    ...saved.filter((scene) => !builtInIds.has(scene.id)),
  ].map((scene, index) => normalizeScene({ ...scene, order: index + 1 }));
}

function sceneFingerprint(scene: DialogueScene | undefined) {
  if (!scene) return "";
  return JSON.stringify(scene);
}

function downloadFile(name: string, contents: string, type: string) {
  const blob = new Blob([contents], { type });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = name;
  anchor.click();
  URL.revokeObjectURL(url);
}

function makeTxt(scenes: DialogueScene[]) {
  return scenes
    .map((scene, index) => {
      const chunks = [
        `[${String(index + 1).padStart(2, "0")}] ${scene.date} | ${scene.location}`,
        `<${scene.chapter}>`,
      ];
      if (scene.direction.trim()) chunks.push(`[지문] ${scene.direction.trim()}`);
      chunks.push(`[${scene.speaker.trim() || "화자 없음"}]`, scene.line.trim());
      return chunks.join("\n");
    })
    .join("\n\n" + "=".repeat(56) + "\n\n");
}

function tasteChecks(scene: DialogueScene) {
  const checks: string[] = [];
  if (scene.line.trim().length > 95) {
    checks.push("대사가 길어요. 숨 쉴 곳에서 두 장면으로 나눠보세요.");
  }
  if (!scene.direction.trim()) {
    checks.push("손짓이나 표정 한 줄을 넣으면 인물이 덜 떠 보입니다.");
  }
  const stiffWords = ["교육생", "선발되었습니다", "진행합니다", "확인하십시오", "과정입니다"];
  const found = stiffWords.find((word) => scene.line.includes(word));
  if (found) {
    checks.push(`‘${found}’이 조금 딱딱해요. 인물이 실제로 입 밖에 낼 말인지 읽어보세요.`);
  }
  if ((scene.line.match(/[,.]/g) ?? []).length >= 6) {
    checks.push("한 문장에 정보가 많아요. 반문이나 끼어들기를 한 번 넣어보세요.");
  }
  return checks;
}

function posesForScene(speaker: string, character: string): DialoguePose[] {
  const catalogPoses = dialogueCharacterBySpeaker.get(speaker)?.poses ?? [];
  if (!character || catalogPoses.some((pose) => pose.asset === character)) {
    return catalogPoses.length
      ? catalogPoses
      : [{ id: "00", label: "인물 없음", asset: "" }];
  }
  return [
    ...catalogPoses,
    { id: "custom", label: "현재 이미지", asset: character },
  ];
}

function SpeakerOptions({ customSpeakers }: { customSpeakers: string[] }) {
  return (
    <>
      {CHARACTER_GROUPS.map((group) => (
        <optgroup key={group} label={group}>
          {dialogueCharacters
            .filter((character) => character.group === group)
            .map((character) => (
              <option key={character.speaker} value={character.speaker}>
                {character.speaker}
              </option>
            ))}
        </optgroup>
      ))}
      {customSpeakers.length ? (
        <optgroup label="불러온 화자">
          {customSpeakers.map((speaker) => (
            <option key={speaker} value={speaker}>
              {speaker}
            </option>
          ))}
        </optgroup>
      ) : null}
    </>
  );
}

function BackgroundPicker({
  value,
  onChange,
  idPrefix,
  compact = false,
}: {
  value: string;
  onChange: (asset: string) => void;
  idPrefix: string;
  compact?: boolean;
}) {
  const current = dialogueBackgroundByAsset.get(value);
  return (
    <div className={styles.backgroundPicker}>
      <div className={styles.backgroundToolbar}>
        <div>
          <b>{current?.label ?? "직접 지정한 배경"}</b>
          <small>{current?.group ?? "사용자 경로"} · 썸네일을 누르면 즉시 변경</small>
        </div>
        <select
          value={value}
          onChange={(event) => onChange(event.target.value)}
          aria-label="장면 배경 선택"
        >
          {!current ? <option value={value}>직접 지정한 배경</option> : null}
          {(["프롤로그", "데시멀 센터", "생활·투자"] as const).map((group) => (
            <optgroup key={group} label={group}>
              {dialogueBackgrounds
                .filter((entry) => entry.group === group)
                .map((entry) => (
                  <option key={entry.id} value={entry.asset}>
                    {entry.label}
                  </option>
                ))}
            </optgroup>
          ))}
        </select>
      </div>
      <div
        className={`${styles.backgroundGrid} ${compact ? styles.backgroundGridCompact : ""}`}
        role="radiogroup"
        aria-label="배경 썸네일"
      >
        {dialogueBackgrounds.map((entry) => {
          const active = entry.asset === value;
          return (
            <button
              className={active ? styles.backgroundCardActive : styles.backgroundCard}
              type="button"
              key={`${idPrefix}-${entry.id}`}
              onClick={() => onChange(entry.asset)}
              aria-pressed={active}
              title={`${entry.group} · ${entry.label}`}
            >
              <span className={styles.backgroundThumb}>
                <Image
                  src={entry.asset}
                  alt=""
                  aria-hidden="true"
                  fill
                  sizes={compact ? "140px" : "180px"}
                  unoptimized
                />
                {active ? <i aria-hidden="true">✓</i> : null}
              </span>
              <span className={styles.backgroundCardCopy}>
                <b>{entry.label}</b>
                <small>{entry.group}</small>
              </span>
            </button>
          );
        })}
      </div>
      <details className={styles.backgroundCustom}>
        <summary>직접 경로 입력</summary>
        <label>
          <span>게임 에셋 경로</span>
          <input
            value={value}
            onChange={(event) => onChange(event.target.value)}
            placeholder="/play/assets/assets/images/..."
          />
        </label>
      </details>
    </div>
  );
}

export default function DialogueEditorPage() {
  const [scenes, setScenes] = useState<DialogueScene[]>(cloneInitial);
  const [appliedScenes, setAppliedScenes] = useState<DialogueScene[]>(cloneInitial);
  const [selectedId, setSelectedId] = useState(initialDialogue[0]?.id ?? "");
  const [query, setQuery] = useState("");
  const [speakerFilter, setSpeakerFilter] = useState("전체");
  const [ready, setReady] = useState(false);
  const [saveLabel, setSaveLabel] = useState("불러오는 중");
  const [notice, setNotice] = useState("");
  const [publishStatus, setPublishStatus] = useState<PublishStatus>("idle");
  const [publishMessage, setPublishMessage] = useState("아직 이번 편집본을 빌드하지 않았어요.");
  const [lastBuiltAt, setLastBuiltAt] = useState<string | null>(null);
  const [sceneComposer, setSceneComposer] = useState<DialogueScene | null>(null);
  const [transformScope, setTransformScope] = useState<TransformScope>("scene");
  const [characterDragging, setCharacterDragging] = useState(false);
  const [selectedLayerId, setSelectedLayerId] = useState("");
  const [selectedSceneIds, setSelectedSceneIds] = useState<string[]>([]);
  const [historyState, setHistoryState] = useState({ undo: 0, redo: 0 });
  const previewStageRef = useRef<HTMLDivElement>(null);
  const characterDragRef = useRef<CharacterDragState | null>(null);
  const scenesRef = useRef(scenes);
  const selectedIdRef = useRef(selectedId);
  const undoHistoryRef = useRef<SceneHistoryEntry[]>([]);
  const redoHistoryRef = useRef<SceneHistoryEntry[]>([]);
  const historyCoalesceRef = useRef<SceneHistoryCoalesce | null>(null);
  const importRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    scenesRef.current = scenes;
  }, [scenes]);

  useEffect(() => {
    selectedIdRef.current = selectedId;
  }, [selectedId]);

  useEffect(() => {
    const restoreTimer = window.setTimeout(() => {
      try {
        const raw = localStorage.getItem(STORAGE_KEY);
        if (raw) {
          const parsed = JSON.parse(raw) as SavedDraft;
          if (validScenes(parsed.scenes)) {
            const builtInIds = new Set(initialDialogue.map((scene) => scene.id));
            const merged = mergeWithCurrentStory(
              parsed.scenes,
              parsed.appearanceVersion !== APPEARANCE_VERSION,
              parsed.contentVersion !== CONTENT_VERSION,
            );
            const addedCount = Math.max(
              0,
              initialDialogue.length -
                parsed.scenes.filter((scene) => builtInIds.has(scene.id)).length,
            );
            setScenes(merged);
            setSelectedId(merged[0].id);
            setSaveLabel(
              addedCount > 0
                ? `새 장면 ${addedCount}개 자동 추가`
                : "임시저장 불러옴",
            );
          }
        }

        const appliedRaw = localStorage.getItem(BUILD_STORAGE_KEY);
        if (appliedRaw) {
          const applied = JSON.parse(appliedRaw) as SavedDraft;
          if (validScenes(applied.scenes)) {
            setAppliedScenes(
              mergeWithCurrentStory(
                applied.scenes,
                applied.appearanceVersion !== APPEARANCE_VERSION,
                applied.contentVersion !== CONTENT_VERSION,
              ),
            );
            setLastBuiltAt(applied.updatedAt);
            setPublishStatus("success");
            setPublishMessage("마지막 빌드가 게임 파일에 반영되어 있어요.");
          }
        }
      } catch {
        setSaveLabel("원본으로 시작");
      } finally {
        setReady(true);
      }
    }, 0);
    return () => window.clearTimeout(restoreTimer);
  }, []);

  useEffect(() => {
    if (!ready) return;
    const statusTimer = window.setTimeout(() => setSaveLabel("저장 중…"), 0);
    const timer = window.setTimeout(() => {
      const draft: SavedDraft = {
        version: 1,
        contentVersion: CONTENT_VERSION,
        appearanceVersion: APPEARANCE_VERSION,
        updatedAt: new Date().toISOString(),
        scenes,
      };
      const raw = JSON.stringify(draft);
      localStorage.setItem(STORAGE_KEY, raw);
      localStorage.setItem(GAME_STORAGE_KEY, raw);
      localStorage.setItem(FLUTTER_GAME_STORAGE_KEY, JSON.stringify(raw));
      setSaveLabel("자동 저장됨");
    }, 280);
    return () => {
      window.clearTimeout(statusTimer);
      window.clearTimeout(timer);
    };
  }, [ready, scenes]);

  useEffect(() => {
    if (!notice) return;
    const timer = window.setTimeout(() => setNotice(""), 1800);
    return () => window.clearTimeout(timer);
  }, [notice]);

  const selectedIndex = Math.max(
    0,
    scenes.findIndex((scene) => scene.id === selectedId),
  );
  const selected = scenes[selectedIndex] ?? scenes[0];
  const selectedStageCharacters = useMemo<DialogueStageCharacter[]>(() => {
    if (selected.characters?.length) return [...selected.characters].sort((a, b) => a.zIndex - b.zIndex);
    if (!selected.character) return [];
    return [{
      id: "primary",
      speaker: selected.speaker,
      asset: selected.character,
      x: selected.characterX,
      y: selected.characterY,
      scale: selected.characterScale,
      opacity: 1,
      flipX: false,
      zIndex: 0,
      enter: "fade",
      exit: "fade",
      motion: "none",
    }];
  }, [selected]);

  const activeLayerId = selectedStageCharacters.some((layer) => layer.id === selectedLayerId)
    ? selectedLayerId
    : selectedStageCharacters[0]?.id ?? "";

  const appliedById = useMemo(
    () => new Map(appliedScenes.map((scene) => [scene.id, scene])),
    [appliedScenes],
  );
  const dirtyIds = useMemo(() => {
    const dirty = new Set<string>();
    for (const scene of scenes) {
      if (sceneFingerprint(scene) !== sceneFingerprint(appliedById.get(scene.id))) {
        dirty.add(scene.id);
      }
    }
    for (const applied of appliedScenes) {
      if (!scenes.some((scene) => scene.id === applied.id)) dirty.add(applied.id);
    }
    return dirty;
  }, [appliedById, appliedScenes, scenes]);
  const dirtyCount = dirtyIds.size;

  const speakers = useMemo(
    () => ["전체", ...Array.from(new Set(scenes.map((scene) => scene.speaker))).sort()],
    [scenes],
  );
  const customSpeakers = useMemo(
    () =>
      Array.from(new Set(scenes.map((scene) => scene.speaker)))
        .filter((speaker) => !dialogueCharacterBySpeaker.has(speaker))
        .sort(),
    [scenes],
  );
  const sameSpeakerSceneCount = useMemo(
    () => scenes.filter((scene) => scene.speaker === selected.speaker).length,
    [scenes, selected.speaker],
  );
  const selectedPoses = useMemo<DialoguePose[]>(() => {
    return posesForScene(selected.speaker, selected.character);
  }, [selected.character, selected.speaker]);
  const composerPoses = useMemo<DialoguePose[]>(
    () =>
      sceneComposer
        ? posesForScene(sceneComposer.speaker, sceneComposer.character)
        : [],
    [sceneComposer],
  );

  const filteredScenes = useMemo(() => {
    const needle = query.trim().toLowerCase();
    return scenes.filter((scene) => {
      if (speakerFilter !== "전체" && scene.speaker !== speakerFilter) return false;
      if (!needle) return true;
      return [scene.speaker, scene.line, scene.direction, scene.location, scene.chapter]
        .join(" ")
        .toLowerCase()
        .includes(needle);
    });
  }, [query, scenes, speakerFilter]);

  const warnings = selected ? tasteChecks(selected) : [];
  const builtTimeLabel = lastBuiltAt
    ? new Intl.DateTimeFormat("ko-KR", {
        month: "numeric",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit",
      }).format(new Date(lastBuiltAt))
    : null;
  const publishToneClass =
    publishStatus === "building"
      ? styles.publishBannerBuilding
      : publishStatus === "error"
        ? styles.publishBannerError
        : dirtyCount
          ? styles.publishBannerDirty
          : publishStatus === "success"
            ? styles.publishBannerSuccess
            : styles.publishBannerIdle;

  function snapshotScenes(source: DialogueScene[]) {
    return structuredClone(source);
  }

  function syncHistoryState() {
    setHistoryState({
      undo: undoHistoryRef.current.length,
      redo: redoHistoryRef.current.length,
    });
  }

  function rememberSceneState(source: DialogueScene[], coalesceKey: string | null) {
    const now = editorNow();
    const previous = historyCoalesceRef.current;
    const shouldCoalesce = Boolean(
      coalesceKey &&
        previous?.key === coalesceKey &&
        now - previous.at <= HISTORY_COALESCE_MS,
    );
    if (!shouldCoalesce) {
      undoHistoryRef.current.push({
        scenes: snapshotScenes(source),
        selectedId: selectedIdRef.current,
      });
      if (undoHistoryRef.current.length > HISTORY_LIMIT) {
        undoHistoryRef.current.shift();
      }
    }
    redoHistoryRef.current = [];
    historyCoalesceRef.current = coalesceKey ? { key: coalesceKey, at: now } : null;
    syncHistoryState();
  }

  function replaceScenes(next: DialogueScene[], options: SceneUpdateOptions = {}) {
    const current = scenesRef.current;
    if (options.recordHistory !== false) {
      rememberSceneState(current, options.coalesceKey ?? null);
    }
    scenesRef.current = next;
    setScenes(next);
  }

  function updateScenes(
    updater: (current: DialogueScene[]) => DialogueScene[],
    options: SceneUpdateOptions = {},
  ) {
    replaceScenes(updater(scenesRef.current), options);
  }

  function toggleSceneSelection(sceneId: string) {
    setSelectedSceneIds((current) =>
      current.includes(sceneId)
        ? current.filter((id) => id !== sceneId)
        : [...current, sceneId],
    );
  }

  function replaceScenesFromToolbox(next: DialogueScene[]) {
    replaceScenes(next, { coalesceKey: null });
    setSelectedSceneIds((current) => current.filter((id) => next.some((scene) => scene.id === id)));
    if (!next.some((scene) => scene.id === selectedIdRef.current)) {
      const nextId = next[0]?.id ?? "";
      selectedIdRef.current = nextId;
      setSelectedId(nextId);
    }
  }

  function undoLastChange() {
    const previous = undoHistoryRef.current.pop();
    if (!previous) {
      setNotice("되돌릴 수정이 없어요");
      return;
    }
    redoHistoryRef.current.push({
      scenes: snapshotScenes(scenesRef.current),
      selectedId: selectedIdRef.current,
    });
    historyCoalesceRef.current = null;
    scenesRef.current = previous.scenes;
    selectedIdRef.current = previous.selectedId;
    setScenes(previous.scenes);
    setSelectedId(
      previous.scenes.some((scene) => scene.id === previous.selectedId)
        ? previous.selectedId
        : previous.scenes[0]?.id ?? "",
    );
    syncHistoryState();
    setNotice("수정 전으로 돌아갔어요");
  }

  function redoLastChange() {
    const next = redoHistoryRef.current.pop();
    if (!next) {
      setNotice("다시 실행할 수정이 없어요");
      return;
    }
    undoHistoryRef.current.push({
      scenes: snapshotScenes(scenesRef.current),
      selectedId: selectedIdRef.current,
    });
    historyCoalesceRef.current = null;
    scenesRef.current = next.scenes;
    selectedIdRef.current = next.selectedId;
    setScenes(next.scenes);
    setSelectedId(
      next.scenes.some((scene) => scene.id === next.selectedId)
        ? next.selectedId
        : next.scenes[0]?.id ?? "",
    );
    syncHistoryState();
    setNotice("취소한 수정을 다시 적용했어요");
  }

  function updateSelected(patch: Partial<DialogueScene>) {
    if (!selected) return;
    const normalizedPatch = {
      ...patch,
      ...(patch.direction === undefined
        ? {}
        : { direction: normalizeDialogueText(patch.direction) }),
      ...(patch.line === undefined ? {} : { line: normalizeDialogueText(patch.line) }),
    };
    updateScenes((current) =>
      current.map((scene) =>
        scene.id === selected.id ? { ...scene, ...normalizedPatch } : scene,
      ),
      { coalesceKey: `scene:${selected.id}:${Object.keys(normalizedPatch).sort().join(",")}` },
    );
  }

  function updateCharacterFrame(
    patch: CharacterFramePatch,
    target: {
      sceneId: string;
      speaker: string;
      scope: TransformScope;
    } = {
      sceneId: selected.id,
      speaker: selected.speaker,
      scope: transformScope === "speaker" && selected.character ? "speaker" : "scene",
    },
    options: SceneUpdateOptions = {},
  ) {
    const normalizedPatch: CharacterFramePatch = {};
    if (patch.characterX !== undefined) {
      normalizedPatch.characterX =
        Math.round(clampNumber(patch.characterX, 0, CHARACTER_X_MIN, CHARACTER_X_MAX) * 10) /
        10;
    }
    if (patch.characterY !== undefined) {
      normalizedPatch.characterY =
        Math.round(clampNumber(patch.characterY, 0, CHARACTER_Y_MIN, CHARACTER_Y_MAX) * 10) /
        10;
    }
    if (patch.characterScale !== undefined) {
      normalizedPatch.characterScale =
        Math.round(
          clampNumber(
            patch.characterScale,
            1,
            CHARACTER_SCALE_MIN,
            CHARACTER_SCALE_MAX,
          ) * 100,
        ) / 100;
    }
    updateScenes((current) =>
      current.map((scene) => {
        const matches =
          target.scope === "speaker"
            ? scene.speaker === target.speaker
            : scene.id === target.sceneId;
        if (!matches) return scene;
        const characters = scene.characters?.length
          ? scene.characters.map((layer, index) =>
              index === 0
                ? {
                    ...layer,
                    ...(normalizedPatch.characterX === undefined ? {} : { x: normalizedPatch.characterX }),
                    ...(normalizedPatch.characterY === undefined ? {} : { y: normalizedPatch.characterY }),
                    ...(normalizedPatch.characterScale === undefined ? {} : { scale: normalizedPatch.characterScale }),
                  }
                : layer,
            )
          : scene.characters;
        return { ...scene, ...normalizedPatch, characters };
      }),
      {
        recordHistory: options.recordHistory,
        coalesceKey:
          options.coalesceKey === undefined
            ? `frame:${target.scope}:${target.sceneId}:${target.speaker}:${Object.keys(
                normalizedPatch,
              ).sort().join(",")}`
            : options.coalesceKey,
      },
    );
  }

  function updateStageLayers(layers: DialogueStageCharacter[]) {
    const ordered = [...layers]
      .sort((a, b) => a.zIndex - b.zIndex)
      .map((layer, zIndex) => ({ ...layer, zIndex }));
    const primary = ordered.find((layer) => layer.speaker === selected.speaker) ?? ordered[0];
    updateSelected({
      characters: ordered,
      character: primary?.asset ?? "",
      characterX: primary?.x ?? 0,
      characterY: primary?.y ?? 0,
      characterScale: primary?.scale ?? 1,
    });
  }

  function updateStageLayerFrame(
    layerId: string,
    patch: Partial<Pick<DialogueStageCharacter, "x" | "y" | "scale">>,
    options: SceneUpdateOptions = {},
    sceneId = selected.id,
  ) {
    const normalizedPatch = {
      ...(patch.x === undefined ? {} : { x: Math.round(clampNumber(patch.x, 0, CHARACTER_X_MIN, CHARACTER_X_MAX) * 10) / 10 }),
      ...(patch.y === undefined ? {} : { y: Math.round(clampNumber(patch.y, 0, CHARACTER_Y_MIN, CHARACTER_Y_MAX) * 10) / 10 }),
      ...(patch.scale === undefined ? {} : { scale: Math.round(clampNumber(patch.scale, 1, CHARACTER_SCALE_MIN, CHARACTER_SCALE_MAX) * 100) / 100 }),
    };
    updateScenes(
      (current) => current.map((scene) => {
        if (scene.id !== sceneId || !scene.characters?.length) return scene;
        const characters = scene.characters.map((layer) =>
          layer.id === layerId ? { ...layer, ...normalizedPatch } : layer,
        );
        const primary = characters.find((layer) => layer.speaker === scene.speaker) ?? characters[0];
        return {
          ...scene,
          characters,
          character: primary?.asset ?? "",
          characterX: primary?.x ?? 0,
          characterY: primary?.y ?? 0,
          characterScale: primary?.scale ?? 1,
        };
      }),
      {
        recordHistory: options.recordHistory,
        coalesceKey: options.coalesceKey === undefined ? `stage-layer:${sceneId}:${layerId}` : options.coalesceKey,
      },
    );
  }

  function applyCharacterPreset(presetId: (typeof CHARACTER_FRAME_PRESETS)[number]["id"]) {
    const preset = CHARACTER_FRAME_PRESETS.find((item) => item.id === presetId);
    if (!preset) return;
    updateCharacterFrame({
      characterX: preset.characterX,
      characterY: preset.characterY,
      characterScale: preset.characterScale,
    }, undefined, { coalesceKey: null });
    setNotice(
      transformScope === "speaker"
        ? `${selected.speaker} 전체 장면에 ${preset.label} 구도를 적용했어요`
        : `현재 장면을 ${preset.label} 구도로 맞췄어요`,
    );
  }

  function beginCharacterDrag(
    event: ReactPointerEvent<HTMLDivElement>,
    layer?: DialogueStageCharacter,
  ) {
    if (!(layer?.asset ?? selected.character)) return;
    event.preventDefault();
    event.currentTarget.focus({ preventScroll: true });
    event.currentTarget.setPointerCapture(event.pointerId);
    characterDragRef.current = {
      pointerId: event.pointerId,
      startClientX: event.clientX,
      startClientY: event.clientY,
      startX: layer?.x ?? selected.characterX,
      startY: layer?.y ?? selected.characterY,
      sceneId: selected.id,
      speaker: layer?.speaker ?? selected.speaker,
      scope: layer ? "scene" : transformScope === "speaker" ? "speaker" : "scene",
      layerId: layer?.id,
    };
    rememberSceneState(scenesRef.current, null);
    setCharacterDragging(true);
  }

  function moveCharacterDrag(event: ReactPointerEvent<HTMLDivElement>) {
    const drag = characterDragRef.current;
    const stage = previewStageRef.current;
    if (!drag || !stage || drag.pointerId !== event.pointerId) return;
    event.preventDefault();
    const bounds = stage.getBoundingClientRect();
    const nextX = drag.startX + ((event.clientX - drag.startClientX) / bounds.width) * 100;
    const nextY = drag.startY - ((event.clientY - drag.startClientY) / bounds.height) * 100;
    if (drag.layerId) {
      updateStageLayerFrame(drag.layerId, { x: nextX, y: nextY }, { recordHistory: false }, drag.sceneId);
    } else {
      updateCharacterFrame(
        { characterX: nextX, characterY: nextY },
        drag,
        { recordHistory: false },
      );
    }
  }

  function endCharacterDrag(event: ReactPointerEvent<HTMLDivElement>) {
    const drag = characterDragRef.current;
    if (!drag || drag.pointerId !== event.pointerId) return;
    if (event.currentTarget.hasPointerCapture(event.pointerId)) {
      event.currentTarget.releasePointerCapture(event.pointerId);
    }
    characterDragRef.current = null;
    setCharacterDragging(false);
    setNotice(
      drag.scope === "speaker"
        ? `${drag.speaker} 전체 배치를 바꿨어요`
        : "장면 배치를 바꿨어요",
    );
  }

  function zoomCharacter(event: ReactWheelEvent<HTMLDivElement>, layer?: DialogueStageCharacter) {
    event.preventDefault();
    event.stopPropagation();
    const step = event.deltaY > 0 ? -0.05 : 0.05;
    if (layer) updateStageLayerFrame(layer.id, { scale: layer.scale + step });
    else updateCharacterFrame({ characterScale: selected.characterScale + step });
  }

  function updateCharacterScaleFromPointer(event: ReactPointerEvent<HTMLInputElement>) {
    const bounds = event.currentTarget.getBoundingClientRect();
    if (!bounds.width) return;
    const ratio = Math.min(1, Math.max(0, (event.clientX - bounds.left) / bounds.width));
    updateCharacterFrame({
      characterScale: CHARACTER_SCALE_MIN + ratio * (CHARACTER_SCALE_MAX - CHARACTER_SCALE_MIN),
    });
  }

  function beginCharacterScaleDrag(event: ReactPointerEvent<HTMLInputElement>) {
    if (!selected.character) return;
    event.preventDefault();
    event.currentTarget.focus({ preventScroll: true });
    event.currentTarget.setPointerCapture(event.pointerId);
    updateCharacterScaleFromPointer(event);
  }

  function moveCharacterScaleDrag(event: ReactPointerEvent<HTMLInputElement>) {
    if (!event.currentTarget.hasPointerCapture(event.pointerId)) return;
    event.preventDefault();
    updateCharacterScaleFromPointer(event);
  }

  function endCharacterScaleDrag(event: ReactPointerEvent<HTMLInputElement>) {
    if (event.currentTarget.hasPointerCapture(event.pointerId)) {
      event.currentTarget.releasePointerCapture(event.pointerId);
    }
  }

  function nudgeCharacterScale(event: KeyboardEvent<HTMLInputElement>) {
    let nextScale: number | null = null;
    if (event.key === "ArrowLeft" || event.key === "ArrowDown") {
      nextScale = selected.characterScale - 0.01;
    } else if (event.key === "ArrowRight" || event.key === "ArrowUp") {
      nextScale = selected.characterScale + 0.01;
    } else if (event.key === "Home") {
      nextScale = CHARACTER_SCALE_MIN;
    } else if (event.key === "End") {
      nextScale = CHARACTER_SCALE_MAX;
    }
    if (nextScale === null) return;
    event.preventDefault();
    event.stopPropagation();
    updateCharacterFrame({ characterScale: nextScale });
  }

  function nudgeCharacter(event: KeyboardEvent<HTMLDivElement>, layer?: DialogueStageCharacter) {
    const step = event.shiftKey ? 5 : 1;
    const patch: CharacterFramePatch = {};
    const currentX = layer?.x ?? selected.characterX;
    const currentY = layer?.y ?? selected.characterY;
    const currentScale = layer?.scale ?? selected.characterScale;
    if (event.key === "ArrowLeft") patch.characterX = currentX - step;
    if (event.key === "ArrowRight") patch.characterX = currentX + step;
    if (event.key === "ArrowUp") patch.characterY = currentY + step;
    if (event.key === "ArrowDown") patch.characterY = currentY - step;
    if (event.key === "+" || event.key === "=") {
      patch.characterScale = currentScale + 0.05;
    }
    if (event.key === "-") patch.characterScale = currentScale - 0.05;
    if (!Object.keys(patch).length) return;
    event.preventDefault();
    event.stopPropagation();
    if (layer) {
      updateStageLayerFrame(layer.id, {
        ...(patch.characterX === undefined ? {} : { x: patch.characterX }),
        ...(patch.characterY === undefined ? {} : { y: patch.characterY }),
        ...(patch.characterScale === undefined ? {} : { scale: patch.characterScale }),
      });
    } else updateCharacterFrame(patch);
  }

  async function saveAndBuild(mode: PublishMode = "quick") {
    if (publishStatus === "building") return;
    const snapshot = scenes.map((scene) => normalizeScene({ ...scene }));
    const validation = validateDialogueScenes(snapshot);
    if (!validation.ok) {
      setPublishStatus("error");
      setPublishMessage(validation.message);
      setNotice("장면 검증에 실패했습니다");
      return;
    }
    const payload: SavedDraft = {
      version: 1,
      contentVersion: CONTENT_VERSION,
      appearanceVersion: APPEARANCE_VERSION,
      updatedAt: new Date().toISOString(),
      scenes: validation.scenes,
    };
    const raw = JSON.stringify(payload);

    localStorage.setItem(STORAGE_KEY, raw);
    setSaveLabel("초안 저장됨");
    setPublishStatus("building");
    setPublishMessage(
      mode === "quick"
        ? "대사와 화면 배치를 게임 파일에 즉시 반영하고 있어요."
        : "새 에셋까지 포함해 Flutter 게임을 다시 만드는 중이에요. 보통 20~60초 걸립니다.",
    );

    try {
      let buildToken = sessionStorage.getItem("dialogue-build-token") || "";
      if (!buildToken) {
        buildToken = window.prompt("개발 PC에 설정한 대사 빌드 토큰을 입력하세요.") || "";
        if (!buildToken) throw new Error("대사 빌드 토큰이 필요합니다.");
        sessionStorage.setItem("dialogue-build-token", buildToken);
      }
      const response = await fetch("/api/dialogue/build", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          ...(buildToken ? { "X-Dialogue-Build-Token": buildToken } : {}),
        },
        body: JSON.stringify({ mode, scenes: validation.scenes }),
      });
      const result = (await response.json()) as {
        ok?: boolean;
        builtAt?: string;
        durationMs?: number;
        message?: string;
        contentVersion?: number;
        appearanceVersion?: number;
        sha256?: string;
        scenes?: DialogueScene[];
        mode?: PublishMode;
      };
      const builtValidation = validateDialogueScenes(result.scenes);
      if (
        !response.ok ||
        !result.ok ||
        !result.builtAt ||
        !result.sha256 ||
        !builtValidation.ok
      ) {
        throw new Error(result.message || "게임 빌드에 실패했습니다.");
      }

      const builtPayload: SavedDraft = {
        version: 1,
        contentVersion: result.contentVersion ?? CONTENT_VERSION,
        appearanceVersion: result.appearanceVersion ?? APPEARANCE_VERSION,
        updatedAt: result.builtAt,
        scenes: builtValidation.scenes,
      };
      const builtRaw = JSON.stringify(builtPayload);
      // shared_preferences_web stores Dart strings as a JSON-encoded value.
      localStorage.setItem(GAME_STORAGE_KEY, builtRaw);
      localStorage.setItem(FLUTTER_GAME_STORAGE_KEY, JSON.stringify(builtRaw));
      localStorage.setItem(BUILD_STORAGE_KEY, builtRaw);
      scenesRef.current = builtValidation.scenes;
      setScenes(builtValidation.scenes);
      setAppliedScenes(builtValidation.scenes);
      setLastBuiltAt(result.builtAt);
      setPublishStatus("success");
      const completedMode = result.mode ?? mode;
      setPublishMessage(
        completedMode === "quick"
          ? `게임 즉시 적용 완료 · ${Math.max(1, Math.round(result.durationMs ?? 0))}ms`
          : `전체 빌드 완료 · ${Math.max(1, Math.round((result.durationMs ?? 0) / 1000))}초`,
      );
      setNotice(completedMode === "quick" ? "게임에 바로 적용했어요 · 열려 있다면 새로고침하세요" : "전체 게임 빌드가 끝났어요");
    } catch (error) {
      const message = error instanceof Error ? error.message : "게임 빌드에 실패했습니다.";
      setPublishStatus("error");
      setPublishMessage(message);
      setNotice("초안은 보존했어요 · 빌드만 다시 시도해주세요");
    }
  }

  function changeSpeaker(speaker: string) {
    const firstPose = dialogueCharacterBySpeaker.get(speaker)?.poses[0];
    const reference = scenes.find(
      (scene) => scene.speaker === speaker && scene.character,
    );
    updateSelected({
      speaker,
      character: firstPose?.asset ?? "",
      characterX: reference?.characterX ?? 0,
      characterY: reference?.characterY ?? 0,
      characterScale: reference?.characterScale ?? 1,
    });
  }

  function updateComposer(patch: Partial<DialogueScene>) {
    setSceneComposer((current) =>
      current
        ? normalizeScene({
            ...current,
            ...patch,
          })
        : null,
    );
  }

  function changeComposerSpeaker(speaker: string) {
    const firstPose = dialogueCharacterBySpeaker.get(speaker)?.poses[0];
    updateComposer({ speaker, character: firstPose?.asset ?? "" });
  }

  function selectRelative(offset: number) {
    const next = Math.min(Math.max(selectedIndex + offset, 0), scenes.length - 1);
    setSelectedId(scenes[next].id);
  }

  function addScene() {
    const base = selected ?? initialDialogue[0];
    setSceneComposer({
      ...base,
      id: "scene-composer",
      order: selectedIndex + 2,
      direction: "",
      line: "",
    });
  }

  function commitScene() {
    if (!sceneComposer || !sceneComposer.line.trim()) return;
    const createdAt = editorNow();
    let id = `scene-custom-${createdAt}`;
    let suffix = 1;
    while (scenes.some((scene) => scene.id === id)) {
      id = `scene-custom-${createdAt}-${suffix}`;
      suffix += 1;
    }
    const created = normalizeScene({ ...sceneComposer, id });
    updateScenes((current) => {
      const insertionIndex = Math.max(
        0,
        current.findIndex((scene) => scene.id === selected.id) + 1,
      );
      const next = [...current];
      next.splice(insertionIndex, 0, created);
      return next.map((scene, index) => ({ ...scene, order: index + 1 }));
    });
    setSelectedId(id);
    setSceneComposer(null);
    setNotice("새 장면을 추가했어요 · 저장·빌드하면 게임에 반영됩니다");
  }

  function duplicateScene() {
    if (!selected) return;
    const id = `scene-copy-${editorNow()}`;
    const copy = { ...selected, id, order: selectedIndex + 2 };
    updateScenes((current) => {
      const next = [...current];
      next.splice(selectedIndex + 1, 0, copy);
      return next.map((scene, index) => ({ ...scene, order: index + 1 }));
    });
    setSelectedId(id);
    setNotice("장면을 복제했어요");
  }

  function deleteScene() {
    if (!selected || scenes.length === 1) return;
    if (!window.confirm(`${selected.order}번 장면을 삭제할까요?`)) return;
    const nextId = scenes[selectedIndex + 1]?.id ?? scenes[selectedIndex - 1]?.id;
    updateScenes((current) =>
      current
        .filter((scene) => scene.id !== selected.id)
        .map((scene, index) => ({ ...scene, order: index + 1 })),
    );
    setSelectedId(nextId);
    setNotice("장면을 삭제했어요");
  }

  function moveScene(offset: number) {
    const target = selectedIndex + offset;
    if (target < 0 || target >= scenes.length) return;
    updateScenes((current) => {
      const next = [...current];
      [next[selectedIndex], next[target]] = [next[target], next[selectedIndex]];
      return next.map((scene, index) => ({ ...scene, order: index + 1 }));
    });
  }

  function exportJson() {
    const payload: SavedDraft = {
      version: 1,
      contentVersion: CONTENT_VERSION,
      appearanceVersion: APPEARANCE_VERSION,
      updatedAt: new Date().toISOString(),
      scenes,
    };
    downloadFile(
      "프로젝트데시멀_대사편집본.json",
      JSON.stringify(payload, null, 2),
      "application/json;charset=utf-8",
    );
    setNotice("JSON을 저장했어요");
  }

  function exportTxt() {
    downloadFile(
      "프로젝트데시멀_대사편집본.txt",
      makeTxt(scenes),
      "text/plain;charset=utf-8",
    );
    setNotice("TXT를 저장했어요");
  }

  async function importJson(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    event.target.value = "";
    if (!file) return;
    try {
      const parsed = JSON.parse(await file.text()) as SavedDraft | DialogueScene[];
      const imported = Array.isArray(parsed) ? parsed : parsed.scenes;
      const appearanceVersion = Array.isArray(parsed) ? undefined : parsed.appearanceVersion;
      const importValidation = validateDialogueScenes(imported);
      if (!importValidation.ok) throw new Error(importValidation.message);
      const normalized = importValidation.scenes.map((scene, index) =>
        normalizeScene({
          ...scene,
          id: scene.id || `scene-import-${index + 1}`,
          order: index + 1,
          chapter: scene.chapter || "새 장",
          date: scene.date || "",
          location: scene.location || "",
          direction: scene.direction || "",
          line: scene.line || "",
          background:
            appearanceVersion === APPEARANCE_VERSION
              ? scene.background || ""
              : initialDialogue.find((current) => current.id === scene.id)?.background ||
                scene.background ||
                "",
          character:
            appearanceVersion === APPEARANCE_VERSION
              ? scene.character || ""
              : initialDialogue.find((current) => current.id === scene.id)?.character ||
                scene.character ||
                "",
          characterX:
            appearanceVersion === APPEARANCE_VERSION
              ? scene.characterX
              : initialDialogue.find((current) => current.id === scene.id)?.characterX ??
                scene.characterX ??
                0,
          characterY:
            appearanceVersion === APPEARANCE_VERSION
              ? scene.characterY
              : initialDialogue.find((current) => current.id === scene.id)?.characterY ??
                scene.characterY ??
                0,
          characterScale:
            appearanceVersion === APPEARANCE_VERSION
              ? scene.characterScale
              : initialDialogue.find((current) => current.id === scene.id)?.characterScale ??
                scene.characterScale ??
                1,
        }),
      );
      replaceScenes(normalized);
      setSelectedId(normalized[0].id);
      setNotice("편집본을 불러왔어요");
    } catch {
      window.alert("이 편집기에서 내보낸 JSON 파일인지 확인해주세요.");
    }
  }

  function resetDraft() {
    if (!window.confirm("편집 중인 내용을 버리고 현재 게임 원본을 초안으로 불러올까요?")) return;
    const reset = cloneInitial();
    replaceScenes(reset);
    setSelectedId(reset[0].id);
    const payload: SavedDraft = {
      version: 1,
      contentVersion: CONTENT_VERSION,
      appearanceVersion: APPEARANCE_VERSION,
      updatedAt: new Date().toISOString(),
      scenes: reset,
    };
    const raw = JSON.stringify(payload);
    localStorage.setItem(STORAGE_KEY, raw);
    setPublishStatus("idle");
    setPublishMessage("원본을 초안에 불러왔어요. 저장·빌드하면 게임 파일도 바뀝니다.");
    setNotice("원본을 초안에 불러왔어요 · 저장·빌드하면 반영됩니다");
  }

  async function copySelected() {
    if (!selected) return;
    await navigator.clipboard.writeText(makeTxt([selected]));
    setNotice("현재 장면을 복사했어요");
  }

  const undoActionRef = useRef(undoLastChange);
  const redoActionRef = useRef(redoLastChange);

  useEffect(() => {
    undoActionRef.current = undoLastChange;
    redoActionRef.current = redoLastChange;
  });

  useEffect(() => {
    function handleGlobalHistoryShortcut(event: globalThis.KeyboardEvent) {
      if (event.defaultPrevented || sceneComposer || !(event.ctrlKey || event.metaKey)) return;
      const key = event.key.toLowerCase();
      if (key === "z") {
        event.preventDefault();
        if (event.shiftKey) redoActionRef.current();
        else undoActionRef.current();
      } else if (key === "y") {
        event.preventDefault();
        redoActionRef.current();
      }
    }

    window.addEventListener("keydown", handleGlobalHistoryShortcut);
    return () => window.removeEventListener("keydown", handleGlobalHistoryShortcut);
  }, [sceneComposer]);

  function handleEditorKey(event: KeyboardEvent<HTMLElement>) {
    if (sceneComposer) {
      if (event.key === "Escape") {
        event.preventDefault();
        setSceneComposer(null);
      }
      return;
    }
    const shortcut = event.ctrlKey || event.metaKey;
    const key = event.key.toLowerCase();
    if (shortcut && key === "z") {
      event.preventDefault();
      if (event.shiftKey) redoLastChange();
      else undoLastChange();
      return;
    }
    if (shortcut && key === "y") {
      event.preventDefault();
      redoLastChange();
      return;
    }
    if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === "s") {
      event.preventDefault();
      void saveAndBuild();
    }
    if ((event.ctrlKey || event.metaKey) && event.key === "Enter") {
      event.preventDefault();
      selectRelative(1);
    }
  }

  if (!selected) return null;

  return (
    <main className={styles.page} onKeyDown={handleEditorKey}>
      <header className={styles.topbar}>
        <div className={styles.brand}>
          <span className={styles.logo}>台本</span>
          <div>
            <h1>대사 편집기</h1>
            <p>프로젝트 데시멀 · {scenes.length}개 장면</p>
          </div>
        </div>
        <div
          className={`${styles.saveState} ${dirtyCount ? styles.saveStateDirty : ""} ${
            publishStatus === "building" ? styles.saveStateBuilding : ""
          }`}
        >
          <i />
          {publishStatus === "building"
            ? "게임 반영 중"
            : dirtyCount
              ? `초안 자동 저장 · 즉시 적용 필요 ${dirtyCount}개`
              : `게임 반영 완료 · ${saveLabel}`}
        </div>
        <nav className={styles.actions} aria-label="파일 메뉴">
          <button
            className={styles.historyAction}
            type="button"
            onClick={undoLastChange}
            disabled={!historyState.undo}
            aria-label="실행 취소"
            title="실행 취소 · Ctrl/⌘+Z"
          >
            ↶
          </button>
          <button
            className={styles.historyAction}
            type="button"
            onClick={redoLastChange}
            disabled={!historyState.redo}
            aria-label="다시 실행"
            title="다시 실행 · Ctrl/⌘+Shift+Z"
          >
            ↷
          </button>
          <a
            href="/play/index.html?dialoguePreview=1"
            target="_blank"
            rel="noreferrer"
          >
            대사 미리보기
          </a>
          <button type="button" onClick={() => importRef.current?.click()}>
            불러오기
          </button>
          <button type="button" onClick={exportTxt}>
            TXT 저장
          </button>
          <button type="button" onClick={exportJson}>
            JSON 백업
          </button>
          <button
            className={styles.fullBuildAction}
            type="button"
            onClick={() => void saveAndBuild("full")}
            disabled={publishStatus === "building"}
          >
            전체 빌드
          </button>
          <button
            className={`${styles.primaryAction} ${
              publishStatus === "building" ? styles.primaryActionBusy : ""
            }`}
            type="button"
            onClick={() => void saveAndBuild("quick")}
            disabled={publishStatus === "building"}
          >
            {publishStatus === "building"
              ? "게임 반영 중…"
              : `게임에 즉시 적용${dirtyCount ? ` · ${dirtyCount}` : ""}`}
          </button>
          <input
            ref={importRef}
            className={styles.hiddenInput}
            type="file"
            accept="application/json,.json"
            onChange={importJson}
          />
        </nav>
      </header>

      <section className={styles.workflowBar} aria-label="대사 편집 순서">
        <div className={styles.workflowSteps}>
          <div className={styles.workflowStep}>
            <b>1</b>
            <span>장면 선택<small>왼쪽 목록에서 고르기</small></span>
          </div>
          <i aria-hidden="true">→</i>
          <div className={styles.workflowStep}>
            <b>2</b>
            <span>대사 수정<small>입력 즉시 초안 저장</small></span>
          </div>
          <i aria-hidden="true">→</i>
          <div className={`${styles.workflowStep} ${dirtyCount ? styles.workflowStepActive : ""}`}>
            <b>3</b>
            <span>게임 반영<small>즉시 적용 버튼 한 번</small></span>
          </div>
        </div>
        <div className={styles.workflowSummary}>
          <span className={dirtyCount ? styles.summaryDirty : styles.summaryReady} />
          <div>
            <b>{dirtyCount ? `반영할 수정 ${dirtyCount}개` : "최신 게임과 일치"}</b>
            <small>{dirtyCount ? "초안과 게임 미리보기에는 이미 반영됐어요" : builtTimeLabel ? `${builtTimeLabel} 적용` : "수정을 시작해보세요"}</small>
          </div>
        </div>
      </section>

      <section className={styles.workspace}>
        <aside className={styles.sceneRail}>
          <div className={styles.railTitle}>
            <div>
              <strong>장면 목록</strong>
              <span>{filteredScenes.length}개 표시</span>
            </div>
            <button
              className={styles.addSceneButton}
              type="button"
              onClick={addScene}
              aria-label="새 장면 추가"
            >
              <span aria-hidden="true">＋</span> 장면 추가
            </button>
          </div>
          <label className={styles.searchBox}>
            <span>⌕</span>
            <input
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="대사·지문 검색"
            />
          </label>
          <select
            className={styles.filter}
            value={speakerFilter}
            onChange={(event) => setSpeakerFilter(event.target.value)}
            aria-label="화자 필터"
          >
            {speakers.map((speaker) => (
              <option key={speaker}>{speaker}</option>
            ))}
          </select>
          <div className={styles.sceneList}>
            {filteredScenes.map((scene) => (
              <div className={styles.sceneListRow} key={scene.id}>
                <button
                  className={`${styles.sceneSelectToggle} ${selectedSceneIds.includes(scene.id) ? styles.sceneSelectToggleActive : ""}`}
                  type="button"
                  onClick={() => toggleSceneSelection(scene.id)}
                  aria-pressed={selectedSceneIds.includes(scene.id)}
                  aria-label={`${scene.order}번 장면 일괄 선택`}
                >
                  {selectedSceneIds.includes(scene.id) ? "✓" : ""}
                </button>
                <button
                  className={scene.id === selected.id ? styles.sceneActive : styles.sceneItem}
                  type="button"
                  onClick={() => setSelectedId(scene.id)}
                  aria-current={scene.id === selected.id ? "true" : undefined}
                >
                  {dirtyIds.has(scene.id) ? (
                    <i className={styles.dirtyMark} aria-label="게임에 저장되지 않은 수정" />
                  ) : null}
                  <span className={styles.sceneNumber}>
                    {String(scene.order).padStart(2, "0")}
                  </span>
                  <span className={styles.sceneCopy}>
                    <b>{scene.speaker}</b>
                    <small>{scene.line || "빈 대사"}</small>
                  </span>
                </button>
              </div>
            ))}
          </div>
        </aside>

        <section className={styles.editorPane}>
          <div className={styles.editorHeading}>
            <div>
              <p>{selected.chapter}</p>
              <h2>장면 {String(selected.order).padStart(2, "0")}</h2>
              <span className={styles.sceneProgress}>
                전체 {scenes.length}개 중 {selectedIndex + 1}번째
              </span>
            </div>
            <div className={styles.iconActions}>
              <button type="button" onClick={() => moveScene(-1)} disabled={selectedIndex === 0}>
                ↑
              </button>
              <button
                type="button"
                onClick={() => moveScene(1)}
                disabled={selectedIndex === scenes.length - 1}
              >
                ↓
              </button>
              <button type="button" onClick={duplicateScene}>복제</button>
              <button className={styles.dangerButton} type="button" onClick={deleteScene}>
                삭제
              </button>
            </div>
          </div>

          <SceneToolbox
            scenes={scenes}
            selectedScene={selected}
            selectedIds={selectedSceneIds}
            filteredIds={filteredScenes.map((scene) => scene.id)}
            onSelectedIdsChange={setSelectedSceneIds}
            onReplaceScenes={replaceScenesFromToolbox}
            onSelectScene={setSelectedId}
          />

          <section
            className={`${styles.publishBanner} ${publishToneClass}`}
            aria-live="polite"
          >
            <span className={styles.publishIcon} aria-hidden="true">
              {publishStatus === "building" ? "↻" : publishStatus === "error" ? "!" : dirtyCount ? "●" : "✓"}
            </span>
            <div className={styles.publishCopy}>
              <b>
                {publishStatus === "building"
                  ? "게임을 빌드하고 있어요"
                  : publishStatus === "error"
                    ? "빌드하지 못했어요"
                    : dirtyCount
                      ? `수정 ${dirtyCount}개가 초안에만 있어요`
                      : publishStatus === "success"
                        ? "게임 파일까지 반영됐어요"
                        : "현재 게임 원본 상태예요"}
              </b>
              <span>{publishMessage}</span>
            </div>
            <button
              className={styles.publishButton}
              type="button"
              onClick={() => void saveAndBuild("quick")}
              disabled={publishStatus === "building"}
            >
              {publishStatus === "building" ? "반영 중…" : publishStatus === "error" ? "다시 시도" : "즉시 적용"}
            </button>
          </section>

          <section className={styles.editorSection}>
            <div className={styles.sectionTitle}>
              <b><span>1</span> 장면 정보</b>
              <small>장 제목·배경·화자·연기를 한 번에 정합니다.</small>
            </div>
            <div className={`${styles.metaGrid} ${styles.metaGridThree}`}>
              <label>
                <span>장 제목</span>
                <input
                  value={selected.chapter}
                  onChange={(event) => updateSelected({ chapter: event.target.value })}
                  placeholder="예: 3장 · 설명서 학준"
                />
              </label>
              <label>
                <span>날짜·시간</span>
                <input
                  value={selected.date}
                  onChange={(event) => updateSelected({ date: event.target.value })}
                />
              </label>
              <label>
                <span>장소</span>
                <input
                  value={selected.location}
                  onChange={(event) => updateSelected({ location: event.target.value })}
                />
              </label>
            </div>

            <div className={styles.backgroundField}>
              <div className={styles.inlineSectionHeading}>
                <span>배경</span>
                <small>기존 장면도 여기서 바로 바꿀 수 있어요</small>
              </div>
              <BackgroundPicker
                value={selected.background}
                onChange={(background) => updateSelected({ background })}
                idPrefix={`scene-${selected.id}`}
                compact
              />
            </div>

            <div className={styles.characterControls}>
              <label className={styles.field}>
                <span>
                  화자
                  <small>누르면 등장인물 목록이 열려요</small>
                </span>
                <select
                  className={styles.speakerSelect}
                  value={selected.speaker}
                  onChange={(event) => changeSpeaker(event.target.value)}
                  aria-label="화자 선택"
                >
                  <SpeakerOptions customSpeakers={customSpeakers} />
                </select>
              </label>

              <div className={styles.poseField}>
                <div className={styles.poseHeading}>
                  <span>표정·동작</span>
                  <small>{selectedPoses.length}개 · 이 화자만 표시</small>
                </div>
                <div
                  className={styles.poseOptions}
                  role="radiogroup"
                  aria-label={`${selected.speaker} 표정과 동작`}
                >
                  {selectedPoses.map((pose) => {
                    const active = pose.asset === selected.character;
                    return (
                      <button
                        className={active ? styles.poseOptionActive : styles.poseOption}
                        type="button"
                        key={`${selected.speaker}-${pose.id}-${pose.asset}`}
                        onClick={() => updateSelected({ character: pose.asset })}
                        aria-pressed={active}
                        title={`${pose.id} · ${pose.label}`}
                      >
                        <span className={styles.poseThumb}>
                          {pose.asset ? (
                            <Image
                              src={pose.asset}
                              alt=""
                              aria-hidden="true"
                              width={48}
                              height={72}
                              unoptimized
                            />
                          ) : (
                            <i aria-hidden="true">∅</i>
                          )}
                        </span>
                        <b>{pose.id}</b>
                        <small>{pose.label}</small>
                      </button>
                    );
                  })}
                </div>
              </div>
            </div>
            <div className={styles.transformStudio}>
              <div className={styles.transformStudioHeader}>
                <div>
                  <b>캐릭터 화면 배치</b>
                  <span>오른쪽 화면에서 캐릭터를 직접 끌어도 됩니다.</span>
                </div>
                <div
                  className={styles.scopeSwitch}
                  role="radiogroup"
                  aria-label="캐릭터 배치 적용 범위"
                >
                  <button
                    type="button"
                    className={transformScope === "scene" ? styles.scopeActive : ""}
                    onClick={() => setTransformScope("scene")}
                    aria-pressed={transformScope === "scene"}
                  >
                    이 장면만
                  </button>
                  <button
                    type="button"
                    className={transformScope === "speaker" ? styles.scopeActive : ""}
                    onClick={() => {
                      if (!selected.character) return;
                      setTransformScope("speaker");
                      setNotice(`${selected.speaker}의 ${sameSpeakerSceneCount}개 장면을 함께 조정합니다`);
                    }}
                    disabled={!selected.character}
                    aria-pressed={transformScope === "speaker"}
                  >
                    {selected.speaker} 전체 · {sameSpeakerSceneCount}
                  </button>
                </div>
              </div>

              <div className={styles.transformSliders}>
                <label>
                  <span><b>가로</b><output>{selected.characterX > 0 ? "+" : ""}{selected.characterX.toFixed(1)}</output></span>
                  <input
                    type="range"
                    min={CHARACTER_X_MIN}
                    max={CHARACTER_X_MAX}
                    step="0.5"
                    value={selected.characterX}
                    disabled={!selected.character}
                    onInput={(event) => updateCharacterFrame({ characterX: Number(event.currentTarget.value) })}
                    aria-label="캐릭터 가로 위치"
                  />
                  <small>왼쪽</small><small>오른쪽</small>
                </label>
                <label>
                  <span><b>세로</b><output>{selected.characterY > 0 ? "+" : ""}{selected.characterY.toFixed(1)}</output></span>
                  <input
                    type="range"
                    min={CHARACTER_Y_MIN}
                    max={CHARACTER_Y_MAX}
                    step="0.5"
                    value={selected.characterY}
                    disabled={!selected.character}
                    onInput={(event) => updateCharacterFrame({ characterY: Number(event.currentTarget.value) })}
                    aria-label="캐릭터 세로 위치"
                  />
                  <small>아래</small><small>위 · 신발 보이기</small>
                </label>
                <label>
                  <span><b>확대</b><output>{Math.round(selected.characterScale * 100)}%</output></span>
                  <input
                    type="range"
                    min={CHARACTER_SCALE_MIN}
                    max={CHARACTER_SCALE_MAX}
                    step="0.01"
                    value={selected.characterScale}
                    disabled={!selected.character}
                    onInput={(event) => updateCharacterFrame({ characterScale: Number(event.currentTarget.value) })}
                    onPointerDown={beginCharacterScaleDrag}
                    onPointerMove={moveCharacterScaleDrag}
                    onPointerUp={endCharacterScaleDrag}
                    onPointerCancel={endCharacterScaleDrag}
                    onKeyDown={nudgeCharacterScale}
                    aria-label="캐릭터 확대율"
                  />
                  <small>전신</small><small>얼굴 가까이</small>
                </label>
              </div>

              <div className={styles.transformPresetRow}>
                <span>빠른 구도</span>
                {CHARACTER_FRAME_PRESETS.map((preset) => (
                  <button
                    type="button"
                    key={preset.id}
                    onClick={() => applyCharacterPreset(preset.id)}
                    disabled={!selected.character}
                  >
                    {preset.label}
                  </button>
                ))}
                <button
                  type="button"
                  onClick={() => updateCharacterFrame({ characterX: 0, characterY: 0, characterScale: 1 })}
                  disabled={!selected.character}
                >
                  초기화
                </button>
              </div>
              <p className={styles.transformHelp}>드래그 이동 · 휠 확대/축소 · 방향키 1칸 · Shift+방향키 5칸</p>
            </div>
          </section>

          <DirectorStudio
            scene={selected}
            scenes={scenes}
            selectedLayerId={activeLayerId}
            onSelectLayer={setSelectedLayerId}
            onUpdateScene={updateSelected}
            onUpdateLayers={updateStageLayers}
          />

          <section className={styles.editorSection}>
            <div className={styles.sectionTitle}>
              <b><span>2</span> 대사 작성</b>
              <small>오른쪽 게임 화면에서 바로 확인할 수 있어요.</small>
            </div>
            <label className={styles.field}>
              <span>
                지문
                <small>표정·손짓·시선처럼 화면에 보이는 행동</small>
              </span>
              <textarea
                className={styles.directionInput}
                value={selected.direction}
                onChange={(event) => updateSelected({ direction: event.target.value })}
                placeholder="예: 수아가 고장 난 바퀴를 연필 끝으로 툭 건드렸다."
                rows={3}
              />
            </label>

            <label className={styles.field}>
              <span>
                대사
                <small>{selected.line.length}자</small>
              </span>
              <textarea
                className={styles.dialogueInput}
                value={selected.line}
                onChange={(event) => updateSelected({ line: event.target.value })}
                placeholder="인물이 실제로 말할 문장을 입력하세요."
                rows={8}
              />
            </label>
          </section>

          <section className={warnings.length ? styles.tasteWarning : styles.tasteGood}>
            <div>
              <b>말맛 체크</b>
              <span>{warnings.length ? "조금만 다듬으면 더 자연스러워요" : "입으로 읽어도 잘 굴러가는 장면이에요"}</span>
            </div>
            {warnings.length ? (
              <ul>
                {warnings.map((warning) => <li key={warning}>{warning}</li>)}
              </ul>
            ) : (
              <p>구체적인 행동과 짧은 호흡이 함께 들어가 있습니다.</p>
            )}
          </section>

          <div className={styles.editorFooter}>
            <button type="button" onClick={() => selectRelative(-1)} disabled={selectedIndex === 0}>
              ← 이전 장면
            </button>
            <button type="button" onClick={copySelected}>현재 장면 복사</button>
            <button
              className={styles.nextButton}
              type="button"
              onClick={() => selectRelative(1)}
              disabled={selectedIndex === scenes.length - 1}
            >
              다음 장면 →
            </button>
          </div>
        </section>

        <aside className={styles.previewPane}>
          <div className={styles.previewHeading}>
            <div>
              <strong>게임 화면 미리보기</strong>
              <span className={styles.liveBadge}>● LIVE · 입력 즉시 반영</span>
            </div>
            <button type="button" onClick={resetDraft}>원본으로</button>
          </div>
          <div className={styles.phone}>
            <div
              ref={previewStageRef}
              className={`${styles.previewStage} ${(selected.cameraShake ?? 0) > 0 ? styles.previewStageShake : ""}`}
            >
              <div
                className={styles.previewBackdrop}
                style={{
                  backgroundImage: selected.background
                    ? `linear-gradient(180deg, rgba(4,14,28,.18), transparent 48%, rgba(2,8,18,.55)), url("${selected.background}")`
                    : undefined,
                  filter: `brightness(${selected.lighting ?? 1})`,
                  transform: `translate(${(selected.cameraX ?? 0) / 5}%, ${-(selected.cameraY ?? 0) / 5}%) scale(${selected.cameraZoom ?? 1})`,
                  transitionDuration: `${selected.transitionDurationMs ?? 700}ms`,
                }}
              />
              <div className={styles.ambientLayer} data-effect={selected.ambientEffect ?? "none"} aria-hidden="true" />
              <div className={styles.sceneMeta}>
                <span>⌂ {selected.location}</span>
                <small>{selected.date}</small>
              </div>
              {selectedStageCharacters.length ? (
                <>
                  <div className={styles.directManipulationHint} aria-hidden="true">
                    인물을 클릭해 선택하고 직접 드래그하세요
                  </div>
                  {selectedStageCharacters.map((layer) => (
                    <div
                      key={layer.id}
                      className={`${styles.characterManipulator} ${characterDragging ? styles.characterManipulatorDragging : ""} ${activeLayerId === layer.id ? styles.characterLayerSelected : ""} ${styles[`characterMotion_${layer.motion}`] ?? ""}`}
                      style={{
                        zIndex: 2 + layer.zIndex,
                        left: `${50 + layer.x}%`,
                        bottom: `${12.3 + layer.y}%`,
                        transform: "translateX(-50%)",
                      }}
                    >
                      <div
                        className={styles.characterVisual}
                        style={{
                          opacity: layer.opacity,
                          transform: `scale(${layer.scale}) scaleX(${layer.flipX ? -1 : 1})`,
                        }}
                      >
                        {layer.asset ? (
                          <Image
                            className={styles.characterImage}
                            src={layer.asset}
                            alt=""
                            aria-hidden="true"
                            fill
                            sizes="322px"
                            draggable={false}
                            unoptimized
                          />
                        ) : null}
                      </div>
                      <div
                        className={styles.characterDragHandle}
                        onPointerDown={(event) => {
                          setSelectedLayerId(layer.id);
                          beginCharacterDrag(event, layer);
                        }}
                        onPointerMove={moveCharacterDrag}
                        onPointerUp={endCharacterDrag}
                        onPointerCancel={endCharacterDrag}
                        onWheel={(event) => zoomCharacter(event, layer)}
                        onKeyDown={(event) => nudgeCharacter(event, layer)}
                        tabIndex={0}
                        aria-label={`${layer.speaker} 화면 위치 조정`}
                        title="몸 위에서 드래그 이동 · 휠 확대/축소"
                      >
                        <span className={styles.characterSelectionFrame} aria-hidden="true" />
                      </div>
                    </div>
                  ))}
                </>
              ) : null}
              <div className={`${styles.previewDialogue} ${styles[`previewDialogue_${selected.dialogueMode ?? "dialogue"}`] ?? ""}`}>
                <b>{selected.speaker || "화자 없음"}</b>
                {selected.direction.trim() ? <em>{selected.direction}</em> : null}
                <p>{selected.line || "대사를 입력하세요."}</p>
                {(selected.choices ?? []).length ? (
                  <div className={styles.previewChoices}>
                    {(selected.choices ?? []).map((choice) => <button type="button" key={choice.id}>{choice.label}</button>)}
                  </div>
                ) : null}
                <span>⌄</span>
              </div>
            </div>
          </div>
          <div className={styles.previewTips}>
            <span>단축키</span>
            <b>Ctrl/⌘ + Z</b> 수정 전으로
            <b>Ctrl/⌘ + S</b> 게임에 즉시 적용
            <b>Ctrl/⌘ + Enter</b> 다음 장면
          </div>
        </aside>
      </section>
      {sceneComposer ? (
        <div
          className={styles.modalBackdrop}
          onMouseDown={(event) => {
            if (event.currentTarget === event.target) setSceneComposer(null);
          }}
        >
          <section
            className={styles.sceneComposer}
            role="dialog"
            aria-modal="true"
            aria-labelledby="scene-composer-title"
          >
            <header className={styles.composerHeader}>
              <div className={styles.composerTitle}>
                <span aria-hidden="true">＋</span>
                <div>
                  <p>장면 {String(selected.order).padStart(2, "0")} 뒤에 삽입</p>
                  <h3 id="scene-composer-title">새 장면 만들기</h3>
                  <small>배경부터 대사까지 채우고 한 번에 추가하세요.</small>
                </div>
              </div>
              <button
                className={styles.composerClose}
                type="button"
                onClick={() => setSceneComposer(null)}
                aria-label="새 장면 작성창 닫기"
              >
                ×
              </button>
            </header>

            <div className={styles.composerBody}>
              <div className={styles.composerColumn}>
                <section className={styles.composerSection}>
                  <div className={styles.composerSectionTitle}>
                    <b><span>1</span> 기본 정보</b>
                    <small>현재 장면의 시간과 장소를 이어받았습니다.</small>
                  </div>
                  <div className={styles.composerMetaGrid}>
                    <label>
                      <span>장 제목</span>
                      <input
                        value={sceneComposer.chapter}
                        onChange={(event) => updateComposer({ chapter: event.target.value })}
                      />
                    </label>
                    <label>
                      <span>날짜·시간</span>
                      <input
                        value={sceneComposer.date}
                        onChange={(event) => updateComposer({ date: event.target.value })}
                      />
                    </label>
                    <label className={styles.composerLocationField}>
                      <span>장소</span>
                      <input
                        value={sceneComposer.location}
                        onChange={(event) => updateComposer({ location: event.target.value })}
                      />
                    </label>
                  </div>
                </section>

                <section className={styles.composerSection}>
                  <div className={styles.composerSectionTitle}>
                    <b><span>2</span> 화자와 연기</b>
                    <small>화자를 바꾸면 해당 인물의 동작만 표시됩니다.</small>
                  </div>
                  <label className={styles.field}>
                    <span>화자</span>
                    <select
                      className={styles.speakerSelect}
                      value={sceneComposer.speaker}
                      onChange={(event) => changeComposerSpeaker(event.target.value)}
                      aria-label="새 장면 화자 선택"
                    >
                      <SpeakerOptions customSpeakers={customSpeakers} />
                    </select>
                  </label>
                  <div className={styles.poseField}>
                    <div className={styles.poseHeading}>
                      <span>표정·동작</span>
                      <small>{composerPoses.length}개 · {sceneComposer.speaker}</small>
                    </div>
                    <div
                      className={styles.poseOptions}
                      role="radiogroup"
                      aria-label="새 장면 표정과 동작"
                    >
                      {composerPoses.map((pose) => {
                        const active = pose.asset === sceneComposer.character;
                        return (
                          <button
                            className={active ? styles.poseOptionActive : styles.poseOption}
                            type="button"
                            key={`composer-${sceneComposer.speaker}-${pose.id}-${pose.asset}`}
                            onClick={() => updateComposer({ character: pose.asset })}
                            aria-pressed={active}
                          >
                            <span className={styles.poseThumb}>
                              {pose.asset ? (
                                <Image
                                  src={pose.asset}
                                  alt=""
                                  aria-hidden="true"
                                  width={48}
                                  height={72}
                                  unoptimized
                                />
                              ) : (
                                <i aria-hidden="true">∅</i>
                              )}
                            </span>
                            <b>{pose.id}</b>
                            <small>{pose.label}</small>
                          </button>
                        );
                      })}
                    </div>
                  </div>
                </section>
              </div>

              <div className={styles.composerColumn}>
                <section className={styles.composerSection}>
                  <div className={styles.composerSectionTitle}>
                    <b><span>3</span> 배경</b>
                    <small>썸네일을 고르면 바로 적용됩니다.</small>
                  </div>
                  <BackgroundPicker
                    value={sceneComposer.background}
                    onChange={(background) => updateComposer({ background })}
                    idPrefix="composer"
                    compact
                  />
                </section>

                <section className={styles.composerSection}>
                  <div className={styles.composerSectionTitle}>
                    <b><span>4</span> 지문과 대사</b>
                    <small>대사는 입력해야 장면을 추가할 수 있습니다.</small>
                  </div>
                  <label className={styles.field}>
                    <span>지문 <small>{sceneComposer.direction.length}자</small></span>
                    <textarea
                      value={sceneComposer.direction}
                      onChange={(event) => updateComposer({ direction: event.target.value })}
                      placeholder="표정, 손짓, 시선이나 장면 변화를 적으세요."
                      rows={3}
                    />
                  </label>
                  <label className={styles.field}>
                    <span>대사 <small>{sceneComposer.line.length}자</small></span>
                    <textarea
                      className={styles.composerDialogueInput}
                      value={sceneComposer.line}
                      onChange={(event) => updateComposer({ line: event.target.value })}
                      placeholder="새 장면에서 실제로 들릴 대사를 입력하세요."
                      rows={6}
                      autoFocus
                    />
                  </label>
                </section>
              </div>
            </div>

            <footer className={styles.composerFooter}>
              <div>
                <b>장면 {String(selected.order + 1).padStart(2, "0")}로 추가</b>
                <span>추가 후에도 목록에서 순서·배경·대사를 다시 바꿀 수 있어요.</span>
              </div>
              <div>
                <button type="button" onClick={() => setSceneComposer(null)}>
                  취소
                </button>
                <button
                  className={styles.composerConfirm}
                  type="button"
                  onClick={commitScene}
                  disabled={!sceneComposer.line.trim()}
                >
                  ＋ 장면 추가
                </button>
              </div>
            </footer>
          </section>
        </div>
      ) : null}
      {notice ? <div className={styles.toast}>{notice}</div> : null}
    </main>
  );
}
