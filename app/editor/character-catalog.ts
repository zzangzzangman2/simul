export type DialoguePose = {
  id: string;
  label: string;
  asset: string;
};

export type DialogueCharacter = {
  speaker: string;
  group: "주요 인물" | "1981년 정책실" | "미래양성원" | "화면 인물 없음";
  poses: DialoguePose[];
};

const webAsset = (asset: string) => (asset ? `/play/assets/${asset}` : "");

function pose(id: string, label: string, asset: string): DialoguePose {
  return { id, label, asset: webAsset(asset) };
}

const protagonistPoses = [
  ["01", "기본", "01_neutral.png"],
  ["02", "활짝 웃음", "02_cheerful_laugh.png"],
  ["03", "장난스러운 미소", "03_playful_grin.png"],
  ["04", "궁금한 질문", "04_curious_question.png"],
  ["05", "깜짝 놀람", "05_surprised.png"],
  ["06", "걱정", "06_worried.png"],
  ["07", "울음 참기", "07_sad_held_back.png"],
  ["08", "화난 항의", "08_angry_protest.png"],
  ["09", "결심", "09_determined.png"],
  ["10", "쑥스러움", "10_embarrassed.png"],
  ["11", "의심", "11_suspicious.png"],
  ["12", "생각", "12_thinking.png"],
  ["13", "양손 설명", "13_explaining_open_hands.png"],
  ["14", "증거 가리키기", "14_pointing_evidence.png"],
  ["15", "손들기", "15_hand_raise.png"],
  ["16", "허리에 손", "16_hands_on_hips.png"],
  ["17", "명찰 들기", "17_holding_badge.png"],
  ["18", "통장과 연필", "18_passbook_pencil.png"],
  ["19", "장부 읽기", "19_reading_ledger.png"],
  ["20", "계산", "20_calculating.png"],
  ["21", "손실 충격", "21_loss_shock.png"],
  ["22", "승리 주먹", "22_victory_fist.png"],
  ["23", "작별 인사", "23_farewell_wave.png"],
  ["24", "보호 자세", "24_protective_stance.png"],
].map(([id, label, file]) =>
  pose(id, label, `assets/images/protagonist_seed01/${file}`),
);

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
  ["01", "차분한 기본", "01_neutral_quality_v2.png"],
  ["02", "따뜻한 미소 · 선명도 개선", "02_warm_smile_quality_v2.png"],
  ["03", "활짝 웃음", "03_bright_laugh_quality_v2.png"],
  ["04", "깜짝 놀람", "04_surprised_quality_v2.png"],
  ["05", "걱정", "05_worried_quality_v2.png"],
  ["06", "불만", "06_annoyed_quality_v2.png"],
  ["07", "단호한 결심", "07_determined_quality_v2.png"],
  ["08", "활기찬 설명", "08_explaining_quality_v2.png"],
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
  ["01", "기본 인사", "01_base_wave_v1.png"],
  ["02", "따뜻한 미소", "02_warm_smile_v1.png"],
  ["03", "신나는 웃음", "03_delighted_laugh_v1.png"],
  ["04", "수줍은 미소", "04_shy_blush_v1.png"],
  ["05", "깜짝 놀람", "05_surprised_v1.png"],
  ["06", "걱정", "06_worried_v1.png"],
  ["07", "삐친 표정", "07_sulky_pout_v1.png"],
  ["08", "단호한 결심", "08_determined_v1.png"],
  ["09", "차분한 설명", "09_explaining_v1.png"],
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

function policyPoses(
  character: string,
  entries: [string, string, string][],
) {
  return entries.map(([id, label, file]) =>
    pose(
      id,
      label,
      `assets/images/cinematic_soft_painted/policy_1981/${character}/${file}`,
    ),
  );
}

const jeonDugwangPoses = policyPoses("jeon_dugwang", [
  ["01", "결재 서명", "01_signing_v1.png"],
  ["02", "냉정한 경청", "02_listening_v1.png"],
  ["03", "손익 계산", "03_calculating_v1.png"],
  ["04", "차가운 웃음", "04_cold_laugh_v1.png"],
  ["05", "압박 지시", "05_pressure_v1.png"],
  ["06", "최종 결정", "06_final_decision_v1.png"],
]);

