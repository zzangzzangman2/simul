"use client";

import { useEffect, useMemo, useState } from "react";
import marketHistory from "./data/market-history.json";

type Market = "ALL" | "KRX" | "NASDAQ" | "TSE";
type Tab = "market" | "portfolio" | "deals";
type OrderMode = "buy" | "sell";

type Asset = {
  id: string;
  symbol: string;
  name: string;
  market: Exclude<Market, "ALL">;
  country: "KR" | "US" | "JP";
  sector: string;
  color: string;
  currency: string;
  baselineMonth: string;
  prices: Record<string, number>;
};

type Position = { units: number; cost: number };
type Acquisition = { dealId: string; acquiredIndex: number; purchasePrice: number };
type AumPoint = { month: string; value: number };

type GameState = {
  version: 1;
  monthIndex: number;
  cash: number;
  positions: Record<string, Position>;
  reputation: number;
  team: number;
  acquisitions: Acquisition[];
  aumHistory: AumPoint[];
  fundRaised: boolean;
};

type TimelineEvent = {
  id: string;
  month: string;
  eyebrow: string;
  title: string;
  body: string;
  signal: string;
};

type Deal = {
  id: string;
  month: string;
  title: string;
  category: string;
  price: number;
  reputation: number;
  monthlyIncome: number;
  thesis: string;
  history: string;
};

const assets = marketHistory.assets as unknown as Asset[];
const months = Object.keys(assets[0].prices)
  .filter((month) => month >= marketHistory.period.start && month <= marketHistory.period.end)
  .sort();

const timeline: TimelineEvent[] = [
  {
    id: "dotcom-peak",
    month: "2000-03",
    eyebrow: "닷컴 사이클",
    title: "기술주 열기가 정점에 닿았다",
    body: "나스닥이 기록적인 고점권에 진입했습니다. 성장 서사는 강하지만 현금흐름이 약한 기업의 가격 변동성이 커집니다.",
    signal: "가격 데이터에 당시 급등락이 이미 반영되어 있습니다.",
  },
  {
    id: "ps2",
    month: "2000-10",
    eyebrow: "콘솔 전쟁",
    title: "PlayStation 2가 북미에 상륙했다",
    body: "게임과 DVD를 한 기기에 묶은 소니의 전략이 거실 플랫폼 경쟁을 바꿉니다. 콘텐츠와 하드웨어의 결합이 주요 투자 테마가 됩니다.",
    signal: "소니와 일본 기술주의 흐름을 확인하세요.",
  },
  {
    id: "september-11",
    month: "2001-09",
    eyebrow: "시장 충격",
    title: "미국 시장이 전례 없는 충격을 맞았다",
    body: "9·11 테러 뒤 미국 증권시장이 며칠간 문을 닫았습니다. 유동성, 통신, 안전자산 선호가 투자위원회의 최우선 의제가 됩니다.",
    signal: "현금을 확보할지, 공포 속 가격을 매수할지 결정하세요.",
  },
  {
    id: "ipod",
    month: "2001-10",
    eyebrow: "제품 출시",
    title: "Apple이 iPod을 공개했다",
    body: "개인용 컴퓨터 회사가 음악 생태계로 확장합니다. 아직 작은 신호지만 하드웨어·소프트웨어·콘텐츠를 묶는 전략이 시작됐습니다.",
    signal: "장기 복리와 단기 생존 사이의 균형이 중요합니다.",
  },
  {
    id: "google-ipo",
    month: "2004-08",
    eyebrow: "IPO",
    title: "검색 광고 기업 Google이 상장했다",
    body: "인터넷 산업의 수익모델이 배너에서 검색 의도 기반 광고로 이동합니다. 닷컴 붕괴 뒤 살아남은 플랫폼의 질이 다시 평가받습니다.",
    signal: "인터넷·소프트웨어 포트폴리오를 재점검할 시점입니다.",
  },
  {
    id: "iphone",
    month: "2007-06",
    eyebrow: "플랫폼 전환",
    title: "첫 iPhone 판매가 시작됐다",
    body: "휴대전화와 인터넷, 미디어 플레이어가 하나로 합쳐집니다. 통신사·반도체·소프트웨어의 가치사슬이 재편되기 시작합니다.",
    signal: "Apple, 삼성전자, SK텔레콤의 다른 노출을 비교하세요.",
  },
  {
    id: "lehman",
    month: "2008-09",
    eyebrow: "금융위기",
    title: "Lehman Brothers가 파산보호를 신청했다",
    body: "신용시장이 얼어붙고 세계 주식시장이 급락합니다. 레버리지가 낮고 현금이 많은 투자회사만 다음 기회를 잡을 수 있습니다.",
    signal: "현금 버퍼와 인수 여력을 동시에 지켜야 합니다.",
  },
  {
    id: "recovery",
    month: "2009-03",
    eyebrow: "사이클 전환",
    title: "공포 속에서 회복의 실마리가 보인다",
    body: "각국의 정책 대응과 밸류에이션 하락이 맞물리며 위험자산이 바닥을 다지기 시작합니다. 위기 때 만든 포지션의 결과가 갈립니다.",
    signal: "남은 현금을 어디에 배분할지 결정하세요.",
  },
];

