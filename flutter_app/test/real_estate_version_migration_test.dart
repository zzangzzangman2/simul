import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/game_engine.dart';
import 'package:millennium_capital/game/personal_finance_state.dart';
import 'package:millennium_capital/game/real_estate_market.dart';
import 'package:millennium_capital/game/real_estate_world.dart';

void main() {
  test('owned property without a generator version restores legacy v1', () {
    const seed = 'legacy-real-estate-version';
    final asset = realEstateMarketAssetById('uijeongbu_station_officetel_20')!;
    final legacyListing = realEstateListingsFor(
      asset,
      seed,
      generatorVersion: 1,
    ).first;
    final original = OwnedRealEstate(
      id: 'legacy-owned',
      optionId: legacyListing.optionId,
      name: legacyListing.displayName,
      purchasePrice: legacyListing.priceAt(DateTime(2015, 6)),
      acquiredDay: 1,
      monthlyIncome: legacyListing.monthlyRentAt(DateTime(2015, 6)),
      monthlyCost: legacyListing.monthlyOperatingCostAt(DateTime(2015, 6)),
      marketAssetId: asset.id,
      marketListingIndex: legacyListing.index,
      realEstateWorldSeed: seed,
      purchaseDateIso: DateTime(2015, 6).toIso8601String(),
    );
    final legacyJson = original.toJson()..remove('realEstateWorldVersion');

    final restored = OwnedRealEstate.fromJson(legacyJson);

    expect(restored.realEstateWorldVersion, 1);
    expect(restored.generatedListing, isNotNull);
    expect(restored.generatedListing!.generatorVersion, 1);
    expect(
      restored.generatedListing!.priceAt(DateTime(2020, 6)),
      legacyListing.priceAt(DateTime(2020, 6)),
    );
  });

  test('new purchase pins the current real-estate generator version', () {
    const engine = GameEngine();
    final base = engine
        .createNewGame(
          '부동산 버전 테스트',
          initialCash: 1000000000,
          worldSeed: 'new-real-estate-version',
        )
        .copyWith(brokerageCash: 0, decisions: const []);
    final targetDate = DateTime(2015, 6, 15);
    final state = base.copyWith(
      day: targetDate.difference(base.campaignStartDate).inDays + 1,
    );
    final asset = realEstateMarketAssetById('uijeongbu_station_officetel_20')!;
    final listing = realEstateActiveListingsAt(
      asset,
      state.simulationSeed,
      state.currentDate,
    ).first;

    final result = engine.purchaseSpendingOption(state, listing.optionId);

    expect(result.success, isTrue, reason: result.message);
    final owned = result.state.personalFinance.realEstate.single;
    expect(owned.realEstateWorldVersion, realEstateWorldGeneratorVersion);
    expect(
      OwnedRealEstate.fromJson(owned.toJson()).realEstateWorldVersion,
      realEstateWorldGeneratorVersion,
    );
    expect(
      owned.generatedListing!.generatorVersion,
      realEstateWorldGeneratorVersion,
    );
  });
}
