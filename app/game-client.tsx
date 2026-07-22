"use client";

import { type FormEvent, useEffect, useState } from "react";
import marketHistory from "./data/market-history.json";

type Market = "DOMESTIC" | "KOSPI" | "KOSDAQ" | "OVERSEAS";
type Exchange = "KOSPI" | "KOSDAQ" | "NASDAQ" | "TSE";
type Tab = "office" | "market" | "portfolio" | "deals";
type OrderMode = "buy" | "sell";

type Asset = {
  id: string;
  symbol: string;
  name: string;
  market: Exchange;
  country: "KR" | "US" | "JP";
  sector: string;
  color: string;
  currency: string;
  baselineDate: string;
  prices: Record<string, number>;
};

type Position = { units: number; cost: number };
type Acquisition = { dealId: string; acquiredDate: string; purchasePrice: number };
type AumPoint = { date: string; value: number };

type GameState = {
  version: 3;
  companyName: string;
  currentDate: string;
  cash: number;
  positions: Record<string, Position>;
  reputation: number;
  team: number;
  acquisitions: Acquisition[];
  aumHistory: AumPoint[];
  fundRaised: boolean;
  performanceMonth: string;
  performanceStartAum: number;
  seenEventIds: string[];
};

type LegacyAcquisition = { dealId: string; acquiredIndex: number; purchasePrice: number };
type LegacyAumPoint = { month: string; value: number };
type LegacyGameStateV2 = {
  version: 2;
  companyName: string;
  monthIndex: number;
  cash: number;
  positions: Record<string, Position>;
  reputation: number;
  team: number;
  acquisitions: LegacyAcquisition[];
  aumHistory: LegacyAumPoint[];
  fundRaised: boolean;
};
type LegacyGameStateV1 = Omit<LegacyGameStateV2, "version" | "companyName"> & { version: 1 };
type StoredGameState = GameState | LegacyGameStateV2 | LegacyGameStateV1;

type TimelineEvent = {
  id: string;
  date: string;
  eyebrow: string;
  title: string;
  body: string;
  signal: string;
};

type Deal = {
  id: string;
  availableFrom: string;
  title: string;
  category: string;
  price: number;
  reputation: number;
  monthlyIncome: number;
  thesis: string;
  history: string;
};

const assets = marketHistory.assets as unknown as Asset[];
const START_DATE = marketHistory.period.start;
const END_DATE = marketHistory.period.end;
const INITIAL_CAPITAL = 0;
const INITIAL_TEAM = 1;
const MIN_ORDER = 10_000;
const HIRING_COST = 350_000;
const FUND_RAISE_AMOUNT = 5_000_000;
const HOME_OFFICE_MONTHLY_COST = 30_000;
const EMPLOYEE_MONTHLY_COST = 250_000;
const DAY_MS = 86_400_000;

const timeline: TimelineEvent[] = [
  {
    id: "dotcom-peak",
    date: "2000-03-10",
    eyebrow: "닷컴 사이클",
    title: "기술주 열기가 정점에 닿았다",
    body: "나스닥이 기록적인 고점권에 진입했습니다. 성장 서사는 강하지만 현금흐름이 약한 기업의 가격 변동성이 커집니다.",
    signal: "가격 데이터에 당시 급등락이 이미 반영되어 있습니다.",
  },
  {
    id: "ps2",
    date: "2000-10-26",
    eyebrow: "콘솔 전쟁",
    title: "PlayStation 2가 북미에 상륙했다",
    body: "게임과 DVD를 한 기기에 묶은 소니의 전략이 거실 플랫폼 경쟁을 바꿉니다. 콘텐츠와 하드웨어의 결합이 주요 투자 테마가 됩니다.",
    signal: "소니와 일본 기술주의 흐름을 확인하세요.",
  },
  {
    id: "september-11",
    date: "2001-09-11",
    eyebrow: "시장 충격",
    title: "미국 시장이 전례 없는 충격을 맞았다",
    body: "9·11 테러 뒤 미국 증권시장이 며칠간 문을 닫았습니다. 유동성, 통신, 안전자산 선호가 투자위원회의 최우선 의제가 됩니다.",
    signal: "현금을 확보할지, 공포 속 가격을 매수할지 결정하세요.",
  },
  {
    id: "ipod",
    date: "2001-10-23",
    eyebrow: "제품 출시",
    title: "Apple이 iPod을 공개했다",
    body: "개인용 컴퓨터 회사가 음악 생태계로 확장합니다. 아직 작은 신호지만 하드웨어·소프트웨어·콘텐츠를 묶는 전략이 시작됐습니다.",
    signal: "장기 복리와 단기 생존 사이의 균형이 중요합니다.",
  },
  {
    id: "google-ipo",
    date: "2004-08-19",
    eyebrow: "IPO",
    title: "검색 광고 기업 Google이 상장했다",
    body: "인터넷 산업의 수익모델이 배너에서 검색 의도 기반 광고로 이동합니다. 닷컴 붕괴 뒤 살아남은 플랫폼의 질이 다시 평가받습니다.",
    signal: "인터넷·소프트웨어 포트폴리오를 재점검할 시점입니다.",
  },
  {
    id: "iphone",
    date: "2007-06-29",
    eyebrow: "플랫폼 전환",
    title: "첫 iPhone 판매가 시작됐다",
    body: "휴대전화와 인터넷, 미디어 플레이어가 하나로 합쳐집니다. 통신사·반도체·소프트웨어의 가치사슬이 재편되기 시작합니다.",
    signal: "Apple, 삼성전자, SK텔레콤의 다른 노출을 비교하세요.",
  },
  {
    id: "lehman",
    date: "2008-09-15",
    eyebrow: "금융위기",
    title: "Lehman Brothers가 파산보호를 신청했다",
    body: "신용시장이 얼어붙고 세계 주식시장이 급락합니다. 레버리지가 낮고 현금이 많은 투자회사만 다음 기회를 잡을 수 있습니다.",
    signal: "현금 버퍼와 인수 여력을 동시에 지켜야 합니다.",
  },
  {
    id: "recovery",
    date: "2009-03-09",
    eyebrow: "사이클 전환",
    title: "공포 속에서 회복의 실마리가 보인다",
    body: "각국의 정책 대응과 밸류에이션 하락이 맞물리며 위험자산이 바닥을 다지기 시작합니다. 위기 때 만든 포지션의 결과가 갈립니다.",
    signal: "남은 현금을 어디에 배분할지 결정하세요.",
  },
];

