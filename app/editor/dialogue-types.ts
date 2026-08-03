export type DialogueMode = "dialogue" | "narration" | "thought" | "system";
export type SceneTransition =
  | "cut"
  | "fade"
  | "dissolve"
  | "slide-left"
  | "slide-right"
  | "flash";
export type AmbientEffect = "none" | "rain" | "snow" | "dust" | "flicker";
export type CharacterEntrance =
  | "none"
  | "fade"
  | "slide-left"
  | "slide-right"
  | "pop";
export type CharacterMotion = "none" | "idle" | "breathing" | "shake" | "float";

export type DialogueStageCharacter = {
  id: string;
  speaker: string;
  asset: string;
  x: number;
  y: number;
  scale: number;
  opacity: number;
  flipX: boolean;
  zIndex: number;
  enter: CharacterEntrance;
  exit: CharacterEntrance;
  motion: CharacterMotion;
};

export type DialogueChoice = {
  id: string;
  label: string;
  targetSceneId: string;
  condition: string;
  effects: string;
};

export type DialogueScene = {
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
  characters?: DialogueStageCharacter[];
  dialogueMode?: DialogueMode;
  textSpeed?: number;
  autoAdvanceMs?: number;
  transition?: SceneTransition;
  transitionDurationMs?: number;
  cameraX?: number;
  cameraY?: number;
  cameraZoom?: number;
  cameraShake?: number;
  ambientEffect?: AmbientEffect;
  lighting?: number;
  bgm?: string;
  soundEffect?: string;
  voice?: string;
  audioVolume?: number;
  nextSceneId?: string;
  condition?: string;
  effects?: string;
  choices?: DialogueChoice[];
  tags?: string[];
  notes?: string;
};

export const DEFAULT_SCENE_DIRECTING = {
  characters: [] as DialogueStageCharacter[],
  dialogueMode: "dialogue" as DialogueMode,
  textSpeed: 32,
  autoAdvanceMs: 0,
  transition: "fade" as SceneTransition,
  transitionDurationMs: 700,
  cameraX: 0,
  cameraY: 0,
  cameraZoom: 1,
  cameraShake: 0,
  ambientEffect: "none" as AmbientEffect,
  lighting: 1,
  bgm: "",
  soundEffect: "",
  voice: "",
  audioVolume: 0.8,
  nextSceneId: "",
  condition: "",
  effects: "",
  choices: [] as DialogueChoice[],
  tags: [] as string[],
  notes: "",
} satisfies Omit<
  DialogueScene,
  | "id"
  | "order"
  | "chapter"
  | "date"
  | "location"
  | "speaker"
  | "direction"
  | "line"
  | "background"
  | "character"
  | "characterX"
  | "characterY"
  | "characterScale"
>;
