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
  assert.match(html, /id="company-name"/);
  assert.match(html, /회사 설립하기/);
  assert.match(html, /disabled/);
  assert.doesNotMatch(html, /투자할 회사를 고르세요/);
  assert.doesNotMatch(html, /codex-preview|react-loading-skeleton|Your site is taking shape/);
});

test("ships a complete 2000-2010 market snapshot", async () => {
  const data = JSON.parse(await readFile(new URL("../app/data/market-history.json", import.meta.url), "utf8"));
  assert.equal(data.period.start, "2000-01");
  assert.equal(data.period.end, "2010-12");
  assert.equal(data.assets.length, 9);

  for (const asset of data.assets) {
    const gameMonths = Object.keys(asset.prices).filter((month) => month >= "2000-01" && month <= "2010-12");
    assert.equal(gameMonths.length, 132, `${asset.symbol} should have 132 monthly observations`);
    assert.ok(Number.isFinite(asset.prices["2000-01"]));
    assert.ok(Number.isFinite(asset.prices["2010-12"]));
  }
});

test("documents and preserves the portrait-mobile product contract", async () => {
  const [rules, guide, css, game] = await Promise.all([
    readFile(new URL("../AGENTS.md", import.meta.url), "utf8"),
    readFile(new URL("../PROJECT_GUIDE.md", import.meta.url), "utf8"),
    readFile(new URL("../app/globals.css", import.meta.url), "utf8"),
    readFile(new URL("../app/game-client.tsx", import.meta.url), "utf8"),
  ]);

  assert.match(rules, /390×844px/);
  assert.match(rules, /최소 360px/);
  assert.match(guide, /첫 방문 시 회사 이름 입력 화면/);
  assert.match(css, /env\(safe-area-inset-bottom\)/);
  assert.match(game, /companyName: string/);
  assert.match(game, /maxLength=\{24\}/);
  assert.match(game, /simul-millennium-capital-v1/);
});
