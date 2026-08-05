export type DialoguePose = {
  id: string;
  label: string;
  asset: string;
};

export type DialogueCharacter = {
  speaker: string;
  group:
    | "주요 인물"
    | "1999년 국정원"
    | "프로젝트 데시멀"
    | "화면 인물 없음";
  poses: DialoguePose[];
};

const webAsset = (asset: string) => (asset ? `/play/assets/${asset}` : "");

function pose(id: string, label: string, asset: string): DialoguePose {
  return { id, label, asset: webAsset(asset) };
}

const protagonistPoses = [pose("00", "인물 없음", "")];

const teacherPoses = [
  ["01", "포인터 설명", "22_포즈1_주인공그림체_공통슬롯_투명.png"],
  ["02", "왼쪽 설명", "23_포즈2_주인공그림체_공통슬롯_투명.png"],
  ["03", "양손 설명", "24_포즈3_주인공그림체_공통슬롯_투명.png"],
  ["04", "교재 들기", "25_포즈4_주인공그림체_공통슬롯_투명.png"],
  ["05", "경청", "26_포즈5_주인공그림체_공통슬롯_투명.png"],
  ["06", "핵심 강조", "27_포즈6_주인공그림체_공통슬롯_투명.png"],
].map(([id, label, file]) =>
  pose(id, label, `assets/images/주식선생님/${file}`),
);

const suaPoses = [
  ["01", "차분한 웨이브 기본", "01_neutral_wavy_v3.png"],
  ["02", "따뜻한 미소와 손인사", "02_warm_smile_wave_v3.png"],
  ["03", "활짝 웃음", "03_bright_laugh_v3.png"],
  ["04", "장난스러운 윙크", "04_playful_wink_v3.png"],
  ["05", "깜짝 놀람", "05_surprised_v3.png"],
  ["06", "걱정", "06_worried_v3.png"],
  ["07", "불만", "07_annoyed_v3.png"],
  ["08", "단호한 결심", "08_determined_v3.png"],
  ["09", "활기찬 설명", "09_explaining_v3.png"],
].map(([id, label, file]) =>
  pose(id, label, `assets/images/production_soft_painted/han_sua/${file}`),
);

const kimSeoaPoses = [
  ["01", "공책 든 기본", "01_neutral_notebook_v1.png"],
  ["02", "부드러운 동의", "02_soft_smile_agree_v1.png"],
  ["03", "안도하는 웃음", "03_relieved_laugh_v1.png"],
  ["04", "수줍은 감사", "04_shy_appreciative_v1.png"],
  ["05", "기록 중 놀람", "05_surprised_record_v1.png"],
  ["06", "장부 걱정", "06_worried_checking_v1.png"],
  ["07", "단호한 경계", "07_firm_boundary_v1.png"],
  ["08", "기록 결심", "08_determined_record_v1.png"],
  ["09", "장부 설명", "09_explaining_ledger_v1.png"],
].map(([id, label, file]) =>
  pose(id, label, `assets/images/production_soft_painted/kim_seoa/${file}`),
);

const leeJianPoses = [
  ["01", "드라이버 든 기본", "01_neutral_screwdriver_v2.png"],
  ["02", "장난스러운 윙크", "02_playful_wink_v2.png"],
  ["03", "수리 집중", "03_focused_repair_v2.png"],
  ["04", "고장 발견 놀람", "04_surprised_fault_v2.png"],
  ["05", "진단 걱정", "05_worried_diagnosis_v2.png"],
  ["06", "방해받은 불만", "06_annoyed_interrupted_v2.png"],
  ["07", "책임지는 사과", "07_apologetic_boundary_v2.png"],
  ["08", "수리 결심", "08_determined_repair_v2.png"],
  ["09", "작동 원리 설명", "09_explaining_mechanism_v2.png"],
].map(([id, label, file]) =>
  pose(id, label, `assets/images/production_soft_painted/lee_jian/${file}`),
);

