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

test("server-renders the investment simulation shell", async () => {
  const response = await render();
  assert.equal(response.status, 200);
  assert.match(response.headers.get("content-type") ?? "", /^text\/html\b/i);

  const html = await response.text();
  assert.match(html, /<title>MILLENNIUM CAPITAL/);
  assert.match(html, /2000\.01\.01/);
  assert.match(html, /시장을 읽고/);
  assert.match(html, /한 달 진행/);
  assert.match(html, /삼성전자/);
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