const seoMuntaePoses = policyPoses("seo_muntae", [
  ["01", "정책 제안", "01_policy_pitch_v1.png"],
  ["02", "괘도 검토", "02_searching_chart_v1.png"],
  ["03", "격한 반박", "03_rebuttal_v1.png"],
  ["04", "지친 양보", "04_exhausted_concession_v1.png"],
]);

const baekGihyeonPoses = policyPoses("baek_gihyeon", [
  ["01", "장부 보고", "01_report_v2.png"],
  ["02", "조용한 조언", "02_advice_v2.png"],
  ["03", "단호한 경고", "03_warning_v2.png"],
  ["04", "확인과 승인", "04_confirmation_v2.png"],
]);

const kangIncheolPoses = policyPoses("kang_incheol", [
  ["01", "수치 계산", "01_calculation_v2.png"],
  ["02", "계산표 설명", "02_explain_v2.png"],
  ["03", "위험 경고", "03_warning_v2.png"],
  ["04", "수정안 제시", "04_revision_v2.png"],
]);

const yoonMiraPoses = policyPoses("yoon_mira", [
  ["01", "복지 보고", "01_report_v1.png"],
  ["02", "걱정", "02_concern_v1.png"],
  ["03", "단호한 반대", "03_objection_v1.png"],
  ["04", "해결안 제시", "04_solution_v1.png"],
]);

const noPortrait = [pose("00", "인물 없음", "")];

export const dialogueCharacters: DialogueCharacter[] = [
  { speaker: "나", group: "주요 인물", poses: protagonistPoses },
  {
    speaker: "민호",
    group: "주요 인물",
    poses: [
      pose(
        "01",
        "걱정스러운 작별",
        "assets/images/historical_prologue/character_minho_farewell_v3.png",
      ),
    ],
  },
  {
    speaker: "박선희 원장",
    group: "주요 인물",
    poses: [
      pose(
        "01",
        "다정한 당부",
        "assets/images/historical_prologue/character_park_sunhee_farewell_v1.png",
      ),
    ],
  },
  {
    speaker: "수아",
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
    speaker: "학준",
    group: "주요 인물",
    poses: [
      pose(
        "01",
        "규정집 설명",
        "assets/images/historical_prologue/character_hakjun_orientation_v2.png",
      ),
    ],
  },
  { speaker: "한서윤 선생님", group: "주요 인물", poses: teacherPoses },
  {
    speaker: "전두광",
    group: "1981년 정책실",
    poses: jeonDugwangPoses,
  },
  {
    speaker: "서문태 정책실장",
    group: "1981년 정책실",
    poses: seoMuntaePoses,
  },
  {
    speaker: "백기현 비서실장",
    group: "1981년 정책실",
    poses: baekGihyeonPoses,
  },
  {
    speaker: "강인철 경제수석",
    group: "1981년 정책실",
    poses: kangIncheolPoses,
  },
  {
    speaker: "윤미라 사회교육수석",
    group: "1981년 정책실",
    poses: yoonMiraPoses,
  },
  {
    speaker: "장대식 법무수석",
    group: "1981년 정책실",
    poses: [
      pose(
        "01",
        "법률수첩 반박",
        "assets/images/historical_prologue/character_jang_daesik_v1.png",
      ),
    ],
  },
  {
    speaker: "오경태 생활지도관",
    group: "미래양성원",
    poses: [
      pose(
        "01",
        "점검표 지시",
        "assets/images/historical_prologue/character_living_guide_oh_gyeongtae_v1.png",
      ),
    ],
  },
  {
    speaker: "차은주 국가계좌 담당관",
    group: "미래양성원",
    poses: [
      pose(
        "01",
        "국가계좌 안내",
        "assets/images/historical_prologue/character_state_account_officer_cha_eunjoo_v1.png",
      ),
    ],
  },
  { speaker: "이야기", group: "화면 인물 없음", poses: noPortrait },
  { speaker: "아이들", group: "화면 인물 없음", poses: noPortrait },
];

export const dialogueCharacterBySpeaker = new Map(
  dialogueCharacters.map((character) => [character.speaker, character]),
);
