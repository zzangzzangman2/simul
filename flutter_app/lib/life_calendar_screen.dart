part of 'main.dart';

const _calendarNavy = Color(0xFF1D2941);
const _calendarPaper = Color(0xFFFFFCF2);
const _calendarGold = Color(0xFFFFCB68);
const _calendarCoral = Color(0xFFFF7E73);
const _calendarBlue = Color(0xFF6CC9ED);
const _calendarMuted = Color(0xFF727C90);

class LifeCalendarScreen extends StatefulWidget {
  const LifeCalendarScreen({super.key, required this.state, this.transitionTo});

  final GameState state;
  final DateTime? transitionTo;

  bool get isTransition => transitionTo != null;

  @override
  State<LifeCalendarScreen> createState() => _LifeCalendarScreenState();
}

class _LifeCalendarScreenState extends State<LifeCalendarScreen> {
  late DateTime _visibleMonth;
  late DateTime _selectedDate;
  late List<LifeCalendarEvent> _events;

  DateTime get _maximumDate => widget.transitionTo ?? widget.state.currentDate;
  DateTime get _minimumMonth =>
      calendarMonthStart(widget.state.campaignStartDate);
  DateTime get _maximumMonth => calendarMonthStart(_maximumDate);

  @override
  void initState() {
    super.initState();
    final focus = widget.transitionTo ?? widget.state.currentDate;
    _visibleMonth = calendarMonthStart(focus);
    _selectedDate = DateTime(focus.year, focus.month, focus.day);
    _events = lifeCalendarEventsForState(widget.state);
  }

  bool _canShowMonth(DateTime month) =>
      !calendarMonthStart(month).isBefore(_minimumMonth) &&
      !calendarMonthStart(month).isAfter(_maximumMonth);

  void _moveMonth(int delta) {
    final target = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    if (!_canShowMonth(target)) return;
    final focus = isSameCalendarMonth(target, widget.state.currentDate)
        ? widget.state.currentDate
        : isSameCalendarMonth(target, _maximumDate)
        ? _maximumDate
        : target;
    setState(() {
      _visibleMonth = calendarMonthStart(target);
      _selectedDate = DateTime(focus.year, focus.month, focus.day);
    });
  }

  void _selectDate(DateTime date) {
    if (date.isAfter(_maximumDate)) return;
    setState(() => _selectedDate = date);
  }

  void _finish() => Navigator.of(context).pop(true);

  @override
  Widget build(BuildContext context) {
    final age = decimalKoreanAge(_visibleMonth);
    final progress = decimalGrowthCalendarProgress(_visibleMonth);
    final selectedEvents = lifeCalendarEventsOn(_events, _selectedDate);
    final transitionTo = widget.transitionTo;
    return PopScope(
      canPop: !widget.isTransition,
      child: Scaffold(
        key: const Key('life-calendar-screen'),
        backgroundColor: _calendarNavy,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFF172238),
                Color(0xFF293A5B),
                Color(0xFF483B58),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: <Widget>[
                _LifeCalendarTopBar(
                  date: _visibleMonth,
                  age: age,
                  transition: widget.isTransition,
                  onClose: widget.isTransition
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: ListView(
                    key: const Key('life-calendar-scroll'),
                    padding: const EdgeInsets.fromLTRB(12, 2, 12, 18),
                    children: <Widget>[
                      _CalendarBookCard(
                        state: widget.state,
                        visibleMonth: _visibleMonth,
                        selectedDate: _selectedDate,
                        maximumDate: _maximumDate,
                        transitionTo: transitionTo,
                        events: _events,
                        growthProgress: progress,
                        onPrevious:
                            _canShowMonth(previousCalendarMonth(_visibleMonth))
                            ? () => _moveMonth(-1)
                            : null,
                        onNext: _canShowMonth(nextCalendarMonth(_visibleMonth))
                            ? () => _moveMonth(1)
                            : null,
                        onSelectDate: _selectDate,
                      ),
                      const SizedBox(height: 12),
                      _CalendarDayRecord(
                        date: _selectedDate,
                        maximumDate: _maximumDate,
                        events: selectedEvents,
                        isIncoming:
                            transitionTo != null &&
                            isSameCalendarDay(_selectedDate, transitionTo),
                      ),
                    ],
                  ),
                ),
                if (transitionTo != null)
                  _CalendarContinueBar(
                    closingDate: widget.state.currentDate,
                    nextDate: transitionTo,
                    onContinue: _finish,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LifeCalendarTopBar extends StatelessWidget {
  const _LifeCalendarTopBar({
    required this.date,
    required this.age,
    required this.transition,
    required this.onClose,
  });

  final DateTime date;
  final int age;
  final bool transition;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 9),
    child: Row(
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _calendarGold,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0x66000000), offset: Offset(0, 4)),
            ],
          ),
          child: const Icon(
            Icons.calendar_month_rounded,
            color: _calendarNavy,
            size: 27,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                '데시멀 성장 달력',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Maplestory',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${date.year}년 · $age살 · ${transition ? '하루를 넘기는 중' : '지나온 날의 기록'}',
                style: const TextStyle(
                  color: Color(0xFFD9E2F5),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (onClose != null)
          IconButton(
            key: const Key('life-calendar-close-button'),
            onPressed: onClose,
            color: Colors.white,
            icon: const Icon(Icons.close_rounded),
          ),
      ],
    ),
  );
}

