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
  ["01", "차분한 기본", "01_neutral_v1.png"],
  ["02", "따뜻한 미소", "02_warm_smile_v1.png"],
  ["03", "활짝 웃음", "03_bright_laugh_v1.png"],
  ["04", "장난스러운 놀림", "04_playful_tease_v1.png"],
  ["05", "깜짝 놀람", "05_surprised_v1.png"],
  ["06", "걱정", "06_worried_v1.png"],
  ["07", "단호한 결심", "07_determined_v1.png"],
].map(([id, label, file]) =>
  pose(id, label, `assets/images/cinematic_soft_painted/sua/${file}`),
);

const iseoPoses = [
  ["01", "차분한 기본", "01_neutral_master.png"],
  ["02", "밝은 인사 웃음", "02_bright_greeting_smile.png"],
  ["03", "차분한 설명", "03_calm_explain_hands_together.png"],
  ["04", "궁금한 질문", "04_curious_open_palm.png"],
  ["05", "깜짝 놀람", "05_surprised_hands_up.png"],
  ["06", "걱정", "06_worried_hands_clasped.png"],
  ["07", "수줍음", "07_shy_hair_touch.png"],
  ["08", "살짝 삐침", "08_mild_annoyed_arms_crossed.png"],
  ["09", "의심", "09_skeptical_hand_on_hip.png"],
  ["10", "단호한 결심", "10_determined_fist.png"],
  ["11", "속상함", "11_sad_downcast.png"],
  ["12", "화난 항의", "12_angry_hand_on_hip.png"],
].map(([id, label, file]) =>
  pose(
    id,
    label,
    `assets/images/photorealistic/students/choi_iseo/${file}`,
  ),
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
    speaker: "이서",
    group: "미래양성원",
    poses: iseoPoses,
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
