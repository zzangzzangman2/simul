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

test("opens the Flutter future-development orphanage prologue from the default route", async () => {
  const response = await render();
  assert.ok([307, 308].includes(response.status));
  assert.equal(new URL(response.headers.get("location"), "http://localhost").pathname, "/play/index.html");

  const [page, flutterIndex, onboarding, main, stockMarket, layout, socialCard] = await Promise.all([
    readFile(new URL("../app/page.tsx", import.meta.url), "utf8"),
    readFile(new URL("../public/play/index.html", import.meta.url), "utf8"),
    readFile(new URL("../flutter_app/lib/visual_novel_onboarding.dart", import.meta.url), "utf8"),
    readFile(new URL("../flutter_app/lib/main.dart", import.meta.url), "utf8"),
    readFile(new URL("../flutter_app/lib/stock_market_screen.dart", import.meta.url), "utf8"),
    readFile(new URL("../app/layout.tsx", import.meta.url), "utf8"),
    readFile(new URL("../public/og.png", import.meta.url)),
  ]);
  assert.match(page, /redirect\("\/play\/index\.html"\)/);
  assert.doesNotMatch(page, /GameClient/);
  assert.match(flutterIndex, /<base href="\/play\/">/);
  assert.match(flutterIndex, /flutter_bootstrap\.js/);
  assert.doesNotMatch(flutterIndex, /투자회사 설립/);
  assert.match(flutterIndex, /2000년 서울/);
  assert.match(flutterIndex, /모바일 세로형 생활·투자 시뮬레이션/);
  assert.match(flutterIndex, /property="og:image" content="\/og\.png"/);
  assert.match(flutterIndex, /name="twitter:card" content="summary_large_image"/);
  assert.doesNotMatch(flutterIndex, /초기자본 100만원/);
  assert.match(onboarding, /1981\.01\.12\s+·\s+23:40/);
  assert.match(onboarding, /이대로 가면 나라가 망한다/);
  assert.match(onboarding, /제6기 오리엔테이션 · 1막 완료/);
  assert.match(onboarding, /bg_blue_house_policy_room_1981_portrait_cartoon_v1\.png/);
  assert.match(onboarding, /bg_orphanage_departure_2000_portrait_v1\.png/);
  assert.match(onboarding, /bg_future_development_orientation_hall_2000_portrait_v1\.png/);
  assert.match(onboarding, /policy-file-\$\{entry\.key\}/);
  assert.match(onboarding, /orientation-roster-continue/);
  assert.match(onboarding, /orientation-exit-button/);
  assert.match(onboarding, /stock-lesson-locked/);
  assert.match(onboarding, /주식선생님\/22_포즈1_주인공그림체_공통슬롯_투명\.png/);
  assert.match(onboarding, /주식선생님\/24_포즈3_주인공그림체_공통슬롯_투명\.png/);
  assert.match(onboarding, /모르는 걸 모른다고 인정하는 법/);
  assert.match(onboarding, /나머지는 아이 몫/);
  assert.match(onboarding, /주식도, 국가계좌도 아직 열지 않아요/);
  assert.match(main, /StoryState\.newOrphanagePlayer/);
  assert.match(main, /academy-market-tutorial-screen/);
  assert.match(stockMarket, /selfRelianceReserve/);
  assert.match(stockMarket, /market-tutorial-teacher-upper-body/);
  assert.match(stockMarket, /stock-order-book/);
  assert.match(stockMarket, /order-book-active-trade/);
  assert.match(layout, /초딩부터 건물주/);
  assert.match(layout, /images: \[\{ url: `\$\{origin\}\/og\.png`, width: 1734, height: 907/);
  assert.match(layout, /themeColor: "#061F2A"/);
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

  assert.match(flutterTemplate, /초딩부터 건물주/);
  assert.match(flutterTemplate, /2000년 서울/);
  assert.match(flutterTemplate, /세뱃돈 1만원/);
  assert.match(flutterTemplate, /property="og:image" content="\/og\.png"/);
  assert.match(flutterTemplate, /name="twitter:image" content="\/og\.png"/);
  assert.doesNotMatch(flutterTemplate, /초기자본 100만원/);
  assert.equal(parsedManifest.name, "초딩부터 건물주");
  assert.match(parsedManifest.description, /2000년 서울/);
  assert.match(parsedManifest.description, /세뱃돈 1만원/);
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
  assert.equal((fixedRoster.match(/FictionalCompanyDefinition\(/g) ?? []).length, 50);
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
  assert.match(guide, /현재 상태 스키마는 `v20`/);
  assert.match(guide, /최대 5슬롯/);
  assert.doesNotMatch(rules, /게임 화면보다 먼저 회사 이름/);
  assert.doesNotMatch(guide, /첫 방문 시 회사 이름 입력 화면/);
  assert.doesNotMatch(guide, /작은 원룸 사무실에서 시작/);
  assert.match(css, /env\(safe-area-inset-bottom\)/);
  assert.match(css, /width: min\(100%, 430px\)/);
  assert.match(css, /\.asset-grid \{[\s\S]*?grid-template-columns: 1fr;/);
  assert.match(state, /schemaVersion = 20/);
  assert.match(state, /simulationSeed/);
  assert.match(market, /daily-market-report-card/);
  assert.match(market, /purchase-market-report-button/);
  assert.match(market, /가상시장 종목/);
  assert.match(market, /market-tutorial-overlay/);
  assert.match(market, /market-detail-tutorial-target/);
  assert.match(market, /market-order-tutorial-done/);
  assert.match(market, /한서윤 선생님/);
  assert.doesNotMatch(market, /historical-executive-section/);
  assert.match(css, /url\("\/office-room\.png"\)/);
  assert.ok(roomImage.byteLength > 100_000);
});

test("uses the deterministic local news combinator without a remote API", async () => {
  const [packageJson, flutterPubspec, combinator, marketNews, main] =
    await Promise.all([
      readFile(new URL("../package.json", import.meta.url), "utf8"),
      readFile(new URL("../flutter_app/pubspec.yaml", import.meta.url), "utf8"),
      readFile(
        new URL("../flutter_app/lib/game/news_combinator.dart", import.meta.url),
        "utf8",
      ),
      readFile(
        new URL("../flutter_app/lib/game/market_news.dart", import.meta.url),
        "utf8",
      ),
      readFile(new URL("../flutter_app/lib/main.dart", import.meta.url), "utf8"),
    ]);

  assert.doesNotMatch(packageJson, /@google\/genai/i);
  assert.doesNotMatch(flutterPubspec, /^\s+http:/m);
  assert.doesNotMatch(`${combinator}${marketNews}${main}`, /\/api\/news/);
  assert.doesNotMatch(`${combinator}${marketNews}${main}`, /package:http/);
  assert.match(combinator, /theoreticalCombinationCount/);
  assert.match(combinator, /12 \* 10 \* 12 \* 10 \* 12 \* 10/);
  assert.match(combinator, /simulationSeed/);
  assert.match(combinator, /toSafeSnapshot/);
  assert.match(main, /NewsCombinator\(\)/);
});

test("tracks mobile browser chrome and provides an exact desktop phone preview", async () => {
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
  assert.match(flutterTemplate, /width:\s*390px/);
  assert.match(flutterTemplate, /height:\s*844px/);
  assert.match(flutterTemplate, /--desktop-preview-scale/);
  assert.match(flutterTemplate, /@media \(hover: hover\)/);
  assert.doesNotMatch(
    flutterTemplate,
    /@media \(min-width:\s*700px\) and \(hover:\s*hover\)/,
  );
  assert.match(
    flutterBootstrap,
    /hostElement:\s*document\.getElementById\('flutter_host'\)/,
  );

  const cssProperties = new Map();
  const viewportListeners = new Map();
  const windowListeners = new Map();
  const mediaListeners = new Map();
  let desktopPreviewQuery;
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
    height: 860,
    addEventListener(type, listener) {
      viewportListeners.set(type, listener);
    },
  };
  const desktopPreviewMedia = {
    matches: false,
    addEventListener(type, listener) {
      mediaListeners.set(type, listener);
    },
  };
  const fakeWindow = {
    innerWidth: 390,
    innerHeight: 1024,
    visualViewport: viewport,
    scrollX: 0,
    scrollY: 24,
    addEventListener(type, listener) {
      windowListeners.set(type, listener);
    },
    matchMedia(query) {
      desktopPreviewQuery = query;
      return desktopPreviewMedia;
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
    activeElement: null,
    getElementById(id) {
      return id === "flutter_host" ? host : null;
    },
  };

  vm.runInNewContext(script, { document, window: fakeWindow });
  assert.equal(cssProperties.get("--app-height"), "860px");
  assert.equal(desktopPreviewQuery, "(hover: hover)");
  assert.equal(host.style.height, "860px");

  fakeWindow.innerHeight = 940;
  viewport.height = 940;
  viewportListeners.get("resize")();
  assert.equal(cssProperties.get("--app-height"), "940px");
  assert.equal(host.style.height, "940px");

  document.activeElement = { tagName: "INPUT", isContentEditable: false };
  fakeWindow.innerHeight = 480;
  viewport.height = 480;
  viewportListeners.get("resize")();
  assert.equal(cssProperties.get("--app-height"), "940px");
  assert.equal(host.style.height, "940px");

  document.activeElement = null;
  fakeWindow.innerHeight = 860;
  viewport.height = 860;
  viewportListeners.get("resize")();
  assert.equal(cssProperties.get("--app-height"), "860px");
  assert.equal(host.style.height, "860px");

  fakeWindow.scrollY = 160;
  body.scrollTop = 160;
  viewportListeners.get("scroll")();
  assert.equal(fakeWindow.scrollY, 0);
  assert.equal(body.scrollTop, 0);

  desktopPreviewMedia.matches = true;
  fakeWindow.innerWidth = 640;
  fakeWindow.innerHeight = 1000;
  mediaListeners.get("change")();
  assert.equal(cssProperties.get("--app-height"), "844px");
  assert.equal(cssProperties.get("--desktop-preview-scale"), "1.0000");
  assert.equal(host.style.height, "844px");

  fakeWindow.innerWidth = 380;
  windowListeners.get("resize")();
  assert.equal(cssProperties.get("--desktop-preview-scale"), "0.8488");
  assert.equal(host.style.height, "844px");

  fakeWindow.innerWidth = 1440;
  fakeWindow.innerHeight = 700;
  windowListeners.get("resize")();
  assert.equal(cssProperties.get("--desktop-preview-scale"), "0.7731");
  assert.equal(host.style.height, "844px");

  fakeWindow.innerHeight = 400;
  windowListeners.get("resize")();
  assert.equal(cssProperties.get("--desktop-preview-scale"), "0.4259");
  assert.ok(
    864 * Number(cssProperties.get("--desktop-preview-scale")) <= 368.1,
    "the complete desktop frame should fit inside the viewport margin",
  );

  desktopPreviewMedia.matches = false;
  fakeWindow.innerWidth = 390;
  fakeWindow.innerHeight = 600;
  viewport.height = 600;
  mediaListeners.get("change")();
  assert.equal(cssProperties.get("--desktop-preview-scale"), "1");
  assert.equal(cssProperties.get("--app-height"), "600px");
  assert.equal(host.style.height, "600px");
});

test("offers a disposable stock-only test entry", async () => {
  const [shortcut, main] = await Promise.all([
    readFile(new URL("../flutter_app/web/stock-test.html", import.meta.url), "utf8"),
    readFile(new URL("../flutter_app/lib/main.dart", import.meta.url), "utf8"),
  ]);

  assert.match(shortcut, /index\.html\?stockTest=1/);
  assert.match(main, /Uri\.base\.queryParameters\['stockTest'\] == '1'/);
  assert.match(main, /key: const Key\('stock-test-market-screen'\)/);
  assert.match(main, /initialCash: 1000000/);
  assert.match(main, /worldSeed: 'stock-market-test-v1'/);
  assert.match(main, /if \(widget\.stockTestMode\) return;/);
});
