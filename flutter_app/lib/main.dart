import 'dart:async';

import 'package:flutter/material.dart';

import 'game/game_engine.dart';
import 'game/game_persistence.dart';
import 'game/game_state.dart';
import 'game/historical_executives.dart';
import 'game/market_news.dart';
import 'game/organization_state.dart';
import 'game/seed_money_content.dart';
import 'game/story_state.dart';

part 'organization_screen.dart';
part 'seed_money_screen.dart';
part 'stock_market_screen.dart';
part 'visual_novel_onboarding.dart';

const _ink = Color(0xFF33405F);
const _sky = Color(0xFFBDEBFA);
const _cream = Color(0xFFFFF8E7);
const _yellow = Color(0xFFFFDF68);
const _coral = Color(0xFFFF7D72);
const _blue = Color(0xFF67C7EC);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MillenniumCapitalApp());
}

class MillenniumCapitalApp extends StatefulWidget {
  const MillenniumCapitalApp({super.key, this.persistence});

  final GamePersistence? persistence;

  @override
  State<MillenniumCapitalApp> createState() => _MillenniumCapitalAppState();
}

class _MillenniumCapitalAppState extends State<MillenniumCapitalApp> {
  static const _engine = GameEngine();
  late final GamePersistence _persistence;
  GameState? _state;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _persistence = widget.persistence ?? GamePersistence();
    _restoreGame();
  }

  Future<void> _restoreGame() async {
    final restored = await _persistence.load();
    if (!mounted) return;
    setState(() {
      _state = restored;
      _isReady = true;
    });
  }

  Future<void> _createCompany(NewGameSetup setup) async {
    final story = StoryState.newPlayer(
      playerName: setup.playerName,
      introChoice: setup.introChoice,
      startingTrait: setup.startingTrait,
      familyRule: setup.familyRule,
    );
    final state = _engine.createNewGame(
      setup.companyName,
      story: story,
      initialCash: 0,
    );
    setState(() => _state = state);
    await _persistence.save(state);
  }

  Future<void> _resolveDecision(String decisionId, String optionId) async {
    final current = _state;
    if (current == null) return;
    final next = _engine.resolveDecision(current, decisionId, optionId);
    setState(() => _state = next);
    await _persistence.save(next);
  }

  Future<GameState> _completeWork(WorkSessionResult result) async {
    final current = _state!;
    final next = _engine.completeWorkSession(current, result);
    setState(() => _state = next);
    await _persistence.save(next);
    return next;
  }

  Future<GameState> _requestFamilyHelp(String helperId) async {
    final current = _state!;
    final next = _engine.requestFamilyHelp(current, helperId);
    setState(() => _state = next);
    await _persistence.save(next);
    return next;
  }

  Future<GameState> _advanceDay() async {
    final current = _state!;
    final next = _engine.advanceOneDay(current);
    setState(() => _state = next);
    await _persistence.save(next);
    return next;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '밀레니엄 캐피탈',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _sky,
        colorScheme: ColorScheme.fromSeed(seedColor: _blue),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: _ink,
            fontSize: 34,
            height: 1.08,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.8,
          ),
          titleLarge: TextStyle(
            color: _ink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF5C6884),
            fontSize: 13,
            height: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      home: !_isReady
          ? const _GameFrame(child: _LoadingScreen())
          : _state == null
          ? _GameFrame(
              child: VisualNovelOnboardingScreen(onCreate: _createCompany),
            )
          : _GameFrame(
              child: OfficeScreen(
                state: _state!,
                engine: _engine,
                onAdvanceDay: _advanceDay,
                onResolveDecision: _resolveDecision,
                onRequestFamilyHelp: _requestFamilyHelp,
                onCompleteWork: _completeWork,
              ),
            ),
    );
  }
}

class _GameFrame extends StatelessWidget {
  const _GameFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _sky,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: _cream,
              boxShadow: [
                BoxShadow(
                  color: Color(0x4033405F),
                  blurRadius: 34,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: _sky,
    body: Center(child: CircularProgressIndicator(color: _coral)),
  );
}

class NewGameSetup {
  const NewGameSetup({
    required this.playerName,
    required this.companyName,
    required this.introChoice,
    required this.startingTrait,
    required this.familyRule,
  });

