import fs from "node:fs";
import path from "node:path";

const projectRoot = process.cwd();
const sourcePath = process.argv[2];
const outputPath = path.join(
  projectRoot,
  "flutter_app/assets/dialogue/dialogue-editor-override.json",
);

if (!sourcePath) {
  throw new Error(
    "Usage: node scripts/import-dialogue-rewrite.mjs <rewrite.txt>",
  );
}

const source = fs.readFileSync(path.resolve(sourcePath), "utf8");
const original = JSON.parse(fs.readFileSync(outputPath, "utf8"));
const scenePattern =
  /<<<SCENE\s+(\d{3})\|([^|\r\n]+)\|([^>\r\n]+)>>>(?:\r?\n)([\s\S]*?)(?:\r?\n)<<<END>>>/g;
const rewrites = Array.from(source.matchAll(scenePattern), (match) => ({
  order: Number(match[1]),
  id: match[2].trim(),
  speaker: match[3].trim() === "한수아" ? "수아" : match[3].trim(),
  line: match[4].replaceAll("\r\n", "\n").trim(),
}));

if (rewrites.length !== 140) {
  throw new Error(`Expected 140 rewrite scenes, found ${rewrites.length}.`);
}

for (const [index, scene] of rewrites.entries()) {
  const order = index + 1;
  const expectedId = `scene-${String(order).padStart(2, "0")}`;
  if (scene.order !== order || scene.id !== expectedId || !scene.line) {
    throw new Error(
      `Invalid rewrite marker at index ${index}: ${scene.order}|${scene.id}`,
    );
  }
}

if (!Array.isArray(original.scenes) || original.scenes.length !== 140) {
  throw new Error("The canonical dialogue must already contain 140 scenes.");
}

const webImage = (relativePath) =>
  relativePath ? `/play/assets/assets/images/${relativePath}` : "";

const backgrounds = {
  policyRoom: webImage(
    "cinematic_soft_painted/policy_1981/backgrounds/bg_policy_room_night_v1.png",
  ),
  conference: webImage(
    "cinematic_soft_painted/policy_1981/backgrounds/bg_conference_night_v1.png",
  ),
  academy1982: webImage(
    "historical_prologue/bg_future_development_orphanage_1982_portrait_cartoon_v1.png",
  ),
  orphanage: webImage(
    "historical_prologue/bg_orphanage_departure_2000_portrait_v1.png",
  ),
  bus: webImage(
    "historical_prologue/bg_bus_transition_seoul_outskirts_2000_portrait_v1.png",
  ),
  gate: webImage(
    "historical_prologue/bg_future_development_academy_gate_2000_portrait_v1.png",
  ),
  hall: webImage(
    "historical_prologue/bg_future_development_orientation_hall_2000_portrait_v1.png",
  ),
  corridor: webImage(
    "cinematic_soft_painted/dormitory_2000/bg_future_academy_dorm_corridor_2000_v1.png",
  ),
  dormDay: webImage(
    "cinematic_soft_painted/dormitory_2000/bg_future_academy_dorm_shared_room_day_2000_v1.png",
  ),
  dormNight: webImage(
    "cinematic_soft_painted/dormitory_2000/bg_future_academy_dorm_shared_room_night_2000_v1.png",
  ),
  stockLab: webImage("bg_stock_academy_2000_portrait_cartoon_v4.png"),
};

function backgroundFor(order) {
  if (order <= 5) return backgrounds.policyRoom;
  if (order <= 16) return backgrounds.conference;
  if (order === 17) return backgrounds.academy1982;
  if (order <= 23) return backgrounds.orphanage;
  if (order === 24) return backgrounds.bus;
  if (order <= 32) return backgrounds.gate;
  if (order <= 54) return backgrounds.hall;
  if (order <= 58) return backgrounds.corridor;
  if (order <= 123) return backgrounds.dormDay;
  if (order <= 130) return backgrounds.dormNight;
  if (order === 131) return backgrounds.dormDay;
  if (order === 132) return backgrounds.corridor;
  return backgrounds.stockLab;
}

function chapterFor(order) {
  if (order <= 16) return "1장 · 사람을 자본으로 만드는 밤";
  if (order <= 23) return "2장 · 한 손으로 드는 전부";
  if (order <= 32) return "3장 · 설명서 학준";
  if (order <= 54) return "4장 · 왜 하필 너였을까";
  if (order <= 130) return "5장 · 열 명이 쓰는 한 방";
  return "6장 · PC 열 대가 켜지는 아침";
}

