"use client";

import { useEffect, useMemo, useState, type PointerEvent as ReactPointerEvent } from "react";
import {
  dialogueCharacterBySpeaker,
  dialogueCharacters,
} from "./character-catalog";
import {
  DEFAULT_SCENE_DIRECTING,
  type DialogueChoice,
  type DialogueScene,
  type DialogueStageCharacter,
} from "./dialogue-types";
import styles from "./director-studio.module.css";

type DirectorStudioProps = {
  scene: DialogueScene;
  scenes: DialogueScene[];
  selectedLayerId: string;
  onSelectLayer: (id: string) => void;
  onUpdateScene: (patch: Partial<DialogueScene>) => void;
  onUpdateLayers: (layers: DialogueStageCharacter[]) => void;
  onUpdateLayer: (
    layerId: string,
    speaker: string,
    patch: Partial<
      Pick<
        DialogueStageCharacter,
        "asset" | "x" | "y" | "scale" | "opacity" | "flipX" | "enter" | "exit" | "motion"
      >
    >,
  ) => void;
};

const entranceLabels = {
  none: "즉시",
  fade: "페이드",
  "slide-left": "왼쪽 이동",
  "slide-right": "오른쪽 이동",
  pop: "팝",
} as const;

const motionLabels = {
  none: "정지",
  idle: "미세 호흡",
  breathing: "호흡",
  shake: "떨림",
  float: "부유",
} as const;

function sceneLayers(scene: DialogueScene): DialogueStageCharacter[] {
  if (scene.characters?.length) return scene.characters;
  if (!scene.character) return [];
  return [
    {
      id: "primary",
      speaker: scene.speaker,
      asset: scene.character,
      x: scene.characterX,
      y: scene.characterY,
      scale: scene.characterScale,
      opacity: 1,
      flipX: false,
      zIndex: 0,
      enter: "fade",
      exit: "fade",
      motion: "none",
    },
  ];
}

function createLayer(speaker: string, index: number): DialogueStageCharacter {
  const pose = dialogueCharacterBySpeaker.get(speaker)?.poses[0];
  return {
    id: `layer-${Date.now()}-${index + 1}`,
    speaker,
    asset: pose?.asset ?? "",
    x: Math.max(-35, Math.min(35, (index - 1) * 26)),
    y: 0,
    scale: 0.9,
    opacity: 1,
    flipX: index % 2 === 0,
    zIndex: index,
    enter: "fade",
    exit: "fade",
    motion: "none",
  };
}

function nextChoiceId(choices: DialogueChoice[]) {
  let index = choices.length + 1;
  while (choices.some((choice) => choice.id === `choice-${index}`)) index += 1;
  return `choice-${index}`;
}

