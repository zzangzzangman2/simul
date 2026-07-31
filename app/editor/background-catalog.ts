export type DialogueBackground = {
  id: string;
  label: string;
  group: "프롤로그" | "미래양성원" | "생활·투자";
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
    "policy-room",
    "청와대 정책실 · 밝은 실사 밤",
    "프롤로그",
    "assets/images/photorealistic/prologue_1981_2000/bg_policy_room_night_photoreal_v1.png",
  ),
  background(
    "conference-night",
    "미래전략 심야회의 · 밝은 실사",
    "프롤로그",
    "assets/images/photorealistic/prologue_1981_2000/bg_conference_night_photoreal_v1.png",
  ),
  background(
    "academy-opening",
    "미래양성원 개원 기록",
    "프롤로그",
    "assets/images/photorealistic/prologue_1981_2000/bg_academy_opening_1982_photoreal_v1.png",
  ),
  background(
    "orphanage-departure",
    "새봄보육원 · 출발방",
    "프롤로그",
    "assets/images/photorealistic/prologue_1981_2000/bg_orphanage_departure_2000_photoreal_v1.png",
  ),
  background(
    "academy-gate",
    "미래양성원 · 정문",
    "프롤로그",
    "assets/images/photorealistic/prologue_1981_2000/bg_academy_gate_2000_photoreal_v1.png",
  ),
  background(
    "orientation-hall",
    "제6기 오리엔테이션 강당",
    "프롤로그",
    "assets/images/photorealistic/prologue_1981_2000/bg_orientation_hall_2000_photoreal_v1.png",
  ),
  background(
    "records-room",
    "미래양성원 · 제3기록실",
    "미래양성원",
    "assets/images/historical_prologue/bg_orphanage_records_room_1999_portrait_cartoon_v1.png",
  ),
  background(
    "academy-dormitory",
    "미래양성원 · 구형 기숙사",
    "미래양성원",
    "assets/images/historical_prologue/bg_orphanage_dormitory_1999_portrait_cartoon_v1.png",
  ),
  background(
    "academy-dorm-corridor-2000",
    "제6기 기숙사 · 중앙 복도",
    "미래양성원",
    "assets/images/photorealistic/prologue_1981_2000/bg_dorm_corridor_2000_photoreal_v1.png",
  ),
  background(
    "academy-dorm-shared-day-2000",
    "제6기 공용 생활실 · 낮",
    "미래양성원",
    "assets/images/photorealistic/prologue_1981_2000/bg_dorm_shared_room_day_2000_photoreal_v1.png",
  ),
  background(
    "academy-dorm-washroom-2000",
    "제6기 기숙사 · 세면실",
    "미래양성원",
    "assets/images/photorealistic/prologue_1981_2000/bg_dorm_washroom_2000_photoreal_v1.png",
  ),
  background(
    "academy-dorm-shared-night-2000",
    "제6기 공용 생활실 · 첫날 밤",
    "미래양성원",
    "assets/images/photorealistic/prologue_1981_2000/bg_dorm_shared_room_night_2000_photoreal_v1.png",
  ),
  background(
    "account-hall",
    "국가계좌 개통 창구",
    "미래양성원",
    "assets/images/historical_prologue/bg_orphanage_account_hall_2000_portrait_cartoon_v1.png",
  ),
  background(
    "electronics-storage",
    "미래양성원 · 전자창고",
    "미래양성원",
    "assets/images/historical_prologue/bg_orphanage_electronics_storage_2000_portrait_cartoon_v1.png",
  ),
  background(
    "investment-room",
    "미래양성원 · 투자실",
    "미래양성원",
    "assets/images/historical_prologue/bg_orphanage_investment_room_2000_portrait_cartoon_v1.png",
  ),
  background(
    "stock-classroom",
    "주식 PC 실습실 · 밝은 실사",
    "생활·투자",
    "assets/images/photorealistic/prologue_1981_2000/bg_stock_pc_classroom_2000_photoreal_v1.png",
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
  background(
    "boy-room",
    "소년의 방 · 1999",
    "생활·투자",
    "assets/images/bg_boy_room_1999.png",
  ),
  background(
    "living-room",
    "가족 거실 · 1999",
    "생활·투자",
    "assets/images/bg_living_room_1999_portrait_cartoon_v2.png",
  ),
];

export const dialogueBackgroundByAsset = new Map(
  dialogueBackgrounds.map((entry) => [entry.asset, entry]),
);