function dateFor(order) {
  if (order <= 16) return "1981.01.12  ·  23:40";
  if (order === 17) return "1982년  ·  미래양성계획 출범";
  if (order <= 23) return "2000.01.02  ·  06:42";
  if (order === 24) return "2000.01.02  ·  07:31";
  if (order <= 32) return "2000.01.02  ·  08:54";
  if (order <= 54) return "2000.01.02  ·  09:00";
  if (order <= 58) return "2000.01.02  ·  11:28";
  if (order <= 65) return "2000.01.02  ·  11:30";
  if (order <= 109) return "2000.01.02  ·  11:37";
  if (order <= 123) return "2000.01.02  ·  13:05";
  if (order <= 130) return "2000.01.02  ·  21:34";
  if (order === 131) return "2000.01.03  ·  08:40";
  if (order === 132) return "2000.01.03  ·  08:55";
  return "2000.01.03  ·  09:00";
}

function locationFor(order) {
  if (order <= 5) return "청와대 · 정책실";
  if (order <= 16) return "청와대 · 미래전략 심야회의";
  if (order === 17) return "국립 미래양성원 · 개원 기록";
  if (order <= 23) return "새봄보육원 · 2층 다섯 번째 방";
  if (order === 24) return "미래양성원행 버스 · 서울 외곽";
  if (order <= 32) return "국립 미래양성원 · 정문";
  if (order <= 54) return "국립 미래양성원 · 제6기 오리엔테이션 강당";
  if (order <= 58 || order === 132) return "국립 미래양성원 · 기숙사 중앙 복도";
  if (order <= 131) return "국립 미래양성원 · 제6기 공용 생활실";
  return "국립 미래양성원 · 주식 PC 실습실";
}

const character = (relativePath) => webImage(relativePath);
const characterByOrder = new Map();
const setCharacters = (orders, relativePath) => {
  for (const order of orders) characterByOrder.set(order, character(relativePath));
};

setCharacters([2], "cinematic_soft_painted/policy_1981/jeon_dugwang/02_listening_v1.png");
setCharacters([6], "cinematic_soft_painted/policy_1981/jeon_dugwang/05_pressure_v1.png");
setCharacters([10, 13], "cinematic_soft_painted/policy_1981/jeon_dugwang/03_calculating_v1.png");
setCharacters([15], "cinematic_soft_painted/policy_1981/jeon_dugwang/01_signing_v1.png");
setCharacters([3], "cinematic_soft_painted/policy_1981/seo_muntae/01_policy_pitch_v1.png");
setCharacters([8], "cinematic_soft_painted/policy_1981/seo_muntae/04_exhausted_concession_v1.png");
setCharacters([12], "cinematic_soft_painted/policy_1981/seo_muntae/02_searching_chart_v1.png");
setCharacters([14], "cinematic_soft_painted/policy_1981/seo_muntae/03_rebuttal_v1.png");
setCharacters([4], "cinematic_soft_painted/policy_1981/baek_gihyeon/03_warning_v2.png");
setCharacters([11], "cinematic_soft_painted/policy_1981/baek_gihyeon/02_advice_v2.png");
setCharacters([5], "cinematic_soft_painted/policy_1981/kang_incheol/02_explain_v2.png");
setCharacters([9], "cinematic_soft_painted/policy_1981/yoon_mira/03_objection_v1.png");
setCharacters([16], "cinematic_soft_painted/policy_1981/yoon_mira/04_solution_v1.png");
setCharacters([19], "historical_prologue/character_minho_farewell_v3.png");
setCharacters([23], "historical_prologue/character_park_sunhee_farewell_v1.png");
setCharacters([20, 27], "protagonist_seed01/03_playful_grin.png");
setCharacters([22, 127], "protagonist_seed01/17_holding_badge.png");
setCharacters([41, 63, 79, 93], "protagonist_seed01/04_curious_question.png");
setCharacters([51, 95], "protagonist_seed01/12_thinking.png");

setCharacters(
  [29, 31, 39, 47, 57, 88, 90, 125, 128, 135],
  "historical_prologue/character_hakjun_orientation_v2.png",
);
setCharacters([35, 43, 46, 52, 56, 132, 137], "주식선생님/22_포즈1_주인공그림체_공통슬롯_투명.png");
setCharacters([38, 48, 58, 62, 134, 136], "주식선생님/23_포즈2_주인공그림체_공통슬롯_투명.png");
setCharacters([36, 40, 44, 50, 60, 139], "주식선생님/24_포즈3_주인공그림체_공통슬롯_투명.png");
setCharacters([45, 54, 140], "주식선생님/26_포즈5_주인공그림체_공통슬롯_투명.png");