export default function DirectorStudio({
  scene,
  scenes,
  selectedLayerId,
  onSelectLayer,
  onUpdateScene,
  onUpdateLayers,
  onUpdateLayer,
}: DirectorStudioProps) {
  const [activeTab, setActiveTab] = useState<"cast" | "camera" | "dialogue" | "branch" | "audio">("cast");
  const [newSpeaker, setNewSpeaker] = useState(() =>
    dialogueCharacterBySpeaker.has(scene.speaker)
      ? scene.speaker
      : dialogueCharacters.find((character) => character.speaker !== "이야기")?.speaker ?? "",
  );
  const layers = useMemo(() => sceneLayers(scene), [scene]);
  const activeLayer = layers.find((layer) => layer.id === selectedLayerId) ?? layers[0];
  const choices = scene.choices ?? DEFAULT_SCENE_DIRECTING.choices;

  useEffect(() => {
    if (layers.length && !layers.some((layer) => layer.id === selectedLayerId)) {
      onSelectLayer(layers[0].id);
    }
  }, [layers, onSelectLayer, selectedLayerId]);

  function updateLayer(
    layerId: string,
    patch: Partial<
      Pick<
        DialogueStageCharacter,
        "asset" | "x" | "y" | "scale" | "opacity" | "flipX" | "enter" | "exit" | "motion"
      >
    >,
  ) {
    const layer = layers.find((item) => item.id === layerId);
    if (!layer) return;
    onUpdateLayer(layerId, layer.speaker, patch);
  }

  function updateLayerLocally(layerId: string, patch: Partial<DialogueStageCharacter>) {
    onUpdateLayers(
      layers.map((layer) => (layer.id === layerId ? { ...layer, ...patch } : layer)),
    );
  }

  function addLayer() {
    const next = [...layers, createLayer(newSpeaker, layers.length)];
    onUpdateLayers(next);
    onSelectLayer(next[next.length - 1].id);
  }

  function removeLayer(layerId: string) {
    const next = layers
      .filter((layer) => layer.id !== layerId)
      .map((layer, index) => ({ ...layer, zIndex: index }));
    onUpdateLayers(next);
    onSelectLayer(next[0]?.id ?? "");
  }

  function moveLayer(layerId: string, offset: number) {
    const ordered = [...layers].sort((a, b) => a.zIndex - b.zIndex);
    const index = ordered.findIndex((layer) => layer.id === layerId);
    const target = index + offset;
    if (index < 0 || target < 0 || target >= ordered.length) return;
    [ordered[index], ordered[target]] = [ordered[target], ordered[index]];
    onUpdateLayers(ordered.map((layer, zIndex) => ({ ...layer, zIndex })));
  }

  function updateChoice(choiceId: string, patch: Partial<DialogueChoice>) {
    onUpdateScene({
      choices: choices.map((choice) =>
        choice.id === choiceId ? { ...choice, ...patch } : choice,
      ),
    });
  }

  function addChoice() {
    const id = nextChoiceId(choices);
    onUpdateScene({
      choices: [
        ...choices,
        { id, label: "새 선택지", targetSceneId: "", condition: "", effects: "" },
      ],
    });
  }

  return (
    <section className={styles.studio} aria-label="장면 연출 스튜디오">
      <header className={styles.header}>
        <div>
          <span>SCENE DIRECTOR</span>
          <h3>장면 연출 스튜디오</h3>
          <p>인물 레이어부터 카메라·분기·오디오까지 이 장면의 모든 연출을 편집합니다.</p>
        </div>
        <div className={styles.sceneStats}>
          <b>{layers.length}</b><span>인물</span>
          <b>{choices.length}</b><span>분기</span>
          <b>{scene.transitionDurationMs ?? DEFAULT_SCENE_DIRECTING.transitionDurationMs}</b><span>ms 전환</span>
        </div>
      </header>

      <nav className={styles.tabs} aria-label="연출 편집 영역">
        {([
          ["cast", "인물·레이어"],
          ["camera", "카메라·효과"],
          ["dialogue", "대사 연출"],
          ["branch", "선택지·분기"],
          ["audio", "오디오·메모"],
        ] as const).map(([id, label]) => (
          <button
            type="button"
            key={id}
            className={activeTab === id ? styles.tabActive : ""}
            onClick={() => setActiveTab(id)}
          >
            {label}
          </button>
        ))}
      </nav>

      {activeTab === "cast" ? (
        <div className={styles.castWorkspace}>
          <div className={styles.layerColumn}>
            <div className={styles.subheading}>
              <div><b>무대 인물</b><small>위쪽일수록 화면 앞에 표시</small></div>
            </div>
            <div className={styles.addLayerRow}>
              <select value={newSpeaker} onChange={(event) => setNewSpeaker(event.target.value)}>
                {dialogueCharacters
                  .filter((character) => character.speaker !== "이야기")
                  .map((character) => <option key={character.speaker}>{character.speaker}</option>)}
              </select>
              <button type="button" onClick={addLayer} disabled={layers.length >= 6}>＋ 인물 추가</button>
            </div>
            <div className={styles.layerList}>
              {[...layers].sort((a, b) => b.zIndex - a.zIndex).map((layer) => (
                <button
                  type="button"
                  key={layer.id}
                  className={activeLayer?.id === layer.id ? styles.layerActive : styles.layerItem}
                  onClick={() => onSelectLayer(layer.id)}
                >
                  <span>{layer.zIndex + 1}</span>
                  <div><b>{layer.speaker}</b><small>{layer.motion === "none" ? "정지" : motionLabels[layer.motion]} · {Math.round(layer.opacity * 100)}%</small></div>
                  <i>{layer.flipX ? "↔" : "→"}</i>
                </button>
              ))}
              {!layers.length ? <p className={styles.empty}>아직 무대에 인물이 없습니다.</p> : null}
            </div>
          </div>

          <div className={styles.inspector}>
            {activeLayer ? (
              <>
                <div className={styles.subheading}>
                  <div><b>선택 인물 속성</b><small>{activeLayer.id}</small></div>
                  <div className={styles.compactActions}>
                    <button type="button" onClick={() => moveLayer(activeLayer.id, 1)}>앞으로</button>
                    <button type="button" onClick={() => moveLayer(activeLayer.id, -1)}>뒤로</button>
                    <button type="button" className={styles.danger} onClick={() => removeLayer(activeLayer.id)}>삭제</button>
                  </div>
                </div>
                <div className={styles.formGrid}>
                  <label><span>인물</span><select value={activeLayer.speaker} onChange={(event) => {
                    const speaker = event.target.value;
                    const asset = dialogueCharacterBySpeaker.get(speaker)?.poses[0]?.asset ?? "";
                    updateLayerLocally(activeLayer.id, { speaker, asset });
                  }}>{dialogueCharacters.filter((character) => character.speaker !== "이야기").map((character) => <option key={character.speaker}>{character.speaker}</option>)}</select></label>
                  <label><span>표정·포즈</span><select value={activeLayer.asset} onChange={(event) => updateLayer(activeLayer.id, { asset: event.target.value })}>
                    {(dialogueCharacterBySpeaker.get(activeLayer.speaker)?.poses ?? []).map((pose) => <option key={pose.asset} value={pose.asset}>{pose.label}</option>)}
                    {!dialogueCharacterBySpeaker.get(activeLayer.speaker)?.poses.some((pose) => pose.asset === activeLayer.asset) ? <option value={activeLayer.asset}>현재 사용자 자산</option> : null}
                  </select></label>
                  <Range label="가로" value={activeLayer.x} min={-60} max={60} step={0.5} suffix="" onChange={(x) => updateLayer(activeLayer.id, { x })} />
                  <Range label="세로" value={activeLayer.y} min={-40} max={80} step={0.5} suffix="" onChange={(y) => updateLayer(activeLayer.id, { y })} />
                  <Range label="크기" value={activeLayer.scale} min={0.45} max={1.8} step={0.01} suffix="×" onChange={(scale) => updateLayer(activeLayer.id, { scale })} />
                  <Range label="투명도" value={activeLayer.opacity} min={0} max={1} step={0.01} suffix="" onChange={(opacity) => updateLayer(activeLayer.id, { opacity })} />
                  <label><span>등장</span><select value={activeLayer.enter} onChange={(event) => updateLayer(activeLayer.id, { enter: event.target.value as DialogueStageCharacter["enter"] })}>{Object.entries(entranceLabels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select></label>
                  <label><span>퇴장</span><select value={activeLayer.exit} onChange={(event) => updateLayer(activeLayer.id, { exit: event.target.value as DialogueStageCharacter["exit"] })}>{Object.entries(entranceLabels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select></label>
                  <label><span>반복 움직임</span><select value={activeLayer.motion} onChange={(event) => updateLayer(activeLayer.id, { motion: event.target.value as DialogueStageCharacter["motion"] })}>{Object.entries(motionLabels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select></label>
                  <button type="button" className={activeLayer.flipX ? styles.toggleActive : styles.toggle} onClick={() => updateLayer(activeLayer.id, { flipX: !activeLayer.flipX })}>↔ 좌우 반전 {activeLayer.flipX ? "켜짐" : "꺼짐"}</button>
                </div>
              </>
            ) : <p className={styles.empty}>왼쪽에서 인물을 추가하거나 선택하세요.</p>}
          </div>
        </div>
      ) : null}

      {activeTab === "camera" ? (
        <div className={styles.panel}>
          <div className={styles.timeline}>
            <TimelineTrack label="배경" color="blue" text={`${scene.transition ?? "fade"} · ${scene.transitionDurationMs ?? 700}ms`} />
            <TimelineTrack label="카메라" color="violet" text={`${scene.cameraZoom ?? 1}× · 흔들림 ${Math.round((scene.cameraShake ?? 0) * 100)}%`} />
            <TimelineTrack label="인물" color="coral" text={`${layers.length}개 레이어`} />
            <TimelineTrack label="대사" color="mint" text={`${scene.textSpeed ?? 32}자/초`} />
            <TimelineTrack label="오디오" color="gold" text={scene.bgm || scene.soundEffect || "없음"} />
          </div>
          <div className={styles.formGridThree}>
            <label><span>장면 전환</span><select value={scene.transition ?? "fade"} onChange={(event) => onUpdateScene({ transition: event.target.value as DialogueScene["transition"] })}><option value="cut">컷</option><option value="fade">페이드</option><option value="dissolve">디졸브</option><option value="slide-left">왼쪽 슬라이드</option><option value="slide-right">오른쪽 슬라이드</option><option value="flash">플래시</option></select></label>
            <NumberField label="전환 시간" value={scene.transitionDurationMs ?? 700} min={0} max={5000} suffix="ms" onChange={(transitionDurationMs) => onUpdateScene({ transitionDurationMs })} />
            <label><span>환경 효과</span><select value={scene.ambientEffect ?? "none"} onChange={(event) => onUpdateScene({ ambientEffect: event.target.value as DialogueScene["ambientEffect"] })}><option value="none">없음</option><option value="rain">비</option><option value="snow">눈</option><option value="dust">먼지</option><option value="flicker">조명 깜빡임</option></select></label>
            <Range label="카메라 가로" value={scene.cameraX ?? 0} min={-50} max={50} step={0.5} suffix="" onChange={(cameraX) => onUpdateScene({ cameraX })} />
            <Range label="카메라 세로" value={scene.cameraY ?? 0} min={-50} max={50} step={0.5} suffix="" onChange={(cameraY) => onUpdateScene({ cameraY })} />
            <Range label="카메라 줌" value={scene.cameraZoom ?? 1} min={0.5} max={2.5} step={0.01} suffix="×" onChange={(cameraZoom) => onUpdateScene({ cameraZoom })} />
            <Range label="화면 흔들림" value={scene.cameraShake ?? 0} min={0} max={1} step={0.01} suffix="" onChange={(cameraShake) => onUpdateScene({ cameraShake })} />
            <Range label="조명 밝기" value={scene.lighting ?? 1} min={0.2} max={1.5} step={0.01} suffix="×" onChange={(lighting) => onUpdateScene({ lighting })} />
          </div>
        </div>
      ) : null}

      {activeTab === "dialogue" ? (
        <div className={styles.panel}>
          <div className={styles.formGridThree}>
            <label><span>대화창 형식</span><select value={scene.dialogueMode ?? "dialogue"} onChange={(event) => onUpdateScene({ dialogueMode: event.target.value as DialogueScene["dialogueMode"] })}><option value="dialogue">일반 대사</option><option value="narration">지문·내레이션</option><option value="thought">속마음</option><option value="system">시스템 메시지</option></select></label>
            <Range label="글자 속도" value={scene.textSpeed ?? 32} min={8} max={120} step={1} suffix="자/초" onChange={(textSpeed) => onUpdateScene({ textSpeed })} />
            <NumberField label="자동 넘김" value={scene.autoAdvanceMs ?? 0} min={0} max={30000} suffix="ms" onChange={(autoAdvanceMs) => onUpdateScene({ autoAdvanceMs })} />
          </div>
          <div className={styles.previewDialogueBox} data-mode={scene.dialogueMode ?? "dialogue"}>
            <b>{scene.speaker}</b>
            {scene.direction ? <em>{scene.direction}</em> : null}
            <p>{scene.line || "대사를 입력하면 이곳에서 스타일을 확인할 수 있습니다."}</p>
            <small>{scene.autoAdvanceMs ? `${scene.autoAdvanceMs}ms 뒤 자동 진행` : "클릭해서 진행"}</small>
          </div>
        </div>
      ) : null}

      {activeTab === "branch" ? (
        <div className={styles.panel}>
          <div className={styles.branchHeader}>
            <div><b>분기 흐름</b><small>조건과 효과는 `flag = 값`, `호감도.한수아 += 2`처럼 한 줄씩 작성</small></div>
            <button type="button" onClick={addChoice} disabled={choices.length >= 6}>＋ 선택지 추가</button>
          </div>
          <div className={styles.branchBase}>
            <label><span>이 장면 표시 조건</span><input value={scene.condition ?? ""} onChange={(event) => onUpdateScene({ condition: event.target.value })} placeholder="예: flag.accepted = true" /></label>
            <label><span>장면 종료 효과</span><input value={scene.effects ?? ""} onChange={(event) => onUpdateScene({ effects: event.target.value })} placeholder="예: flag.metSua = true" /></label>
            <label><span>기본 다음 장면</span><select value={scene.nextSceneId ?? ""} onChange={(event) => onUpdateScene({ nextSceneId: event.target.value })}><option value="">순서대로 다음 장면</option>{scenes.filter((item) => item.id !== scene.id).map((item) => <option key={item.id} value={item.id}>{String(item.order).padStart(2, "0")} · {item.speaker} · {item.id}</option>)}</select></label>
          </div>
          <div className={styles.choiceList}>
            {choices.map((choice, index) => (
              <article key={choice.id} className={styles.choiceCard}>
                <header><b>선택지 {index + 1}</b><code>{choice.id}</code><button type="button" onClick={() => onUpdateScene({ choices: choices.filter((item) => item.id !== choice.id) })}>삭제</button></header>
                <label><span>플레이어에게 보이는 문구</span><input value={choice.label} onChange={(event) => updateChoice(choice.id, { label: event.target.value })} /></label>
                <label><span>이동할 장면</span><select value={choice.targetSceneId} onChange={(event) => updateChoice(choice.id, { targetSceneId: event.target.value })}><option value="">바로 다음 장면</option>{scenes.filter((item) => item.id !== scene.id).map((item) => <option key={item.id} value={item.id}>{String(item.order).padStart(2, "0")} · {item.speaker} · {item.id}</option>)}</select></label>
                <div><label><span>표시 조건</span><input value={choice.condition} onChange={(event) => updateChoice(choice.id, { condition: event.target.value })} placeholder="비우면 항상 표시" /></label><label><span>선택 효과</span><input value={choice.effects} onChange={(event) => updateChoice(choice.id, { effects: event.target.value })} placeholder="flag.answer = 1" /></label></div>
              </article>
            ))}
            {!choices.length ? <p className={styles.empty}>선택지가 없으면 기본 다음 장면으로 바로 진행합니다.</p> : null}
          </div>
        </div>
      ) : null}

      {activeTab === "audio" ? (
        <div className={styles.panel}>
          <div className={styles.formGridThree}>
            <label><span>BGM 자산 경로</span><input value={scene.bgm ?? ""} onChange={(event) => onUpdateScene({ bgm: event.target.value })} placeholder="/play/assets/assets/audio/bgm/..." /></label>
            <label><span>효과음 자산 경로</span><input value={scene.soundEffect ?? ""} onChange={(event) => onUpdateScene({ soundEffect: event.target.value })} placeholder="/play/assets/assets/audio/sfx/..." /></label>
            <label><span>음성 자산 경로</span><input value={scene.voice ?? ""} onChange={(event) => onUpdateScene({ voice: event.target.value })} placeholder="/play/assets/assets/audio/voice/..." /></label>
            <Range label="오디오 음량" value={scene.audioVolume ?? 0.8} min={0} max={1} step={0.01} suffix="" onChange={(audioVolume) => onUpdateScene({ audioVolume })} />
            <label><span>태그</span><input value={(scene.tags ?? []).join(", ")} onChange={(event) => onUpdateScene({ tags: event.target.value.split(",").map((tag) => tag.trim()).filter(Boolean) })} placeholder="프롤로그, 수아, 갈등" /></label>
          </div>
          <label className={styles.notes}><span>제작 메모</span><textarea value={scene.notes ?? ""} onChange={(event) => onUpdateScene({ notes: event.target.value })} placeholder="플레이어에게는 보이지 않는 연출 의도와 수정 메모" /></label>
        </div>
      ) : null}
    </section>
  );
}

function Range({ label, value, min, max, step, suffix, onChange }: { label: string; value: number; min: number; max: number; step: number; suffix: string; onChange: (value: number) => void }) {
  function updateFromPointer(event: ReactPointerEvent<HTMLInputElement>) {
    const rect = event.currentTarget.getBoundingClientRect();
    const ratio = Math.max(0, Math.min(1, (event.clientX - rect.left) / Math.max(1, rect.width)));
    const raw = min + ratio * (max - min);
    const stepped = Math.round((raw - min) / step) * step + min;
    const decimals = (String(step).split(".")[1] ?? "").length;
    onChange(Number(Math.max(min, Math.min(max, stepped)).toFixed(decimals)));
  }

  return (
    <label className={styles.range}>
      <span>{label}<output>{Number(value.toFixed(2))}{suffix}</output></span>
      <input
        type="range"
        value={value}
        min={min}
        max={max}
        step={step}
        onChange={(event) => onChange(Number(event.currentTarget.value))}
        onInput={(event) => onChange(Number(event.currentTarget.value))}
        onPointerDown={(event) => {
          event.preventDefault();
          event.currentTarget.focus();
          event.currentTarget.setPointerCapture(event.pointerId);
          updateFromPointer(event);
        }}
        onPointerMove={(event) => {
          if (event.currentTarget.hasPointerCapture(event.pointerId)) updateFromPointer(event);
        }}
        onPointerUp={(event) => {
          if (event.currentTarget.hasPointerCapture(event.pointerId)) event.currentTarget.releasePointerCapture(event.pointerId);
        }}
      />
    </label>
  );
}

function NumberField({ label, value, min, max, suffix, onChange }: { label: string; value: number; min: number; max: number; suffix: string; onChange: (value: number) => void }) {
  return <label><span>{label}</span><div className={styles.numberField}><input type="number" value={value} min={min} max={max} onChange={(event) => onChange(Number(event.target.value))} /><i>{suffix}</i></div></label>;
}

function TimelineTrack({ label, color, text }: { label: string; color: string; text: string }) {
  return <div className={styles.timelineTrack}><b>{label}</b><span data-color={color}><i /><small>{text}</small></span></div>;
}
