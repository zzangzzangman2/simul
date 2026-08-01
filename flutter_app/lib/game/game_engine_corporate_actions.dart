part of 'game_engine.dart';

extension GameEngineCorporateActions on GameEngine {
  GameState applyCorporateActions(
    GameState state,
    List<MarketCorporateAction> actions,
  ) {
    var cash = state.cash;
    var brokerageCash = state.brokerageCash;
    var positions = [...state.positions];
    var pendingOrders = [...state.pendingOrders];
    final ledger = [...state.ledger];
    final processed = {...state.processedEventIds};
    var changed = false;
    final dateKey = state.currentDate.toIso8601String().split('T').first;

    final orderedActions = [...actions]
      ..sort((left, right) {
        final typeOrder = marketCorporateActionOrder(
          left.type,
        ).compareTo(marketCorporateActionOrder(right.type));
        if (typeOrder != 0) return typeOrder;
        return left.id.compareTo(right.id);
      });
    for (final action in orderedActions) {
      final eventId = 'market-action-${action.id}';
      if (action.date != dateKey || processed.contains(eventId)) continue;
      final canceledOrders = pendingOrders
          .where((order) => order.assetId == action.assetId)
          .toList(growable: false);
      if (canceledOrders.isNotEmpty) {
        final canceledIds = canceledOrders.map((order) => order.id).toSet();
        pendingOrders = pendingOrders
            .where((order) => !canceledIds.contains(order.id))
            .toList(growable: false);
        for (final order in canceledOrders) {
          ledger.add(
            LedgerEntry(
              id: '$eventId-cancel-${order.id}',
              day: state.day,
              amount: 0,
              account: 'brokerage_order',
              counterAccount: 'corporate_action_cancel',
              description:
                  '${order.name} ${_tradeUnits(order.remainingQuantity)}주 '
                  '미체결 주문 · 기업행동으로 자동 취소',
              sourceId: '$eventId-cancel-${order.id}',
              assetId: order.assetId,
              tradeSide: order.side.name,
              marketMinute: state.marketMinute,
              orderType: TradeOrderType.limit.name,
            ),
          );
        }
        changed = true;
      }
      final index = positions.indexWhere(
        (position) => position.assetId == action.assetId,
      );
      final position = index < 0 ? null : positions[index];
      if (position != null && action.type == MarketCorporateActionType.split) {
        final nextUnits = position.units * action.unitFactor;
        if (nextUnits.isFinite && nextUnits > 0) {
          positions[index] = position.copyWith(units: nextUnits);
          ledger.add(
            LedgerEntry(
              id: eventId,
              day: state.day,
              amount: 0,
              account: 'market_security',
              counterAccount: 'corporate_action',
              description:
                  '${position.name} 주식수 조정 · ${action.numerator}:${action.denominator}',
              sourceId: eventId,
            ),
          );
          changed = true;
        }
      } else if (position != null &&
          action.type == MarketCorporateActionType.dividend &&
          action.currency == 'KRW') {
        final grossDividend = (position.units * action.amount).round();
        if (grossDividend > 0) {
          final withholdingTax =
              (grossDividend * gameDividendWithholdingTaxRate).round();
          final netDividend = grossDividend - withholdingTax;
          cash += netDividend;
          brokerageCash += netDividend;
          ledger.add(
            LedgerEntry(
              id: eventId,
              day: state.day,
              amount: grossDividend,
              account: 'brokerage_cash',
              counterAccount: 'dividend_income',
              description: '${position.name} 배당금(세전)',
              sourceId: eventId,
            ),
          );
          if (withholdingTax > 0) {
            ledger.add(
              LedgerEntry(
                id: '$eventId-tax',
                day: state.day,
                amount: -withholdingTax,
                account: 'brokerage_cash',
                counterAccount: 'dividend_withholding_tax',
                description: '${position.name} 배당소득세 원천징수',
                sourceId: '$eventId-tax',
              ),
            );
          }
          changed = true;
        }
      } else if (position != null &&
          action.type == MarketCorporateActionType.spinoff &&
          action.relatedAssetId != null &&
          action.relatedSymbol != null &&
          action.relatedName != null &&
          action.relatedMarket != null) {
        final grantedUnits = position.units * action.unitFactor;
        if (grantedUnits.isFinite && grantedUnits > 0) {
          final detachedValue = action.unitFactor * action.amount;
          final referencePrice = action.referencePrice;
          final allocationWeight =
              (referencePrice != null &&
                          referencePrice.isFinite &&
                          referencePrice > 0 &&
                          detachedValue.isFinite &&
                          detachedValue >= 0
                      ? (detachedValue / referencePrice).clamp(0.0, 1.0)
                      : (action.unitFactor / (1 + action.unitFactor)).clamp(
                          0.0,
                          1.0,
                        ))
                  .toDouble();
          final grantedCost = math.min(
            position.totalCost,
            math.max(0, (position.totalCost * allocationWeight).round()),
          );
          positions[index] = position.copyWith(
            totalCost: position.totalCost - grantedCost,
          );
          final relatedIndex = positions.indexWhere(
            (item) => item.assetId == action.relatedAssetId,
          );
          if (relatedIndex >= 0) {
            positions[relatedIndex] = positions[relatedIndex].copyWith(
              units: positions[relatedIndex].units + grantedUnits,
              totalCost: positions[relatedIndex].totalCost + grantedCost,
            );
          } else {
            positions.add(
              PortfolioPosition(
                assetId: action.relatedAssetId!,
                symbol: action.relatedSymbol!,
                name: action.relatedName!,
                market: action.relatedMarket!,
                currency: action.currency,
                units: grantedUnits,
                totalCost: grantedCost,
              ),
            );
          }
          ledger.add(
            LedgerEntry(
              id: eventId,
              day: state.day,
              amount: 0,
              account: 'market_security',
              counterAccount: 'corporate_spinoff',
              description:
                  '${position.name} 분사 · ${action.relatedName} ${_tradeUnits(grantedUnits)}주 배정',
              sourceId: eventId,
            ),
          );
          changed = true;
        }
      } else if (position != null &&
          action.type == MarketCorporateActionType.materialSpinoff) {
        ledger.add(
          LedgerEntry(
            id: eventId,
            day: state.day,
            amount: 0,
            account: 'market_security',
            counterAccount: 'corporate_material_spinoff',
            description: '${position.name} 물적분할 · 신설법인 지분은 모회사가 보유',
            sourceId: eventId,
          ),
        );
        changed = true;
      } else if (position != null &&
          action.type == MarketCorporateActionType.rightsIssue) {
        final dilutionPct = action.ownershipDilutionRate * 100;
        final isShareholderAllocation =
            action.allocationMethod ==
            MarketRightsIssueAllocationMethod.shareholder;
        final prefersSubscription =
            state.story.storyFlags[marketRightsIssuePreferenceFlag] ==
            marketRightsIssueSubscribePreference;
        final subscriptionUnits = position.units * action.rightsIssueRate;
        final subscriptionCost = (subscriptionUnits * action.amount).round();
        final availableForSubscription = state
            .copyWith(
              brokerageCash: brokerageCash,
              pendingOrders: pendingOrders,
            )
            .availableBrokerageCash;
        final hasExecutableSubscription =
            isShareholderAllocation &&
            prefersSubscription &&
            action.currency == position.currency &&
            subscriptionUnits.isFinite &&
            subscriptionUnits > 0 &&
            subscriptionCost > 0;

        if (hasExecutableSubscription &&
            subscriptionCost <= availableForSubscription) {
          cash -= subscriptionCost;
          brokerageCash -= subscriptionCost;
          positions[index] = position.copyWith(
            units: position.units + subscriptionUnits,
            totalCost: position.totalCost + subscriptionCost,
          );
          ledger.add(
            LedgerEntry(
              id: eventId,
              day: state.day,
              amount: -subscriptionCost,
              account: 'brokerage_cash',
              counterAccount: 'corporate_rights_subscription',
              description:
                  '${position.name} 주주배정 유상증자 청약 · '
                  '${_tradeUnits(subscriptionUnits)}주 배정 · '
                  '청약대금 $subscriptionCost원',
              sourceId: eventId,
              notional: subscriptionCost,
              assetId: action.assetId,
            ),
          );
          changed = true;
        } else {
          final theoreticalExRightsPrice = action.theoreticalExRightsPrice;
          final rightsValuePerShare =
              isShareholderAllocation &&
                  action.referencePrice != null &&
                  theoreticalExRightsPrice != null
              ? math.max(0, action.referencePrice! - theoreticalExRightsPrice)
              : 0.0;
          final rightsSaleProceeds = (position.units * rightsValuePerShare)
              .round();
          if (rightsSaleProceeds > 0) {
            cash += rightsSaleProceeds;
            brokerageCash += rightsSaleProceeds;
          }
          final subscriptionFallback =
              hasExecutableSubscription &&
              subscriptionCost > availableForSubscription;
          ledger.add(
            LedgerEntry(
              id: eventId,
              day: state.day,
              amount: rightsSaleProceeds,
              account: rightsSaleProceeds > 0
                  ? 'brokerage_cash'
                  : 'market_security',
              counterAccount: isShareholderAllocation
                  ? 'corporate_rights_sale'
                  : 'corporate_rights_issue',
              description: isShareholderAllocation
                  ? '${position.name} 주주배정 유상증자 · '
                        '${subscriptionFallback ? '청약대금 부족으로 ' : ''}'
                        '신주인수권 자동매각 $rightsSaleProceeds원 · '
                        '보유주식수 유지 · '
                        '지분율 -${dilutionPct.toStringAsFixed(2)}%'
                  : '${position.name} 제3자배정 유상증자 · 신주인수권 없음 · '
                        '보유주식수 유지 · 지분율 '
                        '-${dilutionPct.toStringAsFixed(2)}%',
              sourceId: eventId,
              notional: rightsSaleProceeds,
              assetId: action.assetId,
            ),
          );
          changed = true;
        }
      } else if (position != null &&
          (action.type == MarketCorporateActionType.merger ||
              action.type == MarketCorporateActionType.shareExchange) &&
          action.relatedAssetId != null &&
          action.relatedSymbol != null &&
          action.relatedName != null &&
          action.relatedMarket != null) {
        final receivedUnits = position.units * action.unitFactor;
        if (receivedUnits.isFinite && receivedUnits > 0) {
          positions.removeAt(index);
          final destinationIndex = positions.indexWhere(
            (item) => item.assetId == action.relatedAssetId,
          );
          if (destinationIndex >= 0) {
            final destination = positions[destinationIndex];
            positions[destinationIndex] = destination.copyWith(
              units: destination.units + receivedUnits,
              totalCost: destination.totalCost + position.totalCost,
            );
          } else {
            positions.add(
              PortfolioPosition(
                assetId: action.relatedAssetId!,
                symbol: action.relatedSymbol!,
                name: action.relatedName!,
                market: action.relatedMarket!,
                currency: action.currency,
                units: receivedUnits,
                totalCost: position.totalCost,
              ),
            );
          }
          final actionLabel = action.type == MarketCorporateActionType.merger
              ? '합병'
              : '포괄적 주식교환';
          ledger.add(
            LedgerEntry(
              id: eventId,
              day: state.day,
              amount: 0,
              account: 'market_security',
              counterAccount: action.type == MarketCorporateActionType.merger
                  ? 'corporate_merger'
                  : 'corporate_share_exchange',
              description:
                  '${position.name} $actionLabel · '
                  '${action.relatedName} ${_tradeUnits(receivedUnits)}주 수령 · '
                  '원가 ${position.totalCost}원 승계',
              sourceId: eventId,
              assetId: action.relatedAssetId!,
            ),
          );
          changed = true;
        }
      } else if (position != null &&
          action.type == MarketCorporateActionType.tenderOffer &&
          action.amount > 0) {
        final payout = (position.units * action.amount).round();
        cash += payout;
        brokerageCash += payout;
        positions.removeAt(index);
        ledger.add(
          LedgerEntry(
            id: eventId,
            day: state.day,
            amount: payout,
            account: 'brokerage_cash',
            counterAccount: 'corporate_tender_offer',
            description:
                '${position.name} 공개매수 참여 · '
                '${_tradeUnits(position.units)}주 ${action.amount.round()}원 정산',
            sourceId: eventId,
            notional: payout,
            assetId: action.assetId,
            disposedCost: position.totalCost,
            realizedPnl: payout - position.totalCost,
          ),
        );
        changed = true;
      } else if (position != null &&
          action.type == MarketCorporateActionType.delisting) {
        final payout = (position.units * action.amount).round();
        cash += payout;
        brokerageCash += payout;
        positions.removeAt(index);
        ledger.add(
          LedgerEntry(
            id: eventId,
            day: state.day,
            amount: payout,
            account: 'brokerage_cash',
            counterAccount: 'delisting_settlement',
            description: '${position.name} 상장폐지 정리매매·잔여가치 정산',
            sourceId: eventId,
            notional: payout,
            disposedCost: position.totalCost,
            realizedPnl: payout - position.totalCost,
          ),
        );
        changed = true;
      }
      processed.add(eventId);
    }

    if (!changed && processed.length == state.processedEventIds.length) {
      return state;
    }
    return state.copyWith(
      cash: cash,
      brokerageCash: brokerageCash,
      positions: positions,
      pendingOrders: pendingOrders,
      ledger: ledger,
      processedEventIds: processed.toList(growable: false),
    );
  }
}