const choiIseoPoses = [
  ["01", "실 든 기본", "01_base_thread_v1.png"],
  ["02", "온화한 미소", "02_gentle_smile_v1.png"],
  ["03", "기쁜 웃음", "03_pleased_laugh_v1.png"],
  ["04", "수줍은 당황", "04_shy_flustered_v1.png"],
  ["05", "깜짝 놀람", "05_surprised_v1.png"],
  ["06", "상처받은 침묵", "06_hurt_withdrawn_v1.png"],
  ["07", "단호한 경계", "07_firm_boundary_v1.png"],
  ["08", "바느질 집중", "08_focused_mending_v1.png"],
  ["09", "꼼꼼한 확인", "09_skeptical_inspection_v1.png"],
].map(([id, label, file]) =>
  pose(id, label, `assets/images/production_soft_painted/choi_iseo/${file}`),
);

const ohJiwooPoses = [
  ["01", "방송 준비 기본", "01_alert_neutral_v1.png"],
  ["02", "덧니 미소와 인사", "02_cheerful_fang_wave_v1.png"],
  ["03", "속보 흥분", "03_breaking_news_excited_v1.png"],
  ["04", "장난스러운 반론", "04_playful_counterpoint_v1.png"],
  ["05", "정정 보도 놀람", "05_surprised_correction_v1.png"],
  ["06", "의심하며 생각", "06_skeptical_thinking_v1.png"],
  ["07", "짜증 섞인 반박", "07_annoyed_rebuttal_v1.png"],
  ["08", "방송 결심", "08_determined_broadcast_v1.png"],
  ["09", "보도 설명", "09_explaining_report_v1.png"],
].map(([id, label, file]) =>
  pose(id, label, `assets/images/production_soft_painted/oh_jiwoo/${file}`),
);

const parkHaeunPoses = [
  ["01", "차분한 기본", "01_neutral_v3.png"],
  ["02", "부드러운 미소", "02_gentle_smile_v3.png"],
  ["03", "활짝 웃음", "03_bright_laugh_v3.png"],
  ["04", "깜짝 놀람", "04_surprised_v3.png"],
  ["05", "조용한 걱정", "05_worried_v3.png"],
  ["06", "화난 표정", "06_angry_v3.png"],
  ["07", "부끄러운 표정", "07_embarrassed_v3.png"],
  ["08", "슬픈 표정", "08_sad_v3.png"],
  ["09", "단호한 표정", "09_firm_v3.png"],
].map(([id, label, file]) =>
  pose(id, label, `assets/images/production_soft_painted/park_haeun/${file}`),
);

const jungArinPoses = [
  ["01", "기본 장난기", "01_base_cheeky_v1.png"],
  ["02", "자신감 있는 미소", "02_confident_smile_v1.png"],
  ["03", "깜찍한 웃음", "03_cheeky_laugh_v1.png"],
  ["04", "담당 지정", "04_assigning_tasks_v1.png"],
  ["05", "깜짝 놀람", "05_startled_v1.png"],
  ["06", "일정 걱정", "06_schedule_worried_v1.png"],
  ["07", "마감 불만", "07_deadline_annoyed_v1.png"],
  ["08", "실행 결의", "08_determined_ready_v1.png"],
  ["09", "순서 설명", "09_counting_explain_v1.png"],
].map(([id, label, file]) =>
  pose(id, label, `assets/images/production_soft_painted/jung_arin/${file}`),
);

const yoonChaeaPoses = [
  ["01", "차분한 기본", "01_neutral_tie_v1.png"],
  ["02", "부드러운 미소", "02_soft_smile_wave_v1.png"],
  ["03", "기쁜 웃음", "03_delighted_laugh_v1.png"],
  ["04", "수줍은 홍조", "04_shy_blush_v1.png"],
  ["05", "깜짝 놀람", "05_surprised_v1.png"],
  ["06", "조용한 걱정", "06_worried_v1.png"],
  ["07", "삐친 표정", "07_sulky_pout_v1.png"],
  ["08", "단단한 결심", "08_determined_v1.png"],
  ["09", "가격 구조 설명", "09_explaining_v1.png"],
].map(([id, label, file]) =>
  pose(id, label, `assets/images/production_soft_painted/yoon_chaea/${file}`),
);

const noPortrait = [pose("00", "인물 없음", "")];

