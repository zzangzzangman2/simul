part of 'market_data.dart';

/// 한국 주식시장 2000~2026 타임라인에서 실명·기사·지수값을 제거하고
/// 사건 반응과 거래일 변동 분포만 양자화한 가상시장 보정 자료다.
/// 원본 SHA-256: d5bff9afc0b7afa1f00453a6df67f6e5ef54c04ad42ded2eef16dd7ce753fd6e
class FictionalCorpusEventPattern {
  const FictionalCorpusEventPattern({
    required this.id,
    required this.sourceYear,
    required this.channel,
    required this.confidence,
    required this.largeDailyBps,
    required this.growthDailyBps,
    required this.large5Bps,
    required this.growth5Bps,
    required this.large20Bps,
    required this.growth20Bps,
    required this.large60Bps,
    required this.growth60Bps,
  });

  final String id;
  final int sourceYear;
  final String channel;
  final int confidence;
  final int largeDailyBps;
  final int growthDailyBps;
  final int large5Bps;
  final int growth5Bps;
  final int large20Bps;
  final int growth20Bps;
  final int large60Bps;
  final int growth60Bps;
}

const fictionalCorpusSourceSha256 =
    'd5bff9afc0b7afa1f00453a6df67f6e5ef54c04ad42ded2eef16dd7ce753fd6e';
const fictionalCorpusSourceEventCount = 439;
const fictionalCorpusSourceShockDayCount = 975;
const fictionalCorpusSourceTradingDayCount = 6545;