const deals: Deal[] = [
  {
    id: "portal-game",
    availableFrom: "2000-07-01",
    title: "포털 × 게임 합병 참여",
    category: "전략적 지분",
    price: 700_000,
    reputation: 14,
    monthlyIncome: 60_000,
    thesis: "검색 트래픽과 게임 결제 이용자를 결합해 체류시간과 현금흐름을 동시에 확보합니다.",
    history: "2000년 네이버컴과 한게임의 합병에서 착안한 게임화된 딜입니다.",
  },
  {
    id: "auction-commerce",
    availableFrom: "2001-02-01",
    title: "온라인 경매 플랫폼 인수",
    category: "바이아웃",
    price: 2_000_000,
    reputation: 20,
    monthlyIncome: 160_000,
    thesis: "판매자 네트워크를 선점하고 거래 수수료 기반의 반복 매출을 만듭니다.",
    history: "2001년 eBay의 옥션 투자·인수 흐름에서 착안한 가상 소형 딜입니다.",
  },
  {
    id: "social-community",
    availableFrom: "2003-08-01",
    title: "미니홈피 커뮤니티 인수",
    category: "볼트온 인수",
    price: 6_000_000,
    reputation: 30,
    monthlyIncome: 450_000,
    thesis: "통신 가입자 기반에 디지털 아이템과 소셜 그래프를 더합니다.",
    history: "2003년 SK커뮤니케이션즈의 싸이월드 인수에서 착안했습니다.",
  },
  {
    id: "video-platform",
    availableFrom: "2006-10-01",
    title: "UGC 비디오 플랫폼 공동인수",
    category: "컨소시엄",
    price: 18_000_000,
    reputation: 45,
    monthlyIncome: 1_500_000,
    thesis: "검색 광고 다음 성장축으로 동영상 소비와 창작자 네트워크를 선점합니다.",
    history: "2006년 Google의 YouTube 인수에서 착안한 축소형 공동투자 시나리오입니다.",
  },
];

const countryFlag: Record<Asset["country"], string> = { KR: "KR", US: "US", JP: "JP" };
const storageKey = "simul-millennium-capital-v1";
const tradingFee = 0.0025;

const quoteDatesByAsset = Object.fromEntries(
  assets.map((asset) => [asset.id, Object.keys(asset.prices).sort()]),
) as Record<string, string[]>;

function dateToTime(date: string) {
  const [year, month, day] = date.split("-").map(Number);
  return Date.UTC(year, month - 1, day);
}

function timeToDate(time: number) {
  return new Date(time).toISOString().slice(0, 10);
}

function addDays(date: string, amount: number) {
  return timeToDate(dateToTime(date) + amount * DAY_MS);
}

function daysBetween(from: string, to: string) {
  return Math.round((dateToTime(to) - dateToTime(from)) / DAY_MS);
}

function monthKey(date: string) {
  return date.slice(0, 7);
}

function endOfMonth(month: string) {
  const [year, value] = month.split("-").map(Number);
  return timeToDate(Date.UTC(year, value, 0));
}

function legacyMonthAtIndex(index: number) {
  const date = new Date(Date.UTC(2000, Math.max(0, Math.min(index, 131)), 1));
  return `${date.getUTCFullYear()}-${String(date.getUTCMonth() + 1).padStart(2, "0")}`;
}

function daysInMonth(date: string) {
  return Number(endOfMonth(monthKey(date)).slice(8, 10));
}

function amountForDay(monthlyAmount: number, date: string) {
  const day = Number(date.slice(8, 10));
  const count = daysInMonth(date);
  return Math.floor((monthlyAmount * day) / count) - Math.floor((monthlyAmount * (day - 1)) / count);
}

function monthlyOperatingCost(team: number) {
  return HOME_OFFICE_MONTHLY_COST + Math.max(0, team - 1) * EMPLOYEE_MONTHLY_COST;
}

function initialState(companyName = ""): GameState {
  return {
    version: 3,
    companyName,
    currentDate: START_DATE,
    cash: INITIAL_CAPITAL,
    positions: {},
    reputation: 12,
    team: INITIAL_TEAM,
    acquisitions: [],
    aumHistory: [{ date: START_DATE, value: INITIAL_CAPITAL }],
    fundRaised: false,
    performanceMonth: monthKey(START_DATE),
    performanceStartAum: INITIAL_CAPITAL,
    seenEventIds: [],
  };
}