const deals: Deal[] = [
  {
    id: "portal-game",
    month: "2000-07",
    title: "포털 × 게임 합병 참여",
    category: "전략적 지분",
    price: 900_000_000,
    reputation: 14,
    monthlyIncome: 9_000_000,
    thesis: "검색 트래픽과 게임 결제 이용자를 결합해 체류시간과 현금흐름을 동시에 확보합니다.",
    history: "2000년 네이버컴과 한게임의 합병에서 착안한 게임화된 딜입니다.",
  },
  {
    id: "auction-commerce",
    month: "2001-02",
    title: "온라인 경매 플랫폼 인수",
    category: "바이아웃",
    price: 1_600_000_000,
    reputation: 20,
    monthlyIncome: 18_000_000,
    thesis: "판매자 네트워크를 선점하고 거래 수수료 기반의 반복 매출을 만듭니다.",
    history: "2001년 eBay의 옥션 투자·인수 흐름에서 착안한 가상 소형 딜입니다.",
  },
  {
    id: "social-community",
    month: "2003-08",
    title: "미니홈피 커뮤니티 인수",
    category: "볼트온 인수",
    price: 3_400_000_000,
    reputation: 30,
    monthlyIncome: 42_000_000,
    thesis: "통신 가입자 기반에 디지털 아이템과 소셜 그래프를 더합니다.",
    history: "2003년 SK커뮤니케이션즈의 싸이월드 인수에서 착안했습니다.",
  },
  {
    id: "video-platform",
    month: "2006-10",
    title: "UGC 비디오 플랫폼 공동인수",
    category: "컨소시엄",
    price: 8_500_000_000,
    reputation: 45,
    monthlyIncome: 115_000_000,
    thesis: "검색 광고 다음 성장축으로 동영상 소비와 창작자 네트워크를 선점합니다.",
    history: "2006년 Google의 YouTube 인수에서 착안한 축소형 공동투자 시나리오입니다.",
  },
];

const countryFlag: Record<Asset["country"], string> = { KR: "KR", US: "US", JP: "JP" };
const storageKey = "simul-millennium-capital-v1";
const tradingFee = 0.0025;

function initialState(): GameState {
  return {
    version: 1,
    monthIndex: 0,
    cash: 5_000_000_000,
    positions: {},
    reputation: 12,
    team: 3,
    acquisitions: [],
    aumHistory: [{ month: months[0], value: 5_000_000_000 }],
    fundRaised: false,
  };
}

function priceAt(asset: Asset, monthIndex: number) {
  const month = months[Math.max(0, Math.min(monthIndex, months.length - 1))];
  return asset.prices[month] ?? 100;
}

function portfolioValue(positions: Record<string, Position>, monthIndex: number) {
  return assets.reduce((total, asset) => {
    const position = positions[asset.id];
    return total + (position?.units ?? 0) * priceAt(asset, monthIndex);
  }, 0);
}

function acquiredValue(acquisitions: Acquisition[], monthIndex: number) {
  return acquisitions.reduce((total, acquisition) => {
    const heldMonths = Math.max(0, monthIndex - acquisition.acquiredIndex);
    return total + acquisition.purchasePrice * Math.pow(1.02, heldMonths / 12);
  }, 0);
}

function totalAum(state: GameState, monthIndex = state.monthIndex) {
  return (
    state.cash +
    portfolioValue(state.positions, monthIndex) +
    acquiredValue(state.acquisitions, monthIndex)
  );
}

