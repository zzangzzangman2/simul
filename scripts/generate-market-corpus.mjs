import { createHash } from "node:crypto";
import { readFileSync, writeFileSync } from "node:fs";

const [sourcePath, outputPath, calendarOutputPath] = process.argv.slice(2);
if (!sourcePath || !outputPath) {
  throw new Error(
    "Usage: node generate-market-corpus.mjs <timeline.txt> <output.dart> [calendar.dart]",
  );
}

const raw = readFileSync(sourcePath, "utf8").replace(/^\uFEFF/, "");
const lines = raw.split(/\r?\n/);
const checksum = createHash("sha256").update(raw).digest("hex");

function percent(line, label) {
  const escaped = label.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const match = line.match(
    new RegExp(`${escaped}\\s+([+-]?\\d+(?:\\.\\d+)?)%`),
  );
  return match ? Math.round(Number(match[1]) * 100) : 0;
}

function channelFor(category) {
  if (/감염병|보건/.test(category)) return "pandemic";
  if (/자연재해|재난|기후/.test(category)) return "disaster";
  if (/원자재|유가|에너지/.test(category)) return "commodity";
  if (/반도체|기술|바이오/.test(category)) return "technology";
  if (/통화정책|금리/.test(category)) return "rates";
  if (/외환|환율/.test(category)) return "currency";
  if (/신용|금융|재정|부동산|카드/.test(category)) return "credit";
  if (/무역|중국|신흥시장|공급망/.test(category)) return "trade";
  if (/공매도|시장|국내증시|제도|수급/.test(category)) {
    return "market_structure";
  }
  if (/기업|회계|구조조정|지배구조/.test(category)) return "corporate";
  if (/환경/.test(category)) return "environment";
  if (/남북|군사|핵|미사일|지정학|전쟁|정치|테러/.test(category)) {
    return "geopolitics";
  }
  return "demand";
}

const events = [];
for (let index = 0; index < lines.length; index += 1) {
  const header = lines[index].match(
    /^(EVT-\d+) \| 발생 (\d{4})-\d{2}-\d{2} .* \| \[([^\]]+)\] \| 신뢰도 ([ABC])/,
  );
  if (!header) continue;
  const kospi = lines[index + 4] ?? "";
  const kosdaq = lines[index + 5] ?? "";
  if (!kospi.startsWith("KOSPI:") || !kosdaq.startsWith("KOSDAQ:")) {
    throw new Error(`Unexpected event record layout at ${header[1]}`);
  }
  events.push({
    id: header[1].toLowerCase(),
    sourceYear: Number(header[2]),
    channel: channelFor(header[3]),
    confidence: { A: 3, B: 2, C: 1 }[header[4]],
    largeDailyBps: percent(kospi, "당일"),
    growthDailyBps: percent(kosdaq, "당일"),
    large5Bps: percent(kospi, "향후5일"),
    growth5Bps: percent(kosdaq, "향후5일"),
    large20Bps: percent(kospi, "향후20일"),
    growth20Bps: percent(kosdaq, "향후20일"),
    large60Bps: percent(kospi, "향후60일"),
    growth60Bps: percent(kosdaq, "향후60일"),
  });
}

const daily = [];
const dailyDates = [];
for (let index = 0; index < lines.length; index += 1) {
  const dailyHeader = lines[index].match(/^DAY (\d{4}-\d{2}-\d{2}) \|/);
  if (!dailyHeader) continue;
  const kospi = lines[index + 1] ?? "";
  const kosdaq = lines[index + 2] ?? "";
  if (!kospi.startsWith("  KOSPI ") || !kosdaq.startsWith("  KOSDAQ ")) {
    throw new Error(`Unexpected daily record layout at ${lines[index]}`);
  }
  daily.push([
    percent(kospi, "D1"),
    percent(kosdaq, "D1"),
    percent(kospi, "고저폭"),
    percent(kosdaq, "고저폭"),
    percent(kospi, "갭"),
    percent(kosdaq, "갭"),
    percent(kospi, "20D변동성"),
    percent(kosdaq, "20D변동성"),
  ]);
  dailyDates.push(dailyHeader[1]);
}

if (events.length !== 439 || daily.length !== 6545) {
  throw new Error(
    `Corpus count mismatch: events=${events.length}, daily=${daily.length}`,
  );
}

