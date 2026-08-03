"use client";

import { useEffect, useMemo, useState } from "react";
import type { DialogueScene } from "./dialogue-types";
import styles from "./scene-toolbox.module.css";

const VERSION_KEY = "project-decimal-editor-versions-v1";
const TEMPLATE_KEY = "project-decimal-editor-templates-v1";

type VersionEntry = { id: string; label: string; createdAt: string; scenes: DialogueScene[] };
type TemplateEntry = { id: string; label: string; scene: DialogueScene };

type SceneToolboxProps = {
  scenes: DialogueScene[];
  selectedScene: DialogueScene;
  selectedIds: string[];
  filteredIds: string[];
  onSelectedIdsChange: (ids: string[]) => void;
  onReplaceScenes: (scenes: DialogueScene[]) => void;
  onSelectScene: (id: string) => void;
};

function loadStored<T>(key: string): T[] {
  try {
    const raw = localStorage.getItem(key);
    const parsed = raw ? JSON.parse(raw) : [];
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function saveStored<T>(key: string, value: T[]) {
  localStorage.setItem(key, JSON.stringify(value));
}

function renumber(scenes: DialogueScene[]) {
  return scenes.map((scene, index) => ({ ...scene, order: index + 1 }));
}

export default function SceneToolbox({
  scenes,
  selectedScene,
  selectedIds,
  filteredIds,
  onSelectedIdsChange,
  onReplaceScenes,
  onSelectScene,
}: SceneToolboxProps) {
  const [open, setOpen] = useState(false);
  const [tab, setTab] = useState<"batch" | "replace" | "template" | "version" | "audit">("batch");
  const [findText, setFindText] = useState("");
  const [replaceText, setReplaceText] = useState("");
  const [replaceScope, setReplaceScope] = useState<"selected" | "all">("selected");
  const [tagText, setTagText] = useState("");
  const [batchTransition, setBatchTransition] = useState("fade");
  const [templateName, setTemplateName] = useState("");
  const [versionName, setVersionName] = useState("");
  const [templates, setTemplates] = useState<TemplateEntry[]>([]);
  const [versions, setVersions] = useState<VersionEntry[]>([]);

  useEffect(() => {
    const timer = window.setTimeout(() => {
      setTemplates(loadStored<TemplateEntry>(TEMPLATE_KEY));
      setVersions(loadStored<VersionEntry>(VERSION_KEY));
    }, 0);
    return () => window.clearTimeout(timer);
  }, []);

  const targetIds = selectedIds.length ? selectedIds : [selectedScene.id];
  const audit = useMemo(() => {
    const byId = new Map(scenes.map((scene) => [scene.id, scene]));
    const visited = new Set<string>();
    const queue = scenes[0] ? [scenes[0].id] : [];
    while (queue.length) {
      const id = queue.shift()!;
      if (visited.has(id)) continue;
      visited.add(id);
      const scene = byId.get(id);
      if (!scene) continue;
      const index = scenes.findIndex((item) => item.id === id);
      const targets = [
        ...(scene.nextSceneId ? [scene.nextSceneId] : scenes[index + 1] ? [scenes[index + 1].id] : []),
        ...(scene.choices ?? []).map((choice) => choice.targetSceneId).filter(Boolean),
      ];
      for (const target of targets) if (!visited.has(target)) queue.push(target);
    }
    const unreachable = scenes.filter((scene) => !visited.has(scene.id));
    const emptyLines = scenes.filter((scene) => !scene.line.trim());
    const missingAssets = scenes.filter((scene) => scene.speaker !== "이야기" && !scene.character && !(scene.characters?.length));
    return { unreachable, emptyLines, missingAssets };
  }, [scenes]);

  function updateTargets(updater: (scene: DialogueScene) => DialogueScene) {
    const ids = new Set(targetIds);
    onReplaceScenes(renumber(scenes.map((scene) => ids.has(scene.id) ? updater(scene) : scene)));
  }

  function addTag() {
    const tag = tagText.trim();
    if (!tag) return;
    updateTargets((scene) => ({ ...scene, tags: Array.from(new Set([...(scene.tags ?? []), tag])) }));
    setTagText("");
  }

  function applyTransition() {
    updateTargets((scene) => ({ ...scene, transition: batchTransition as DialogueScene["transition"] }));
  }

  function duplicateTargets() {
    const ids = new Set(targetIds);
    const now = Date.now();
    const next: DialogueScene[] = [];
    for (const scene of scenes) {
      next.push(scene);
      if (ids.has(scene.id)) next.push(structuredClone({ ...scene, id: `${scene.id}-copy-${now}-${next.length}` }));
    }
    onReplaceScenes(renumber(next));
  }

  function deleteTargets() {
    if (targetIds.length >= scenes.length) return;
    if (!window.confirm(`${targetIds.length}개 장면을 삭제할까요?`)) return;
    const ids = new Set(targetIds);
    const next = renumber(scenes.filter((scene) => !ids.has(scene.id)));
    onReplaceScenes(next);
    onSelectedIdsChange([]);
    onSelectScene(next[0].id);
  }

  function replaceAcrossScenes() {
    if (!findText) return;
    const ids = replaceScope === "all" ? new Set(scenes.map((scene) => scene.id)) : new Set(targetIds);
    const fields = ["chapter", "date", "location", "speaker", "direction", "line", "notes"] as const;
    onReplaceScenes(renumber(scenes.map((scene) => {
      if (!ids.has(scene.id)) return scene;
      const patch = Object.fromEntries(fields.map((field) => [field, (scene[field] ?? "").replaceAll(findText, replaceText)]));
      return { ...scene, ...patch };
    })));
  }

  function saveTemplate() {
    const label = templateName.trim() || `${selectedScene.speaker} 장면`;
    const next = [{ id: `template-${Date.now()}`, label, scene: structuredClone(selectedScene) }, ...templates].slice(0, 20);
    setTemplates(next);
    saveStored(TEMPLATE_KEY, next);
    setTemplateName("");
  }

  function applyTemplate(template: TemplateEntry) {
    const templateFields: Partial<DialogueScene> = structuredClone(template.scene);
    delete templateFields.id;
    delete templateFields.order;
    updateTargets((scene) => ({ ...scene, ...templateFields }));
  }

  function saveVersion() {
    const label = versionName.trim() || `수동 저장 ${new Date().toLocaleString("ko-KR")}`;
    const next = [{ id: `version-${Date.now()}`, label, createdAt: new Date().toISOString(), scenes: structuredClone(scenes) }, ...versions].slice(0, 20);
    setVersions(next);
    saveStored(VERSION_KEY, next);
    setVersionName("");
  }

  function restoreVersion(version: VersionEntry) {
    if (!window.confirm(`“${version.label}” 버전으로 되돌릴까요? 현재 상태는 먼저 버전 저장하는 것이 안전합니다.`)) return;
    onReplaceScenes(renumber(structuredClone(version.scenes)));
    onSelectedIdsChange([]);
    onSelectScene(version.scenes[0]?.id ?? scenes[0].id);
  }

  function removeTemplate(id: string) {
    const next = templates.filter((item) => item.id !== id);
    setTemplates(next);
    saveStored(TEMPLATE_KEY, next);
  }

  function removeVersion(id: string) {
    const next = versions.filter((item) => item.id !== id);
    setVersions(next);
    saveStored(VERSION_KEY, next);
  }

  return (
    <section className={styles.toolbox}>
      <button type="button" className={styles.toggle} onClick={() => setOpen((value) => !value)} aria-expanded={open}>
        <span>⌘</span><b>일괄 편집·버전 관리</b><small>{selectedIds.length ? `${selectedIds.length}개 선택됨` : "현재 장면 기준"}</small><i>{open ? "−" : "+"}</i>
      </button>
      {open ? (
        <div className={styles.body}>
          <nav>{([['batch','일괄'],['replace','찾아바꾸기'],['template','템플릿'],['version','버전'],['audit','검사']] as const).map(([id,label]) => <button type="button" key={id} className={tab === id ? styles.active : ""} onClick={() => setTab(id)}>{label}</button>)}</nav>
          {tab === "batch" ? <div className={styles.panel}>
            <div className={styles.summary}><b>{targetIds.length}개 장면</b><span>{selectedIds.length ? "체크한 장면에만 적용" : "현재 장면에 적용"}</span></div>
            <div className={styles.actions}><button type="button" onClick={() => onSelectedIdsChange(filteredIds)}>검색 결과 전체 선택</button><button type="button" onClick={() => onSelectedIdsChange([])}>선택 해제</button><button type="button" onClick={duplicateTargets}>선택 복제</button><button type="button" className={styles.danger} onClick={deleteTargets}>선택 삭제</button></div>
            <div className={styles.inlineForm}><input value={tagText} onChange={(event) => setTagText(event.target.value)} placeholder="추가할 태그" /><button type="button" onClick={addTag}>태그 추가</button><select value={batchTransition} onChange={(event) => setBatchTransition(event.target.value)}><option value="cut">컷</option><option value="fade">페이드</option><option value="dissolve">디졸브</option><option value="slide-left">왼쪽 슬라이드</option><option value="slide-right">오른쪽 슬라이드</option><option value="flash">플래시</option></select><button type="button" onClick={applyTransition}>전환 일괄 적용</button></div>
          </div> : null}
          {tab === "replace" ? <div className={styles.panel}><div className={styles.inlineForm}><input value={findText} onChange={(event) => setFindText(event.target.value)} placeholder="찾을 문구" /><input value={replaceText} onChange={(event) => setReplaceText(event.target.value)} placeholder="바꿀 문구" /><select value={replaceScope} onChange={(event) => setReplaceScope(event.target.value as "selected" | "all")}><option value="selected">선택 장면</option><option value="all">전체 장면</option></select><button type="button" onClick={replaceAcrossScenes} disabled={!findText}>모두 바꾸기</button></div><p>장 제목·날짜·장소·화자·지문·대사·제작 메모를 한 번에 검색합니다.</p></div> : null}
          {tab === "template" ? <div className={styles.panel}><div className={styles.inlineForm}><input value={templateName} onChange={(event) => setTemplateName(event.target.value)} placeholder="템플릿 이름" /><button type="button" onClick={saveTemplate}>현재 장면을 템플릿으로 저장</button></div><StoredList items={templates} empty="저장한 장면 템플릿이 없습니다." onApply={applyTemplate} onRemove={removeTemplate} /></div> : null}
          {tab === "version" ? <div className={styles.panel}><div className={styles.inlineForm}><input value={versionName} onChange={(event) => setVersionName(event.target.value)} placeholder="버전 이름" /><button type="button" onClick={saveVersion}>전체 편집본 버전 저장</button></div><StoredList items={versions} empty="수동 저장한 버전이 없습니다." onApply={restoreVersion} onRemove={removeVersion} /></div> : null}
          {tab === "audit" ? <div className={styles.audit}><AuditCard label="도달 불가" count={audit.unreachable.length} items={audit.unreachable} onSelect={onSelectScene} /><AuditCard label="빈 대사" count={audit.emptyLines.length} items={audit.emptyLines} onSelect={onSelectScene} /><AuditCard label="인물 자산 없음" count={audit.missingAssets.length} items={audit.missingAssets} onSelect={onSelectScene} /></div> : null}
        </div>
      ) : null}
    </section>
  );
}

function StoredList<T extends { id: string; label: string }>({ items, empty, onApply, onRemove }: { items: T[]; empty: string; onApply: (item: T) => void; onRemove: (id: string) => void }) {
  if (!items.length) return <p className={styles.empty}>{empty}</p>;
  return <div className={styles.storedList}>{items.map((item) => <article key={item.id}><div><b>{item.label}</b><small>{"createdAt" in item ? new Date(String(item.createdAt)).toLocaleString("ko-KR") : item.id}</small></div><button type="button" onClick={() => onApply(item)}>적용</button><button type="button" onClick={() => onRemove(item.id)}>삭제</button></article>)}</div>;
}

function AuditCard({ label, count, items, onSelect }: { label: string; count: number; items: DialogueScene[]; onSelect: (id: string) => void }) {
  return <article className={count ? styles.auditWarn : styles.auditGood}><header><b>{label}</b><strong>{count}</strong></header>{items.slice(0, 5).map((scene) => <button type="button" key={scene.id} onClick={() => onSelect(scene.id)}>{scene.order}. {scene.speaker} · {scene.id}</button>)}{!count ? <p>문제 없음</p> : null}</article>;
}