function syncSnapshot(state: GameState) {
  const month = months[state.monthIndex];
  const value = totalAum(state);
  const history = [...state.aumHistory];
  const last = history[history.length - 1];
  if (last?.month === month) {
    history[history.length - 1] = { month, value };
  } else {
    history.push({ month, value });
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

function monthLabel(month: string) {
  const [year, value] = month.split("-");
  return `${year}.${value}.01`;
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
  const [tab, setTab] = useState<Tab>("market");
  const [marketFilter, setMarketFilter] = useState<Market>("ALL");
  const [selectedId, setSelectedId] = useState("samsung");
  const [orderMode, setOrderMode] = useState<OrderMode>("buy");
  const [orderPercent, setOrderPercent] = useState(25);
  const [activeEvent, setActiveEvent] = useState<TimelineEvent | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  useEffect(() => {
    try {
      const saved = window.localStorage.getItem(storageKey);
      if (saved) {
        const parsed = JSON.parse(saved) as GameState;
        if (parsed.version === 1 && parsed.monthIndex < months.length) setGame(parsed);
      }
    } catch {
      window.localStorage.removeItem(storageKey);
    } finally {
      setHydrated(true);
    }
  }, []);

  useEffect(() => {
    if (hydrated) window.localStorage.setItem(storageKey, JSON.stringify(game));
  }, [game, hydrated]);

  useEffect(() => {
    if (!toast) return;
    const timeout = window.setTimeout(() => setToast(null), 2600);
    return () => window.clearTimeout(timeout);
  }, [toast]);

  const selectedAsset = assets.find((asset) => asset.id === selectedId) ?? assets[0];
  const currentMonth = months[game.monthIndex];
  const currentAum = totalAum(game);
  const invested = portfolioValue(game.positions, game.monthIndex);
  const ownedCompanies = acquiredValue(game.acquisitions, game.monthIndex);
  const lastHistory = game.aumHistory[game.aumHistory.length - 2]?.value ?? 5_000_000_000;
  const aumChange = ((currentAum - lastHistory) / lastHistory) * 100;
  const selectedPrice = priceAt(selectedAsset, game.monthIndex);
  const previousPrice =
    game.monthIndex > 0
      ? priceAt(selectedAsset, game.monthIndex - 1)
      : selectedAsset.prices[selectedAsset.baselineMonth] ?? selectedPrice;
  const selectedReturn = ((selectedPrice - previousPrice) / previousPrice) * 100;
  const selectedPosition = game.positions[selectedAsset.id];
  const selectedPositionValue = (selectedPosition?.units ?? 0) * selectedPrice;
  const selectedSeries = useMemo(() => {
    const startIndex = Math.max(0, game.monthIndex - 11);
    return months.slice(startIndex, game.monthIndex + 1).map((_, offset) => priceAt(selectedAsset, startIndex + offset));
  }, [game.monthIndex, selectedAsset]);
  const visibleAssets = marketFilter === "ALL" ? assets : assets.filter((asset) => asset.market === marketFilter);
  const campaignComplete = game.monthIndex >= months.length - 1;
  const monthlyIncome = game.acquisitions.reduce((sum, acquisition) => {
    return sum + (deals.find((deal) => deal.id === acquisition.dealId)?.monthlyIncome ?? 0);
  }, 0);

  function placeOrder() {
    setGame((current) => {
      const price = priceAt(selectedAsset, current.monthIndex);
      const position = current.positions[selectedAsset.id] ?? { units: 0, cost: 0 };

      if (orderMode === "buy") {
        const cashSpend = current.cash * (orderPercent / 100);
        if (cashSpend < 1_000_000) {
          setToast("최소 주문금액은 100만원입니다.");
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

  function advanceMonth() {
    if (campaignComplete) {
      setToast("2010년 12월까지 플레이를 완료했습니다.");
      return;
    }
    setGame((current) => {
      const nextIndex = current.monthIndex + 1;
      const operatingCost = current.team * 6_000_000;
      const income = current.acquisitions.reduce((sum, acquisition) => {
        return sum + (deals.find((deal) => deal.id === acquisition.dealId)?.monthlyIncome ?? 0);
      }, 0);
      const currentValue = totalAum(current);
      const nextCash = Math.max(0, current.cash - operatingCost + income);
      const nextValue =
        nextCash + portfolioValue(current.positions, nextIndex) + acquiredValue(current.acquisitions, nextIndex);
      const result = ((nextValue - currentValue) / currentValue) * 100;
      const nextMonth = months[nextIndex];
      const nextEvent = timeline.find((event) => event.month === nextMonth) ?? null;
      const next = {
        ...current,
        monthIndex: nextIndex,
        cash: nextCash,
        reputation: Math.max(0, current.reputation + (result > 1 ? 1 : result < -5 ? -2 : 0)),
        aumHistory: [...current.aumHistory, { month: nextMonth, value: nextValue }],
      };
      if (nextEvent) setActiveEvent(nextEvent);
      setToast(`${monthLabel(nextMonth)} · 운용결과 ${formatPercent(result)}`);
      return next;
    });
  }

  function acquire(deal: Deal) {
    if (deal.month > currentMonth) {
      setToast(`${deal.month.replace("-", ".")}부터 검토할 수 있습니다.`);
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
          { dealId: deal.id, acquiredIndex: current.monthIndex, purchasePrice: deal.price },
        ],
      }),
    );
    setToast(`${deal.title} 거래를 완료했습니다.`);
  }

  function hire() {
    const hiringCost = 300_000_000;
    if (game.cash < hiringCost) {
      setToast("채용에 필요한 현금 3억원이 부족합니다.");
      return;
    }
    setGame((current) =>
      syncSnapshot({
        ...current,
        cash: current.cash - hiringCost,
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
        cash: current.cash + 3_000_000_000,
        reputation: current.reputation + 2,
        fundRaised: true,
      }),
    );
    setToast("외부 출자금 30억원을 유치했습니다.");
  }

  function resetGame() {
    if (!window.confirm("현재 회사를 지우고 2000년 1월 1일로 돌아갈까요?")) return;
    window.localStorage.removeItem(storageKey);
    setGame(initialState());
    setTab("market");
    setSelectedId("samsung");
    setToast("새 회사를 시작했습니다.");
  }

  const aumSeries = game.aumHistory.slice(-18).map((point) => point.value);

  return (
    <main className="game-shell">
      <header className="topbar">
        <div className="brand-lockup">
          <span className="brand-mark" aria-hidden="true">M/00</span>
          <span className="brand-copy">MILLENNIUM<br />CAPITAL</span>
        </div>
        <div className="date-block">
          <span>SIMULATION DATE</span>
          <strong data-testid="game-date">{monthLabel(currentMonth)}</strong>
        </div>
      </header>

      <section className="hero-grid">
        <div className="hero-copy">
          <span className="status-pill"><i /> REAL HISTORY MODE</span>
          <p className="hero-kicker">2000년, 당신의 첫 투자회사</p>
          <h1>시장을 읽고,<br /><em>회사를 소유하라.</em></h1>
          <p className="hero-description">실제 월별 주가 흐름 위에서 투자하고, 팀을 키우고, 시대를 바꾼 인수 기회를 선점하세요.</p>
        </div>
        <div className="hero-ledger">
          <div className="ledger-topline">
            <span>운용자산 AUM</span>
            <span className={aumChange >= 0 ? "positive" : "negative"}>{formatPercent(aumChange)} M/M</span>
          </div>
          <strong className="aum-value" data-testid="aum-value">₩ {formatWon(currentAum).replace("억", " 억")}</strong>
          <Sparkline values={aumSeries.length > 1 ? aumSeries : [currentAum, currentAum]} color="#d8ff65" />
          <div className="ledger-breakdown">
            <span><small>현금</small>{formatWon(game.cash)}</span>
            <span><small>상장주식</small>{formatWon(invested)}</span>
            <span><small>인수기업</small>{formatWon(ownedCompanies)}</span>
          </div>
        </div>
      </section>

      <section className="command-strip" aria-label="회사 현황">
        <div><span>TEAM</span><strong>{game.team}명</strong></div>
        <div><span>REPUTATION</span><strong>{game.reputation}</strong></div>
        <div><span>MONTHLY DEAL INCOME</span><strong>{formatWon(monthlyIncome)}</strong></div>
        <div className="command-actions">
          <button type="button" className="text-button" onClick={hire}>인재 채용 · 3억</button>
          <button type="button" className="text-button" onClick={raiseFund}>2호 펀드</button>
        </div>
      </section>

      <div className="ticker-tape" aria-label="주요 시장 월간 등락">
        <div className="ticker-track">
          {assets.concat(assets).map((asset, index) => {
            const now = priceAt(asset, game.monthIndex);
            const prev = game.monthIndex ? priceAt(asset, game.monthIndex - 1) : now;
            const change = ((now - prev) / prev) * 100;
            return <span key={`${asset.id}-${index}`}><b>{asset.symbol}</b><i className={change >= 0 ? "positive" : "negative"}>{formatPercent(change)}</i></span>;
          })}
        </div>
      </div>

      <nav className="game-tabs" aria-label="게임 메뉴">
        <button type="button" className={tab === "market" ? "active" : ""} onClick={() => setTab("market")}>시장</button>
        <button type="button" className={tab === "portfolio" ? "active" : ""} onClick={() => setTab("portfolio")}>포트폴리오</button>
        <button type="button" className={tab === "deals" ? "active" : ""} onClick={() => setTab("deals")}>딜룸 <span>{deals.filter((deal) => deal.month <= currentMonth && !game.acquisitions.some((item) => item.dealId === deal.id)).length}</span></button>
      </nav>

      {tab === "market" && (
        <section className="market-layout">
          <div className="market-list-panel">
            <div className="section-heading">
              <div><span>01 / PUBLIC MARKETS</span><h2>투자할 회사를 고르세요</h2></div>
              <div className="market-filters" role="group" aria-label="시장 필터">
                {(["ALL", "KRX", "NASDAQ", "TSE"] as Market[]).map((market) => (
                  <button type="button" key={market} className={marketFilter === market ? "active" : ""} onClick={() => setMarketFilter(market)}>{market}</button>
                ))}
              </div>
            </div>
            <div className="asset-grid">
              {visibleAssets.map((asset) => {
                const price = priceAt(asset, game.monthIndex);
                const prev = game.monthIndex ? priceAt(asset, game.monthIndex - 1) : asset.prices[asset.baselineMonth] ?? price;
                const change = ((price - prev) / prev) * 100;
                const start = Math.max(0, game.monthIndex - 5);
                const series = months.slice(start, game.monthIndex + 1).map((_, offset) => priceAt(asset, start + offset));
                return (
                  <button type="button" className={`asset-card ${selectedId === asset.id ? "selected" : ""}`} key={asset.id} onClick={() => setSelectedId(asset.id)} aria-pressed={selectedId === asset.id}>
                    <span className="asset-card-top"><i>{countryFlag[asset.country]}</i><b>{asset.name}</b><small>{asset.symbol}</small></span>
                    <span className="asset-index">{price.toFixed(1)}</span>
                    <span className={change >= 0 ? "asset-change positive" : "asset-change negative"}>{formatPercent(change)}</span>
                    <Sparkline values={series.length > 1 ? series : [price, price]} color={asset.color} />
                    <span className="asset-meta">{asset.market} · {asset.sector}</span>
                  </button>
                );
              })}
            </div>
          </div>

          <aside className="order-ticket" data-testid="order-ticket">
            <div className="ticket-heading">
              <div><span>{selectedAsset.market} / {selectedAsset.symbol}</span><h3>{selectedAsset.name}</h3></div>
              <span className="price-index">IDX {selectedPrice.toFixed(2)}</span>
            </div>
            <div className="ticket-chart"><Sparkline values={selectedSeries} color={selectedAsset.color} /></div>
            <div className="ticket-performance">
              <span><small>이번 달</small><b className={selectedReturn >= 0 ? "positive" : "negative"}>{formatPercent(selectedReturn)}</b></span>
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
              <small>거래비용 0.25% 반영 · 수정주가 지수 기준</small>
            </div>
            <button type="button" className="primary-button" onClick={placeOrder} data-testid="place-order">{selectedAsset.name} {orderMode === "buy" ? "투자하기" : "매도하기"}</button>
          </aside>
        </section>
      )}

      {tab === "portfolio" && (
        <section className="portfolio-section">
          <div className="section-heading"><div><span>02 / PORTFOLIO</span><h2>자본 배분 현황</h2></div></div>
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
                <div className="empty-state"><span>NO POSITIONS YET</span><h3>첫 회사를 선택해<br />포트폴리오를 만드세요.</h3><button type="button" onClick={() => setTab("market")}>시장으로 이동 →</button></div>
              ) : assets.filter((asset) => game.positions[asset.id]?.units).map((asset) => {
                const position = game.positions[asset.id];
                const value = position.units * priceAt(asset, game.monthIndex);
                const gain = ((value - position.cost) / position.cost) * 100;
                return <button type="button" className="holding-row" key={asset.id} onClick={() => { setSelectedId(asset.id); setTab("market"); }}><i style={{ background: asset.color }} /><span><b>{asset.name}</b><small>{asset.market} · {asset.symbol}</small></span><span><b>{formatWon(value)}</b><small className={gain >= 0 ? "positive" : "negative"}>{formatPercent(gain)}</small></span></button>;
              })}
            </div>
          </div>
        </section>
      )}

      {tab === "deals" && (
        <section className="deals-section">
          <div className="section-heading"><div><span>03 / PRIVATE DEALS</span><h2>역사가 만든 인수 기회</h2></div><p>실제 거래에서 착안했지만 가격과 조건은 게임 규모에 맞춘 가상 시나리오입니다.</p></div>
          <div className="deal-grid">
            {deals.map((deal, index) => {
              const locked = deal.month > currentMonth;
              const completed = game.acquisitions.some((item) => item.dealId === deal.id);
              const eligible = !locked && !completed && game.reputation >= deal.reputation && game.cash >= deal.price;
              return (
                <article className={`deal-card ${locked ? "locked" : ""}`} key={deal.id}>
                  <div className="deal-number">0{index + 1}</div>
                  <span className="deal-category">{locked ? `${deal.month.replace("-", ".")} 공개` : deal.category}</span>
                  <h3>{deal.title}</h3>
                  <p>{deal.thesis}</p>
                  <div className="deal-terms"><span><small>거래가</small>{formatWon(deal.price)}</span><span><small>필요 평판</small>{deal.reputation}</span><span><small>월 현금흐름</small>{formatWon(deal.monthlyIncome)}</span></div>
                  <p className="history-note">{deal.history}</p>
                  <button type="button" disabled={locked || completed} className={eligible ? "ready" : ""} onClick={() => acquire(deal)}>{completed ? "인수 완료" : locked ? "아직 비공개" : eligible ? "투자위원회 승인 →" : "조건 확인"}</button>
                </article>
              );
            })}
          </div>
        </section>
      )}

      <section className="history-note-bar">
        <span>DATA NOTE</span>
        <p>월별 수정주가를 종목별 기준월=100으로 정규화한 개발용 스냅샷입니다. 분할·배당 반영 수익률 흐름을 재현하며 실제 당시 호가·인수조건은 아닙니다.</p>
        <a href="https://github.com/zzangzzangman2/simul/blob/main/DATA_SOURCES.md" target="_blank" rel="noreferrer">출처와 방법론 ↗</a>
      </section>

      <div className="sticky-command">
        <div><span>{campaignComplete ? "CAMPAIGN COMPLETE" : "NEXT DECISION"}</span><strong>{campaignComplete ? "2010년대 진입" : monthLabel(months[Math.min(game.monthIndex + 1, months.length - 1)])}</strong></div>
        <button type="button" onClick={advanceMonth} data-testid="advance-month">{campaignComplete ? "완주 기록 보기" : "한 달 진행"}<i>→</i></button>
      </div>

      <footer>
        <span>MILLENNIUM CAPITAL · BUILD 0.1</span>
        <button type="button" onClick={resetGame}>게임 초기화</button>
      </footer>

      {activeEvent && (
        <div className="event-backdrop" role="presentation" onClick={() => setActiveEvent(null)}>
          <article className="event-modal" role="dialog" aria-modal="true" aria-labelledby="event-title" onClick={(event) => event.stopPropagation()}>
            <button type="button" className="event-close" onClick={() => setActiveEvent(null)} aria-label="이벤트 닫기">×</button>
            <span className="event-date">{monthLabel(activeEvent.month)} · {activeEvent.eyebrow}</span>
            <div className="event-rule" />
            <h2 id="event-title">{activeEvent.title}</h2>
            <p>{activeEvent.body}</p>
            <strong>{activeEvent.signal}</strong>
            <button type="button" className="primary-button" onClick={() => setActiveEvent(null)}>투자위원회로 돌아가기</button>
          </article>
        </div>
      )}

      {toast && <div className="toast" role="status">{toast}</div>}
    </main>
  );
}