function isPristineLegacy(state: LegacyGameStateV1 | LegacyGameStateV2) {
  return (
    state.monthIndex === 0 &&
    state.cash === 5_000_000_000 &&
    state.team === 3 &&
    Object.keys(state.positions).length === 0 &&
    state.acquisitions.length === 0 &&
    !state.fundRaised &&
    state.aumHistory.length <= 1
  );
}

function migrateLegacyState(state: LegacyGameStateV1 | LegacyGameStateV2): GameState {
  const companyName = state.version === 2 ? state.companyName : "";
  if (isPristineLegacy(state)) return initialState(companyName);

  const currentMonth = legacyMonthAtIndex(state.monthIndex);
  const currentDate = endOfMonth(currentMonth);
  const migrated: GameState = {
    version: 3,
    companyName,
    currentDate,
    cash: state.cash,
    positions: state.positions,
    reputation: state.reputation,
    team: state.team,
    acquisitions: state.acquisitions.map((item) => ({
      dealId: item.dealId,
      acquiredDate: endOfMonth(legacyMonthAtIndex(item.acquiredIndex)),
      purchasePrice: item.purchasePrice,
    })),
    aumHistory: state.aumHistory.map((point) => ({
      date: endOfMonth(point.month),
      value: point.value,
    })),
    fundRaised: state.fundRaised,
    performanceMonth: monthKey(currentDate),
    performanceStartAum: state.aumHistory.at(-1)?.value ?? state.cash,
    seenEventIds: timeline.filter((event) => event.date <= currentDate).map((event) => event.id),
  };
  migrated.performanceStartAum = totalAum(migrated, currentDate);
  return migrated;
}

function priceAtDate(asset: Asset, date: string) {
  const dates = quoteDatesByAsset[asset.id];
  let low = 0;
  let high = dates.length - 1;
  let result = -1;
  while (low <= high) {
    const middle = Math.floor((low + high) / 2);
    if (dates[middle] <= date) {
      result = middle;
      low = middle + 1;
    } else {
      high = middle - 1;
    }
  }
  return result >= 0 ? asset.prices[dates[result]] : null;
}

function hasQuoteOnDate(asset: Asset, date: string) {
  return Object.prototype.hasOwnProperty.call(asset.prices, date);
}

function portfolioValue(positions: Record<string, Position>, date: string) {
  return assets.reduce((total, asset) => {
    const position = positions[asset.id];
    return total + (position?.units ?? 0) * (priceAtDate(asset, date) ?? 0);
  }, 0);
}

function acquiredValue(acquisitions: Acquisition[], date: string) {
  return acquisitions.reduce((total, acquisition) => {
    const heldDays = Math.max(0, daysBetween(acquisition.acquiredDate, date));
    return total + acquisition.purchasePrice * Math.pow(1.02, heldDays / 365.2425);
  }, 0);
}

function totalAum(state: GameState, date = state.currentDate) {
  return (
    state.cash +
    portfolioValue(state.positions, date) +
    acquiredValue(state.acquisitions, date)
  );
}

function syncSnapshot(state: GameState) {
  const value = totalAum(state);
  const history = [...state.aumHistory];
  const last = history[history.length - 1];
  if (last?.date === state.currentDate) {
    history[history.length - 1] = { date: state.currentDate, value };
  } else {
    history.push({ date: state.currentDate, value });
  }
  return { ...state, aumHistory: history };
}

function formatWon(value: number, compact = true) {
  if (compact && Math.abs(value) >= 100_000_000) {
    return `${(value / 100_000_000).toLocaleString("ko-KR", { maximumFractionDigits: 1 })}억`;
  }
  return `${Math.round(value).toLocaleString("ko-KR")}원`;
}

function formatPercent(value: number) {
  const safe = Number.isFinite(value) ? value : 0;
  return `${safe > 0 ? "+" : ""}${safe.toFixed(1)}%`;
}

function dateLabel(date: string) {
  return date.replaceAll("-", ".");
}

function chartPoints(values: number[], width = 260, height = 72) {
  if (values.length < 2) return `0,${height / 2} ${width},${height / 2}`;
  const min = Math.min(...values);
  const max = Math.max(...values);
  const spread = max - min || 1;
  return values
    .map((value, index) => {
      const x = (index / (values.length - 1)) * width;
      const y = height - ((value - min) / spread) * (height - 8) - 4;
      return `${x.toFixed(1)},${y.toFixed(1)}`;
    })
    .join(" ");
}

function Sparkline({ values, color }: { values: number[]; color: string }) {
  return (
    <svg className="sparkline" viewBox="0 0 260 72" role="img" aria-label="최근 가격 흐름">
      <polyline points={chartPoints(values)} fill="none" stroke={color} strokeWidth="3" vectorEffect="non-scaling-stroke" />
    </svg>
  );
}

