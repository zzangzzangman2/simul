import 'game_state.dart';
import 'market_data.dart';
import 'real_estate_world.dart';
import 'world_economy.dart';

class WorldLoadProgress {
  const WorldLoadProgress(this.fraction, this.label)
    : assert(fraction >= 0 && fraction <= 1);

  final double fraction;
  final String label;
}

typedef WorldLoadProgressCallback = void Function(WorldLoadProgress progress);
typedef CampaignWorldPreparer =
    Future<void> Function(
      GameState state,
      WorldLoadProgressCallback onProgress,
    );

/// Moves deterministic campaign generation to the loading boundary.
///
/// The full market timeline stays private in the cache. Gameplay screens still
/// request dated views, so prewarming cannot reveal future listings, prices,
/// financials, relations, or corporate actions.
Future<void> prepareCampaignWorld(
  GameState state,
  WorldLoadProgressCallback onProgress,
) async {
  onProgress(
    const WorldLoadProgress(0.16, '2000~2026 기업·상장·주식시장 연표를 구성 중입니다…'),
  );
  await Future<void>.delayed(Duration.zero);
  await FictionalMarketUniverse.prewarmCampaign(seed: state.simulationSeed);

  onProgress(const WorldLoadProgress(0.82, '서울·경기 부동산 매물과 지역 사건을 구성 중입니다…'));
  await Future<void>.delayed(Duration.zero);
  final realEstate = prewarmFictionalRealEstateWorld(state.simulationSeed);
  if (realEstate.listingCount <= 0 || realEstate.eventCount <= 0) {
    throw StateError('The real-estate campaign world is empty');
  }

  onProgress(const WorldLoadProgress(0.90, '주식·부동산·동네상권의 공통 경제 사건을 연결 중입니다…'));
  await Future<void>.delayed(Duration.zero);
  final economy = worldEconomySnapshot(
    worldSeed: state.simulationSeed,
    asOf: state.currentDate,
  );
  if (economy.revealedEvents.any(
    (event) => event.revealedOn.isAfter(state.currentDate),
  )) {
    throw StateError('The shared economy view leaked a future event');
  }

  onProgress(const WorldLoadProgress(0.94, '현재 날짜의 공개 정보만 보이는지 확인 중입니다…'));
  await Future<void>.delayed(Duration.zero);
  final currentView = await FictionalMarketUniverse.load(
    seed: state.simulationSeed,
    throughDate: state.currentDate,
  );
  if (currentView.assets.isEmpty) {
    throw StateError('The current market view is empty');
  }

  onProgress(const WorldLoadProgress(0.96, '세계관 구성이 완료되었습니다.'));
}