const output = [];
output.push("part of 'market_data.dart';");
output.push("");
output.push(
  "/// 한국 주식시장 2000~2026 타임라인에서 실명·기사·지수값을 제거하고",
);
output.push(
  "/// 사건 반응과 거래일 변동 분포만 양자화한 가상시장 보정 자료다.",
);
output.push(`/// 원본 SHA-256: ${checksum}`);
output.push("class FictionalCorpusEventPattern {");
output.push("  const FictionalCorpusEventPattern({");
output.push("    required this.id,");
output.push("    required this.sourceYear,");
output.push("    required this.channel,");
output.push("    required this.confidence,");
output.push("    required this.largeDailyBps,");
output.push("    required this.growthDailyBps,");
output.push("    required this.large5Bps,");
output.push("    required this.growth5Bps,");
output.push("    required this.large20Bps,");
output.push("    required this.growth20Bps,");
output.push("    required this.large60Bps,");
output.push("    required this.growth60Bps,");
output.push("  });");
output.push("");
output.push("  final String id;");
output.push("  final int sourceYear;");
output.push("  final String channel;");
output.push("  final int confidence;");
output.push("  final int largeDailyBps;");
output.push("  final int growthDailyBps;");
output.push("  final int large5Bps;");
output.push("  final int growth5Bps;");
output.push("  final int large20Bps;");
output.push("  final int growth20Bps;");
output.push("  final int large60Bps;");
output.push("  final int growth60Bps;");
output.push("}");
output.push("");
output.push(
  `const fictionalCorpusSourceSha256 = '${checksum}';`,
);
output.push(
  `const fictionalCorpusSourceEventCount = ${events.length};`,
);
output.push(
  "const fictionalCorpusSourceShockDayCount = 975;",
);
output.push(
  `const fictionalCorpusSourceTradingDayCount = ${daily.length};`,
);
output.push("");
output.push(
  "const fictionalCorpusEventPatterns = <FictionalCorpusEventPattern>[",
);
for (const event of events) {
  output.push("  FictionalCorpusEventPattern(");
  output.push(`    id: '${event.id}',`);
  output.push(`    sourceYear: ${event.sourceYear},`);
  output.push(`    channel: '${event.channel}',`);
  output.push(`    confidence: ${event.confidence},`);
  output.push(`    largeDailyBps: ${event.largeDailyBps},`);
  output.push(`    growthDailyBps: ${event.growthDailyBps},`);
  output.push(`    large5Bps: ${event.large5Bps},`);
  output.push(`    growth5Bps: ${event.growth5Bps},`);
  output.push(`    large20Bps: ${event.large20Bps},`);
  output.push(`    growth20Bps: ${event.growth20Bps},`);
  output.push(`    large60Bps: ${event.large60Bps},`);
  output.push(`    growth60Bps: ${event.growth60Bps},`);
  output.push("  ),");
}
output.push("];");
output.push("");
output.push("const fictionalCorpusDailySampleStride = 8;");
output.push("const fictionalCorpusDailySamples = <int>[");
for (const sample of daily) {
  output.push(`  ${sample.join(", ")},`);
}
output.push("];");
output.push("");

writeFileSync(outputPath, `${output.join("\n")}\n`, "utf8");

if (calendarOutputPath) {
  const calendar = [
    "/// 한국 주식시장 타임라인의 실제 거래일 날짜만 분리한 달력이다.",
    "/// 종목명·기사·지수값은 포함하지 않는다.",
    `/// 원본 SHA-256: ${checksum}`,
    `const fictionalCorpusFirstTradingDate = '${dailyDates[0]}';`,
    `const fictionalCorpusLastTradingDate = '${dailyDates.at(-1)}';`,
    "",
    "const fictionalCorpusTradingDateKeys = <String>{",
    ...dailyDates.map((date) => `  '${date}',`),
    "};",
    "",
  ];
  writeFileSync(calendarOutputPath, calendar.join("\n"), "utf8");
}

console.log(
  JSON.stringify(
    {
      checksum,
      events: events.length,
      dailySamples: daily.length,
      outputPath,
      calendarOutputPath: calendarOutputPath ?? null,
    },
    null,
    2,
  ),
);
