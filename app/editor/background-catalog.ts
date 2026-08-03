export type DialogueBackground = {
  id: string;
  label: string;
  group: "프롤로그" | "데시멀 센터" | "생활·투자";
  asset: string;
};

const webAsset = (asset: string) => `/play/assets/${asset}`;

function background(
  id: string,
  label: string,
  group: DialogueBackground["group"],
  asset: string,
): DialogueBackground {
  return { id, label, group, asset: webAsset(asset) };
}

export const dialogueBackgrounds: DialogueBackground[] = [
  background(
    "nis-economic-security-room",
    "1999년 국정원 · 경제안보상황실",
    "프롤로그",
    "assets/images/cinematic_soft_painted/decimal_nis_1999/backgrounds/bg_nis_economic_security_room_night_1999_v1.png",
  ),
  background(
    "nis-decimal-archive",
    "1999년 국정원 · 데시멀 봉인기록실",
    "프롤로그",
    "assets/images/cinematic_soft_painted/decimal_nis_1999/backgrounds/bg_nis_decimal_archive_predawn_1999_v1.png",
  ),
  background(
    "decimal-imf-failure",
    "1997년 IMF · 유리상자의 실패",
    "프롤로그",
    "assets/images/cinematic_soft_painted/decimal/bg_decimal_imf_failure_1997_v1.png",
  ),
  background(
    "decimal-matrix-exam",
    "1999년 · 숨겨진 행렬 시험",
    "프롤로그",
    "assets/images/cinematic_soft_painted/decimal/bg_decimal_matrix_exam_1999_v1.png",
  ),
  background(
    "decimal-unfair-game",
    "1999년 · 불공정 배분 게임",
    "프롤로그",
    "assets/images/cinematic_soft_painted/decimal/bg_decimal_unfair_game_1999_v1.png",
  ),
  background(
    "decimal-desire-test",
    "1999년 · 결핍과 욕망 검증",
    "프롤로그",
    "assets/images/cinematic_soft_painted/decimal/bg_decimal_desire_test_1999_v1.png",
  ),
  background(
    "bus-transition",
    "서울행 승합차 · 겨울",
    "프롤로그",
    "assets/images/cinematic_soft_painted/decimal/bg_decimal_gangnam_exterior_winter_1999_v1.png",
  ),
  background(
    "decimal-gangnam-exterior",
    "1999년 마지막 밤 · 강남 아지트",
    "데시멀 센터",
    "assets/images/cinematic_soft_painted/decimal/bg_decimal_gangnam_exterior_winter_1999_v1.png",
  ),
  background(
    "decimal-secure-entry",
    "데시멀 센터 · 보안 입구",
    "데시멀 센터",
    "assets/images/cinematic_soft_painted/decimal/bg_decimal_secure_entry_1999_v1.png",
  ),
  background(
    "decimal-living-lounge",
    "데시멀 센터 · 생활 라운지",
    "데시멀 센터",
    "assets/images/cinematic_soft_painted/decimal/bg_decimal_living_lounge_1999_v1.png",
  ),
  background(
    "decimal-sleeping-wing",
    "데시멀 센터 · 수면동",
    "데시멀 센터",
    "assets/images/cinematic_soft_painted/decimal/bg_decimal_sleeping_wing_1999_v1.png",
  ),
  background(
    "decimal-trading-floor",
    "데시멀 센터 · 트레이딩 플로어",
    "데시멀 센터",
    "assets/images/cinematic_soft_painted/decimal/bg_decimal_trading_floor_dawn_2000_v1.png",
  ),
  background(
    "decimal-electronics-workshop",
    "데시멀 센터 · 기기 정비실",
    "데시멀 센터",
    "assets/images/cinematic_soft_painted/decimal/bg_decimal_electronics_workshop_2000_v1.png",
  ),
  background(
    "decimal-records-archive",
    "데시멀 센터 · 기록 보관실",
    "데시멀 센터",
    "assets/images/cinematic_soft_painted/decimal/bg_decimal_records_archive_2000_v1.png",
  ),
  background(
    "bank-branch",
    "2000년 동네 은행",
    "생활·투자",
    "assets/images/bg_bank_branch_2000_portrait_cartoon_v2.png",
  ),
  background(
    "stationery-shop",
    "동네 문구점",
    "생활·투자",
    "assets/images/bg_stationery_shop_2000.webp",
  ),
];

export const dialogueBackgroundByAsset = new Map(
  dialogueBackgrounds.map((entry) => [entry.asset, entry]),
);
