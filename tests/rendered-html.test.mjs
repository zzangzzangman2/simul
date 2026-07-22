import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import vm from "node:vm";

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

test("opens the Flutter family-story prologue from the default route", async () => {
  const response = await render();
  assert.ok([307, 308].includes(response.status));
  assert.equal(new URL(response.headers.get("location"), "http://localhost").pathname, "/play/index.html");

  const [page, flutterIndex, onboarding, layout, socialCard] = await Promise.all([
    readFile(new URL("../app/page.tsx", import.meta.url), "utf8"),
    readFile(new URL("../public/play/index.html", import.meta.url), "utf8"),
    readFile(new URL("../flutter_app/lib/visual_novel_onboarding.dart", import.meta.url), "utf8"),
    readFile(new URL("../app/layout.tsx", import.meta.url), "utf8"),
    readFile(new URL("../public/og-apartment-v2.png", import.meta.url)),
  ]);
  assert.match(page, /redirect\("\/play\/index\.html"\)/);
  assert.doesNotMatch(page, /GameClient/);
  assert.match(flutterIndex, /<base href="\/play\/">/);
  assert.match(flutterIndex, /flutter_bootstrap\.js/);
  assert.doesNotMatch(flutterIndex, /투자회사 설립/);
  assert.match(flutterIndex, /창립자 1명이 현금 0원/);
  assert.match(flutterIndex, /종잣돈 1만원을 직접/);
  assert.match(flutterIndex, /property="og:image" content="\/og-apartment-v2\.png"/);
  assert.match(flutterIndex, /name="twitter:card" content="summary_large_image"/);
  assert.doesNotMatch(flutterIndex, /초기자본 100만원/);
  assert.match(onboarding, /1999\.12\.31\s+·\s+23:57/);
  assert.match(onboarding, /우리 투자연구소 이름/);
  assert.match(onboarding, /0원부터 첫날 시작하기/);
  assert.match(layout, /0원에서 시작하는 투자회사/);
  assert.match(layout, /images: \[\{ url: `\$\{origin\}\/og-apartment-v2\.png`, width: 1672, height: 941/);
  assert.match(layout, /themeColor: "#151B29"/);
  assert.doesNotMatch(layout, /100만원으로 시작/);
  assert.ok(socialCard.byteLength > 1_000_000);
});

test("bridges a legacy React save before Flutter starts without overwriting Flutter progress", async () => {
  const flutterTemplate = await readFile(
    new URL("../flutter_app/web/index.html", import.meta.url),
    "utf8",
  );
  const script = flutterTemplate.match(
    /<script id="legacy-save-bridge">([\s\S]*?)<\/script>/,
  )?.[1];
  assert.ok(script, "legacy save bridge should be present");
  assert.ok(
    flutterTemplate.indexOf('id="legacy-save-bridge"') <
      flutterTemplate.indexOf('src="flutter_bootstrap.js"'),
    "legacy save bridge must run before Flutter bootstrap",
  );

  function runBridge(entries) {
    const storage = new Map(Object.entries(entries));
    const writes = [];
    const localStorage = {
      getItem(key) {
        return storage.has(key) ? storage.get(key) : null;
      },
      setItem(key, value) {
        writes.push([key, value]);
        storage.set(key, String(value));
      },
    };
    vm.runInNewContext(script, { localStorage });
    return { storage, writes };
  }

  const legacyKey = "simul-millennium-capital-v1";
  const flutterKey = `flutter.${legacyKey}`;
  const bridgeMarkerKey = `${legacyKey}-flutter-bridge-v1`;
  const legacySave = JSON.stringify({ version: 3, companyName: "가족 투자연구소" });
  const migrated = runBridge({ [legacyKey]: legacySave });
  const encodedLegacySave = JSON.stringify(legacySave);
  assert.equal(migrated.storage.get(flutterKey), encodedLegacySave);
  assert.equal(JSON.parse(migrated.storage.get(flutterKey)), legacySave);
  assert.deepEqual(migrated.writes, [
    [flutterKey, encodedLegacySave],
    [bridgeMarkerKey, "1"],
  ]);

  const flutterSave = JSON.stringify({ version: 8, companyName: "새 연구소" });
  const preserved = runBridge({
    [legacyKey]: legacySave,
    [flutterKey]: flutterSave,
  });
  assert.equal(preserved.storage.get(flutterKey), flutterSave);
  assert.deepEqual(preserved.writes, [[bridgeMarkerKey, "1"]]);

  const deletedAfterMigration = runBridge({
    [legacyKey]: legacySave,
    [bridgeMarkerKey]: "1",
  });
  assert.equal(deletedAfterMigration.storage.get(flutterKey), undefined);
  assert.deepEqual(deletedAfterMigration.writes, []);
  assert.deepEqual(runBridge({}).writes, []);
  assert.deepEqual(runBridge({ [legacyKey]: "not-json" }).writes, []);
  assert.deepEqual(
    runBridge({ [legacyKey]: JSON.stringify({ version: 3, companyName: "   " }) }).writes,
    [],
  );
});

test("keeps Flutter launch metadata aligned with the current starting conditions", async () => {
  const [flutterTemplate, manifest] = await Promise.all([
    readFile(new URL("../flutter_app/web/index.html", import.meta.url), "utf8"),
    readFile(new URL("../flutter_app/web/manifest.json", import.meta.url), "utf8"),
  ]);
  const parsedManifest = JSON.parse(manifest);

  assert.match(flutterTemplate, /2000년 1월 1일/);
  assert.match(flutterTemplate, /창립자 1명이 현금 0원/);
  assert.match(flutterTemplate, /종잣돈 1만원을 직접/);
  assert.match(flutterTemplate, /property="og:image" content="\/og-apartment-v2\.png"/);
  assert.match(flutterTemplate, /name="twitter:image" content="\/og-apartment-v2\.png"/);
  assert.doesNotMatch(flutterTemplate, /초기자본 100만원/);
  assert.match(parsedManifest.description, /2000년 1월 1일/);
  assert.match(parsedManifest.description, /창립자 1명이 현금 0원/);
  assert.match(parsedManifest.description, /종잣돈 1만원을 직접/);
  assert.doesNotMatch(parsedManifest.description, /초기자본 100만원/);
});

test("ships a complete daily 2000-2010 market snapshot", async () => {
  const data = JSON.parse(await readFile(new URL("../app/data/market-history.json", import.meta.url), "utf8"));
  assert.equal(data.schemaVersion, 4);
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
    assert.ok(Object.values(asset.prices).every((price) => Number.isFinite(price) && price > 0));
    assert.ok(Array.isArray(asset.corporateActions));
  }

  const actions = data.assets.flatMap((asset) => asset.corporateActions);
  assert.equal(actions.length, 299);
  assert.equal(new Set(actions.map((action) => action.id)).size, actions.length);
  assert.ok(actions.some((action) => action.type === "split"));
  assert.ok(actions.some((action) => action.type === "dividend"));
  assert.ok(actions.every((action) => /^\d{4}-\d{2}-\d{2}$/.test(action.date)));
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
  assert.match(guide, /처음하기.*이어하기/);
  assert.match(guide, /현재 상태 스키마는 `v13`/);
  assert.match(guide, /최대 5슬롯/);
  assert.doesNotMatch(rules, /게임 화면보다 먼저 회사 이름/);
  assert.doesNotMatch(guide, /첫 방문 시 회사 이름 입력 화면/);
  assert.doesNotMatch(guide, /작은 원룸 사무실에서 시작/);
  assert.match(css, /env\(safe-area-inset-bottom\)/);
  assert.match(css, /width: min\(100%, 430px\)/);
  assert.match(css, /\.asset-grid \{[\s\S]*?grid-template-columns: 1fr;/);
  assert.match(game, /companyName: string/);
  assert.match(game, /version: 3/);
  assert.match(game, /currentDate: string/);
  assert.match(game, /INITIAL_CAPITAL = 0/);
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
  assert.match(generator, /gemini-3\.6-flash/);
  assert.match(generator, /ThinkingLevel\.MEDIUM/);
  assert.doesNotMatch(generator, /temperature:/);
  assert.match(generator, /maxOutputTokens: 2048/);
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
