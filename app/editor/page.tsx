"use client";

import Image from "next/image";
import {
  ChangeEvent,
  KeyboardEvent,
  useEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import { DialogueScene, initialDialogue } from "./dialogue-data";
import styles from "./editor.module.css";

const STORAGE_KEY = "future-academy-dialogue-editor-v1";
const GAME_STORAGE_KEY = "future-academy-dialogue-runtime-v1";
const FLUTTER_GAME_STORAGE_KEY = `flutter.${GAME_STORAGE_KEY}`;

type SavedDraft = {
  version: 1;
  updatedAt: string;
  scenes: DialogueScene[];
};

function cloneInitial() {
  return initialDialogue.map((scene) => ({ ...scene }));
}

function validScenes(value: unknown): value is DialogueScene[] {
  if (!Array.isArray(value) || value.length === 0) return false;
  return value.every(
    (scene) =>
      scene &&
      typeof scene === "object" &&
      typeof scene.id === "string" &&
      typeof scene.speaker === "string" &&
      typeof scene.line === "string",
  );
}

function mergeWithCurrentStory(saved: DialogueScene[]) {
  const savedById = new Map(saved.map((scene) => [scene.id, scene]));
  const builtInIds = new Set(initialDialogue.map((scene) => scene.id));
  return [
    ...initialDialogue.map((scene) => ({
      ...scene,
      ...(savedById.get(scene.id) ?? {}),
    })),
    ...saved.filter((scene) => !builtInIds.has(scene.id)),
  ].map((scene, index) => ({ ...scene, order: index + 1 }));
}

function sceneFingerprint(scene: DialogueScene | undefined) {
  if (!scene) return "";
  return JSON.stringify({
    order: scene.order,
    chapter: scene.chapter,
    date: scene.date,
    location: scene.location,
    speaker: scene.speaker,
    direction: scene.direction,
    line: scene.line,
    background: scene.background,
    character: scene.character,
  });
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

export default function DialogueEditorPage() {
  const [scenes, setScenes] = useState<DialogueScene[]>(cloneInitial);
  const [appliedScenes, setAppliedScenes] = useState<DialogueScene[]>(cloneInitial);
  const [selectedId, setSelectedId] = useState(initialDialogue[0]?.id ?? "");
  const [query, setQuery] = useState("");
  const [speakerFilter, setSpeakerFilter] = useState("전체");
  const [ready, setReady] = useState(false);
  const [saveLabel, setSaveLabel] = useState("불러오는 중");
  const [notice, setNotice] = useState("");
  const [pendingSceneId, setPendingSceneId] = useState<string | null>(null);
  const importRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    const restoreTimer = window.setTimeout(() => {
      try {
        const raw = localStorage.getItem(STORAGE_KEY);
        if (raw) {
          const parsed = JSON.parse(raw) as SavedDraft;
          if (validScenes(parsed.scenes)) {
            const builtInIds = new Set(initialDialogue.map((scene) => scene.id));
            const merged = mergeWithCurrentStory(parsed.scenes);
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

        const appliedRaw = localStorage.getItem(GAME_STORAGE_KEY);
        if (appliedRaw) {
          const applied = JSON.parse(appliedRaw) as SavedDraft;
          if (validScenes(applied.scenes)) {
            setAppliedScenes(mergeWithCurrentStory(applied.scenes));
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
        updatedAt: new Date().toISOString(),
        scenes,
      };
      localStorage.setItem(STORAGE_KEY, JSON.stringify(draft));
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
  const selectedDirty = selected ? dirtyIds.has(selected.id) : false;
  const pendingScene = pendingSceneId
    ? scenes.find((scene) => scene.id === pendingSceneId)
    : undefined;

  const speakers = useMemo(
    () => ["전체", ...Array.from(new Set(scenes.map((scene) => scene.speaker))).sort()],
    [scenes],
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

  useEffect(() => {
    if (!dirtyCount) return;
    const warnBeforeClose = (event: BeforeUnloadEvent) => {
      event.preventDefault();
      event.returnValue = "";
    };
    window.addEventListener("beforeunload", warnBeforeClose);
    return () => window.removeEventListener("beforeunload", warnBeforeClose);
  }, [dirtyCount]);

  const warnings = selected ? tasteChecks(selected) : [];

  function updateSelected(patch: Partial<DialogueScene>) {
    if (!selected) return;
    setScenes((current) =>
      current.map((scene) => (scene.id === selected.id ? { ...scene, ...patch } : scene)),
    );
  }

  function saveToGame() {
    const payload: SavedDraft = {
      version: 1,
      updatedAt: new Date().toISOString(),
      scenes,
    };
    const raw = JSON.stringify(payload);

    // shared_preferences_web stores Dart strings as a JSON-encoded localStorage value.
    localStorage.setItem(GAME_STORAGE_KEY, raw);
    localStorage.setItem(FLUTTER_GAME_STORAGE_KEY, JSON.stringify(raw));
    localStorage.setItem(STORAGE_KEY, raw);
    setAppliedScenes(scenes.map((scene) => ({ ...scene })));
    setSaveLabel("임시저장됨");
    setNotice("게임에 바로 적용했어요 · 새 게임에서 확인할 수 있어요");
  }

  function requestScene(targetId: string) {
    if (targetId === selectedId) return;
    if (selectedDirty) {
      setPendingSceneId(targetId);
      return;
    }
    setSelectedId(targetId);
  }

  function discardCurrentAndMove() {
    if (!pendingSceneId || !selected) return;
    const applied = appliedById.get(selected.id);
    setScenes((current) => {
      const restored = applied
        ? current.map((scene) =>
            scene.id === selected.id ? { ...applied } : scene,
          )
        : current.filter((scene) => scene.id !== selected.id);
      return restored.map((scene, index) => ({ ...scene, order: index + 1 }));
    });
    setSelectedId(pendingSceneId);
    setPendingSceneId(null);
    setNotice("수정 내용을 버리고 이동했어요");
  }

  function saveCurrentAndMove() {
    if (!pendingSceneId) return;
    const targetId = pendingSceneId;
    saveToGame();
    setPendingSceneId(null);
    setSelectedId(targetId);
  }

  function selectRelative(offset: number) {
    const next = Math.min(Math.max(selectedIndex + offset, 0), scenes.length - 1);
    requestScene(scenes[next].id);
  }

  function addScene() {
    const base = selected ?? initialDialogue[0];
    const id = `scene-custom-${Date.now()}`;
    const created: DialogueScene = {
      ...base,
      id,
      order: selectedIndex + 2,
      speaker: "새 화자",
      direction: "",
      line: "새 대사를 입력하세요.",
      character: "",
    };
    setScenes((current) => {
      const next = [...current];
      next.splice(selectedIndex + 1, 0, created);
      return next.map((scene, index) => ({ ...scene, order: index + 1 }));
    });
    setSelectedId(id);
    setNotice("새 장면을 추가했어요");
  }

  function duplicateScene() {
    if (!selected) return;
    const id = `scene-copy-${Date.now()}`;
    const copy = { ...selected, id, order: selectedIndex + 2 };
    setScenes((current) => {
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
    setScenes((current) =>
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
    setScenes((current) => {
      const next = [...current];
      [next[selectedIndex], next[target]] = [next[target], next[selectedIndex]];
      return next.map((scene, index) => ({ ...scene, order: index + 1 }));
    });
  }

  function exportJson() {
    const payload: SavedDraft = {
      version: 1,
      updatedAt: new Date().toISOString(),
      scenes,
    };
    downloadFile(
      "미래양성원6기_대사편집본.json",
      JSON.stringify(payload, null, 2),
      "application/json;charset=utf-8",
    );
    setNotice("JSON을 저장했어요");
  }

  function exportTxt() {
    downloadFile(
      "미래양성원6기_대사편집본.txt",
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
      if (!validScenes(imported)) throw new Error("invalid");
      const normalized = imported.map((scene, index) => ({
        ...scene,
        id: scene.id || `scene-import-${index + 1}`,
        order: index + 1,
        chapter: scene.chapter || "새 장",
        date: scene.date || "",
        location: scene.location || "",
        direction: scene.direction || "",
        background: scene.background || "",
        character: scene.character || "",
      }));
      setScenes(normalized);
      setSelectedId(normalized[0].id);
      setNotice("편집본을 불러왔어요");
    } catch {
      window.alert("이 편집기에서 내보낸 JSON 파일인지 확인해주세요.");
    }
  }

  function resetDraft() {
    if (!window.confirm("모든 수정을 버리고 현재 게임 원본으로 돌아갈까요?")) return;
    const reset = cloneInitial();
    setScenes(reset);
    setAppliedScenes(reset);
    setSelectedId(reset[0].id);
    localStorage.removeItem(STORAGE_KEY);
    localStorage.removeItem(GAME_STORAGE_KEY);
    localStorage.removeItem(FLUTTER_GAME_STORAGE_KEY);
    setNotice("게임 원본으로 되돌렸어요");
  }

  async function copySelected() {
    if (!selected) return;
    await navigator.clipboard.writeText(makeTxt([selected]));
    setNotice("현재 장면을 복사했어요");
  }

  function handleEditorKey(event: KeyboardEvent<HTMLElement>) {
    if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === "s") {
      event.preventDefault();
      saveToGame();
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
            <p>미래양성원 제6기 · {scenes.length}개 장면</p>
          </div>
        </div>
        <div
          className={`${styles.saveState} ${dirtyCount ? styles.saveStateDirty : ""}`}
        >
          <i />
          {dirtyCount
            ? `게임 미적용 ${dirtyCount}개 · ${saveLabel}`
            : `게임 적용 완료 · ${saveLabel}`}
        </div>
        <nav className={styles.actions} aria-label="파일 메뉴">
          <a href="/play/index.html" target="_blank" rel="noreferrer">
            게임 열기
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
          <button className={styles.primaryAction} type="button" onClick={saveToGame}>
            게임에 저장{dirtyCount ? ` · ${dirtyCount}` : ""}
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

      <section className={styles.workspace}>
        <aside className={styles.sceneRail}>
          <div className={styles.railTitle}>
            <div>
              <strong>장면 목록</strong>
              <span>{filteredScenes.length}개 표시</span>
            </div>
            <button type="button" onClick={addScene} aria-label="새 장면 추가">
              ＋
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
              <button
                className={scene.id === selected.id ? styles.sceneActive : styles.sceneItem}
                type="button"
                key={scene.id}
                onClick={() => requestScene(scene.id)}
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
            ))}
          </div>
        </aside>

        <section className={styles.editorPane}>
          <div className={styles.editorHeading}>
            <div>
              <p>{selected.chapter}</p>
              <h2>장면 {String(selected.order).padStart(2, "0")}</h2>
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

          <div className={styles.metaGrid}>
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

          <label className={styles.field}>
            <span>화자</span>
            <input
              className={styles.speakerInput}
              value={selected.speaker}
              onChange={(event) => updateSelected({ speaker: event.target.value })}
              placeholder="예: 수아"
            />
          </label>

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
              autoFocus
            />
          </label>

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
              <span>입력 즉시 반영</span>
            </div>
            <button type="button" onClick={resetDraft}>원본으로</button>
          </div>
          <div className={styles.phone}>
            <div
              className={styles.previewStage}
              style={{
                backgroundImage: selected.background
                  ? `linear-gradient(180deg, rgba(4,14,28,.18), transparent 48%, rgba(2,8,18,.55)), url("${selected.background}")`
                  : undefined,
              }}
            >
              <div className={styles.sceneMeta}>
                <span>⌂ {selected.location}</span>
                <small>{selected.date}</small>
              </div>
              {selected.character ? (
                <Image
                  className={styles.character}
                  src={selected.character}
                  alt=""
                  aria-hidden="true"
                  width={640}
                  height={960}
                  unoptimized
                />
              ) : null}
              <div className={styles.previewDialogue}>
                <b>{selected.speaker || "화자 없음"}</b>
                {selected.direction.trim() ? <em>{selected.direction}</em> : null}
                <p>{selected.line || "대사를 입력하세요."}</p>
                <span>⌄</span>
              </div>
            </div>
          </div>
          <div className={styles.previewTips}>
            <span>단축키</span>
            <b>Ctrl/⌘ + S</b> 게임에 저장
            <b>Ctrl/⌘ + Enter</b> 다음 장면
          </div>
        </aside>
      </section>
      {notice ? <div className={styles.toast}>{notice}</div> : null}
      {pendingSceneId ? (
        <div className={styles.modalBackdrop}>
          <section
            className={styles.saveModal}
            role="dialog"
            aria-modal="true"
            aria-labelledby="save-dialogue-title"
          >
            <span className={styles.modalIcon}>✎</span>
            <h3 id="save-dialogue-title">이 장면을 저장하시겠습니까?</h3>
            <p>
              장면 {String(selected.order).padStart(2, "0")}의 수정 내용이 아직 게임에
              적용되지 않았어요.
              {pendingScene ? ` 장면 ${String(pendingScene.order).padStart(2, "0")}로 이동할게요.` : ""}
            </p>
            <div className={styles.modalActions}>
              <button type="button" onClick={() => setPendingSceneId(null)}>
                취소
              </button>
              <button className={styles.discardAction} type="button" onClick={discardCurrentAndMove}>
                저장 안 함
              </button>
              <button className={styles.confirmAction} type="button" onClick={saveCurrentAndMove} autoFocus>
                저장하고 이동
              </button>
            </div>
          </section>
        </div>
      ) : null}
    </main>
  );
}
