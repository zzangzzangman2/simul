import { mkdir, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const domesticAssets = [
  ["samsung", "005930.KS", "삼성전자", "KOSPI", "반도체·전자", "#ff5b35"],
  ["skt", "017670.KS", "SK텔레콤", "KOSPI", "통신", "#a88bff"],
  ["posco", "005490.KS", "포항제철", "KOSPI", "철강", "#78a7ff"],
  ["kepco", "015760.KS", "한국전력", "KOSPI", "전력", "#5aa974"],
  ["hyundai-motor", "005380.KS", "현대자동차", "KOSPI", "자동차", "#4774b8"],
  ["saerom", "035610.KQ", "새롬기술", "KOSDAQ", "인터넷전화", "#ff8a45"],
  ["hancom", "030520.KQ", "한글과컴퓨터", "KOSDAQ", "소프트웨어", "#3fa5a0"],
  ["hyundai-electronics", "000660.KS", "현대전자산업", "KOSPI", "반도체", "#5c7cfa"],
  ["kia", "000270.KS", "기아자동차", "KOSPI", "자동차", "#e45b64"],
  ["hyundai-precision", "012330.KS", "현대정공", "KOSPI", "자동차부품", "#537188"],
  ["samsung-sdi", "006400.KS", "삼성SDI", "KOSPI", "디스플레이·전지", "#425fbc"],
  ["samsung-electro-mechanics", "009150.KS", "삼성전기", "KOSPI", "전자부품", "#5772e5"],
  ["samsung-heavy", "010140.KS", "삼성중공업", "KOSPI", "조선", "#367d9a"],
  ["korean-air", "003490.KS", "대한항공", "KOSPI", "항공", "#5b9bd5"],
  ["incheon-steel", "004020.KS", "인천제철", "KOSPI", "철강", "#607d8b"],
  ["honam-petrochemical", "011170.KS", "호남석유화학", "KOSPI", "화학", "#6e8f5e"],
  ["ssangyong-oil", "010950.KS", "쌍용정유", "KOSPI", "정유", "#d28c45"],
  ["cheil-jedang", "001040.KS", "제일제당", "KOSPI", "식품·생활", "#d46b58"],
  ["hanwha", "000880.KS", "한화", "KOSPI", "화학·기계", "#ee8b2d"],
  ["yuhan", "000100.KS", "유한양행", "KOSPI", "제약", "#4b9f7c"],
  ["shinsegae", "004170.KS", "신세계", "KOSPI", "유통", "#b46b88"],
  ["sm-entertainment", "041510.KQ", "에스엠엔터테인먼트", "KOSDAQ", "엔터테인먼트", "#bf5af2"],
].map(([id, symbol, name, market, sector, color]) => ({
  id,
  symbol,
  name,
  market,
  country: "KR",
  sector,
  color,
}));

const overseasAssets = [
  ["apple", "AAPL", "Apple", "NASDAQ", "US", "테크", "#d8ff65"],
  ["microsoft", "MSFT", "Microsoft", "NASDAQ", "US", "소프트웨어", "#5fd4ff"],
  ["cisco", "CSCO", "Cisco", "NASDAQ", "US", "네트워크", "#ffcf5c"],
  ["toyota", "7203.T", "Toyota", "TSE", "JP", "자동차", "#ff7fa4"],
  ["sony", "6758.T", "Sony", "TSE", "JP", "전자·미디어", "#9ae5c8"],
  ["softbank", "9984.T", "SoftBank", "TSE", "JP", "인터넷·통신", "#ff9e5c"],
].map(([id, symbol, name, market, country, sector, color]) => ({
  id,
  symbol,
  name,
  market,
  country,
  sector,
  color,
}));

const assets = [...domesticAssets, ...overseasAssets];
const start = Math.floor(Date.parse("1999-11-01T00:00:00Z") / 1000);
const end = Math.floor(Date.parse("2011-02-01T00:00:00Z") / 1000);

function dayKey(timestamp, timeZone) {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(new Date(timestamp * 1000));
  const year = parts.find((part) => part.type === "year")?.value;
  const month = parts.find((part) => part.type === "month")?.value;
  const day = parts.find((part) => part.type === "day")?.value;
  return `${year}-${month}-${day}`;
}

async function fetchAsset(asset) {
  const url = new URL(
    `https://query1.finance.yahoo.com/v8/finance/chart/${encodeURIComponent(asset.symbol)}`,
  );
  url.searchParams.set("period1", String(start));
  url.searchParams.set("period2", String(end));
  url.searchParams.set("interval", "1d");
  url.searchParams.set("events", "history");
  url.searchParams.set("includeAdjustedClose", "true");

  const response = await fetch(url, {
    headers: { "User-Agent": "simul-market-snapshot/0.2" },
  });
  if (!response.ok) throw new Error(`${asset.symbol}: HTTP ${response.status}`);

  const payload = await response.json();
  const chart = payload.chart?.result?.[0];
  if (!chart) {
    throw new Error(`${asset.symbol}: ${payload.chart?.error?.description ?? "no chart result"}`);
  }

  const closes = chart.indicators?.quote?.[0]?.close;
  const adjusted = chart.indicators?.adjclose?.[0]?.adjclose;
  if (!Array.isArray(closes)) throw new Error(`${asset.symbol}: close series missing`);
  if (!Array.isArray(adjusted)) throw new Error(`${asset.symbol}: adjusted close series missing`);

  const rawCloses = {};
  const rawAdjusted = {};
  chart.timestamp.forEach((timestamp, index) => {
    const date = dayKey(timestamp, chart.meta.exchangeTimezoneName);
    if (Number.isFinite(closes[index])) rawCloses[date] = closes[index];
    if (Number.isFinite(adjusted[index])) rawAdjusted[date] = adjusted[index];
  });

  const sortedDates = Object.keys(rawCloses).sort();
  const baselineKey = sortedDates.filter((date) => date <= "1999-12-31").at(-1) ?? sortedDates[0];
  const baselineAdjusted = rawAdjusted[baselineKey];
  const prices = Object.fromEntries(
    Object.entries(rawCloses)
      .filter(([date]) => date >= "1999-12-01" && date <= "2010-12-31")
      .map(([date, value]) => [date, Number(value.toFixed(4))]),
  );
  const adjustedIndex = Object.fromEntries(
    Object.entries(rawAdjusted)
      .filter(([date]) => date >= "1999-12-01" && date <= "2010-12-31")
      .map(([date, value]) => [date, Number(((value / baselineAdjusted) * 100).toFixed(4))]),
  );
  const tradeDates = Object.keys(prices);

  return {
    ...asset,
    currency: chart.meta.currency,
    baselineDate: baselineKey,
    baselineClose: Number(rawCloses[baselineKey].toFixed(6)),
    baselineAdjustedClose: Number(baselineAdjusted.toFixed(6)),
    firstTradeDate: tradeDates.at(0),
    lastTradeDate: tradeDates.at(-1),
    prices,
    adjustedIndex,
  };
}

const fetchedAssets = [];
for (const asset of assets) {
  fetchedAssets.push(await fetchAsset(asset));
  console.log(`fetched ${asset.symbol}`);
}

const output = {
  schemaVersion: 3,
  generatedAt: new Date().toISOString(),
  period: { start: "2000-01-01", end: "2010-12-31", baseline: "1999-12" },
  methodology:
    "prices는 거래일의 실제 일별 종가이며 adjustedIndex는 분할·배당을 반영한 수정주가 기준일=100 보조지수입니다. 장중 틱은 이전 종가에서 실제 종가로 수렴하도록 결정론적으로 생성하고 마지막 틱은 prices 값과 일치합니다. 주말·휴장일은 직전 거래일 종가를 유지합니다.",
  source: {
    name: "Yahoo Finance chart endpoint",
    url: "https://finance.yahoo.com/",
    note: "국내 22개와 기존 해외 6개의 개발용 기본 팩입니다. KRX 전 종목 완전판은 계정형 수집기로 생성하며 공개·상용 배포 전 재배포 권한을 확인해야 합니다.",
  },
  assets: fetchedAssets,
};

const here = dirname(fileURLToPath(import.meta.url));
const outputPaths = [
  resolve(here, "../app/data/market-history.json"),
  resolve(here, "../flutter_app/assets/market/market-history.json"),
];
for (const outputPath of outputPaths) {
  await mkdir(dirname(outputPath), { recursive: true });
  await writeFile(outputPath, `${JSON.stringify(output, null, 2)}\n`, "utf8");
  console.log(`wrote ${outputPath}`);
}
