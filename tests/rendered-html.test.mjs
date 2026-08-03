import assert from "node:assert/strict";
import { access, readFile, readdir } from "node:fs/promises";
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

test("redirects a static-server root request to the Flutter game", async () => {
  const staticIndex = await readFile(
    new URL("../public/index.html", import.meta.url),
    "utf8",
  );

  assert.match(staticIndex, /http-equiv="refresh" content="0; url=\/play\/index\.html"/);
  assert.match(staticIndex, /window\.location\.replace\(target\)/);
  assert.match(staticIndex, /`\/play\/index\.html\$\{window\.location\.search\}\$\{window\.location\.hash\}`/);
  assert.doesNotMatch(staticIndex, /Directory listing/i);
});

test("opens the Flutter Project Decimal prologue from the default route", async () => {
  const response = await render();
  assert.ok([307, 308].includes(response.status));
  assert.equal(new URL(response.headers.get("location"), "http://localhost").pathname, "/play/index.html");

  const [
    page,
    flutterIndex,
    onboarding,
    main,
    stockMarket,
    stockOrderBook,
    layout,
    dialogueBundleRaw,
  ] = await Promise.all([
    readFile(new URL("../app/page.tsx", import.meta.url), "utf8"),
    readFile(new URL("../public/play/index.html", import.meta.url), "utf8"),
    readFile(new URL("../flutter_app/lib/visual_novel_onboarding.dart", import.meta.url), "utf8"),
    readFile(new URL("../flutter_app/lib/main.dart", import.meta.url), "utf8"),
    readFile(new URL("../flutter_app/lib/stock_market_screen.dart", import.meta.url), "utf8"),
    readFile(new URL("../flutter_app/lib/stock_market_order_book.dart", import.meta.url), "utf8"),
    readFile(new URL("../app/layout.tsx", import.meta.url), "utf8"),
    readFile(
      new URL(
        "../flutter_app/assets/dialogue/dialogue-editor-override.json",
        import.meta.url,
      ),
      "utf8",
    ),
  ]);
  const dialogueBundle = JSON.parse(dialogueBundleRaw);
  const dialogueText = dialogueBundle.scenes
    .map((scene) => scene.line)
    .join("\n");
  const protagonistPoses = await readdir(
    new URL("../flutter_app/assets/images/protagonist_seed01/", import.meta.url),
  );
  assert.equal(protagonistPoses.filter((name) => name.endsWith(".png")).length, 24);
  assert.match(page, /redirect\("\/play\/index\.html"\)/);
  assert.doesNotMatch(page, /GameClient/);
  assert.match(flutterIndex, /<base href="\/play\/">/);
  assert.match(flutterIndex, /flutter_bootstrap\.js/);
  assert.doesNotMatch(flutterIndex, /투자회사 설립/);
  assert.match(flutterIndex, /2000년 서울/);
  assert.match(flutterIndex, /모바일 세로형 생활·투자 시뮬레이션/);
  assert.doesNotMatch(flutterIndex, /\/og\.png/);
  assert.match(flutterIndex, /name="twitter:card" content="summary"/);
  assert.doesNotMatch(flutterIndex, /초기자본 100만원/);
  assert.match(dialogueBundleRaw, /1999\.04\.16\s+·\s+23:40/);
  assert.match(dialogueText, /우리가 놓친 건 주가가 아니라, 결정권이 넘어가는 순간이야/);
  assert.match(dialogueText, /트레이딩 플로어 시계 다섯 개 중 하나가 1990년으로 돌아갔어/);
  assert.match(dialogueText, /사적인 행동을 공간으로 지킵니다/);
  assert.match(dialogueBundleRaw, /bg_decimal_living_lounge_1999_v1\.png/);
  assert.match(dialogueBundleRaw, /bg_decimal_sleeping_wing_1999_v1\.png/);
  assert.match(dialogueBundleRaw, /bg_decimal_trading_floor_dawn_2000_v1\.png/);
  assert.match(dialogueBundleRaw, /bg_nis_economic_security_room_night_1999_v1\.png/);
  assert.match(dialogueBundleRaw, /bg_decimal_matrix_exam_1999_v1\.png/);
  assert.match(dialogueBundleRaw, /production_soft_painted\/han_sua\/03_bright_laugh_v3\.png/);
  assert.doesNotMatch(dialogueBundleRaw, /production_soft_painted\/han_sua\/[^"]*quality_v2\.png/);
  assert.match(dialogueBundleRaw, /decimal_nis_1999\/characters\/han_gyujin_nis_director_v1\.png/);
  assert.match(dialogueBundleRaw, /decimal_nis_1999\/characters\/lim_seohee_economic_security_chief_v1\.png/);
  assert.match(dialogueBundleRaw, /decimal_nis_1999\/characters\/jo_mingyeong_rights_auditor_v1\.png/);
  assert.match(dialogueBundleRaw, /decimal_nis_1999\/characters\/cha_eunjoo_selection_officer_v2\.png/);
  assert.match(dialogueBundleRaw, /decimal_nis_1999\/characters\/oh_gyeongtae_facilities_manager_v2\.png/);
  assert.doesNotMatch(dialogueBundleRaw, /cinematic_soft_painted\/policy_1981\//);
  assert.match(dialogueBundleRaw, /bg_decimal_gangnam_exterior_winter_1999_v1\.png/);
  assert.match(dialogueBundleRaw, /bg_decimal_secure_entry_1999_v1\.png/);
  assert.doesNotMatch(onboarding, /policy-file-\$\{entry\.key\}/);
  assert.doesNotMatch(onboarding, /orientation-roster-continue/);
  assert.match(dialogueBundleRaw, /protagonist_seed01\/03_playful_grin\.png/);
  assert.match(dialogueBundleRaw, /protagonist_seed01\/13_explaining_open_hands\.png/);
  assert.match(dialogueBundleRaw, /protagonist_seed01\/09_determined\.png/);
  assert.match(onboarding, /orientation-exit-button/);
  assert.match(onboarding, /academy-pc-powered-off/);
  assert.match(dialogueBundleRaw, /주식선생님\/22_포즈1_주인공그림체_공통슬롯_투명\.png/);
  assert.match(dialogueBundleRaw, /주식선생님\/26_포즈5_주인공그림체_공통슬롯_투명\.png/);
  assert.match(dialogueBundleRaw, /주식선생님\/27_포즈6_주인공그림체_공통슬롯_투명\.png/);
  assert.match(dialogueText, /열 권의 얇은 장부 첫 장에는 모두 같은 숫자, 50,000원/);
  assert.match(main, /StoryState\.newDecimalPlayer/);
  assert.match(main, /academy-market-tutorial-screen/);
  assert.match(stockMarket, /selfRelianceReserve/);
  assert.match(stockMarket, /market-tutorial-teacher-upper-body/);
  assert.match(stockOrderBook, /stock-order-book/);
  assert.match(stockOrderBook, /order-book-active-trade/);
  assert.match(layout, /10대부터 건물주/);
  assert.doesNotMatch(layout, /og\.png/);
  assert.match(layout, /themeColor: "#061F2A"/);
  assert.doesNotMatch(layout, /100만원으로 시작/);
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

  assert.match(flutterTemplate, /10대부터 건물주/);
  assert.match(flutterTemplate, /2000년 서울/);
  assert.match(flutterTemplate, /국가원금 5만원/);
  assert.doesNotMatch(flutterTemplate, /og:image/);
  assert.doesNotMatch(flutterTemplate, /twitter:image/);
  assert.match(flutterTemplate, /name="twitter:card" content="summary"/);
  assert.doesNotMatch(flutterTemplate, /초기자본 100만원/);
  assert.equal(parsedManifest.name, "10대부터 건물주");
  assert.match(parsedManifest.description, /2000년 서울/);
  assert.match(parsedManifest.description, /국가원금 5만원/);
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

  assert.match(rules, /390×844(?:px)?/);
  assert.match(rules, /최소 너비 360px/);
  assert.match(guide, /처음하기.*이어하기/);
  assert.match(guide, /현재 상태 스키마는 `v25`/);
  assert.match(guide, /최대 5슬롯/);
  assert.doesNotMatch(rules, /게임 화면보다 먼저 회사 이름/);
  assert.doesNotMatch(guide, /첫 방문 시 회사 이름 입력 화면/);
  assert.doesNotMatch(guide, /작은 원룸 사무실에서 시작/);
  assert.match(css, /env\(safe-area-inset-bottom\)/);
  assert.match(css, /width: min\(100%, 430px\)/);
  assert.match(css, /\.asset-grid \{[\s\S]*?grid-template-columns: 1fr;/);
  assert.match(state, /schemaVersion = 25/);
  assert.match(state, /simulationSeed/);
  assert.match(market, /daily-market-report-card/);
  assert.match(market, /purchase-market-report-button/);
  assert.match(market, /가상시장 종목/);
  assert.match(market, /market-tutorial-overlay/);
  assert.match(market, /market-detail-tutorial-target/);
  assert.match(market, /market-order-tutorial-done/);
  assert.match(market, /한서윤 운영관/);
  assert.doesNotMatch(market, /historical-executive-section/);
  assert.match(css, /url\("\/office-room\.png"\)/);
  assert.ok(roomImage.byteLength > 100_000);
});

test("uses the deterministic local news combinator without a remote API", async () => {
  const [packageJson, flutterPubspec, combinator, marketNews, main, campaignScenes] =
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
      readFile(new URL("../flutter_app/lib/campaign_scenes.dart", import.meta.url), "utf8"),
    ]);

  assert.doesNotMatch(packageJson, /@google\/genai/i);
  assert.doesNotMatch(flutterPubspec, /^\s+http:/m);
  assert.doesNotMatch(`${combinator}${marketNews}${main}${campaignScenes}`, /\/api\/news/);
  assert.doesNotMatch(`${combinator}${marketNews}${main}${campaignScenes}`, /package:http/);
  assert.match(combinator, /theoreticalCombinationCount/);
  assert.match(combinator, /12 \* 10 \* 12 \* 10 \* 12 \* 10/);
  assert.match(combinator, /simulationSeed/);
  assert.match(combinator, /toSafeSnapshot/);
  assert.match(campaignScenes, /NewsCombinator\(\)/);
});

test("fills the mobile viewport and provides an exact desktop phone preview", async () => {
  const [flutterTemplate, flutterBootstrap, fontManifest, visualNovel] = await Promise.all([
    readFile(new URL("../flutter_app/web/index.html", import.meta.url), "utf8"),
    readFile(new URL("../flutter_app/web/flutter_bootstrap.js", import.meta.url), "utf8"),
    readFile(new URL("../public/play/assets/FontManifest.json", import.meta.url), "utf8"),
    readFile(new URL("../flutter_app/lib/visual_novel_onboarding.dart", import.meta.url), "utf8"),
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
  assert.match(
    flutterTemplate,
    /@media \(hover: hover\) and \(pointer: fine\) and \(min-width: 700px\)/,
  );
  assert.doesNotMatch(flutterTemplate, /@media \(hover: hover\)\s*\{/);
  assert.match(
    flutterBootstrap,
    /hostElement:\s*document\.getElementById\('flutter_host'\)/,
  );
  assert.match(fontManifest, /"family":"Maplestory"/);
  assert.match(fontManifest, /MaplestoryLight\.ttf/);
  assert.match(fontManifest, /MaplestoryBold\.ttf/);
  assert.match(
    visualNovel,
    /key: const Key\('story-line-text'\),[\s\S]*?fontFamily: 'Pretendard'/,
  );
  assert.match(
    visualNovel,
    /key: const Key\('story-speaker-name'\),[\s\S]*?fontFamily: 'Pretendard'/,
  );
  assert.match(visualNovel, /key: const Key\('story-speaker-affiliation'\)/);
  assert.match(visualNovel, /key: Key\('story-dialogue-divider'\)/);
  assert.match(visualNovel, /key: Key\('story-stage-reading-scrim'\)/);
  assert.match(visualNovel, /Color\(0x70000000\)/);
  assert.doesNotMatch(visualNovel, /_dialoguePanelColor/);
  assert.doesNotMatch(visualNovel, /BackdropFilter/);
  assert.doesNotMatch(visualNovel, /story-moving-light-beam/);
  assert.doesNotMatch(visualNovel, /story-dialogue-opacity-control/);
  assert.doesNotMatch(visualNovel, /project-decimal-dialogue-panel-opacity/);

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
  assert.equal(
    desktopPreviewQuery,
    "(hover: hover) and (pointer: fine) and (min-width: 700px)",
  );
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


test("ships an intuitive dialogue editor and builds saved dialogue into the game", async () => {
  const [
    editor,
    editorCss,
    catalog,
    backgroundCatalog,
    data,
    canonicalRaw,
    validation,
    generator,
    buildScript,
    packageJson,
    buildRoute,
    onboarding,
    pubspec,
    mbtiGuide,
    directorStudio,
    sceneToolbox,
    dialogueTypes,
  ] = await Promise.all([
    readFile(new URL("../app/editor/page.tsx", import.meta.url), "utf8"),
    readFile(new URL("../app/editor/editor.module.css", import.meta.url), "utf8"),
    readFile(new URL("../app/editor/character-catalog.ts", import.meta.url), "utf8"),
    readFile(new URL("../app/editor/background-catalog.ts", import.meta.url), "utf8"),
    readFile(new URL("../app/editor/dialogue-data.ts", import.meta.url), "utf8"),
    readFile(
      new URL(
        "../flutter_app/assets/dialogue/dialogue-editor-override.json",
        import.meta.url,
      ),
      "utf8",
    ),
    readFile(new URL("../app/editor/dialogue-validation.ts", import.meta.url), "utf8"),
    readFile(
      new URL("../scripts/generate-dialogue-editor-data.mjs", import.meta.url),
      "utf8",
    ),
    readFile(new URL("../scripts/build-flutter-web.mjs", import.meta.url), "utf8"),
    readFile(new URL("../package.json", import.meta.url), "utf8"),
    readFile(new URL("../app/api/dialogue/build/route.ts", import.meta.url), "utf8"),
    readFile(new URL("../flutter_app/lib/visual_novel_onboarding.dart", import.meta.url), "utf8"),
    readFile(new URL("../flutter_app/pubspec.yaml", import.meta.url), "utf8"),
    readFile(new URL("../characters/cohort6_girls/README.md", import.meta.url), "utf8"),
    readFile(new URL("../app/editor/director-studio.tsx", import.meta.url), "utf8"),
    readFile(new URL("../app/editor/scene-toolbox.tsx", import.meta.url), "utf8"),
    readFile(new URL("../app/editor/dialogue-types.ts", import.meta.url), "utf8"),
  ]);
  const canonical = JSON.parse(canonicalRaw);
  const hanSuaAssets = (
    await readdir(
      new URL(
        "../flutter_app/assets/images/production_soft_painted/han_sua/",
        import.meta.url,
      ),
    )
  )
    .filter((name) => name.endsWith(".png"))
    .sort();
  const expectedHanSuaAssets = [
    "01_neutral_wavy_v3.png",
    "02_warm_smile_wave_v3.png",
    "03_bright_laugh_v3.png",
    "04_playful_wink_v3.png",
    "05_surprised_v3.png",
    "06_worried_v3.png",
    "07_annoyed_v3.png",
    "08_determined_v3.png",
    "09_explaining_v3.png",
  ];
  const canonicalStoryText = canonical.scenes
    .map(({ chapter, date, location, speaker, direction, line }) =>
      [chapter, date, location, speaker, direction, line].join(" "),
    )
    .join("\n");

  assert.match(editor, /대사 편집기/);
  assert.match(editor, /자동 저장됨/);
  assert.match(editor, /말맛 체크/);
  assert.match(editor, /게임에 즉시 적용/);
  assert.match(editor, /\/api\/dialogue\/build/);
  assert.match(editor, /게임 즉시 적용 완료/);
  assert.match(editor, /화자 선택/);
  assert.match(editor, /표정·동작/);
  assert.match(editor, /이 화자만 표시/);
  assert.match(editor, /새 장면 만들기/);
  assert.match(editor, /기존 장면도 여기서 바로 바꿀 수 있어요/);
  assert.match(editor, /BackgroundPicker/);
  assert.match(editor, /장면 추가/);
  assert.match(editor, /캐릭터 화면 배치/);
  assert.match(editor, /이 장면만/);
  assert.match(editor, /전체 ·/);
  assert.match(editor, /beginCharacterDrag/);
  assert.match(editor, /characterScale/);
  assert.match(editor, /전신/);
  assert.match(editor, /전체 빌드/);
  assert.match(editor, /undoLastChange/);
  assert.match(editor, /redoLastChange/);
  assert.match(editor, /shortcut && key === "z"/);
  assert.match(editor, /수정 전으로 돌아갔어요/);
  assert.match(editor, /characterDragHandle/);
  assert.match(editorCss, /\.characterDragHandle\s*\{/);
  assert.match(editorCss, /pointer-events: none/);
  assert.match(editorCss, /\.transformStudio\s*\{/);
  assert.match(backgroundCatalog, /bg_bank_branch_2000_portrait_cartoon_v2\.png/);
  assert.match(backgroundCatalog, /bg_decimal_trading_floor_dawn_2000_v1\.png/);
  assert.match(editorCss, /\.sceneComposer\s*\{/);
  assert.match(editorCss, /\.backgroundGrid\s*\{/);
  assert.match(editorCss, /\.characterManipulator\s*\{[\s\S]*?bottom: 12\.3%/);
  assert.match(editor, /project-decimal-dialogue-runtime-v2/);
  assert.match(editor, /play\/index\.html\?dialoguePreview=1/);
  assert.doesNotMatch(editor, /window\.location\.hostname/);
  assert.doesNotMatch(editor, /이 장면을 저장하시겠습니까/);
  assert.doesNotMatch(editor, /저장하고 이동/);
  assert.match(editor, /새 장면 .*개 자동 추가/);
  assert.match(editor, /DirectorStudio/);
  assert.match(editor, /SceneToolbox/);
  assert.match(directorStudio, /인물·레이어/);
  assert.match(directorStudio, /카메라·효과/);
  assert.match(directorStudio, /선택지·분기/);
  assert.match(directorStudio, /오디오·메모/);
  assert.match(directorStudio, /setPointerCapture/);
  assert.match(sceneToolbox, /찾아바꾸기/);
  assert.match(sceneToolbox, /버전/);
  assert.match(sceneToolbox, /도달 불가/);
  assert.match(dialogueTypes, /DialogueStageCharacter/);
  assert.match(dialogueTypes, /DialogueChoice/);
  assert.match(onboarding, /_StoryCameraStage/);
  assert.match(onboarding, /_StoryAmbientOverlay/);
  assert.match(onboarding, /_selectChoice/);
  assert.equal(canonical.contentVersion, 3);
  assert.equal(canonical.appearanceVersion, 17);
  assert.deepEqual(hanSuaAssets, expectedHanSuaAssets);
  assert.equal(canonical.scenes.length, 292);
  assert.equal(new Set(canonical.scenes.map((scene) => scene.id)).size, 292);
  let previousSceneDate = 0;
  const referencedAssets = new Set();
  for (const scene of canonical.scenes) {
    for (const field of ["id", "speaker", "line", "character", "background"]) {
      assert.equal(typeof scene[field], "string");
    }
    assert.equal(typeof scene.characterX, "number");
    assert.equal(typeof scene.characterY, "number");
    assert.equal(typeof scene.characterScale, "number");
    assert.ok(scene.characterX >= -60 && scene.characterX <= 60);
    assert.ok(scene.characterY >= -40 && scene.characterY <= 80);
    assert.ok(scene.characterScale >= 0.45 && scene.characterScale <= 1.8);
    assert.ok(scene.line.length <= 6000);
    const dateMatch = scene.date.match(/^(\d{4})(?:\.(\d{2})\.(\d{2}))?/);
    assert.ok(dateMatch, `${scene.id} 날짜를 해석할 수 있어야 합니다.`);
    const sceneDate = Date.UTC(
      Number(dateMatch[1]),
      Number(dateMatch[2] ?? 1) - 1,
      Number(dateMatch[3] ?? 1),
    );
    assert.ok(sceneDate >= previousSceneDate, `${scene.id} 날짜가 역행했습니다.`);
    previousSceneDate = sceneDate;
    for (const asset of [scene.background, scene.character]) {
      if (asset) referencedAssets.add(asset);
    }
  }
  assert.doesNotMatch(canonicalRaw, /왕딱지|단팥빵|첫날이니/);
  await Promise.all(
    [...referencedAssets].map((asset) => {
      assert.match(asset, /^\/play\/assets\/assets\//);
      return access(
        new URL(`../flutter_app/${asset.slice("/play/assets/".length)}`, import.meta.url),
      );
    }),
  );
  assert.equal((data.match(/"id": "decimal-/g) ?? []).length, 292);
  for (const student of [
    "김서아",
    "이지안",
    "최이서",
    "정아린",
    "박하은",
    "오지우",
    "윤채아",
    "한수아",
    "김학준",
    "\\{\\{playerName\\}\\}",
  ]) {
    assert.match(data, new RegExp(`"speaker": "${student}"`));
  }
  for (const [student, type] of [
    ["김서아", "ISFJ"],
    ["이지안", "ISTP"],
    ["최이서", "ISFP"],
    ["정아린", "ESTJ"],
    ["박하은", "ENFJ"],
    ["한수아", "ENFP"],
    ["오지우", "ENTP"],
    ["윤채아", "INTJ"],
  ]) {
    assert.match(mbtiGuide, new RegExp(`${student}.*${type}`));
  }
  assert.match(data, /생활권과 안전/);
  assert.match(data, /수익률보다 중단권/);
  assert.match(data, /외부 감사 기록 분리 보관/);
  assert.match(data, /공동 소유/);
  assert.match(data, /다음엔 먼저 물어볼게/);
  assert.match(data, /생활 내기는 돈·식사·잠자리 금지/);
  assert.match(data, /수면칸/);
  assert.match(data, /사물함/);
  assert.match(data, /50,000원/);
  assert.match(data, /프로젝트 데시멀/);
  assert.match(data, /밥솥/);
  assert.doesNotMatch(
    canonicalStoryText,
    /미래양성원|제6기|SEED|선배|후배|선생님|학생|기숙사/,
  );
  assert.doesNotMatch(data, /단팥빵 얘기 들은 다음부터 계속 배고파/);
  assert.match(data, /bg_decimal_gangnam_exterior_winter_1999_v1\.png/);
  assert.match(editor, /const CONTENT_VERSION = 3/);
  assert.match(editor, /const APPEARANCE_VERSION = 17/);
  assert.equal(data.includes("\\\\n"), false);
  assert.match(data, /character_hakjun_orientation_v2\.png/);
  assert.match(generator, /dialogue-editor-override\.json/);
  assert.match(generator, /loadCanonicalDialogue/);
  assert.doesNotMatch(generator, /_onboardingBeatCount/);
  assert.doesNotMatch(generator, /visual_novel_onboarding\.dart/);
  assert.match(generator, /appearanceVersion !== 17/);
  assert.match(generator, /content 3 \/ appearance 17/);
  assert.match(generator, /Dialogue editor synced/);
  assert.match(validation, /DIALOGUE_MAX_TEXT_LENGTH = 6000/);
  assert.match(validation, /중복 장면 ID/);
  assert.match(buildScript, /renameWithRetry/);
  assert.match(validation, /CHARACTER_SCALE_MIN = 0\.45/);
  assert.match(validation, /characterX/);
  assert.match(validation, /characterScale/);
  assert.doesNotMatch(buildScript, /syncDirectoryContents/);
  const protagonistCatalog = catalog.slice(
    catalog.indexOf("const protagonistPoses"),
    catalog.indexOf("const teacherPoses"),
  );
  const teacherCatalog = catalog.slice(
    catalog.indexOf("const teacherPoses"),
    catalog.indexOf("const suaPoses"),
  );
  const suaCatalog = catalog.slice(
    catalog.indexOf("const suaPoses"),
    catalog.indexOf("const kimSeoaPoses"),
  );
  assert.equal((protagonistCatalog.match(/\.png/g) ?? []).length, 24);
  assert.equal((teacherCatalog.match(/\.png/g) ?? []).length, 6);
  assert.equal((suaCatalog.match(/\.png/g) ?? []).length, 9);
  for (const asset of expectedHanSuaAssets) {
    assert.ok(suaCatalog.includes(asset), asset);
  }
  assert.doesNotMatch(suaCatalog, /quality_v2/);
  assert.match(catalog, /speaker: "\{\{playerName\}\}"/);
  assert.match(packageJson, /prebuild:flutter-web/);
  assert.match(packageJson, /dialogue:sync/);
  assert.match(buildRoute, /dialogue-editor-override\.json/);
  assert.match(buildRoute, /appearanceVersion: 17/);
  assert.match(buildRoute, /validateDialogueScenes/);
  assert.match(buildRoute, /DIALOGUE_BUILD_TOKEN/);
  assert.match(buildRoute, /requiresToken:\s*true/);
  assert.doesNotMatch(
    buildRoute,
    /if\s*\(requestIsLoopback\(request\)\)\s*return true/,
  );
  assert.match(buildRoute, /DIALOGUE_BUILD_ENABLED\s*===\s*["']1["']/);
  assert.match(buildRoute, /sha256/);
  assert.match(buildRoute, /backups/);
  assert.match(catalog, /production_soft_painted\/park_haeun/);
  assert.match(catalog, /production_soft_painted\/yoon_chaea/);
  assert.match(buildRoute, /mode === "quick"/);
  assert.match(buildRoute, /copyFile\(assetPath, runtimeDialoguePath\)/);
  assert.match(buildRoute, /새 에셋은 전체 빌드가 필요합니다/);
  assert.match(buildRoute, /encodeURI\(asset\.slice\("\/play\/"\.length\)\)/);
  assert.match(buildRoute, /persistDialogue\(validation\.scenes, mode\)/);
  assert.match(catalog, /production_soft_painted\/han_sua/);
  assert.match(catalog, /production_soft_painted\/kim_seoa/);
  assert.match(catalog, /production_soft_painted\/lee_jian/);
  assert.match(catalog, /production_soft_painted\/choi_iseo/);
  assert.match(catalog, /production_soft_painted\/oh_jiwoo/);
  assert.match(catalog, /speaker: "윤채아"[\s\S]*?poses: yoonChaeaPoses/);
  assert.match(catalog, /speaker: "김서아"[\s\S]*?poses: kimSeoaPoses/);
  assert.match(catalog, /speaker: "이지안"[\s\S]*?poses: leeJianPoses/);
  assert.match(catalog, /speaker: "최이서"[\s\S]*?poses: choiIseoPoses/);
  assert.match(catalog, /speaker: "오지우"[\s\S]*?poses: ohJiwooPoses/);
  assert.match(
    catalog,
    /const parkHaeunPoses[\s\S]*09_explaining_v2\.png[\s\S]*production_soft_painted\/park_haeun/,
  );
  assert.match(data, /park_haeun\/02_bright_smile_wave_v2\.png/);
  assert.match(data, /yoon_chaea\/09_explaining_v1\.png/);
  assert.match(data, /kim_seoa\/01_neutral_notebook_v1\.png/);
  assert.match(data, /lee_jian\/09_explaining_mechanism_v2\.png/);
  assert.match(data, /choi_iseo\/08_focused_mending_v1\.png/);
  assert.match(data, /oh_jiwoo\/09_explaining_report_v1\.png/);
  assert.match(data, /han_sua\/03_bright_laugh_v3\.png/);
  assert.doesNotMatch(data, /han_sua\/[^"]*quality_v2\.png/);
  for (const [legacy, current] of [
    ["01_neutral_quality_v2.png", "01_neutral_wavy_v3.png"],
    ["02_warm_smile_quality_v2.png", "02_warm_smile_wave_v3.png"],
    ["03_bright_laugh_quality_v2.png", "03_bright_laugh_v3.png"],
    ["04_surprised_quality_v2.png", "05_surprised_v3.png"],
    ["05_worried_quality_v2.png", "06_worried_v3.png"],
    ["06_annoyed_quality_v2.png", "07_annoyed_v3.png"],
    ["07_determined_quality_v2.png", "08_determined_v3.png"],
    ["08_explaining_quality_v2.png", "09_explaining_v3.png"],
  ]) {
    assert.ok(editor.includes(`"${legacy}": "${current}"`), legacy);
    assert.ok(onboarding.includes(`'${legacy}': '${current}'`), legacy);
  }
  assert.match(editor, /character: migrateHanSuaCharacterAsset\(scene\.character\)/);
  assert.match(onboarding, /_migrateHanSuaCharacterAsset\(normalized\)/);
  assert.match(buildRoute, /persistDialogue\(validation\.scenes, mode\)/);
  assert.match(buildRoute, /scripts\/build-flutter-web\.mjs/);
  assert.match(onboarding, /_dialogueBundleAsset/);
  assert.match(onboarding, /_dialogueAppearanceVersion = 17/);
  assert.match(onboarding, /_mergeCurrentAppearance/);
  assert.match(onboarding, /rootBundle\.loadString/);
  assert.match(
    onboarding,
    /injectedRaw == null && widget\.allowRuntimeDialoguePreview/,
  );
  assert.match(onboarding, /characterX/);
  assert.match(onboarding, /characterScale/);
  assert.match(onboarding, /Transform\.translate/);
  assert.doesNotMatch(onboarding, /switch \(_beat\)/);
  assert.doesNotMatch(onboarding, /왕딱지|단팥빵|첫날이니/);
  assert.match(onboarding, /character: asset\('character'\)/);
  assert.match(onboarding, /background: asset\('background'\)/);
  assert.match(onboarding, /_dialogueEndBeat = loaded\.keys\.reduce\(math\.max\)/);
  assert.match(onboarding, /_storyCharacterBottomInset = -280\.0/);
  assert.match(onboarding, /_storyDialogueBottomInset = 28\.0/);
  assert.match(onboarding, /_storyCharacterSceneScale = 2\.0/);
  assert.doesNotMatch(onboarding, /story-crt-scanline/);
  assert.doesNotMatch(onboarding, /orientation-dust-motes/);
  assert.doesNotMatch(onboarding, /_minhoCharacterScale|character_minho_farewell/);
  assert.doesNotMatch(onboarding, /왼쪽으로 움직여 대화창 배경을 더 투명하게 조절/);
  assert.match(pubspec, /assets\/dialogue\//);
});