export function GameClient() {
  const [game, setGame] = useState<GameState>(initialState);
  const [hydrated, setHydrated] = useState(false);
  const [companyDraft, setCompanyDraft] = useState("");
  const [tab, setTab] = useState<Tab>("office");
  const [marketFilter, setMarketFilter] = useState<Market>("DOMESTIC");
  const [selectedId, setSelectedId] = useState("apple");
  const [orderMode, setOrderMode] = useState<OrderMode>("buy");
  const [orderPercent, setOrderPercent] = useState(25);
  const [orderSheetOpen, setOrderSheetOpen] = useState(false);
  const [activeEvent, setActiveEvent] = useState<TimelineEvent | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  useEffect(() => {
    const restoreTimeout = window.setTimeout(() => {
      try {
        const saved = window.localStorage.getItem(storageKey);
        if (saved) {
          const parsed = JSON.parse(saved) as StoredGameState;
          if (parsed.version === 3 && parsed.currentDate >= START_DATE && parsed.currentDate <= END_DATE) {
            setGame(parsed);
            setCompanyDraft(parsed.companyName);
          } else if (parsed.version === 2 || parsed.version === 1) {
            const migrated = migrateLegacyState(parsed);
            setGame(migrated);
            setCompanyDraft(migrated.companyName);
          }
        }
      } catch {
        window.localStorage.removeItem(storageKey);
      } finally {
        setHydrated(true);
      }
    }, 0);

    return () => window.clearTimeout(restoreTimeout);
  }, []);

  useEffect(() => {
    if (hydrated) window.localStorage.setItem(storageKey, JSON.stringify(game));
  }, [game, hydrated]);

  useEffect(() => {
    if (!toast) return;
    const timeout = window.setTimeout(() => setToast(null), 2600);
    return () => window.clearTimeout(timeout);
  }, [toast]);

  useEffect(() => {
    if (!orderSheetOpen) return;
    function closeOnEscape(event: KeyboardEvent) {
      if (event.key === "Escape") setOrderSheetOpen(false);
    }
    window.addEventListener("keydown", closeOnEscape);
    return () => window.removeEventListener("keydown", closeOnEscape);
  }, [orderSheetOpen]);

  const selectedAsset = assets.find((asset) => asset.id === selectedId) ?? assets[0];
  const currentDate = game.currentDate;
  const currentAum = totalAum(game);
  const invested = portfolioValue(game.positions, currentDate);
  const ownedCompanies = acquiredValue(game.acquisitions, currentDate);
  const selectedPrice = priceAtDate(selectedAsset, currentDate);
  const previousPrice = priceAtDate(selectedAsset, addDays(currentDate, -1)) ?? selectedPrice;
  const selectedReturn = selectedPrice && previousPrice ? ((selectedPrice - previousPrice) / previousPrice) * 100 : 0;
  const selectedPosition = game.positions[selectedAsset.id];
  const selectedPositionValue = (selectedPosition?.units ?? 0) * (selectedPrice ?? 0);
  const selectedSeries = Array.from(
    { length: 30 },
    (_, index) => priceAtDate(selectedAsset, addDays(currentDate, index - 29)),
  ).filter((value): value is number => value !== null);
  const visibleAssets = marketFilter === "DOMESTIC"
    ? assets.filter((asset) => asset.country === "KR")
    : marketFilter === "OVERSEAS"
      ? assets.filter((asset) => asset.country !== "KR")
      : assets.filter((asset) => asset.market === marketFilter);
  const campaignComplete = currentDate >= END_DATE;
  const dayNumber = daysBetween(START_DATE, currentDate) + 1;
  const anyMarketOpenToday = assets.some((asset) => hasQuoteOnDate(asset, currentDate));

  function placeOrder() {
    setGame((current) => {
      const price = priceAtDate(selectedAsset, current.currentDate);
      const position = current.positions[selectedAsset.id] ?? { units: 0, cost: 0 };

      if (!price) {
        setToast(`${selectedAsset.name}의 이전 거래 기록이 아직 없습니다.`);
        return current;
      }
      if (!hasQuoteOnDate(selectedAsset, current.currentDate)) {
        setToast("오늘은 해당 시장의 휴장일입니다. 다음 거래일까지 기다려주세요.");
        return current;
      }

      if (orderMode === "buy") {
        const cashSpend = current.cash * (orderPercent / 100);
        if (cashSpend < MIN_ORDER) {
          setToast(`최소 주문금액은 ${formatWon(MIN_ORDER)}입니다.`);
          return current;
        }
        const investment = cashSpend / (1 + tradingFee);
        const next = {
          ...current,
          cash: current.cash - cashSpend,
          positions: {
            ...current.positions,
            [selectedAsset.id]: {
              units: position.units + investment / price,
              cost: position.cost + cashSpend,
            },
          },
        };
        setToast(`${selectedAsset.name}에 ${formatWon(investment)} 투자했습니다.`);
        return syncSnapshot(next);
      }

      if (!position.units) {
        setToast("매도할 보유분이 없습니다.");
        return current;
      }
      const fraction = orderPercent / 100;
      const unitsSold = position.units * fraction;
      const proceeds = unitsSold * price * (1 - tradingFee);
      const remainingUnits = position.units - unitsSold;
      const positions = { ...current.positions };
      if (remainingUnits < 0.000001) delete positions[selectedAsset.id];
      else {
        positions[selectedAsset.id] = {
          units: remainingUnits,
          cost: position.cost * (1 - fraction),
        };
      }
      setToast(`${selectedAsset.name} ${orderPercent}%를 매도했습니다.`);
      return syncSnapshot({ ...current, cash: current.cash + proceeds, positions });
    });
  }

  function advanceDay() {
    if (campaignComplete) {
      setToast("2010년 12월 31일까지 플레이를 완료했습니다.");
      return;
    }
    setGame((current) => {
      const nextDate = addDays(current.currentDate, 1);
      const operatingCost = amountForDay(monthlyOperatingCost(current.team), nextDate);
      const monthlyDealIncome = current.acquisitions.reduce((sum, acquisition) => {
        return sum + (deals.find((deal) => deal.id === acquisition.dealId)?.monthlyIncome ?? 0);
      }, 0);
      const income = amountForDay(monthlyDealIncome, nextDate);
      if (current.cash + income < operatingCost) {
        setToast(`내일 운영비 ${formatWon(operatingCost)}이 부족합니다. 주식을 매도해 현금을 확보하세요.`);
        return current;
      }
      const currentValue = totalAum(current);
      const nextCash = current.cash - operatingCost + income;
      const nextValue =
        nextCash + portfolioValue(current.positions, nextDate) + acquiredValue(current.acquisitions, nextDate);
      const dailyResult = ((nextValue - currentValue) / currentValue) * 100;
      const changedMonth = monthKey(nextDate) !== current.performanceMonth;
      const monthlyResult = ((currentValue - current.performanceStartAum) / current.performanceStartAum) * 100;
      const nextEvent = timeline.find(
        (event) => event.date === nextDate && !current.seenEventIds.includes(event.id),
      ) ?? null;
      const next = {
        ...current,
        currentDate: nextDate,
        cash: nextCash,
        reputation: changedMonth
          ? Math.max(0, current.reputation + (monthlyResult > 3 ? 1 : monthlyResult < -10 ? -2 : 0))
          : current.reputation,
        aumHistory: [...current.aumHistory, { date: nextDate, value: nextValue }],
        performanceMonth: changedMonth ? monthKey(nextDate) : current.performanceMonth,
        performanceStartAum: changedMonth ? nextValue : current.performanceStartAum,
        seenEventIds: nextEvent ? [...current.seenEventIds, nextEvent.id] : current.seenEventIds,
      };
      if (nextEvent) setActiveEvent(nextEvent);
      setToast(`${dateLabel(nextDate)} · 하루 결과 ${formatPercent(dailyResult)}`);
      return next;
    });
  }

  function acquire(deal: Deal) {
    if (deal.availableFrom > currentDate) {
      setToast(`${dateLabel(deal.availableFrom)}부터 검토할 수 있습니다.`);
      return;
    }
    if (game.acquisitions.some((item) => item.dealId === deal.id)) {
      setToast("이미 완료한 거래입니다.");
      return;
    }
    if (game.reputation < deal.reputation) {
      setToast(`평판 ${deal.reputation}이 필요합니다.`);
      return;
    }
    if (game.cash < deal.price) {
      setToast(`${formatWon(deal.price - game.cash)}의 현금이 더 필요합니다.`);
      return;
    }
    setGame((current) =>
      syncSnapshot({
        ...current,
        cash: current.cash - deal.price,
        reputation: current.reputation + 4,
        acquisitions: [
          ...current.acquisitions,
          { dealId: deal.id, acquiredDate: current.currentDate, purchasePrice: deal.price },
        ],
      }),
    );
    setToast(`${deal.title} 거래를 완료했습니다.`);
  }

  function hire() {
    if (game.cash < HIRING_COST) {
      setToast(`채용에 필요한 ${formatWon(HIRING_COST)}이 부족합니다.`);
      return;
    }
    setGame((current) =>
      syncSnapshot({
        ...current,
        cash: current.cash - HIRING_COST,
        team: current.team + 1,
        reputation: current.reputation + 1,
      }),
    );
    setToast("새 투자심사역이 합류했습니다.");
  }

  function raiseFund() {
    if (game.fundRaised) {
      setToast("2호 펀드는 이미 결성했습니다.");
      return;
    }
    if (game.reputation < 20) {
      setToast("2호 펀드 결성에는 평판 20이 필요합니다.");
      return;
    }
    setGame((current) =>
      syncSnapshot({
        ...current,
        cash: current.cash + FUND_RAISE_AMOUNT,
        reputation: current.reputation + 2,
        fundRaised: true,
      }),
    );
    setToast(`외부 출자금 ${formatWon(FUND_RAISE_AMOUNT)}을 유치했습니다.`);
  }

  function resetGame() {
    if (!window.confirm(`${game.companyName}의 기록을 지우고 2000년 1월 1일로 돌아갈까요?`)) return;
    window.localStorage.removeItem(storageKey);
    setGame(initialState());
    setCompanyDraft("");
    setTab("office");
    setSelectedId("apple");
    setOrderSheetOpen(false);
    setToast("새 회사를 시작했습니다.");
  }

  function createCompany(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const companyName = companyDraft.trim().replace(/\s+/g, " ");
    if (!companyName) return;
    setGame((current) => {
      const next = { ...current, companyName };
      window.localStorage.setItem(storageKey, JSON.stringify(next));
      return next;
    });
    setTab("office");
    setToast(`${companyName}의 첫 출근입니다. 컴퓨터를 눌러 시장을 확인하세요.`);
    window.requestAnimationFrame(() => window.scrollTo({ top: 0 }));
  }

  function navigateTab(nextTab: Tab) {
    setTab(nextTab);
    setOrderSheetOpen(false);
    window.requestAnimationFrame(() => window.scrollTo({ top: 0, behavior: "smooth" }));
  }

  function openOrderSheet(assetId: string) {
    setSelectedId(assetId);
    setOrderSheetOpen(true);
  }

  if (!game.companyName) {
    return (
      <main className="onboarding-shell">
        <header className="onboarding-topbar">
          <div className="brand-lockup">
            <span className="brand-mark" aria-hidden="true">M/00</span>
            <span className="brand-copy"><b>부자되기 시뮬레이션</b><small>SEOUL · 2000</small></span>
          </div>
          <span>PORTRAIT EDITION · 2000.01.01</span>
        </header>

        <section className="onboarding-stage">
          <div className="onboarding-copy">
            <span className="status-pill"><i /> REAL HISTORY MODE</span>
            <p className="onboarding-index">00 / INCORPORATION</p>
            <h1>당신의 투자회사에<br /><em>이름을 붙이세요.</em></h1>
            <p>2000년 1월 1일, 작은 원룸 사무실과 0원의 빈 장부가 전부입니다. 혼자 시작해 하루씩 회사를 키워보세요.</p>

            <dl className="founding-chips" aria-label="초기 회사 조건">
              <div><dt>시작일</dt><dd>2000.01.01</dd></div>
              <div><dt>초기 자본</dt><dd>0원</dd></div>
              <div><dt>창립 팀</dt><dd>1명</dd></div>
              <div><dt>시장</dt><dd>한국 · 미국 · 일본</dd></div>
            </dl>

            <form className="company-form" onSubmit={createCompany}>
              <label htmlFor="company-name">회사 이름</label>
              <div className="company-input-wrap">
                <input
                  id="company-name"
                  data-testid="company-name-input"
                  value={companyDraft}
                  onChange={(event) => setCompanyDraft(event.target.value.slice(0, 24))}
                  maxLength={24}
                  placeholder="예: 새벽투자파트너스"
                  autoComplete="organization"
                  enterKeyHint="done"
                  aria-describedby="company-name-help"
                />
                <span>{companyDraft.length}/24</span>
              </div>
              <small id="company-name-help">이 이름은 상단 간판과 자동 저장 데이터에 사용됩니다.</small>
              <button type="submit" data-testid="create-company" disabled={!companyDraft.trim()}>
                회사 설립하기 <i>→</i>
              </button>
            </form>
          </div>

        </section>
      </main>
    );
  }

  return (
    <main className={`game-shell view-${tab}`}>
      <header className="topbar">
        {tab === "office" ? (
          <div className="brand-lockup">
            <span className="brand-mark" aria-hidden="true">M/00</span>
            <span className="brand-copy"><b>{game.companyName}</b><small>MY FIRST OFFICE</small></span>
          </div>
        ) : (
          <button type="button" className="room-back" onClick={() => navigateTab("office")}>
            <i aria-hidden="true">←</i><span><b>내 방으로</b><small>COMPUTER TERMINAL</small></span>
          </button>
        )}
        <div className="date-block">
          <span>DAY {dayNumber}</span>
          <strong data-testid="game-date">{dateLabel(currentDate)}</strong>
        </div>
      </header>

      <div className="game-viewport">
        {tab === "office" ? (
          <section className="office-screen" data-testid="office-screen" aria-label="나의 첫 사무실">
            <div className="office-scene">
              <div className="office-hud">
                <span className="day-badge">DAY {dayNumber} · 1인 회사</span>
                <div className="office-resources">
                  <span><small>보유 현금</small><b data-testid="office-cash">{formatWon(game.cash)}</b></span>
                  <span><small>총자산</small><b>{formatWon(currentAum)}</b></span>
                  <span><small>평판</small><b>{game.reputation}</b></span>
                </div>
              </div>

              <div className="room-mission">
                <span>첫 번째 목표</span>
                <strong>컴퓨터를 켜서<br />시장을 확인하세요.</strong>
                <small>{anyMarketOpenToday ? "오늘 거래 가능한 시장이 있습니다." : "오늘은 신정 휴장입니다. 내일로 진행해보세요."}</small>
              </div>

              <button type="button" className="room-hotspot computer-hotspot" onClick={() => navigateTab("market")} data-testid="room-computer" aria-label="CRT 컴퓨터 — 주식시장 열기">
                <span className="hotspot-pulse" aria-hidden="true" />
                <span className="hotspot-label"><b>컴퓨터</b><small>주식시장 열기</small></span>
              </button>
              <button type="button" className="room-hotspot phone-hotspot" onClick={() => navigateTab("deals")} aria-label="유선전화 — 인수 제안 확인">
                <span className="hotspot-pulse" aria-hidden="true" />
                <span className="hotspot-label"><b>전화</b><small>인수 제안</small></span>
              </button>
              <button type="button" className="room-hotspot files-hotspot" onClick={() => navigateTab("portfolio")} aria-label="서류함 — 포트폴리오 확인">
                <span className="hotspot-pulse" aria-hidden="true" />
                <span className="hotspot-label"><b>서류함</b><small>내 자산</small></span>
              </button>

              <div className="office-actions" aria-label="회사 관리">
                <button type="button" onClick={hire}><span>인재 찾기</span><small>{formatWon(HIRING_COST)}</small></button>
                <button type="button" onClick={raiseFund}><span>투자 제안서</span><small>평판 20</small></button>
                <button type="button" onClick={resetGame}><span>새 게임</span><small>초기화</small></button>
              </div>
            </div>
          </section>
        ) : (
          <section className="terminal-screen" data-testid="computer-terminal">
            <div className="terminal-wallet" aria-label="회사 자산 요약">
              <span><small>현금</small><b>{formatWon(game.cash)}</b></span>
              <span><small>총자산</small><b data-testid="aum-value">{formatWon(currentAum)}</b></span>
              <span><small>오늘</small><b className={anyMarketOpenToday ? "market-open" : "market-closed"}>{anyMarketOpenToday ? "장 열림" : "휴장"}</b></span>
            </div>

            <nav className="game-tabs" aria-label="컴퓨터 메뉴">
              <button type="button" className={tab === "market" ? "active" : ""} onClick={() => navigateTab("market")}>주식시장</button>
              <button type="button" className={tab === "portfolio" ? "active" : ""} onClick={() => navigateTab("portfolio")}>내 자산</button>
              <button type="button" className={tab === "deals" ? "active" : ""} onClick={() => navigateTab("deals")}>인수제안 <span>{deals.filter((deal) => deal.availableFrom <= currentDate && !game.acquisitions.some((item) => item.dealId === deal.id)).length}</span></button>
            </nav>

            <div className="terminal-scroll">
              {tab === "market" && (
                <section className="market-layout">
                  <div className="market-list-panel">
                    <div className="section-heading">
                      <div><span>DAILY MARKET TERMINAL</span><h2>어디에 투자할까요?</h2></div>
                      <div className="market-filters" role="group" aria-label="시장 필터">
                        {(["DOMESTIC", "KOSPI", "KOSDAQ", "OVERSEAS"] as Market[]).map((market) => (
                          <button type="button" key={market} className={marketFilter === market ? "active" : ""} onClick={() => setMarketFilter(market)}>{{ DOMESTIC: "국내", KOSPI: "코스피", KOSDAQ: "코스닥", OVERSEAS: "해외" }[market]}</button>
                        ))}
                      </div>
                    </div>
                    <p className={`market-day-note ${anyMarketOpenToday ? "open" : "closed"}`}><i />{anyMarketOpenToday ? "오늘 거래 데이터가 도착했습니다." : "주말·휴장일에는 직전 거래일 종가를 표시합니다."}</p>
                    <div className="asset-grid">
                      {visibleAssets.map((asset) => {
                        const price = priceAtDate(asset, currentDate);
                        const previous = priceAtDate(asset, addDays(currentDate, -1)) ?? price;
                        const change = price && previous ? ((price - previous) / previous) * 100 : 0;
                        const series = Array.from({ length: 14 }, (_, index) => priceAtDate(asset, addDays(currentDate, index - 13)))
                          .filter((value): value is number => value !== null);
                        const quoteToday = hasQuoteOnDate(asset, currentDate);
                        return (
                          <button type="button" className={`asset-card ${selectedId === asset.id ? "selected" : ""}`} key={asset.id} onClick={() => openOrderSheet(asset.id)} aria-pressed={selectedId === asset.id}>
                            <span className="asset-card-top"><i>{countryFlag[asset.country]}</i><b>{asset.name}</b><small>{asset.symbol}</small></span>
                            <span className="asset-index">{price ? price.toFixed(1) : "—"}</span>
                            <span className={change >= 0 ? "asset-change positive" : "asset-change negative"}>{price ? formatPercent(change) : "기록 없음"}</span>
                            <Sparkline values={series.length > 1 ? series : [price ?? 0, price ?? 0]} color={asset.color} />
                            <span className="asset-meta">{quoteToday ? "오늘 종가" : "직전 종가"} · {asset.market}</span>
                          </button>
                        );
                      })}
                    </div>
                    <p className="terminal-data-note">장중 움직임은 게임용으로 생성하고 거래일 마감값은 실제 일별 종가를 사용합니다. 주말·휴장일은 직전 종가를 유지합니다.</p>
                  </div>
                </section>
              )}

              {tab === "portfolio" && (
                <section className="portfolio-section">
                  <div className="section-heading"><div><span>MY LEDGER</span><h2>내 자산 현황</h2></div></div>
                  <div className="portfolio-grid">
                    <article className="allocation-card">
                      <div className="allocation-visual" style={{ "--cash": `${currentAum ? (game.cash / currentAum) * 100 : 100}%`, "--listed": `${currentAum ? (invested / currentAum) * 100 : 0}%` } as React.CSSProperties}>
                        <span><b>{formatWon(currentAum)}</b><small>총 운용자산</small></span>
                      </div>
                      <ul className="allocation-legend">
                        <li><i className="legend-cash" />현금 <b>{formatWon(game.cash)}</b></li>
                        <li><i className="legend-listed" />상장주식 <b>{formatWon(invested)}</b></li>
                        <li><i className="legend-private" />인수기업 <b>{formatWon(ownedCompanies)}</b></li>
                      </ul>
                    </article>
                    <div className="holdings-list">
                      {assets.filter((asset) => game.positions[asset.id]?.units).length === 0 ? (
                        <div className="empty-state"><span>아직 보유 주식이 없습니다</span><h3>컴퓨터에서 첫 투자를<br />시작해보세요.</h3><button type="button" onClick={() => setTab("market")}>주식시장 열기 →</button></div>
                      ) : assets.filter((asset) => game.positions[asset.id]?.units).map((asset) => {
                        const position = game.positions[asset.id];
                        const value = position.units * (priceAtDate(asset, currentDate) ?? 0);
                        const gain = ((value - position.cost) / position.cost) * 100;
                        return <button type="button" className="holding-row" key={asset.id} onClick={() => { setSelectedId(asset.id); setTab("market"); setOrderSheetOpen(true); }}><i style={{ background: asset.color }} /><span><b>{asset.name}</b><small>{asset.market} · {asset.symbol}</small></span><span><b>{formatWon(value)}</b><small className={gain >= 0 ? "positive" : "negative"}>{formatPercent(gain)}</small></span></button>;
                      })}
                    </div>
                  </div>
                </section>
              )}

              {tab === "deals" && (
                <section className="deals-section">
                  <div className="section-heading"><div><span>INCOMING CALLS</span><h2>인수 제안</h2></div><p>실제 거래에서 착안했지만 가격과 조건은 게임 규모에 맞춘 가상 시나리오입니다.</p></div>
                  <div className="deal-grid">
                    {deals.map((deal, index) => {
                      const locked = deal.availableFrom > currentDate;
                      const completed = game.acquisitions.some((item) => item.dealId === deal.id);
                      const eligible = !locked && !completed && game.reputation >= deal.reputation && game.cash >= deal.price;
                      return (
                        <article className={`deal-card ${locked ? "locked" : ""}`} key={deal.id}>
                          <div className="deal-number">0{index + 1}</div>
                          <span className="deal-category">{locked ? `${dateLabel(deal.availableFrom)} 공개` : deal.category}</span>
                          <h3>{deal.title}</h3>
                          <p>{deal.thesis}</p>
                          <div className="deal-terms"><span><small>거래가</small>{formatWon(deal.price)}</span><span><small>필요 평판</small>{deal.reputation}</span><span><small>월 현금흐름</small>{formatWon(deal.monthlyIncome)}</span></div>
                          <p className="history-note">{deal.history}</p>
                          <button type="button" disabled={locked || completed} className={eligible ? "ready" : ""} onClick={() => acquire(deal)}>{completed ? "인수 완료" : locked ? "아직 비공개" : eligible ? "계약 승인 →" : "조건 확인"}</button>
                        </article>
                      );
                    })}
                  </div>
                </section>
              )}
            </div>
          </section>
        )}
      </div>

      <div className="sticky-command">
        <div><span>{campaignComplete ? "CAMPAIGN COMPLETE" : `DAY ${dayNumber} 마감`}</span><strong>{campaignComplete ? "2010년대 진입" : `${dateLabel(addDays(currentDate, 1))}로`}</strong></div>
        <button type="button" onClick={advanceDay} data-testid="advance-day">{campaignComplete ? "완주 기록" : "하루 보내기"}<i>→</i></button>
      </div>

      {orderSheetOpen && (
        <div className="order-sheet-backdrop" role="presentation" onClick={() => setOrderSheetOpen(false)}>
          <aside className="order-ticket" role="dialog" aria-modal="true" aria-labelledby="order-title" data-testid="order-ticket" onClick={(event) => event.stopPropagation()}>
            <div className="sheet-handle" aria-hidden="true" />
            <button type="button" className="sheet-close" onClick={() => setOrderSheetOpen(false)} aria-label="거래창 닫기">×</button>
            <div className="ticket-heading">
              <div><span>{selectedAsset.market} / {selectedAsset.symbol}</span><h3 id="order-title">{selectedAsset.name}</h3></div>
              <span className="price-index">{selectedAsset.currency} {selectedPrice?.toFixed(2) ?? "—"}</span>
            </div>
            <div className="ticket-chart"><Sparkline values={selectedSeries} color={selectedAsset.color} /></div>
            <div className="ticket-performance">
              <span><small>오늘</small><b className={selectedReturn >= 0 ? "positive" : "negative"}>{formatPercent(selectedReturn)}</b></span>
              <span><small>보유 가치</small><b>{formatWon(selectedPositionValue)}</b></span>
            </div>
            <div className="segmented" role="group" aria-label="주문 유형">
              <button type="button" className={orderMode === "buy" ? "active" : ""} onClick={() => setOrderMode("buy")}>매수</button>
              <button type="button" className={orderMode === "sell" ? "active" : ""} onClick={() => setOrderMode("sell")}>매도</button>
            </div>
            <div className="percent-grid" role="group" aria-label="주문 비율">
              {[10, 25, 50, 100].map((percent) => <button type="button" key={percent} className={orderPercent === percent ? "active" : ""} onClick={() => setOrderPercent(percent)}>{percent === 100 ? "MAX" : `${percent}%`}</button>)}
            </div>
            <div className="order-summary">
              <span>{orderMode === "buy" ? "예상 사용 현금" : "예상 매도 가치"}</span>
              <strong>{formatWon(orderMode === "buy" ? game.cash * orderPercent / 100 : selectedPositionValue * orderPercent / 100)}</strong>
              <small>거래비용 0.25% 반영 · 실제 종가 기준</small>
            </div>
            <button type="button" className="primary-button" onClick={placeOrder} data-testid="place-order" disabled={!selectedPrice || !hasQuoteOnDate(selectedAsset, currentDate)}>{!selectedPrice ? "아직 거래 기록 없음" : !hasQuoteOnDate(selectedAsset, currentDate) ? "오늘은 휴장입니다" : `${selectedAsset.name} ${orderMode === "buy" ? "투자하기" : "매도하기"}`}</button>
          </aside>
        </div>
      )}

      {activeEvent && (
        <div className="event-backdrop" role="presentation" onClick={() => setActiveEvent(null)}>
          <article className="event-modal" role="dialog" aria-modal="true" aria-labelledby="event-title" onClick={(event) => event.stopPropagation()}>
            <button type="button" className="event-close" onClick={() => setActiveEvent(null)} aria-label="이벤트 닫기">×</button>
            <span className="event-date">{dateLabel(activeEvent.date)} · {activeEvent.eyebrow}</span>
            <div className="event-rule" />
            <h2 id="event-title">{activeEvent.title}</h2>
            <p>{activeEvent.body}</p>
            <strong>{activeEvent.signal}</strong>
            <button type="button" className="primary-button" onClick={() => setActiveEvent(null)}>내 방으로 돌아가기</button>
          </article>
        </div>
      )}

      {toast && <div className="toast" role="status">{toast}</div>}
    </main>
  );
}
