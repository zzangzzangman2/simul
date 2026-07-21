import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

async function render() {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", `${process.pid}-${Date.now()}`);
  const { default: worker } = await import(workerUrl.href);

  return worker.fetch(
    new Request("http://localhost/", { headers: { accept: "text/html" } }),
    { ASSETS: { fetch: async () => new Response("Not found", { status: 404 }) } },
    { waitUntil() {}, passThroughOnException() {} },
  );
}

test("server-renders the required company-name onboarding", async () => {
  const response = await render();
  assert.equal(response.status, 200);
  assert.match(response.headers.get("content-type") ?? "", /^text\/html\b/i);

  const html = await response.text();
  assert.match(html, /<title>MILLENNIUM CAPITAL/);
  assert.match(html, /2000\.01\.01/);
  assert.match(html, /당신의 투자회사에/);
  assert.match(html, /100만원/);
  assert.match(html, /창립 팀<\/dt><dd>1명/);
  assert.match(html, /id="company-name"/);
  assert.match(html, /회사 설립하기/);
  assert.match(html, /disabled/);
  assert.doesNotMatch(html, /투자할 회사를 고르세요/);
  assert.doesNotMatch(html, /codex-preview|react-loading-skeleton|Your site is taking shape/);
});

test("ships a complete daily 2000-2010 market snapshot", async () => {
  const data = JSON.parse(await readFile(new URL("../app/data/market-history.json", import.meta.url), "utf8"));
  assert.equal(data.schemaVersion, 3);
  assert.equal(data.period.start, "2000-01-01");
  assert.equal(data.period.end, "2010-12-31");
  assert.equal(data.assets.length, 28);
  assert.equal(data.assets.filter((asset) => asset.country === "KR").length, 22);
  assert.equal(data.assets.filter((asset) => asset.country !== "KR").length, 6);
  assert.deepEqual(new Set(data.assets.map((asset) => asset.market)), new Set(["KOSPI", "KOSDAQ", "NASDAQ", "TSE"]));

  for (const asset of data.assets) {
    const dates = Object.keys(asset.prices).sort();
    assert.ok(dates.length >= 2700, `${asset.symbol} should have at least 2700 daily observations`);
    assert.equal(new Set(dates).size, dates.length, `${asset.symbol} should not contain duplicate dates`);
    assert.ok(dates[0] >= "1999-12-01" && dates[0] <= "2000-04-28");
    assert.ok(dates.at(-1) >= "2010-12-30");
    assert.ok(dates.every((date) => /^\d{4}-\d{2}-\d{2}$/.test(date)));
    assert.ok(Object.values(asset.prices).every(Number.isFinite));
  }
});

test("documents and preserves the portrait-mobile product contract", async () => {
  const [rules, guide, css, game, roomImage] = await Promise.all([
    readFile(new URL("../AGENTS.md", import.meta.url), "utf8"),
    readFile(new URL("../PROJECT_GUIDE.md", import.meta.url), "utf8"),
    readFile(new URL("../app/globals.css", import.meta.url), "utf8"),
    readFile(new URL("../app/game-client.tsx", import.meta.url), "utf8"),
    readFile(new URL("../public/office-room.png", import.meta.url)),
  ]);

  assert.match(rules, /390×844px/);
  assert.match(rules, /최소 360px/);
  assert.match(guide, /첫 방문 시 회사 이름 입력 화면/);
  assert.match(css, /env\(safe-area-inset-bottom\)/);
  assert.match(css, /width: min\(100%, 430px\)/);
  assert.match(css, /\.asset-grid \{[\s\S]*?grid-template-columns: 1fr;/);
  assert.match(game, /companyName: string/);
  assert.match(game, /version: 3/);
  assert.match(game, /currentDate: string/);
  assert.match(game, /INITIAL_CAPITAL = 1_000_000/);
  assert.match(game, /INITIAL_TEAM = 1/);
  assert.match(game, /maxLength=\{24\}/);
  assert.match(game, /simul-millennium-capital-v1/);
  assert.match(game, /data-testid="office-screen"/);
  assert.match(game, /data-testid="room-computer"/);
  assert.match(game, /data-testid="advance-day"/);
  assert.match(game, /orderSheetOpen/);
  assert.match(game, /order-sheet-backdrop/);
  assert.match(game, /navigateTab/);
  assert.match(css, /url\("\/office-room\.png"\)/);
  assert.ok(roomImage.byteLength > 100_000);
});

test("validates the dynamic news API before invoking Gemini", async () => {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("news-test", `${process.pid}-${Date.now()}`);
  const { default: worker } = await import(workerUrl.href);
  const response = await worker.fetch(
    new Request("http://localhost/api/news", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        year: 1999,
        companyName: "애플",
        action: "경영진 교체",
        megaTrend: "모바일 기기 확산",
      }),
    }),
    { ASSETS: { fetch: async () => new Response("Not found", { status: 404 }) } },
    { waitUntil() {}, passThroughOnException() {} },
  );

  assert.equal(response.status, 400);
  assert.match((await response.json()).error, /2000~2010/);
});

test("keeps Gemini credentials server-side and forces the news JSON schema", async () => {
  const [route, generator] = await Promise.all([
    readFile(new URL("../app/api/news/route.ts", import.meta.url), "utf8"),
    readFile(new URL("../lib/dynamic-news.ts", import.meta.url), "utf8"),
  ]);

  assert.match(route, /export async function POST/);
  assert.match(generator, /gemini-3\.5-flash/);
  assert.match(generator, /vertexai: true/);
  assert.match(generator, /responseMimeType: "application\/json"/);
  assert.match(generator, /responseJsonSchema: articleSchema/);
  assert.match(generator, /minimum: -30/);
  assert.match(generator, /maximum: 50/);
  assert.doesNotMatch(generator, /NEXT_PUBLIC_[A-Z_]*(?:KEY|SECRET)/);
});
test("allows local Flutter Web preflight and rejects unknown origins", async () => {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("cors-test", `${process.pid}-${Date.now()}`);
  const { default: worker } = await import(workerUrl.href);
  const env = { ASSETS: { fetch: async () => new Response("Not found", { status: 404 }) } };
  const ctx = { waitUntil() {}, passThroughOnException() {} };

  const preflight = await worker.fetch(
    new Request("http://localhost/api/news", {
      method: "OPTIONS",
      headers: { origin: "http://localhost:3001" },
    }),
    env,
    ctx,
  );
  assert.equal(preflight.status, 204);
  assert.equal(preflight.headers.get("access-control-allow-origin"), "http://localhost:3001");

  const rejected = await worker.fetch(
    new Request("http://localhost/api/news", {
      method: "POST",
      headers: { origin: "https://attacker.example", "content-type": "application/json" },
      body: "{}",
    }),
    env,
    ctx,
  );
  assert.equal(rejected.status, 403);
});