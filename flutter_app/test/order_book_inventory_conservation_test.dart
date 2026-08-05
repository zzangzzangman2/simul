import 'package:flutter_test/flutter_test.dart';
import 'package:millennium_capital/game/order_book.dart';

void main() {
  const outstanding = 1000000;

  GameOrderBookSnapshot snapshot({
    required int day,
    required double owned,
    double tenderOwned = 0,
  }) => buildGameOrderBookSnapshot(
    assetId: 'inventory_audit_stock',
    day: day,
    minute: 600,
    currentPrice: 10000,
    previousClose: 10000,
    date: DateTime(2000, 1, 3),
    market: 'KSE',
    simulationSeed: 'inventory-conservation-test',
    sharesOutstanding: outstanding,
    playerOwnedUnits: owned,
    playerTenderAcquiredUnits: tenderOwned,
  );

  test(
    'player, external float, and locked holders always conserve issuance',
    () {
      for (final ownership in const <double>[
        0,
        1,
        200000,
        510000,
        999000,
        1000000,
      ]) {
        final profile = gameMarketInventoryProfile(
          assetId: 'inventory_audit_stock',
          day: 12,
          referencePrice: 10000,
          simulationSeed: 'inventory-conservation-test',
          sharesOutstanding: outstanding,
          playerOwnedUnits: ownership,
          playerTenderAcquiredUnits: ownership >= 510000 ? 310000 : 0,
        );

        expect(profile.hasIssuedShareLedger, isTrue);
        expect(profile.conservedShares, outstanding);
        expect(profile.nonPlayerTradableShares, greaterThanOrEqualTo(0));
        expect(profile.nonPlayerLockedShares, greaterThanOrEqualTo(0));
        expect(
          profile.playerTenderAcquiredShares,
          lessThanOrEqualTo(profile.playerOwnedShares),
        );
        expect(profile.maximumQuoteQuantity, 50000);
      }
    },
  );

  test(
    '100 percent ownership removes synthetic asks but preserves funded bids',
    () {
      final book = snapshot(day: 1, owned: outstanding.toDouble());

      expect(book.ownershipIsConserved, isTrue);
      expect(book.nonPlayerTradableShares, 0);
      expect(book.asks, isEmpty);
      expect(book.totalAskQuantity, 0);
      expect(book.bids, isNotEmpty);
      expect(
        book.totalBidQuantity,
        lessThanOrEqualTo(book.visibleBidDemandLimit),
      );
      expect(book.externalBidCash, greaterThan(0));
      final displayedBidNotional = book.bids.fold<double>(
        0,
        (sum, level) => sum + level.price * level.quantity,
      );
      expect(displayedBidNotional, lessThanOrEqualTo(book.externalBidCash));
    },
  );

  test('visible asks never exceed remaining external tradable inventory', () {
    for (final ownership in const <double>[0, 200000, 510000, 900000, 999000]) {
      final book = snapshot(
        day: 17,
        owned: ownership,
        tenderOwned: ownership >= 510000 ? 310000 : 0,
      );

      expect(book.ownershipIsConserved, isTrue);
      expect(
        book.totalAskQuantity,
        lessThanOrEqualTo(book.nonPlayerTradableShares),
      );
      expect(
        book.totalAskQuantity,
        lessThanOrEqualTo(book.visibleAskSupplyLimit),
      );
      for (final level in <GameOrderBookLevel>[...book.asks, ...book.bids]) {
        expect(level.quantity, lessThanOrEqualTo(outstanding));
      }
    }
  });

  test(
    'bid and ask walls are independently imbalanced rather than mirrored',
    () {
      var unequalDays = 0;
      var bidHeavyDays = 0;
      var askHeavyDays = 0;
      for (var day = 1; day <= 120; day += 1) {
        final book = snapshot(day: day, owned: 100000);
        if (book.totalBidQuantity != book.totalAskQuantity) unequalDays += 1;
        if (book.totalBidQuantity > book.totalAskQuantity) bidHeavyDays += 1;
        if (book.totalAskQuantity > book.totalBidQuantity) askHeavyDays += 1;
      }

      expect(unequalDays, greaterThan(100));
      expect(bidHeavyDays + askHeavyDays, unequalDays);
      expect(bidHeavyDays, greaterThan(0));
      expect(askHeavyDays, greaterThan(0));
    },
  );

  test(
    'one regular order follows the 5 percent or 100 million share ceiling',
    () {
      expect(gameMaximumQuoteQuantity(1000), 50);
      expect(gameMaximumQuoteQuantity(1000000), 50000);
      expect(gameMaximumQuoteQuantity(5000000000), 100000000);
    },
  );
}