class _CalendarBookCard extends StatelessWidget {
  const _CalendarBookCard({
    required this.state,
    required this.visibleMonth,
    required this.selectedDate,
    required this.maximumDate,
    required this.transitionTo,
    required this.events,
    required this.growthProgress,
    required this.onPrevious,
    required this.onNext,
    required this.onSelectDate,
  });

  final GameState state;
  final DateTime visibleMonth;
  final DateTime selectedDate;
  final DateTime maximumDate;
  final DateTime? transitionTo;
  final List<LifeCalendarEvent> events;
  final double growthProgress;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    const weekdayLabels = <String>['월', '화', '수', '목', '금', '토', '일'];
    final cells = lifeCalendarMonthCells(visibleMonth);
    return Container(
      decoration: BoxDecoration(
        color: _calendarPaper,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFF101A2E), width: 2.2),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x77000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          const _CalendarBinding(),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 5, 12, 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[Color(0xFFFFD16F), Color(0xFFFFA978)],
              ),
            ),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _CalendarMonthArrow(
                      key: const Key('life-calendar-previous-month'),
                      icon: Icons.chevron_left_rounded,
                      onPressed: onPrevious,
                    ),
                    Expanded(
                      child: Text(
                        '${visibleMonth.year}년 ${visibleMonth.month}월',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _calendarNavy,
                          fontFamily: 'Maplestory',
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    _CalendarMonthArrow(
                      key: const Key('life-calendar-next-month'),
                      icon: Icons.chevron_right_rounded,
                      onPressed: onNext,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          key: const Key('life-calendar-growth-progress'),
                          minHeight: 7,
                          value: growthProgress,
                          backgroundColor: const Color(0x66FFFFFF),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            _calendarNavy,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      visibleMonth.year <= decimalGrowthCalendarAgeTwentyYear
                          ? '14살 → 20살'
                          : '20살 성장 기록 완료',
                      style: const TextStyle(
                        color: _calendarNavy,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 11),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    for (var index = 0; index < weekdayLabels.length; index++)
                      Expanded(
                        child: Text(
                          weekdayLabels[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: index == 5
                                ? const Color(0xFF3F84B5)
                                : index == 6
                                ? const Color(0xFFD85858)
                                : _calendarMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                GridView.builder(
                  key: const Key('life-calendar-month-grid'),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cells.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 3,
                    mainAxisSpacing: 3,
                    childAspectRatio: 0.92,
                  ),
                  itemBuilder: (context, index) {
                    final date = cells[index];
                    if (date == null) return const SizedBox.shrink();
                    return _CalendarDayCell(
                      date: date,
                      selected: isSameCalendarDay(date, selectedDate),
                      closing: isSameCalendarDay(date, state.currentDate),
                      incoming:
                          transitionTo != null &&
                          isSameCalendarDay(date, transitionTo!),
                      disabled: date.isAfter(maximumDate),
                      events: lifeCalendarEventsOn(events, date),
                      onTap: () => onSelectDate(date),
                    );
                  },
                ),
                const SizedBox(height: 7),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _CalendarLegendDot(color: _calendarGold, label: '오늘 마감'),
                    SizedBox(width: 12),
                    _CalendarLegendDot(color: _calendarBlue, label: '다음 날'),
                    SizedBox(width: 12),
                    _CalendarLegendDot(color: _calendarCoral, label: '기록'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarBinding extends StatelessWidget {
  const _CalendarBinding();

  @override
  Widget build(BuildContext context) => Container(
    height: 20,
    color: const Color(0xFFEEE6D5),
    alignment: Alignment.center,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List<Widget>.generate(
        7,
        (index) => Container(
          width: 17,
          height: 7,
          decoration: BoxDecoration(
            color: _calendarNavy,
            borderRadius: BorderRadius.circular(99),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Colors.white, offset: Offset(0, 2)),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CalendarMonthArrow extends StatelessWidget {
  const _CalendarMonthArrow({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 38,
    height: 34,
    child: IconButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      color: _calendarNavy,
      disabledColor: _calendarNavy.withValues(alpha: 0.25),
      icon: Icon(icon, size: 25),
    ),
  );
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.selected,
    required this.closing,
    required this.incoming,
    required this.disabled,
    required this.events,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool closing;
  final bool incoming;
  final bool disabled;
  final List<LifeCalendarEvent> events;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final weekend = isWeekendOutingDay(date);
    final holiday = !isMarketTradingDay(date);
    final eventColor = events.isEmpty
        ? _calendarCoral
        : Color(events.first.accentValue);
    final borderColor = incoming
        ? _calendarBlue
        : selected
        ? _calendarNavy
        : const Color(0xFFD7D6D1);
    final fillColor = closing
        ? _calendarGold.withValues(alpha: 0.72)
        : incoming
        ? _calendarBlue.withValues(alpha: 0.16)
        : Colors.white;
    return Semantics(
      button: !disabled,
      label: '${date.month}월 ${date.day}일, ${lifeCalendarDayStatus(date)}',
      child: InkWell(
        key: Key('life-calendar-day-${marketDateKey(date)}'),
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          decoration: BoxDecoration(
            color: disabled
                ? const Color(0xFFF3F0E9).withValues(alpha: 0.55)
                : fillColor,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: borderColor,
              width: selected || incoming ? 2 : 1,
            ),
          ),
          child: Opacity(
            opacity: disabled ? 0.36 : 1,
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        color: date.weekday == DateTime.sunday
                            ? const Color(0xFFD85858)
                            : date.weekday == DateTime.saturday
                            ? const Color(0xFF3F84B5)
                            : _calendarNavy,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (closing) ...<Widget>[
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 9,
                        color: _calendarNavy,
                      ),
                    ],
                  ],
                ),
                const Spacer(),
                Text(
                  events.isNotEmpty
                      ? events.first.markerLabel
                      : weekend
                      ? '일정'
                      : holiday
                      ? '휴장'
                      : '개장',
                  maxLines: 1,
                  style: TextStyle(
                    color: events.isNotEmpty
                        ? eventColor
                        : weekend
                        ? _calendarCoral
                        : holiday
                        ? _calendarMuted
                        : const Color(0xFF4A9870),
                    fontSize: 6.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: events.isEmpty ? 4 : 13,
                  height: 4,
                  decoration: BoxDecoration(
                    color: events.isEmpty
                        ? eventColor.withValues(alpha: 0.16)
                        : eventColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarLegendDot extends StatelessWidget {
  const _CalendarLegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(
          color: _calendarMuted,
          fontSize: 7.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _CalendarDayRecord extends StatelessWidget {
  const _CalendarDayRecord({
    required this.date,
    required this.maximumDate,
    required this.events,
    required this.isIncoming,
  });

  final DateTime date;
  final DateTime maximumDate;
  final List<LifeCalendarEvent> events;
  final bool isIncoming;

  @override
  Widget build(BuildContext context) {
    final future = date.isAfter(maximumDate);
    final event = events.isEmpty ? null : events.first;
    final accent = event == null ? _calendarBlue : Color(event.accentValue);
    final title = future
        ? '아직 쓰이지 않은 페이지'
        : event?.title ??
              (isIncoming
                  ? '새로운 하루'
                  : isWeekendOutingDay(date)
                  ? '주말 자유 일정'
                  : !isMarketTradingDay(date)
                  ? '휴장일의 생활 기록'
                  : '정규 거래일');
    final body = future
        ? '이 날짜가 오면 사건의 그림과 글이 여기에 기록됩니다.'
        : event?.body ??
              (isIncoming
                  ? '달력을 한 칸 넘기고 08:00 조간신문으로 하루를 시작합니다.'
                  : isWeekendOutingDay(date)
                  ? '행동력 2칸으로 알바·선물·시장 공부·휴식을 고른 뒤, 저녁에는 친해진 동기와 공개 장소로 외출할 수 있습니다.'
                  : !isMarketTradingDay(date)
                  ? '시장은 쉬지만 데시멀톡과 생활 관계 행동은 이어집니다.'
                  : '15:00 종가 뒤 데시멀톡·관계 행동 중 하나를 고르고 하루를 정리합니다.');
    return Container(
      key: const Key('life-calendar-event-card'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xF7FFFCF2),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent, width: 2),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x55000000), offset: Offset(0, 7)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 98,
            height: 128,
            child: _CalendarEventArtwork(
              imageAsset: event?.imageAsset,
              accent: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${date.year}. ${date.month}. ${date.day}.',
                        style: TextStyle(
                          color: accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        event?.markerLabel ?? lifeCalendarDayStatus(date),
                        style: TextStyle(
                          color: accent,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _calendarNavy,
                    fontFamily: 'Maplestory',
                    fontSize: 15,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  body,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF58647A),
                    fontSize: 9.5,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (events.length > 1) ...<Widget>[
                  const Spacer(),
                  Text(
                    '이날의 다른 기록 +${events.length - 1}',
                    style: TextStyle(
                      color: accent,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarEventArtwork extends StatelessWidget {
  const _CalendarEventArtwork({required this.imageAsset, required this.accent});

  final String? imageAsset;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('life-calendar-event-art-slot'),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          accent.withValues(alpha: 0.2),
          Colors.white,
          _calendarGold.withValues(alpha: 0.25),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: accent.withValues(alpha: 0.55)),
    ),
    clipBehavior: Clip.antiAlias,
    child: imageAsset == null || imageAsset!.isEmpty
        ? _CalendarArtworkPlaceholder(accent: accent)
        : Image.asset(
            imageAsset!,
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, _, _) =>
                _CalendarArtworkPlaceholder(accent: accent),
          ),
  );
}

class _CalendarArtworkPlaceholder extends StatelessWidget {
  const _CalendarArtworkPlaceholder({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.photo_outlined, color: accent, size: 33),
        const SizedBox(height: 6),
        Text(
          'EVENT ART',
          style: TextStyle(
            color: accent,
            fontSize: 7,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          '그림 슬롯',
          style: TextStyle(
            color: _calendarMuted,
            fontSize: 7,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _CalendarContinueBar extends StatelessWidget {
  const _CalendarContinueBar({
    required this.closingDate,
    required this.nextDate,
    required this.onContinue,
  });

  final DateTime closingDate;
  final DateTime nextDate;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 9, 12, 12),
    decoration: const BoxDecoration(
      color: Color(0xF21A253B),
      border: Border(top: BorderSide(color: Color(0x55FFFFFF))),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          key: const Key('life-calendar-continue-button'),
          onPressed: onContinue,
          style: FilledButton.styleFrom(
            foregroundColor: _calendarNavy,
            backgroundColor: _calendarGold,
            side: const BorderSide(color: Colors.white, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
            ),
          ),
          icon: const Icon(Icons.auto_stories_rounded),
          label: Text(
            '${closingDate.month}월 ${closingDate.day}일 기록 완료 · '
            '${nextDate.month}월 ${nextDate.day}일로',
            style: const TextStyle(
              fontFamily: 'Maplestory',
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ),
  );
}