  final String playerName;
  final String companyName;
  final String introChoice;
  final StoryTrait startingTrait;
  final FamilyRule familyRule;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onCreate});

  final ValueChanged<NewGameSetup> onCreate;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _playerController = TextEditingController();
  final _companyController = TextEditingController();
  int _step = 0;
  String? _introChoice;
  StoryTrait? _trait;
  FamilyRule? _familyRule;

  @override
  void dispose() {
    _playerController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  void _finish() {
    final playerName = _playerController.text.trim();
    final companyName = _companyController.text.trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    if (playerName.isEmpty ||
        companyName.isEmpty ||
        _introChoice == null ||
        _trait == null ||
        _familyRule == null) {
      return;
    }
    widget.onCreate(
      NewGameSetup(
        playerName: playerName,
        companyName: companyName,
        introChoice: _introChoice!,
        startingTrait: _trait!,
        familyRule: _familyRule!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _step == 0 ? '1999.12.31 · 23:57' : '2000.01.01 · 새 천년';
    return Scaffold(
      backgroundColor: _sky,
      body: SafeArea(
        child: Column(
          children: [
            _BrandHeader(trailing: dateLabel),
            _StoryProgress(step: _step),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: ListView(
                  key: ValueKey(_step),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: _buildStep(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStep(BuildContext context) => switch (_step) {
    0 => _buildColdOpen(context),
    1 => _buildEnvelope(context),
    2 => _buildFamilyAgreement(context),
    _ => _buildResearchDesk(context),
  };

  List<Widget> _buildColdOpen(BuildContext context) => [
    const _Sticker(icon: Icons.nightlight_round, label: '00 / NEW MILLENNIUM'),
    const SizedBox(height: 15),
    Text('새 천년,\n낡은 컴퓨터', style: Theme.of(context).textTheme.headlineLarge),
    const SizedBox(height: 10),
    const Text(
      '모두가 새 천년을 기다리던 밤, 우리 집에는 버려질 뻔한 베이지색 컴퓨터 한 대가 들어왔습니다.',
      style: TextStyle(
        color: Color(0xFF596783),
        fontSize: 13,
        height: 1.5,
        fontWeight: FontWeight.w700,
      ),
    ),
    const SizedBox(height: 10),
    _OutlinedCard(
      color: const Color(0xFF26334F),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '거실 · TV 카운트다운',
                  style: TextStyle(
                    color: _yellow,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '누나  “날짜가 1900년으로 돌아가면 어떡해?”',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '아빠  “망가지면 고치면 되지.”',
                  style: TextStyle(
                    color: Color(0xFFD9E6FF),
                    fontSize: 11,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 82,
            height: 118,
            child: Image.asset(
              'assets/images/hero-boy.png',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 16),
    const Text(
      '열 살인 나는 처음으로 뭐라고 말했을까?',
      style: TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w900),
    ),
    const SizedBox(height: 8),
    _StoryOption(
      key: const Key('story-intro-computer'),
      title: '“제가 먼저 켜봐도 돼요?”',
      subtitle: '호기심 · 아버지와 컴퓨터를 살펴봅니다.',
      onTap: () => setState(() {
        _introChoice = 'computer';
        _step = 1;
      }),
    ),
    _StoryOption(
      key: const Key('story-intro-y2k'),
      title: '“정말 컴퓨터가 다 멈출 수도 있어요?”',
      subtitle: '신중함 · 어머니와 위험을 먼저 확인합니다.',
      onTap: () => setState(() {
        _introChoice = 'y2k';
        _step = 1;
      }),
    ),
    _StoryOption(
      key: const Key('story-intro-stocks'),
      title: '“이걸로 주식도 살 수 있어요?”',
      subtitle: '야심 · 투자와 책임 이야기가 일찍 시작됩니다.',
      onTap: () => setState(() {
        _introChoice = 'stocks';
        _step = 1;
      }),
    ),
  ];

  List<Widget> _buildEnvelope(BuildContext context) {
    final canContinue =
        _playerController.text.trim().isNotEmpty && _trait != null;
    return [
      _BackStoryButton(onTap: () => setState(() => _step = 0)),
      const _Sticker(icon: Icons.mail_rounded, label: '첫 저금장부'),
      const SizedBox(height: 14),
      Text(
        '첫 장은 0원\n직접 모으기로 했다',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: 10),
      const _OutlinedCard(
        color: Color(0xFFFFFEF8),
        child: Text(
          '“어떤 회사를 믿고, 왜 믿었는지 기록해 보아라. 많이 버는 것보다 잃었을 때 이유를 아는 사람이 되어라.”\n\n계좌는 어머니 명의로 만들고 비밀번호와 도장은 부모님이 보관합니다. 나는 기업을 조사하고 투자 제안서를 씁니다.',
          style: TextStyle(
            color: _ink,
            fontSize: 12,
            height: 1.55,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(height: 14),
      TextField(
        key: const Key('player-name-input'),
        controller: _playerController,
        maxLength: 12,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: '주인공 이름',
          hintText: '예: 민준',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      const Text(
        '왜 투자 기록을 시작하고 싶을까?',
        style: TextStyle(
          color: _ink,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 8),
      _StoryOption(
        key: const Key('story-trait-stability'),
        title: '부모님이 돈 때문에 싸우지 않았으면 좋겠어요',
        subtitle: '안정 · 현금관리와 위험통제에 관심을 둡니다.',
        selected: _trait == StoryTrait.stability,
        onTap: () => setState(() => _trait = StoryTrait.stability),
      ),
      _StoryOption(
        key: const Key('story-trait-innovation'),
        title: '세상을 바꾸는 회사를 먼저 찾고 싶어요',
        subtitle: '혁신 · 기술과 제품을 먼저 살펴봅니다.',
        selected: _trait == StoryTrait.innovation,
        onTap: () => setState(() => _trait = StoryTrait.innovation),
      ),
      _StoryOption(
        key: const Key('story-trait-analysis'),
        title: '신문 속 숫자가 왜 움직이는지 알고 싶어요',
        subtitle: '분석 · 재무와 시장 기록을 꼼꼼히 봅니다.',
        selected: _trait == StoryTrait.analysis,
        onTap: () => setState(() => _trait = StoryTrait.analysis),
      ),
      _StoryOption(
        key: const Key('story-trait-control'),
        title: '언젠가 큰 회사의 주인이 되고 싶어요',
        subtitle: '지배 · 지분과 이사회라는 장기 목표를 세웁니다.',
        selected: _trait == StoryTrait.control,
        onTap: () => setState(() => _trait = StoryTrait.control),
      ),
      const SizedBox(height: 5),
      _StoryNextButton(
        key: const Key('story-next-motivation'),
        label: '가족과 약속 정하기',
        enabled: canContinue,
        onTap: () => setState(() => _step = 2),
      ),
    ];
  }

  List<Widget> _buildFamilyAgreement(BuildContext context) => [
    _BackStoryButton(onTap: () => setState(() => _step = 1)),
    const _Sticker(
      icon: Icons.family_restroom_rounded,
      label: '01 / FAMILY AGREEMENT',
    ),
    const SizedBox(height: 14),
    Text('우리 가족의\n투자 약속', style: Theme.of(context).textTheme.headlineLarge),
    const SizedBox(height: 10),
    const _OutlinedCard(
      color: Color(0xFFFFF4B8),
      child: Text(
        '생활비와 투자금은 섞지 않는다.\n빚을 내지 않는다.\n처음에는 한 번에 10만원 이상 사지 않는다.\n비밀번호와 도장은 부모님이 보관한다.',
        style: TextStyle(
          color: _ink,
          fontSize: 12,
          height: 1.65,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    const SizedBox(height: 14),
    const Text(
      '마지막 한 줄은 내가 고릅니다.',
      style: TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w900),
    ),
    const SizedBox(height: 8),
    _StoryOption(
      key: const Key('family-rule-report-losses'),
      title: '손실을 숨기지 않는다',
      subtitle: '정직한 보고 · 어머니 신뢰가 높아집니다.',
      selected: _familyRule == FamilyRule.reportLosses,
      onTap: () => setState(() => _familyRule = FamilyRule.reportLosses),
    ),
    _StoryOption(
      key: const Key('family-rule-no-hot-tips'),
      title: '남이 찍어준 종목은 사지 않는다',
      subtitle: '독립적인 조사 · 아버지 신뢰가 높아집니다.',
      selected: _familyRule == FamilyRule.noHotTips,
      onTap: () => setState(() => _familyRule = FamilyRule.noHotTips),
    ),
    _StoryOption(
      key: const Key('family-rule-keep-cash'),
      title: '매달 현금을 남겨둔다',
      subtitle: '위기 대비 · 외할아버지 신뢰가 높아집니다.',
      selected: _familyRule == FamilyRule.keepCash,
      onTap: () => setState(() => _familyRule = FamilyRule.keepCash),
    ),
    const SizedBox(height: 5),
    _StoryNextButton(
      key: const Key('story-next-family-rule'),
      label: 'A4 간판 만들기',
      enabled: _familyRule != null,
      onTap: () => setState(() => _step = 3),
    ),
  ];

  List<Widget> _buildResearchDesk(BuildContext context) => [
    _BackStoryButton(onTap: () => setState(() => _step = 2)),
    const _Sticker(icon: Icons.edit_note_rounded, label: '02 / RESEARCH DESK'),
    const SizedBox(height: 14),
    Text('A4 용지에\n이름을 적어보자', style: Theme.of(context).textTheme.headlineLarge),
    const SizedBox(height: 10),
    const Text(
      '아직 법인은 아니에요. 엄마가 관리하는 교육용 계좌와 작은방 책상에서 시작하는 가족 투자연구소입니다.',
      style: TextStyle(
        color: Color(0xFF596783),
        fontSize: 13,
        height: 1.5,
        fontWeight: FontWeight.w700,
      ),
    ),
    const SizedBox(height: 12),
    const _StartingConditions(),
    const SizedBox(height: 14),
    _CompanyNameCard(
      controller: _companyController,
      onChanged: (_) => setState(() {}),
      onSubmit: _finish,
    ),
  ];
}

class _StoryProgress extends StatelessWidget {
  const _StoryProgress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xEFFFFEF8),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 7),
      child: Row(
        children: List.generate(4, (index) {
          final active = index <= step;
          return Expanded(
            child: Container(
              height: 5,
              margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
              decoration: BoxDecoration(
                color: active ? _coral : const Color(0xFFD9DDE2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StoryOption extends StatelessWidget {
  const _StoryOption({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.selected = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFFFF4B8) : Colors.white,
              border: Border.all(color: _ink, width: selected ? 3 : 2),
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [BoxShadow(color: _ink, offset: Offset(0, 3))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF6D7892),
                          fontSize: 9,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: selected ? _coral : _ink,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryNextButton extends StatelessWidget {
  const _StoryNextButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: enabled ? onTap : null,
        iconAlignment: IconAlignment.end,
        icon: const Icon(Icons.arrow_forward_rounded),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          foregroundColor: _ink,
          backgroundColor: _yellow,
          disabledBackgroundColor: const Color(0xFFE4E6E5),
          elevation: 0,
          side: const BorderSide(color: _ink, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _BackStoryButton extends StatelessWidget {
  const _BackStoryButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.arrow_back_rounded, size: 18),
        label: const Text('이전 장면'),
        style: TextButton.styleFrom(foregroundColor: _ink),
      ),
    );
  }
}

class OfficeScreen extends StatelessWidget {
  const OfficeScreen({
    super.key,
    required this.state,
    required this.engine,
    required this.onAdvanceDay,
    required this.onResolveDecision,
    required this.onRequestFamilyHelp,
    required this.onCompleteWork,
  });

  final GameState state;
  final GameEngine engine;
  final Future<GameState> Function() onAdvanceDay;
  final Future<void> Function(String, String) onResolveDecision;
  final Future<GameState> Function(String) onRequestFamilyHelp;
  final Future<GameState> Function(WorkSessionResult) onCompleteWork;

  @override
  Widget build(BuildContext context) {
    final date = state.currentDate;
    final dateLabel =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    final pending = state.pendingDecisions;

    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: Column(
          children: [
            _BrandHeader(trailing: 'DAY ${state.day} · $dateLabel'),
            Expanded(
              child: Stack(
                children: [
                  const Positioned.fill(child: _CartoonRoomBackground()),
                  Positioned.fill(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
                      child: Column(
                        children: [
                          _OfficeStatusCard(state: state),
                          const SizedBox(height: 10),
                          _TodayNewsCard(state: state),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SizedBox(
                                width: 118,
                                child: Image.asset(
                                  'assets/images/hero-boy.png',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  children: [
                                    _RoomButton(
                                      key: const Key('open-decisions-button'),
                                      icon: pending.isEmpty
                                          ? Icons.mark_email_read_rounded
                                          : Icons.mark_email_unread_rounded,
                                      title:
                                          '안건함 ${pending.isEmpty ? '' : '(${pending.length})'}',
                                      subtitle: pending.isEmpty
                                          ? '새 안건 없음'
                                          : '결정이 기다려요',
                                      color: pending.isEmpty
                                          ? const Color(0xFFDFF7EF)
                                          : _yellow,
                                      onTap: () => _openDecision(context),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _RoomButton(
                                            key: const Key(
                                              'open-market-button',
                                            ),
                                            icon: Icons.computer_rounded,
                                            title: 'CRT',
                                            subtitle: '실시간 시장',
                                            color: const Color(0xFFDDF3FF),
                                            compact: true,
                                            onTap: () =>
                                                Navigator.of(context).push(
                                                  MaterialPageRoute<void>(
                                                    builder: (_) =>
                                                        StockMarketScreen(
                                                          state: state,
                                                        ),
                                                  ),
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _RoomButton(
                                            icon: Icons.folder_rounded,
                                            title: '서류함',
                                            subtitle: '장부',
                                            color: const Color(0xFFFFDCD7),
                                            compact: true,
                                            onTap: () => _showLedger(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    _RoomButton(
                                      key: const Key(
                                        'open-organization-button',
                                      ),
                                      icon: Icons.groups_2_rounded,
                                      title: '사람들',
                                      subtitle: '가족 도움 · 직원 배치',
                                      color: const Color(0xFFFFE9C7),
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => OrganizationScreen(
                                            state: state,
                                            onRequestFamilyHelp:
                                                onRequestFamilyHelp,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _RoomButton(
                                      key: const Key('open-work-button'),
                                      icon: Icons.savings_rounded,
                                      title: '일거리',
                                      subtitle: state.cash >= 10000
                                          ? '계속할지는 내 선택'
                                          : '종잣돈 ${_money(state.cash)}원',
                                      color: const Color(0xFFDDF5E8),
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => SeedMoneyHubScreen(
                                            state: state,
                                            onComplete: onCompleteWork,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _AdvanceBar(
              hasPendingDecision: pending.isNotEmpty,
              onAdvanceDay: () => _handleAdvanceDay(context),
              onOpenDecision: () => _openDecision(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAdvanceDay(BuildContext context) async {
    final beforeDay = state.day;
    final next = await onAdvanceDay();
    if (!context.mounted) return;
    // 중요 안건에 막혀 하루가 흐르지 않았으면 속보도 없다.
    if (next.day <= beforeDay) return;
    final headline = historicalNewsForDate(next.currentDate);
    if (headline == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          NewsBulletinSheet(event: headline, date: next.currentDate),
    );
  }

  void _openDecision(BuildContext context) {
    final pending = state.pendingDecisions;
    if (pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지금은 기다리는 안건이 없어요. 하루를 보내보세요!')),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DecisionSheet(
        state: state,
        decision: pending.first,
        onSelect: (optionId) async {
          Navigator.of(sheetContext).pop();
          await onResolveDecision(pending.first.id, optionId);
        },
      ),
    );
  }

  void _showLedger(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '현금 원장',
              style: TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            if (state.ledger.isEmpty)
              const Text('아직 기록된 거래가 없어요.')
            else
              ...state.ledger.reversed
                  .take(5)
                  .map(
                    (entry) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.description),
                      subtitle: Text('DAY ${entry.day} · ${entry.sourceId}'),
                      trailing: Text(
                        '${entry.amount > 0 ? '+' : ''}${_money(entry.amount)}원',
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class DecisionSheet extends StatelessWidget {
  const DecisionSheet({
    super.key,
    required this.state,
    required this.decision,
    required this.onSelect,
  });

  final GameState state;
  final DecisionCardData decision;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.62,
      maxChildSize: 0.96,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(top: BorderSide(color: _ink, width: 3)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF9BA5B7),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _Sticker(
                  icon: Icons.campaign_rounded,
                  label: decision.category,
                ),
                const Spacer(),
                Text(
                  '마감 DAY ${decision.dueDay}',
                  style: const TextStyle(
                    color: _coral,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(decision.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 5),
            Text(
              '제안자 · ${decision.proposer}',
              style: const TextStyle(
                color: Color(0xFF6E7890),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(decision.body, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _FactChip(
                    label: '핵심 장점',
                    value: decision.benefit,
                    color: const Color(0xFFDFF7EF),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FactChip(
                    label: '핵심 위험',
                    value: decision.risk,
                    color: const Color(0xFFFFE3DF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              '사람들의 의견',
              style: TextStyle(
                color: _ink,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            ...decision.advisorOpinions.map(
              (opinion) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '• $opinion',
                  style: const TextStyle(
                    color: Color(0xFF66718A),
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '어떻게 할까요?',
              style: TextStyle(
                color: _ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            ...decision.options.map((option) {
              final locked = option.cashCost > state.cash;
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: SizedBox(
                  height: 64,
                  child: ElevatedButton(
                    key: Key('decision-option-${option.id}'),
                    onPressed: locked ? null : () => onSelect(option.id),
                    style: ElevatedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      foregroundColor: _ink,
                      backgroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE5E7E8),
                      elevation: 0,
                      side: const BorderSide(color: _ink, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                locked
                                    ? '현금 부족 · ${_money(option.cashCost)}원 필요'
                                    : option.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const Text(
              '실제 회사명을 사용하지만 내부 수치·의견·결과는 게임용 가상 시나리오입니다. 성공 확률과 미래 결과는 숨겨집니다.',
              style: TextStyle(
                color: Color(0xFF8A92A2),
                fontSize: 9,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfficeStatusCard extends StatelessWidget {
  const _OfficeStatusCard({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final diverged = state.company.worldMode == WorldMode.diverged;
    final authority = state.story.accountAuthorityLevel;
    final orderLimit = switch (authority) {
      0 => '관찰 전용',
      1 => '10만원',
      2 => '25만원',
      3 => '자산 25%',
      4 => '해외 검토',
      _ => '동등 발언권',
    };
    return _OutlinedCard(
      color: const Color(0xF7FFFEF8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'DAY ${state.day} · ${state.companyName} 투자연구소',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _coral,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: diverged
                      ? const Color(0xFFFFE3DF)
                      : const Color(0xFFDFF7EF),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  diverged ? '대체역사 진행 중' : 'FAMILY RESEARCH DESK',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _StatusValue(
                  label: '연구계좌 현금',
                  value: '${_money(state.cash)}원',
                ),
              ),
              Expanded(
                child: _StatusValue(
                  label: '가족 신뢰',
                  value: '${state.story.familyTrust}',
                ),
              ),
              _StatusValue(label: '주문 한도', value: orderLimit),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            diverged
                ? '분기 DAY ${state.company.divergedAtDay} · ${state.company.divergenceReason}'
                : '계좌 명의: 어머니 · 생활비와 분리 · 대출·미수·신용 금지',
            style: const TextStyle(
              color: Color(0xFF7B849A),
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

typedef _NewsToneStyle = ({
  Color fill,
  Color accent,
  IconData icon,
  String tag,
});

_NewsToneStyle _newsToneStyle(NewsTone tone) => switch (tone) {
  NewsTone.breaking => (
    fill: const Color(0xFFFFF0EC),
    accent: _coral,
    icon: Icons.campaign_rounded,
    tag: '속보',
  ),
  NewsTone.shock => (
    fill: const Color(0xFFFFE6E1),
    accent: const Color(0xFFE0574B),
    icon: Icons.warning_amber_rounded,
    tag: '시장 충격',
  ),
  NewsTone.launch => (
    fill: const Color(0xFFE7F4FF),
    accent: const Color(0xFF3E8FD0),
    icon: Icons.rocket_launch_rounded,
    tag: '새 소식',
  ),
  NewsTone.milestone => (
    fill: const Color(0xFFFFF7DA),
    accent: const Color(0xFFE0A100),
    icon: Icons.auto_awesome_rounded,
    tag: '오늘의 소식',
  ),
  NewsTone.weekend => (
    fill: const Color(0xFFECEEF6),
    accent: const Color(0xFF7C86A0),
    icon: Icons.weekend_rounded,
    tag: '주말',
  ),
  NewsTone.holiday => (
    fill: const Color(0xFFEFEAF7),
    accent: const Color(0xFF8A6FC0),
    icon: Icons.celebration_rounded,
    tag: '휴장',
  ),
  NewsTone.calm => (
    fill: const Color(0xFFE7F5EC),
    accent: const Color(0xFF3AA982),
    icon: Icons.wb_sunny_rounded,
    tag: '오늘의 소식',
  ),
};

class _TodayNewsCard extends StatelessWidget {
  const _TodayNewsCard({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final brief = buildDailyBrief(state);
    final pending = state.pendingDecisions;
    final project = state.project;
    final tone = _newsToneStyle(brief.tone);

    return _OutlinedCard(
      color: tone.fill,
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tone.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tone.icon, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      brief.isBreaking ? tone.tag : '오늘의 소식',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  brief.eyebrow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7B849A),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _MarketStatusPill(closed: brief.marketClosed),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            brief.title,
            style: const TextStyle(
              color: _ink,
              fontSize: 15,
              height: 1.25,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            brief.body,
            style: const TextStyle(
              color: Color(0xFF5E6883),
              fontSize: 11,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xF2FFFEF8),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0x2233405F), width: 1.5),
            ),
            child: Row(
              children: [
                Icon(
                  pending.isEmpty
                      ? Icons.schedule_rounded
                      : Icons.notifications_active_rounded,
                  color: pending.isEmpty ? const Color(0xFF3AA982) : _coral,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pending.isEmpty ? '시간을 보내도 좋아요' : '중요 안건에서 시간이 멈췄어요',
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        pending.isNotEmpty
                            ? pending.first.title
                            : project == null
                            ? '‘하루 보내기’를 누르면 다음 소식이 와요.'
                            : 'Project Atlas · ${_projectLabel(project.status)} · 다음 변화 대기 중',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF7B849A),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketStatusPill extends StatelessWidget {
  const _MarketStatusPill({required this.closed});

  final bool closed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: closed ? const Color(0xFFE7E9F0) : const Color(0xFFDFF7EF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: closed ? const Color(0x3333405F) : const Color(0x333AA982),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: closed ? const Color(0xFF9AA2B5) : const Color(0xFF3AA982),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            closed ? '휴장' : '개장',
            style: TextStyle(
              color: closed ? const Color(0xFF6B7488) : const Color(0xFF2E8768),
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class NewsBulletinSheet extends StatelessWidget {
  const NewsBulletinSheet({super.key, required this.event, required this.date});

  final HistoricalNewsEvent event;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final tone = _newsToneStyle(event.tone);
    final dateLabel =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.42,
      maxChildSize: 0.9,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(top: BorderSide(color: _ink, width: 3)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF9BA5B7),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: tone.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tone.icon, color: Colors.white, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        '속보 · ${event.eyebrow}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  dateLabel,
                  style: const TextStyle(
                    color: Color(0xFF7B849A),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              event.title,
              style: const TextStyle(
                color: _ink,
                fontSize: 22,
                height: 1.2,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              event.body,
              style: const TextStyle(
                color: Color(0xFF515C77),
                fontSize: 13,
                height: 1.6,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7DA),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _ink, width: 2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_rounded,
                    color: Color(0xFFE0A100),
                    size: 20,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '투자 메모',
                          style: TextStyle(
                            color: _coral,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          event.signal,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 12,
                            height: 1.45,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check_rounded),
                label: const Text('확인했어요'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: _ink,
                  backgroundColor: _yellow,
                  elevation: 0,
                  side: const BorderSide(color: _ink, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '실제 사건에서 착안한 게임용 소식입니다. 내부 수치·결과는 가상입니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF9AA2B5),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvanceBar extends StatelessWidget {
  const _AdvanceBar({
    required this.hasPendingDecision,
    required this.onAdvanceDay,
    required this.onOpenDecision,
  });

  final bool hasPendingDecision;
  final VoidCallback onAdvanceDay;
  final VoidCallback onOpenDecision;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 9, 10, 10),
      decoration: const BoxDecoration(
        color: Color(0xFF8FDAF2),
        border: Border(top: BorderSide(color: _ink, width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hasPendingDecision ? '결정할 안건이 있어요!' : '다음 날 새로운 소식이 와요!',
              style: const TextStyle(
                color: _ink,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              key: const Key('advance-day-button'),
              onPressed: hasPendingDecision ? onOpenDecision : onAdvanceDay,
              iconAlignment: IconAlignment.end,
              icon: Icon(
                hasPendingDecision
                    ? Icons.mark_email_unread_rounded
                    : Icons.arrow_forward_rounded,
              ),
              label: Text(hasPendingDecision ? '안건 열기' : '하루 보내기'),
              style: ElevatedButton.styleFrom(
                foregroundColor: _ink,
                backgroundColor: _yellow,
                elevation: 0,
                side: const BorderSide(color: _ink, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.trailing});

  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Color(0xF2FFFEF8),
        border: Border(bottom: BorderSide(color: Color(0x2933405F), width: 2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _yellow,
              border: Border.all(color: _ink, width: 2),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: _ink, offset: Offset(3, 3))],
            ),
            child: const Text(
              'MC',
              style: TextStyle(color: _ink, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '밀레니엄 캐피탈',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  '2000 투자 모험',
                  style: TextStyle(
                    color: Color(0xFF5A91AD),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            trailing,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF65728E),
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartingConditions extends StatelessWidget {
  const _StartingConditions();

  @override
  Widget build(BuildContext context) {
    const conditions = [
      ('출발하는 날', '2000.01.01', Color(0xFFFFFEF8)),
      ('내 돈', '0원부터', Color(0xFFFFF4B8)),
      ('우리 팀', '연구원 1명', Color(0xFFDFF7EF)),
      ('첫 무대', '한국 · 미국 · 일본', Color(0xFFFFE3DF)),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.35,
        crossAxisSpacing: 9,
        mainAxisSpacing: 9,
      ),
      itemCount: conditions.length,
      itemBuilder: (context, index) {
        final item = conditions[index];
        return _OutlinedCard(
          color: item.$3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.$1,
                style: const TextStyle(
                  color: Color(0xFF7A849A),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.$2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CompanyNameCard extends StatelessWidget {
  const _CompanyNameCard({
    required this.controller,
    required this.onChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final enabled = controller.text.trim().isNotEmpty;
    return _OutlinedCard(
      color: const Color(0xFFFFFEF8),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '우리 투자연구소 이름',
            style: TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('company-name-input'),
            controller: controller,
            maxLength: 24,
            onChanged: onChanged,
            onSubmitted: (_) => enabled ? onSubmit() : null,
            decoration: InputDecoration(
              hintText: '예: 새벽투자파트너스',
              counterText: '${controller.text.length}/24',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF8792AA),
                  width: 2,
                ),
              ),
            ),
          ),
          const Text(
            '연구소 이름과 가족 약속은 이 기기에 자동 저장돼요.',
            style: TextStyle(
              color: Color(0xFF8790A3),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              key: const Key('create-company-button'),
              onPressed: enabled ? onSubmit : null,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.star_rounded),
              label: const Text('A4 간판 붙이기'),
              style: ElevatedButton.styleFrom(
                foregroundColor: _ink,
                backgroundColor: _coral,
                disabledBackgroundColor: const Color(0xFFE4E6E5),
                elevation: 0,
                side: const BorderSide(color: _ink, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomButton extends StatelessWidget {
  const _RoomButton({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title, $subtitle 열기',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            constraints: const BoxConstraints(minHeight: 58),
            padding: EdgeInsets.all(compact ? 8 : 11),
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: _ink, width: 2),
              borderRadius: BorderRadius.circular(17),
              boxShadow: const [BoxShadow(color: _ink, offset: Offset(0, 4))],
            ),
            child: Row(
              children: [
                Icon(icon, color: _ink, size: compact ? 21 : 27),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _ink,
                          fontSize: compact ? 10 : 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF6D7892),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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

class _CartoonRoomBackground extends StatelessWidget {
  const _CartoonRoomBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE5F8FF), Color(0xFFFFEDBE), Color(0xFFC98B62)],
          stops: [0, 0.66, 1],
        ),
      ),
    );
  }
}

class _Sticker extends StatelessWidget {
  const _Sticker({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _yellow,
        border: Border.all(color: _ink, width: 2),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: _ink, offset: Offset(2, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _coral, size: 15),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: _ink,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusValue extends StatelessWidget {
  const _StatusValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF7B849A), fontSize: 9),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FactChip extends StatelessWidget {
  const _FactChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 90),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: _ink, width: 2),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _coral,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: _ink,
              fontSize: 10,
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlinedCard extends StatelessWidget {
  const _OutlinedCard({
    required this.child,
    required this.color,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: _ink, width: 2),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Color(0xCC33405F), offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

String _money(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final result = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) result.write(',');
    result.write(digits[i]);
  }
  return '${negative ? '-' : ''}$result';
}

String _projectLabel(ProjectStatus status) => switch (status) {
  ProjectStatus.proposal => '제안',
  ProjectStatus.development => '개발 중',
  ProjectStatus.launchReview => '출시 심사',
  ProjectStatus.launched => '출시됨',
  ProjectStatus.cancelled => '중단',
  ProjectStatus.completed => '초기 결과 확인',
};
