part of 'main.dart';

class _AnnouncedCorporateAction {
  const _AnnouncedCorporateAction({required this.stock, required this.action});

  final _StockDefinition stock;
  final MarketCorporateAction action;
}

class _CorporateActionScheduleCard extends StatelessWidget {
  const _CorporateActionScheduleCard({
    required this.actions,
    required this.subscribeRights,
    required this.savingPreference,
    required this.preferenceEnabled,
    required this.onPreferenceChanged,
  });

  final List<_AnnouncedCorporateAction> actions;
  final bool subscribeRights;
  final bool savingPreference;
  final bool preferenceEnabled;
  final ValueChanged<bool> onPreferenceChanged;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('market-corporate-action-schedule'),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _marketLine),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '기업행동 공시 일정',
          style: TextStyle(
            color: _marketInk,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '거래일 14일 전에 공시된 일정만 표시해요.',
          style: TextStyle(
            color: _marketMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _marketSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '주주배정 유상증자 처리',
                style: TextStyle(
                  color: _marketInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      key: const Key('market-rights-auto-sell'),
                      label: const Text('권리 자동매도'),
                      selected: !subscribeRights,
                      onSelected: !preferenceEnabled || savingPreference
                          ? null
                          : (_) => onPreferenceChanged(false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      key: const Key('market-rights-subscribe'),
                      label: Text(savingPreference ? '저장 중…' : '예수금으로 청약'),
                      selected: subscribeRights,
                      onSelected: !preferenceEnabled || savingPreference
                          ? null
                          : (_) => onPreferenceChanged(true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              const Text(
                '청약대금이 부족하면 해당 권리는 자동매도됩니다.',
                style: TextStyle(
                  color: _marketMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (actions.isEmpty)
          const Text(
            '현재 공시된 예정 기업행동이 없습니다.',
            key: Key('market-corporate-action-empty'),
            style: TextStyle(
              color: _marketMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          for (var index = 0; index < actions.length; index++) ...[
            _CorporateActionScheduleRow(row: actions[index]),
            if (index != actions.length - 1)
              const Divider(height: 17, color: _marketLine),
          ],
      ],
    ),
  );
}

class _CorporateActionScheduleRow extends StatelessWidget {
  const _CorporateActionScheduleRow({required this.row});

  final _AnnouncedCorporateAction row;

  @override
  Widget build(BuildContext context) {
    final action = row.action;
    final date = DateTime.parse(action.date);
    final label = switch (action.type) {
      MarketCorporateActionType.dividend => '현금배당',
      MarketCorporateActionType.rightsIssue => '유상증자',
      MarketCorporateActionType.split => '주식분할',
      MarketCorporateActionType.spinoff => '인적분할',
      MarketCorporateActionType.materialSpinoff => '물적분할',
      MarketCorporateActionType.merger => '합병',
      MarketCorporateActionType.shareExchange => '주식교환',
      MarketCorporateActionType.tenderOffer => '공개매수',
      MarketCorporateActionType.delisting => '상장폐지',
    };
    final detail = switch (action.type) {
      MarketCorporateActionType.dividend =>
        '주당 ${_money(action.amount.round())}원',
      MarketCorporateActionType.rightsIssue =>
        '${(action.rightsIssueRate * 100).toStringAsFixed(1)}% · '
            '신주 ${_money(action.amount.round())}원',
      MarketCorporateActionType.split =>
        '1주당 ${action.unitFactor.toStringAsFixed(2)}주',
      MarketCorporateActionType.spinoff ||
      MarketCorporateActionType.merger ||
      MarketCorporateActionType.shareExchange =>
        action.relatedName ?? '대상 법인 공시',
      MarketCorporateActionType.tenderOffer =>
        '주당 ${_money(action.amount.round())}원',
      MarketCorporateActionType.materialSpinoff ||
      MarketCorporateActionType.delisting => action.source,
    };
    return Row(
      key: Key('market-corporate-action-${action.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 46,
          child: Text(
            _shortInvestorDate(date),
            style: const TextStyle(
              color: _marketAccent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              fontFeatures: _marketNumberFeatures,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${row.stock.name} · $label',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _marketInk,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _marketMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