setCharacters([26, 49, 120, 126], "production_soft_painted/han_sua/05_worried_quality_v2.png");
setCharacters([30, 87], "production_soft_painted/han_sua/06_annoyed_quality_v2.png");
setCharacters([32, 76, 89], "production_soft_painted/han_sua/03_bright_laugh_quality_v2.png");
setCharacters([37, 94], "production_soft_painted/han_sua/04_surprised_quality_v2.png");
setCharacters([61], "production_soft_painted/han_sua/02_warm_smile_quality_v2.png");
setCharacters([64, 86], "production_soft_painted/han_sua/08_explaining_quality_v2.png");
setCharacters([129], "production_soft_painted/han_sua/07_determined_quality_v2.png");

setCharacters([69], "production_soft_painted/kim_seoa/02_soft_smile_agree_v1.png");
setCharacters([70], "production_soft_painted/kim_seoa/01_neutral_notebook_v1.png");
setCharacters([111], "production_soft_painted/kim_seoa/05_surprised_record_v1.png");
setCharacters([113], "production_soft_painted/kim_seoa/09_explaining_ledger_v1.png");
setCharacters([71, 101], "production_soft_painted/lee_jian/03_focused_repair_v2.png");
setCharacters([72], "production_soft_painted/lee_jian/09_explaining_mechanism_v2.png");
setCharacters([107], "production_soft_painted/lee_jian/07_apologetic_boundary_v2.png");
setCharacters([109], "production_soft_painted/lee_jian/02_playful_wink_v2.png");
setCharacters([73, 74], "production_soft_painted/choi_iseo/08_focused_mending_v1.png");
setCharacters([100, 102], "production_soft_painted/choi_iseo/07_firm_boundary_v1.png");
setCharacters([108], "production_soft_painted/choi_iseo/02_gentle_smile_v1.png");
setCharacters([75], "production_soft_painted/jung_arin/09_counting_explain_v1.png");
setCharacters([77], "production_soft_painted/jung_arin/02_confident_smile_v1.png");
setCharacters([98], "production_soft_painted/jung_arin/04_assigning_tasks_v1.png");
setCharacters([103], "production_soft_painted/jung_arin/07_deadline_annoyed_v1.png");
setCharacters([105], "production_soft_painted/jung_arin/05_startled_v1.png");
setCharacters([116], "production_soft_painted/jung_arin/08_determined_ready_v1.png");
setCharacters([78], "production_soft_painted/park_haeun/02_warm_smile_v1.png");
setCharacters([80], "production_soft_painted/park_haeun/01_base_wave_v1.png");
setCharacters([104, 106, 118], "production_soft_painted/park_haeun/09_explaining_v1.png");
setCharacters([112], "production_soft_painted/park_haeun/05_surprised_v1.png");
setCharacters([81], "production_soft_painted/yoon_chaea/01_neutral_tie_v1.png");
setCharacters([82, 122], "production_soft_painted/yoon_chaea/09_explaining_v1.png");
setCharacters([84, 115], "production_soft_painted/yoon_chaea/08_determined_v1.png");
setCharacters([83], "production_soft_painted/oh_jiwoo/04_playful_counterpoint_v1.png");
setCharacters([85], "production_soft_painted/oh_jiwoo/02_cheerful_fang_wave_v1.png");
setCharacters([117, 121], "production_soft_painted/oh_jiwoo/06_skeptical_thinking_v1.png");

const rewriteById = new Map(rewrites.map((scene) => [scene.id, scene]));
const scenes = original.scenes
  .map((scene) => {
    const rewrite = rewriteById.get(scene.id);
    if (!rewrite) throw new Error(`Missing rewrite for ${scene.id}.`);
    return {
      ...scene,
      order: rewrite.order,
      chapter: chapterFor(rewrite.order),
      date: dateFor(rewrite.order),
      location: locationFor(rewrite.order),
      speaker: rewrite.speaker,
      direction: "",
      line: rewrite.line,
      background: backgroundFor(rewrite.order),
      character: characterByOrder.get(rewrite.order) ?? "",
    };
  })
  .sort((left, right) => left.order - right.order);

for (const scene of scenes) {
  for (const value of [scene.background, scene.character]) {
    if (!value) continue;
    const relativePath = value.replace("/play/assets/assets/", "flutter_app/assets/");
    const localPath = path.join(projectRoot, relativePath);
    if (!fs.existsSync(localPath)) {
      throw new Error(`Missing referenced asset: ${relativePath}`);
    }
  }
}

const output = {
  version: 1,
  contentVersion: 1,
  updatedAt: new Date().toISOString(),
  scenes,
  appearanceVersion: 13,
};
fs.writeFileSync(outputPath, `${JSON.stringify(output, null, 2)}\n`, "utf8");
console.log(`Imported ${scenes.length} rewritten dialogue scenes.`);
