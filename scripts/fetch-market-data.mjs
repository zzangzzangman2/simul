import { mkdir, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const assets = [
  {
    id: "samsung",
    symbol: "005930.KS",
    name: "삼성전자",
    market: "KRX",
    country: "KR",
    sector: "반도체",
    color: "#ff5b35",
  },
  {
    id: "skt",
    symbol: "017670.KS",
    name: "SK텔레콤",
    market: "KRX",
    country: "KR",
    sector: "통신",
    color: "#a88bff",
  },
  {
    id: "posco",
    symbol: "005490.KS",
    name: "POSCO홀딩스",
    market: "KRX",
    country: "KR",
    sector: "소재",
    color: "#78a7ff",
  },
  {
    id: "apple",
    symbol: "AAPL",
    name: "Apple",
    market: "NASDAQ",
    country: "US",
    sector: "테크",
    color: "#d8ff65",
  },
  {
    id: "microsoft",
    symbol: "MSFT",
    name: "Microsoft",
    market: "NASDAQ",
    country: "US",
    sector: "소프트웨어",
    color: "#5fd4ff",
  },
  {
    id: "cisco",
    symbol: "CSCO",
    name: "Cisco",
    market: "NASDAQ",
    country: "US",
    sector: "네트워크",
    color: "#ffcf5c",
  },
  {
    id: "toyota",
    symbol: "7203.T",
    name: "Toyota",
    market: "TSE",
    country: "JP",
    sector: "자동차",
    color: "#ff7fa4",
  },
  {
    id: "sony",
    symbol: "6758.T",
    name: "Sony",
    market: "TSE",
    country: "JP",
    sector: "전자·미디어",
    color: "#9ae5c8",
  },
  {
    id: "softbank",
    symbol: "9984.T",
    name: "SoftBank",
    market: "TSE",
    country: "JP",
    sector: "인터넷·통신",
    color: "#ff9e5c",
  },
];

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
    headers: { "User-Agent": "simul-market-snapshot/0.1" },
  });
  if (!response.ok) {
    throw new Error(`${asset.symbol}: HTTP ${response.status}`);
  }

  const payload = await response.json();
  const chart = payload.chart?.result?.[0];
  if (!chart) {
    throw new Error(`${asset.symbol}: ${payload.chart?.error?.description ?? "no chart result"}`);
  }

  const adjusted = chart.indicators?.adjclose?.[0]?.adjclose;
  if (!Array.isArray(adjusted)) {
    throw new Error(`${asset.symbol}: adjusted close series missing`);
  }

  const raw = {};
  chart.timestamp.forEach((timestamp, index) => {
    const value = adjusted[index];
    if (Number.isFinite(value)) {
      raw[dayKey(timestamp, chart.meta.exchangeTimezoneName)] = value;
    }
  });

  const sortedDates = Object.keys(raw).sort();
  const baselineKey = sortedDates.filter((date) => date <= "1999-12-31").at(-1) ?? sortedDates[0];
  const baseline = raw[baselineKey];
  const prices = Object.fromEntries(
    Object.entries(raw)
      .filter(([date]) => date >= "1999-12-01" && date <= "2010-12-31")
      .map(([date, value]) => [date, Number(((value / baseline) * 100).toFixed(4))]),
  );

  return {
    ...asset,
    currency: chart.meta.currency,
    baselineDate: baselineKey,
    baselineAdjustedClose: Number(baseline.toFixed(6)),
    prices,
  };
}

const fetchedAssets = [];
for (const asset of assets) {
  fetchedAssets.push(await fetchAsset(asset));
  console.log(`fetched ${asset.symbol}`);
}

const output = {
  schemaVersion: 2,
  generatedAt: new Date().toISOString(),
  period: { start: "2000-01-01", end: "2010-12-31", baseline: "1999-12" },
  methodology:
    "일별 수정주가를 1999년 12월 마지막 가용 거래일=100으로 정규화하고, 해당 기간 응답이 없는 종목은 2000년 1월 첫 가용일=100을 사용했습니다. 분할·배당을 반영한 수익률 흐름 비교용이며 당시 화면상 실제 호가가 아닙니다. 주말·휴장일은 게임에서 직전 거래일 값을 유지합니다.",
  source: {
    name: "Yahoo Finance chart endpoint",
    url: "https://finance.yahoo.com/",
    note: "개발용 스냅샷입니다. 상용 배포 전 각 거래소 또는 라이선스 공급자의 재배포 권한을 확인해야 합니다.",
  },
  assets: fetchedAssets,
};

const here = dirname(fileURLToPath(import.meta.url));
const outputPath = resolve(here, "../app/data/market-history.json");
await mkdir(dirname(outputPath), { recursive: true });
await writeFile(outputPath, `${JSON.stringify(output, null, 2)}\n`, "utf8");
console.log(`wrote ${outputPath}`);
