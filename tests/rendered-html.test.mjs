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
  assert.match(flutterIndex, /2000년 서울/);
  assert.match(flutterIndex, /부자되기 생활 시뮬레이션/);
  assert.match(flutterIndex, /property="og:image" content="\/og-apartment-v2\.png"/);
  assert.match(flutterIndex, /name="twitter:card" content="summary_large_image"/);
  assert.doesNotMatch(flutterIndex, /초기자본 100만원/);
  assert.match(onboarding, /1999\.12\.31\s+·\s+23:57/);
  assert.match(onboarding, /우리 투자연구소 이름/);
  assert.match(onboarding, /0원부터 첫날 시작하기/);
  assert.match(layout, /부자되기 시뮬레이션/);
  assert.match(layout, /images: \[\{ url: `\$\{origin\}\/og-apartment-v2\.png`, width: 1672, height: 941/);
  assert.match(layout, /themeColor: "#DDF8F3"/);
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

  assert.match(flutterTemplate, /부자되기 시뮬레이션/);
  assert.match(flutterTemplate, /2000년 서울/);
  assert.match(flutterTemplate, /0원에서 시작해/);
  assert.match(flutterTemplate, /property="og:image" content="\/og-apartment-v2\.png"/);
  assert.match(flutterTemplate, /name="twitter:image" content="\/og-apartment-v2\.png"/);
  assert.doesNotMatch(flutterTemplate, /초기자본 100만원/);
  assert.equal(parsedManifest.name, "부자되기 시뮬레이션");
  assert.match(parsedManifest.description, /2000년 서울/);
  assert.match(parsedManifest.description, /0원에서 시작해/);
  assert.doesNotMatch(parsedManifest.description, /초기자본 100만원/);
});

test("ships a fixed fictional roster and an expanding market generator", async () => {
  const source = await readFile(
    new URL("../flutter_app/lib/game/fictional_market.dart", import.meta.url),
    "utf8",
  );
  const fixedRoster = source.slice(
    source.indexOf("const fixedFictionalCompanies"),
    source.indexOf("const _spinoffBlueprints"),
  );
  assert.equal((fixedRoster.match(/FictionalCompanyDefinition\(/g) ?? []).length, 30);
  assert.match(source, /한빛통신/);
  assert.match(source, /rightsIssue/);
  assert.match(source, /materialSpinoff/);
  assert.match(source, /delisting/);
  assert.match(source, /buildFictionalMarketUniverse/);
  assert.doesNotMatch(source, /assets\/market\/market-history\.json/);
});

test("documents and preserves the portrait-mobile product contract", async () => {
  const [rules, guide, css, state, market, roomImage] = await Promise.all([
    readFile(new URL("../AGENTS.md", import.meta.url), "utf8"),
    readFile(new URL("../PROJECT_GUIDE.md", import.meta.url), "utf8"),
    readFile(new URL("../app/globals.css", import.meta.url), "utf8"),
    readFile(new URL("../flutter_app/lib/game/game_state.dart", import.meta.url), "utf8"),
    readFile(new URL("../flutter_app/lib/stock_market_screen.dart", import.meta.url), "utf8"),
    readFile(new URL("../public/office-room.png", import.meta.url)),
  ]);

  assert.match(rules, /390×844px/);
  assert.match(rules, /최소 360px/);
  assert.match(guide, /처음하기.*이어하기/);
  assert.match(guide, /현재 상태 스키마는 `v15`/);
  assert.match(guide, /최대 5슬롯/);
  assert.doesNotMatch(rules, /게임 화면보다 먼저 회사 이름/);
  assert.doesNotMatch(guide, /첫 방문 시 회사 이름 입력 화면/);
  assert.doesNotMatch(guide, /작은 원룸 사무실에서 시작/);
  assert.match(css, /env\(safe-area-inset-bottom\)/);
  assert.match(css, /width: min\(100%, 430px\)/);
  assert.match(css, /\.asset-grid \{[\s\S]*?grid-template-columns: 1fr;/);
  assert.match(state, /schemaVersion = 15/);
  assert.match(state, /simulationSeed/);
  assert.match(market, /daily-market-report-card/);
  assert.match(market, /purchase-market-report-button/);
  assert.match(market, /가상시장 종목/);
  assert.doesNotMatch(market, /historical-executive-section/);
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
        date: "1999-12-31",
        marketSummary: "국내 증시는 정규 거래일을 마쳤다.",
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
  assert.doesNotMatch(generator, /가격 엔진에 전달/);
  assert.match(generator, /가격·거래·저장 상태에는 사용하지 않음/);
  assert.doesNotMatch(generator, /body\.companyName/);
  assert.doesNotMatch(generator, /body\.action/);
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
test("keeps the Flutter host fixed while the mobile keyboard shrinks the visual viewport", async () => {
  const [flutterTemplate, flutterBootstrap] = await Promise.all([
    readFile(new URL("../flutter_app/web/index.html", import.meta.url), "utf8"),
    readFile(new URL("../flutter_app/web/flutter_bootstrap.js", import.meta.url), "utf8"),
  ]);
  const script = flutterTemplate.match(
    /<script id="mobile-viewport-lock">([\s\S]*?)<\/script>/,
  )?.[1];

  assert.ok(script, "mobile viewport lock should be present");
  assert.match(flutterTemplate, /id="flutter_host"/);
  assert.match(flutterTemplate, /position:\s*fixed/);
  assert.match(
    flutterBootstrap,
    /hostElement:\s*document\.getElementById\('flutter_host'\)/,
  );

  const cssProperties = new Map();
  const viewportListeners = new Map();
  const windowListeners = new Map();
  const host = { style: {} };
  const body = { scrollTop: 24 };
  const root = {
    clientHeight: 800,
    style: {
      setProperty(name, value) {
        cssProperties.set(name, value);
      },
    },
  };
  const viewport = {
    height: 800,
    addEventListener(type, listener) {
      viewportListeners.set(type, listener);
    },
  };
  const fakeWindow = {
    innerHeight: 800,
    visualViewport: viewport,
    scrollX: 0,
    scrollY: 24,
    addEventListener(type, listener) {
      windowListeners.set(type, listener);
    },
    requestAnimationFrame(callback) {
      callback();
    },
    setTimeout(callback) {
      callback();
    },
    scrollTo(x, y) {
      this.scrollX = x;
      this.scrollY = y;
    },
  };
  const document = {
    documentElement: root,
    body,
    getElementById(id) {
      return id === "flutter_host" ? host : null;
    },
  };

  vm.runInNewContext(script, { document, window: fakeWindow });
  assert.equal(cssProperties.get("--app-height"), "800px");
  assert.equal(host.style.height, "800px");

  fakeWindow.innerHeight = 480;
  viewport.height = 480;
  viewportListeners.get("resize")();
  assert.equal(cssProperties.get("--app-height"), "800px");
  assert.equal(host.style.height, "800px");

  fakeWindow.scrollY = 160;
  body.scrollTop = 160;
  viewportListeners.get("scroll")();
  assert.equal(fakeWindow.scrollY, 0);
  assert.equal(body.scrollTop, 0);
});