export const dialogueCharacters: DialogueCharacter[] = [
  { speaker: "{{playerName}}", group: "주요 인물", poses: protagonistPoses },
  {
    speaker: "한수아",
    group: "주요 인물",
    poses: suaPoses,
  },
  {
    speaker: "김서아",
    group: "주요 인물",
    poses: kimSeoaPoses,
  },
  {
    speaker: "이지안",
    group: "주요 인물",
    poses: leeJianPoses,
  },
  {
    speaker: "최이서",
    group: "주요 인물",
    poses: choiIseoPoses,
  },
  {
    speaker: "박하은",
    group: "주요 인물",
    poses: parkHaeunPoses,
  },
  {
    speaker: "정아린",
    group: "주요 인물",
    poses: jungArinPoses,
  },
  {
    speaker: "윤채아",
    group: "주요 인물",
    poses: yoonChaeaPoses,
  },
  {
    speaker: "오지우",
    group: "주요 인물",
    poses: ohJiwooPoses,
  },
  {
    speaker: "김학준",
    group: "주요 인물",
    poses: [
      pose("01", "중립 검산", "assets/images/production_soft_painted/kim_hakjun/01_neutral_crosscheck_uniform_v4.png"),
      pose("02", "규칙 설명", "assets/images/production_soft_painted/kim_hakjun/02_explaining_rules_uniform_v4.png"),
      pose("03", "조건 의심", "assets/images/production_soft_painted/kim_hakjun/03_skeptical_condition_check_uniform_v4.png"),
      pose("04", "숨은 조항 발견", "assets/images/production_soft_painted/kim_hakjun/04_surprised_hidden_clause_uniform_v4.png"),
      pose("05", "불공정 손실 걱정", "assets/images/production_soft_painted/kim_hakjun/05_worried_unfair_loss_uniform_v4.png"),
      pose("06", "단호한 이의", "assets/images/production_soft_painted/kim_hakjun/06_firm_objection_uniform_v4.png"),
      pose("07", "검산 결의", "assets/images/production_soft_painted/kim_hakjun/07_determined_verification_uniform_v4.png"),
      pose("08", "계산 기록", "assets/images/production_soft_painted/kim_hakjun/08_calculating_notes_uniform_v4.png"),
      pose("09", "절제된 팀 인정", "assets/images/production_soft_painted/kim_hakjun/09_restrained_team_smile_uniform_v4.png"),
    ],
  },
  { speaker: "한서윤 운영관", group: "주요 인물", poses: teacherPoses },
  {
    speaker: "한규진 국정원장",
    group: "1999년 국정원",
    poses: [
      pose(
        "01",
        "재가동 승인",
        "assets/images/cinematic_soft_painted/decimal_nis_1999/characters/han_gyujin_nis_director_v1.png",
      ),
    ],
  },
  {
    speaker: "임서희 경제안보국장",
    group: "1999년 국정원",
    poses: [
      pose(
        "01",
        "시장 위험 분석",
        "assets/images/cinematic_soft_painted/decimal_nis_1999/characters/lim_seohee_economic_security_chief_v1.png",
      ),
    ],
  },
  {
    speaker: "도윤석 기획조정관",
    group: "1999년 국정원",
    poses: [
      pose(
        "01",
        "작전 기록 검토",
        "assets/images/cinematic_soft_painted/decimal_nis_1999/characters/do_yunseok_planning_coordinator_v1.png",
      ),
    ],
  },
  {
    speaker: "조민경 권익감사관",
    group: "1999년 국정원",
    poses: [
      pose(
        "01",
        "중단권 감사",
        "assets/images/cinematic_soft_painted/decimal_nis_1999/characters/jo_mingyeong_rights_auditor_v1.png",
      ),
    ],
  },
  {
    speaker: "오경태 시설관리관",
    group: "프로젝트 데시멀",
    poses: [
      pose(
        "01",
        "점검표 지시",
        "assets/images/cinematic_soft_painted/decimal_nis_1999/characters/oh_gyeongtae_facilities_manager_v2.png",
      ),
    ],
  },
  {
    speaker: "차은주 선발관",
    group: "프로젝트 데시멀",
    poses: [
      pose(
        "01",
        "선발 기록 확인",
        "assets/images/cinematic_soft_painted/decimal_nis_1999/characters/cha_eunjoo_selection_officer_v2.png",
      ),
    ],
  },
  { speaker: "이야기", group: "화면 인물 없음", poses: noPortrait },
  { speaker: "아이들", group: "화면 인물 없음", poses: noPortrait },
  { speaker: "거절한 후보", group: "화면 인물 없음", poses: noPortrait },
];

export const dialogueCharacterBySpeaker = new Map(
  dialogueCharacters.map((character) => [character.speaker, character]),
);
