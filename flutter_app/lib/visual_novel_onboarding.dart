part of 'main.dart';

const _onboardingBeatCount = 292;
const _maximumDialogueBeatCount = 320;
const _dialogueAppearanceVersion = 15;
const _dialogueContentVersion = 3;
const _dialogueRuntimeStorageKey = 'project-decimal-dialogue-runtime-v2';
const _dialogueBundleAsset = 'assets/dialogue/dialogue-editor-override.json';
const _orientationCompleteBeat = _onboardingBeatCount - 1;
const _storyCharacterBottomInset = 76.0;
const _storyDialogueBottomInset = 28.0;
const _storyCharacterHeightFactor = 0.9;
const _storyCharacterAspectRatio = 2 / 3;
const _minhoCharacterAsset =
    'assets/images/historical_prologue/character_minho_farewell_v3.png';
const _minhoCharacterScale = 0.72;
const _maximumWheelBackSteps = 12;
const _wheelBackDebounce = Duration(milliseconds: 180);

typedef PrologueCheckpointSaver =
    Future<void> Function(
      int beat,
      bool academyPcPoweredOn,
      bool academyStockAppOpen,
      String playerName,
      String companyName,
    );

class _PrologueSkipStep {
  const _PrologueSkipStep({
    required this.sectionLabel,
    required this.destinationLabel,
    required this.targetBeat,
  });

  final String sectionLabel;
  final String destinationLabel;
  final int targetBeat;
}

double _storyCharacterScaleForAsset(String asset) =>
    asset == _minhoCharacterAsset ? _minhoCharacterScale : 1.0;

void _playStoryFeedback({bool strong = false}) {
  if (strong) {
    unawaited(HapticFeedback.mediumImpact());
  } else {
    unawaited(HapticFeedback.selectionClick());
  }
  unawaited(SystemSound.play(SystemSoundType.click));
}

typedef NewGameCreator =
    Future<void> Function(
      NewGameSetup setup,
      WorldLoadProgressCallback onProgress,
    );

class _DialogueOverride {
  const _DialogueOverride({
    required this.id,
    required this.speaker,
    required this.line,
    required this.direction,
    required this.date,
    required this.location,
    this.background,
    this.character,
  });

  final String id;
  final String speaker;
  final String line;
  final String direction;
  final String date;
  final String location;
  final String? background;
  final String? character;
}

String _canonicalDialogueAsset(Object? value) {
  final asset = value is String ? value : '';
  const webAssetPrefix = '/play/assets/';
  return asset.startsWith(webAssetPrefix)
      ? asset.substring(webAssetPrefix.length)
      : asset;
}

Map<int, _DialogueOverride> _canonicalDialogueOverrides() =>
    <int, _DialogueOverride>{
      for (final scene in canonicalDialogueScenes)
        (scene['order']! as int) - 1: _DialogueOverride(
          id: scene['id']! as String,
          speaker: scene['speaker']! as String,
          line: scene['line']! as String,
          direction: scene['direction']! as String,
          date: scene['date']! as String,
          location: scene['location']! as String,
          background: _canonicalDialogueAsset(scene['background']),
          character: _canonicalDialogueAsset(scene['character']),
        ),
    };

class VisualNovelOnboardingScreen extends StatefulWidget {
  const VisualNovelOnboardingScreen({
    super.key,
    required this.onCreate,
    this.onExit,
    this.onCheckpoint,
    this.initialBeat = 0,
    this.initialAcademyPcPoweredOn = false,
    this.initialAcademyStockAppOpen = false,
    this.initialPlayerName = '',
    this.initialCompanyName = '',
    this.allowRuntimeDialoguePreview = false,
    this.dialogueOverrideJson,
  });

  final NewGameCreator onCreate;
  final VoidCallback? onExit;
  final PrologueCheckpointSaver? onCheckpoint;
  final int initialBeat;
  final bool initialAcademyPcPoweredOn;
  final bool initialAcademyStockAppOpen;
  final String initialPlayerName;
  final String initialCompanyName;
  final bool allowRuntimeDialoguePreview;
  final String? dialogueOverrideJson;

  @override
  State<VisualNovelOnboardingScreen> createState() =>
      _VisualNovelOnboardingScreenState();
}

class _VisualNovelOnboardingScreenState
    extends State<VisualNovelOnboardingScreen> {
  final _playerController = TextEditingController();
  final _companyController = TextEditingController();
  final List<String> _dialogueHistory = <String>[];
  final List<int> _beatNavigationHistory = <int>[];
  Map<int, _DialogueOverride> _dialogueOverrides =
      _canonicalDialogueOverrides();
  late int _beat;
  int _dialogueEndBeat = canonicalDialogueScenes.length - 1;
  bool _isCreating = false;
  late bool _playerNameConfirmed;
  String? _creationError;
  late bool _academyPcPoweredOn;
  late bool _academyStockAppOpen;
  DateTime? _lastWheelBackAt;
  late Future<void> _dialogueLoadFuture;
  WorldLoadProgress _creationProgress = const WorldLoadProgress(
    0.02,
    '데시멀 국가계좌 정보를 정리하는 중…',
  );

  @override
  void initState() {
    super.initState();
    _beat = widget.initialBeat.clamp(0, canonicalDialogueScenes.length - 1);
    _academyPcPoweredOn = widget.initialAcademyPcPoweredOn;
    _academyStockAppOpen =
        widget.initialAcademyPcPoweredOn && widget.initialAcademyStockAppOpen;
    _playerController.text = widget.initialPlayerName.trim();
    _playerNameConfirmed = _playerController.text.isNotEmpty;
    _companyController.text = widget.initialCompanyName;
    _dialogueLoadFuture = _loadDialogueOverrides();
    unawaited(_dialogueLoadFuture);
  }

  @override
  void didUpdateWidget(covariant VisualNovelOnboardingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.allowRuntimeDialoguePreview !=
            widget.allowRuntimeDialoguePreview ||
        oldWidget.dialogueOverrideJson != widget.dialogueOverrideJson) {
      _dialogueLoadFuture = _loadDialogueOverrides();
      unawaited(_dialogueLoadFuture);
    }
  }

  Map<int, _DialogueOverride> _decodeDialogueOverrides(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return const {};
    final rawScenes = decoded['scenes'];
    if (rawScenes is! List) return const {};

    final loaded = <int, _DialogueOverride>{};
    for (final rawScene in rawScenes) {
      if (rawScene is! Map<String, dynamic>) continue;
      final order = rawScene['order'];
      if (order is! num) continue;
      final beat = order.toInt() - 1;
      if (beat < 0 || beat >= _maximumDialogueBeatCount) continue;

      String text(String key) {
        final value = rawScene[key] is String ? rawScene[key] as String : '';
        return value
            .replaceAll(r'\r\n', '\n')
            .replaceAll(r'\n', '\n')
            .replaceAll(r'\r', '\n');
      }

      String? asset(String key) {
        if (!rawScene.containsKey(key)) return null;
        final value = text(key).trim();
        const webAssetPrefix = '/play/assets/';
        return value.startsWith(webAssetPrefix)
            ? value.substring(webAssetPrefix.length)
            : value;
      }

      loaded[beat] = _DialogueOverride(
        id: text('id'),
        speaker: text('speaker'),
        line: text('line'),
        direction: text('direction'),
        date: text('date'),
        location: text('location'),
        background: asset('background'),
        character: asset('character'),
      );
    }
    return loaded;
  }

  int _decodeDialogueAppearanceVersion(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return 0;
      final version = decoded['appearanceVersion'];
      return version is num ? version.toInt() : 0;
    } catch (_) {
      return 0;
    }
  }

  int _decodeDialogueContentVersion(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return 0;
      final version = decoded['contentVersion'];
      return version is num ? version.toInt() : 0;
    } catch (_) {
      return 0;
    }
  }

  _DialogueOverride _mergeCurrentAppearance(
    _DialogueOverride draft,
    _DialogueOverride current,
  ) => _DialogueOverride(
    id: draft.id,
    speaker: draft.speaker,
    line: draft.line,
    direction: draft.direction,
    date: draft.date,
    location: draft.location,
    background: current.background,
    character: current.character,
  );

  Future<void> _loadDialogueOverrides() async {
    final loaded = <int, _DialogueOverride>{};
    final injectedRaw = widget.dialogueOverrideJson;
    if (injectedRaw != null) {
      loaded.addAll(_decodeDialogueOverrides(injectedRaw));
    }

    if (injectedRaw == null && widget.allowRuntimeDialoguePreview) {
      // Preview mode must be immediately usable even when an earlier asset
      // request is still being torn down in the browser. The generated Dart
      // map and bundled JSON come from the same canonical source.
      loaded.addAll(_canonicalDialogueOverrides());
    } else if (injectedRaw == null) {
      try {
        final bundledRaw = await rootBundle.loadString(_dialogueBundleAsset);
        loaded.addAll(_decodeDialogueOverrides(bundledRaw));
      } catch (error, stackTrace) {
        // An absent or damaged generated asset falls back to the source dialogue.
        debugPrint('Failed to load bundled dialogue: $error\n$stackTrace');
      }
    }

    final bundledAppearance = Map<int, _DialogueOverride>.of(loaded);

    if (injectedRaw == null && widget.allowRuntimeDialoguePreview) {
      try {
        final preferences = await SharedPreferences.getInstance();
        await preferences.reload();
        final raw = preferences.getString(_dialogueRuntimeStorageKey);
        if (raw != null && raw.trim().isNotEmpty) {
          final browserDraft = _decodeDialogueOverrides(raw);
          if (browserDraft.isNotEmpty) {
            if (_decodeDialogueContentVersion(raw) < _dialogueContentVersion) {
              final customScenes = Map<int, _DialogueOverride>.fromEntries(
                browserDraft.entries.where(
                  (entry) => bundledAppearance[entry.key]?.id != entry.value.id,
                ),
              );
              browserDraft
                ..clear()
                ..addAll(bundledAppearance)
                ..addAll(customScenes);
            }
            if (_decodeDialogueAppearanceVersion(raw) <
                _dialogueAppearanceVersion) {
              for (final entry in browserDraft.entries.toList()) {
                final current = bundledAppearance[entry.key];
                if (current != null && current.id == entry.value.id) {
                  browserDraft[entry.key] = _mergeCurrentAppearance(
                    entry.value,
                    current,
                  );
                }
              }
            }
            // A browser draft may contain only edited/custom scenes. Keep the
            // generated canonical map underneath it so a partial cache can
            // never resurrect the handwritten legacy switch fallbacks.
            loaded.addAll(browserDraft);
          }
        }
      } catch (_) {
        // A damaged browser draft must never prevent the prologue from starting.
      }
    }

    if (!mounted || loaded.isEmpty) return;
    setState(() {
      _dialogueOverrides = Map<int, _DialogueOverride>.unmodifiable(loaded);
      _dialogueEndBeat = loaded.keys.reduce(math.max);
    });
  }

  @override
  void dispose() {
    _playerController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  String _backgroundForBeat(int beat) {
    final background = _dialogueOverrides[beat]?.background?.trim();
    return background == null || background.isEmpty
        ? 'assets/images/bg_stock_academy_2000_portrait_cartoon_v4.png'
        : background;
  }

  String get _background => _backgroundForBeat(_beat);

  int _firstBeatWithBackground(String token, int fallbackBeat) {
    for (var beat = 0; beat <= _dialogueEndBeat; beat += 1) {
      if (_backgroundForBeat(beat).contains(token)) return beat;
    }
    return math.min(fallbackBeat, _dialogueEndBeat);
  }

  _PrologueSkipStep _prologueSkipStepForBeat(int beat) {
    final archiveBeat = _firstBeatWithBackground('bg_nis_decimal_archive_', 20);
    final matrixBeat = _firstBeatWithBackground('bg_decimal_matrix_exam_', 38);
    final unfairBeat = _firstBeatWithBackground('bg_decimal_unfair_game_', 68);
    final desireBeat = _firstBeatWithBackground('bg_decimal_desire_test_', 99);
    final gangnamBeat = _firstBeatWithBackground(
      'bg_decimal_gangnam_exterior_',
      123,
    );
    final loungeBeat = _firstBeatWithBackground(
      'bg_decimal_living_lounge_',
      149,
    );
    final tradingBeat = _firstBeatWithBackground(
      'bg_decimal_trading_floor_',
      269,
    );

    if (beat < archiveBeat) {
      return _PrologueSkipStep(
        sectionLabel: '데시멀 재가동',
        destinationLabel: '봉인된 실패 기록',
        targetBeat: archiveBeat,
      );
    }
    if (beat < matrixBeat) {
      return _PrologueSkipStep(
        sectionLabel: '봉인된 실패 기록',
        destinationLabel: '행렬 시험',
        targetBeat: matrixBeat,
      );
    }
    if (beat < unfairBeat) {
      return _PrologueSkipStep(
        sectionLabel: '행렬 시험',
        destinationLabel: '불공정 게임',
        targetBeat: unfairBeat,
      );
    }
    if (beat < desireBeat) {
      return _PrologueSkipStep(
        sectionLabel: '불공정 게임',
        destinationLabel: '욕망 검증',
        targetBeat: desireBeat,
      );
    }
    if (beat < gangnamBeat) {
      return _PrologueSkipStep(
        sectionLabel: '욕망 검증',
        destinationLabel: '강남 아지트 도착',
        targetBeat: gangnamBeat,
      );
    }
    if (beat < loungeBeat) {
      return _PrologueSkipStep(
        sectionLabel: '강남 아지트 도착',
        destinationLabel: '최종 열 명 소개',
        targetBeat: loungeBeat,
      );
    }
    if (beat < tradingBeat) {
      return _PrologueSkipStep(
        sectionLabel: '첫날 공동생활',
        destinationLabel: '트레이딩 플로어',
        targetBeat: tradingBeat,
      );
    }
    return _PrologueSkipStep(
      sectionLabel: '첫 주문 브리핑',
      destinationLabel: '주식 PC 튜토리얼',
      targetBeat: _dialogueEndBeat,
    );
  }

  _PrologueSkipStep get _currentPrologueSkipStep =>
      _prologueSkipStepForBeat(_beat);

  String get _location =>
      _dialogueOverrides[_beat]?.location.trim() ?? '프로젝트 데시멀';

  String get _dateLabel => _dialogueOverrides[_beat]?.date.trim() ?? '';

  String? get _character {
    final character = _dialogueOverrides[_beat]?.character?.trim();
    return character == null || character.isEmpty ? null : character;
  }

  bool get _isNarration => _speaker == '이야기';

  bool get _isOrientationRosterScene =>
      _dialogueOverrides[_beat]?.id == 'decimal-final-ten-roster';

  bool _hasBatchim(String value) {
    if (value.isEmpty) return false;
    final last = value.runes.last;
    return last >= 0xAC00 && last <= 0xD7A3 ? (last - 0xAC00) % 28 != 0 : false;
  }

  String _resolvePlayerName(String source) {
    final name = _playerController.text.trim();
    if (name.isEmpty || !source.contains('{{playerName}}')) return source;
    final hasBatchim = _hasBatchim(name);
    return source
        .replaceAll('{{playerName}}은', '$name${hasBatchim ? '은' : '는'}')
        .replaceAll('{{playerName}}이', '$name${hasBatchim ? '이' : '가'}')
        .replaceAll('{{playerName}}과', '$name${hasBatchim ? '과' : '와'}')
        .replaceAll('{{playerName}}', name);
  }

  String get _speaker =>
      _resolvePlayerName(_dialogueOverrides[_beat]?.speaker ?? '이야기');

  String get _line => _resolvePlayerName(
    _dialogueOverrides[_beat]?.line ?? '대사 정본을 불러오지 못했습니다.',
  );

  String? get _stageDirection {
    final direction = _dialogueOverrides[_beat]?.direction.trim();
    return direction == null || direction.isEmpty
        ? null
        : _resolvePlayerName(direction);
  }

  String get _historyLine {
    final direction = _stageDirection?.trim();
    if (direction == null || direction.isEmpty) return _line;
    return '$direction\n$_line';
  }

  void _rememberCurrentLine() {
    final entry = '$_speaker\n$_historyLine';
    if (_dialogueHistory.isEmpty || _dialogueHistory.last != entry) {
      _dialogueHistory.add(entry);
    }
  }

  void _rememberNavigationBeat(int beat) {
    if (_beatNavigationHistory.isNotEmpty &&
        _beatNavigationHistory.last == beat) {
      return;
    }
    _beatNavigationHistory.add(beat);
    if (_beatNavigationHistory.length > _maximumWheelBackSteps) {
      _beatNavigationHistory.removeAt(0);
    }
  }

  void _goBackOneBeat() {
    if (_isCreating || _beatNavigationHistory.isEmpty) return;
    final previousBeat = _beatNavigationHistory.removeLast();
    if (previousBeat == _beat) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _playStoryFeedback();
    setState(() => _beat = previousBeat);
    unawaited(_saveCheckpoint());
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || event.scrollDelta.dy >= 0) return;
    final now = DateTime.now();
    final last = _lastWheelBackAt;
    if (last != null && now.difference(last) < _wheelBackDebounce) return;
    _lastWheelBackAt = now;
    _goBackOneBeat();
  }

  void _next() {
    if (_beat >= _dialogueEndBeat) return;
    final currentBeat = _beat;
    FocusManager.instance.primaryFocus?.unfocus();
    _rememberCurrentLine();
    _rememberNavigationBeat(currentBeat);
    _playStoryFeedback();
    setState(() {
      if (_beat == currentBeat) {
        _beat = math.min(currentBeat + 1, _dialogueEndBeat);
      }
    });
    unawaited(_saveCheckpoint());
  }

  Future<void> _saveCheckpoint() =>
      widget.onCheckpoint?.call(
        _beat,
        _academyPcPoweredOn,
        _academyStockAppOpen,
        _playerController.text,
        _companyController.text,
      ) ??
      Future<void>.value();

  void _confirmPlayerName() {
    final playerName = _playerController.text.trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    if (playerName.isEmpty) {
      setState(() => _creationError = '플레이할 이름을 입력해 주세요.');
      return;
    }
    if (playerName.length > 12) {
      setState(() => _creationError = '이름은 12자 이내로 입력해 주세요.');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    _playStoryFeedback(strong: true);
    setState(() {
      _playerController.text = playerName;
      _playerNameConfirmed = true;
      _creationError = null;
    });
    unawaited(_saveCheckpoint());
  }

  void _exitOnboarding() {
    unawaited(_saveCheckpoint());
    widget.onExit?.call();
  }

  Future<void> _showBacklog() async {
    _playStoryFeedback();
    final entries = <String>[..._dialogueHistory];
    final current = '$_speaker\n$_historyLine';
    if (entries.isEmpty || entries.last != current) entries.add(current);
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFF8E7),
      builder: (context) => SizedBox(
        key: const Key('story-backlog-sheet'),
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, color: _coral),
                  SizedBox(width: 8),
                  Text(
                    '지나간 대사',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                itemCount: entries.length,
                separatorBuilder: (_, _) => const Divider(height: 18),
                itemBuilder: (context, index) {
                  final parts = entries[index].split('\n');
                  final speaker = parts.first;
                  final line = parts.skip(1).join('\n');
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        speaker,
                        style: const TextStyle(
                          color: _coral,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        line,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSkipDialog() async {
    _playStoryFeedback();
    final startingBeat = _beat;
    final skipStep = _currentPrologueSkipStep;
    final shouldSkip = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('story-skip-dialog'),
        title: Text('${_withObjectParticle(skipStep.sectionLabel)} 건너뛸까요?'),
        content: Text(
          '${skipStep.sectionLabel} 구간만 건너뛰고 '
          '${skipStep.destinationLabel}의 첫 장면으로 이동합니다.'
          '${skipStep.targetBeat == _dialogueEndBeat ? ' 이동한 위치와 PC 진행 상태는 자동 저장됩니다.' : ''}',
        ),
        actions: [
          TextButton(
            key: const Key('story-skip-cancel'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('계속 보기'),
          ),
          FilledButton(
            key: const Key('story-skip-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text('${skipStep.destinationLabel}으로'),
          ),
        ],
      ),
    );
    if (!mounted || shouldSkip != true) return;
    _playStoryFeedback(strong: true);
    setState(() {
      _beatNavigationHistory.clear();
      _beat = skipStep.targetBeat;
    });
    unawaited(_saveCheckpoint());
    await _dialogueLoadFuture;
    if (!mounted) return;
    final resolvedSkipStep = _prologueSkipStepForBeat(startingBeat);
    if (_beat == resolvedSkipStep.targetBeat) return;
    setState(() => _beat = resolvedSkipStep.targetBeat);
    unawaited(_saveCheckpoint());
  }

  String _withObjectParticle(String value) {
    if (value.isEmpty) return value;
    final last = value.runes.last;
    final hasBatchim = last >= 0xAC00 && last <= 0xD7A3
        ? (last - 0xAC00) % 28 != 0
        : true;
    return '$value${hasBatchim ? '을' : '를'}';
  }

  Future<void> _finish() async {
    if (_isCreating) return;
    final playerName = _playerController.text.trim();
    final companyName = _companyController.text.trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    if (playerName.isEmpty || companyName.isEmpty) {
      setState(() {
        _creationError = '운용자 이름과 투자장부 이름을 모두 입력해 주세요.';
      });
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isCreating = true;
      _creationError = null;
      _creationProgress = const WorldLoadProgress(0.02, '데시멀 국가계좌 정보를 정리하는 중…');
    });
    await WidgetsBinding.instance.endOfFrame;
    try {
      await widget.onCreate(
        NewGameSetup(
          playerName: playerName,
          companyName: companyName,
          introChoice: 'stocks',
          startingTrait: StoryTrait.analysis,
          operatingPrinciple: OperatingPrinciple.reportLosses,
        ),
        (progress) {
          if (mounted) setState(() => _creationProgress = progress);
        },
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to finish new-game onboarding: $error\n$stackTrace');
      if (mounted) {
        setState(() {
          _creationError = '저장이나 주문 연습 화면 준비에 실패했습니다. 잠시 후 다시 눌러 주세요.';
        });
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _toggleAcademyPcPower() {
    if (_isCreating) return;
    _playStoryFeedback(strong: true);
    setState(() {
      _academyPcPoweredOn = !_academyPcPoweredOn;
      if (!_academyPcPoweredOn) _academyStockAppOpen = false;
      _creationError = null;
    });
    unawaited(_saveCheckpoint());
  }

  void _openAcademyStockApp() {
    if (_isCreating || !_academyPcPoweredOn) return;
    _playStoryFeedback();
    setState(() {
      _academyStockAppOpen = true;
      _creationError = null;
    });
    unawaited(_saveCheckpoint());
  }

  void _closeAcademyStockApp() {
    if (_isCreating || !_academyPcPoweredOn) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _playStoryFeedback();
    setState(() {
      _academyStockAppOpen = false;
      _creationError = null;
    });
    unawaited(_saveCheckpoint());
  }

  Future<void> _startAcademyMarketTutorial() async {
    if (_isCreating || !_academyPcPoweredOn || !_academyStockAppOpen) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _creationError = null);
    await _finish();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final isKeyboardOpen = viewInsets.bottom > 0;
    final isNameEntry =
        !_playerNameConfirmed ||
        (_beat >= _dialogueEndBeat &&
            _academyPcPoweredOn &&
            _academyStockAppOpen);
    final keyboardLift = isKeyboardOpen && isNameEntry
        ? viewInsets.bottom
        : 0.0;
    final panelBottomInset = _playerNameConfirmed && _beat < _dialogueEndBeat
        ? _storyDialogueBottomInset
        : 10.0;
    return Listener(
      key: const Key('story-wheel-navigation-listener'),
      onPointerSignal: _handlePointerSignal,
      child: Scaffold(
        backgroundColor: const Color(0xFF171B2A),
        resizeToAvoidBottomInset: false,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final sceneCharacterAsset = _character;
            final isTeacherScene = _speaker == '한서윤 운영관';
            return Stack(
              key: const Key('onboarding-stage'),
              fit: StackFit.expand,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 700),
                  child: _LivingBackground(
                    key: ValueKey(_background),
                    asset: _background,
                    sceneBeat: _beat,
                    ambientFlicker: true,
                  ),
                ),
                if (_playerNameConfirmed && sceneCharacterAsset != null)
                  Positioned.fill(
                    top: -_storyCharacterBottomInset,
                    bottom: _storyCharacterBottomInset,
                    child: IgnorePointer(
                      child: _OnboardingCharacterSlot(
                        key: const Key('story-character-stage-slot'),
                        asset: sceneCharacterAsset,
                        alignment: Alignment.bottomCenter,
                        characterKey: isTeacherScene
                            ? const Key('academy-teacher-character')
                            : const Key('story-character-character'),
                      ),
                    ),
                  ),
                const DecoratedBox(
                  key: Key('story-stage-reading-scrim'),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x33000000),
                        Colors.transparent,
                        Color(0x70000000),
                      ],
                      stops: [0, 0.52, 1],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: GestureDetector(
                    key: const Key('story-stage-advance-area'),
                    behavior: HitTestBehavior.translucent,
                    onTap: _isCreating || !_playerNameConfirmed
                        ? null
                        : () => _activeNovelDialogueState?._handleExternalTap(),
                  ),
                ),
                SafeArea(
                  child: IgnorePointer(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: _SceneLabel(
                        date: _dateLabel,
                        location: _location,
                        progress: (_beat + 1) / (_dialogueEndBeat + 1),
                      ),
                    ),
                  ),
                ),

                if (_playerNameConfirmed)
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 54, right: 10),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xB8292B3A),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0x55FFFFFF)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                key: const Key('story-backlog-button'),
                                tooltip: '지난 대사',
                                visualDensity: VisualDensity.compact,
                                color: Colors.white,
                                onPressed: _showBacklog,
                                icon: const Icon(
                                  Icons.history_rounded,
                                  size: 19,
                                ),
                              ),
                              IconButton(
                                key: const Key('story-skip-button'),
                                tooltip:
                                    '${_currentPrologueSkipStep.sectionLabel} 건너뛰기',
                                visualDensity: VisualDensity.compact,
                                color: _yellow,
                                onPressed: _showSkipDialog,
                                icon: const Icon(
                                  Icons.fast_forward_rounded,
                                  size: 19,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                AnimatedPositioned(
                  key: const Key('keyboard-name-panel'),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  left: 12,
                  right: 12,
                  bottom: keyboardLift + panelBottomInset,
                  child: SafeArea(
                    top: false,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          layoutBuilder: (currentChild, previousChildren) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                for (final child in previousChildren)
                                  IgnorePointer(child: child),
                                ?currentChild,
                              ],
                            );
                          },
                          child: _buildDialogue(context),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_isCreating)
                  Positioned.fill(
                    child: _NewGamePreparationOverlay(
                      progress: _creationProgress,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDialogue(BuildContext context) {
    if (!_playerNameConfirmed) {
      return _PlayerNameSetup(
        controller: _playerController,
        error: _creationError,
        onChanged: () => setState(() => _creationError = null),
        onConfirm: _confirmPlayerName,
      );
    }
    if (_beat >= _dialogueEndBeat) return _orientationComplete();
    if (_isOrientationRosterScene) return _orientationRoster();
    return _NovelDialogue(
      key: ValueKey(_beat),
      speaker: _speaker,
      playerName: _playerController.text.trim(),
      line: _line,
      stageDirection: _stageDirection,
      narration: _isNarration,
      onContinue: _next,
    );
  }

  Widget _orientationRoster() => _NovelDialogue(
    key: const ValueKey('orientation-roster'),
    speaker: _speaker,
    playerName: _playerController.text.trim(),
    line: _line,
    stageDirection: _stageDirection,
    onContinue: _next,
    child: Container(
      key: const Key('orientation-roster-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F2E3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8BE91)),
      ),
      child: Column(
        children: [
          const Text(
            '프로젝트 데시멀 · 최종 열 명',
            style: TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _orientationStat(
                  key: const Key('orientation-total-count'),
                  label: '총원',
                  value: '10명',
                  color: const Color(0xFF536A96),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _orientationStat(
                  key: const Key('orientation-male-count'),
                  label: '남자 동기',
                  value: '2명',
                  color: const Color(0xFF3F72A5),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _orientationStat(
                  key: const Key('orientation-female-count'),
                  label: '여자 동기',
                  value: '8명',
                  color: const Color(0xFFC85C72),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          const Text(
            '전국 보호시설 비공개 선발 · 남자 2명 · 여자 8명',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF697386),
              fontSize: 10,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _orientationStat({
    required Key key,
    required String label,
    required String value,
    required Color color,
  }) => Container(
    key: key,
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF697386),
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );

  Widget _orientationComplete() {
    final endingOverride = _dialogueOverrides[_beat];
    final isCanonicalPcEnding = endingOverride == null
        ? _beat == _orientationCompleteBeat
        : endingOverride.id == canonicalDialogueScenes.last['id'];
    return _NovelDialogue(
      key: const ValueKey('orientation-complete'),
      speaker: isCanonicalPcEnding
          ? _academyPcPoweredOn
                ? '데시멀 실습 PC'
                : _speaker
          : _speaker,
      playerName: _playerController.text.trim(),
      line: !isCanonicalPcEnding
          ? _line
          : !_academyPcPoweredOn
          ? '각자 배정된 PC의 전원 버튼을 눌러 보세요. 켜고 끄는 것부터 자기 손으로 확인합니다.'
          : _academyStockAppOpen
          ? '한빛통신의 실제 거래일 시세를 불러옵니다. 이름과 투자장부 이름을 정하면 첫 주문 실습이 시작됩니다.'
          : '부팅이 끝났습니다. 바탕화면의 주식실습 프로그램을 열어 회사·한 주·가격을 실제 화면에서 확인하세요.',
      stageDirection: !isCanonicalPcEnding
          ? _stageDirection
          : !_academyPcPoweredOn
          ? '06번 좌석의 베이지색 CRT와 본체는 아직 꺼져 있다.'
          : _academyStockAppOpen
          ? '주식실습 프로그램이 국가계좌 개통 정보를 기다리고 있다.'
          : '본체 팬이 돌고 CRT 화면에 데시멀 전용 바탕화면이 떠올랐다.',
      child: _AcademyPcTerminal(
        poweredOn: _academyPcPoweredOn,
        stockAppOpen: _academyStockAppOpen,
        playerController: _playerController,
        companyController: _companyController,
        creationError: _creationError,
        onTogglePower: _toggleAcademyPcPower,
        onOpenStockApp: _openAcademyStockApp,
        onCloseStockApp: _closeAcademyStockApp,
        onChanged: () {
          setState(() => _creationError = null);
          unawaited(_saveCheckpoint());
        },
        onStartTutorial: () => unawaited(_startAcademyMarketTutorial()),
        onExit: _exitOnboarding,
      ),
    );
  }
}

class _PlayerNameSetup extends StatelessWidget {
  const _PlayerNameSetup({
    required this.controller,
    required this.error,
    required this.onChanged,
    required this.onConfirm,
  });

  final TextEditingController controller;
  final String? error;
  final VoidCallback onChanged;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('prologue-player-name-card'),
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xF51B2A40), Color(0xF50B1423)],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xB883E5FF), width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x85000000),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.badge_outlined, color: Color(0xFF83E5FF), size: 20),
            SizedBox(width: 8),
            Text(
              '기록에 남길 이름',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Maplestory',
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        const Text(
          '지금 정한 이름으로 프롤로그의 주인공이 되고, 이후 저장과 모든 대사에도 그대로 표시됩니다.',
          style: TextStyle(
            color: Color(0xFFD9E9F5),
            fontFamily: 'Pretendard',
            fontSize: 11.5,
            height: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('prologue-player-name-input'),
          controller: controller,
          autofocus: true,
          maxLength: 12,
          textInputAction: TextInputAction.done,
          onChanged: (_) => onChanged(),
          onSubmitted: (_) => onConfirm(),
          style: const TextStyle(
            color: Color(0xFF17243A),
            fontFamily: 'Maplestory',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '플레이할 이름을 입력하세요',
            filled: true,
            fillColor: const Color(0xFFF7FBFF),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: Color(0xFF9DC7DC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: Color(0xFF4FD7FF), width: 2),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 7),
          Text(
            error!,
            key: const Key('prologue-player-name-error'),
            style: const TextStyle(
              color: Color(0xFFFFB0A8),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('prologue-player-name-confirm'),
            onPressed: onConfirm,
            icon: const Icon(Icons.login_rounded, size: 19),
            label: const Text('이 이름으로 시작'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(45),
              foregroundColor: const Color(0xFF092033),
              backgroundColor: const Color(0xFF83E5FF),
              textStyle: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _NewGamePreparationOverlay extends StatelessWidget {
  const _NewGamePreparationOverlay({required this.progress});

  final WorldLoadProgress progress;

  @override
  Widget build(BuildContext context) => ColoredBox(
    key: const Key('new-game-preparation-overlay'),
    color: const Color(0xD9171B2A),
    child: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFFE4A3), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 30,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.savings_rounded,
                  color: Color(0xFF536A96),
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  '국가계좌를 개통하고 있어요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF33405F),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 10),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    progress.label,
                    key: const Key('new-game-preparation-status'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF66728A),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                LinearProgressIndicator(
                  key: const Key('new-game-preparation-progress'),
                  value: progress.fraction,
                  minHeight: 9,
                  backgroundColor: const Color(0xFFE8E1D1),
                  color: const Color(0xFFFFA45F),
                  borderRadius: BorderRadius.circular(99),
                ),
                const SizedBox(height: 10),
                Text(
                  '${(progress.fraction * 100).round()}%',
                  key: const Key('new-game-preparation-percent'),
                  style: const TextStyle(
                    color: Color(0xFF536A96),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '주식·부동산 세계 계산은 처음하기에서 이미 끝냈어요.\n'
                  '지금은 운용자·투자회사 이름과 국가 환수 장부를 저장하는 중입니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF8B877F),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _LivingBackground extends StatefulWidget {
  const _LivingBackground({
    super.key,
    required this.asset,
    this.sceneBeat = 0,
    this.ambientFlicker = false,
  });

  final String asset;
  final int sceneBeat;
  final bool ambientFlicker;

  @override
  State<_LivingBackground> createState() => _LivingBackgroundState();
}

class _LivingBackgroundState extends State<_LivingBackground>
    with TickerProviderStateMixin {
  late final AnimationController _ambientController;
  late final AnimationController _scenePulseController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
    _scenePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    final isTestBinding = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding');
    if (const bool.fromEnvironment('FLUTTER_TEST') || isTestBinding) {
      _ambientController.value = 0.25;
      _scenePulseController.value = 1;
    } else {
      _ambientController.repeat();
      _scenePulseController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _LivingBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sceneBeat == widget.sceneBeat) return;
    final isTestBinding = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding');
    if (const bool.fromEnvironment('FLUTTER_TEST') || isTestBinding) {
      _scenePulseController.value = 1;
    } else {
      _scenePulseController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _scenePulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([_ambientController, _scenePulseController]),
    builder: (context, child) => LayoutBuilder(
      builder: (context, _) {
        final t = _ambientController.value;
        final wave = math.sin(t * math.pi * 2);
        final slowZoom = 1.032 + (wave + 1) * 0.0035;
        final scenePulse = math.sin(_scenePulseController.value * math.pi);
        final fluorescentPulse =
            0.025 +
            (math.sin(t * math.pi * 14) + 1) * 0.012 +
            (math.sin(t * math.pi * 34) > 0.97 ? 0.025 : 0);
        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(
              scale: slowZoom,
              alignment: Alignment(0, -0.08 + wave * 0.015),
              child: Image.asset(
                widget.asset,
                key: const Key('story-background-image'),
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
              ),
            ),
            if (widget.ambientFlicker)
              IgnorePointer(
                child: Opacity(
                  key: const Key('orientation-light-flicker'),
                  opacity: fluorescentPulse.clamp(0.0, 0.08),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFFF4C9),
                          Color(0x22FFE7A1),
                          Colors.transparent,
                        ],
                        stops: [0, 0.28, 0.66],
                      ),
                    ),
                  ),
                ),
              ),
            IgnorePointer(
              child: Opacity(
                key: const Key('story-scene-reaction-glow'),
                opacity: (scenePulse * 0.13).clamp(0.0, 0.13),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.25),
                      radius: 0.95,
                      colors: [Color(0x6686DFFF), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _OnboardingCharacterSlot extends StatefulWidget {
  const _OnboardingCharacterSlot({
    super.key,
    required this.asset,
    required this.alignment,
    required this.characterKey,
  });

  final String asset;
  final Alignment alignment;
  final Key characterKey;

  @override
  State<_OnboardingCharacterSlot> createState() =>
      _OnboardingCharacterSlotState();
}

class _OnboardingCharacterSlotState extends State<_OnboardingCharacterSlot>
    with TickerProviderStateMixin {
  late final AnimationController _idleController;
  late final AnimationController _reactionController;
  late final bool _motionEnabled;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8200),
    );
    _reactionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    final isTestBinding = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding');
    _motionEnabled =
        !const bool.fromEnvironment('FLUTTER_TEST') && !isTestBinding;
    if (_motionEnabled) {
      _idleController.repeat();
      _reactionController.forward();
    } else {
      _reactionController.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant _OnboardingCharacterSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset == widget.asset &&
        oldWidget.alignment == widget.alignment) {
      return;
    }
    if (_motionEnabled) {
      _reactionController.forward(from: 0);
    } else {
      _reactionController.value = 1;
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    _reactionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: 1,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          final horizontalOffset = widget.alignment.x < 0
              ? -0.08
              : widget.alignment.x > 0
              ? 0.08
              : 0.0;
          final entrance = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: entrance,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(horizontalOffset, 0.02),
                end: Offset.zero,
              ).animate(entrance),
              child: child,
            ),
          );
        },
        child: LayoutBuilder(
          key: ValueKey(
            '${widget.asset}-${widget.alignment.x}-${widget.alignment.y}',
          ),
          builder: (context, constraints) {
            final characterHeight =
                constraints.maxHeight * _storyCharacterHeightFactor;
            final characterWidth =
                (characterHeight * _storyCharacterAspectRatio)
                    .clamp(0.0, constraints.maxWidth)
                    .toDouble();
            final characterImageHeight = characterHeight
                .clamp(0.0, constraints.maxHeight - _storyCharacterBottomInset)
                .toDouble();
            return Align(
              alignment: widget.alignment,
              child: SizedBox(
                key: widget.characterKey,
                width: characterWidth,
                height: characterHeight,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Transform.scale(
                    key: const Key('story-character-scale'),
                    scale: _storyCharacterScaleForAsset(widget.asset),
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: characterWidth,
                      height: characterImageHeight,
                      child: Image.asset(
                        key: const Key('story-character-image'),
                        widget.asset,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                        filterQuality: FilterQuality.high,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        _idleController,
        _reactionController,
      ]),
      child: stage,
      builder: (context, child) {
        final motionAllowed =
            _motionEnabled && !MediaQuery.disableAnimationsOf(context);
        final phaseSeed = widget.asset.codeUnits.fold<int>(
          0,
          (sum, value) => (sum + value) % 360,
        );
        final phase = phaseSeed / 180 * math.pi;
        final idleAngle = _idleController.value * math.pi * 2;
        final breathing = motionAllowed
            ? (math.sin(idleAngle + phase) + 1) * 0.5
            : 0.0;
        final reactionProgress = motionAllowed
            ? Curves.easeOutCubic.transform(_reactionController.value)
            : 1.0;
        final reactionEmphasis = motionAllowed
            ? math.sin(_reactionController.value * math.pi)
            : 0.0;
        final reactionSide = phaseSeed.isEven ? 1.0 : -1.0;
        return Transform.translate(
          key: const Key('story-character-living-motion'),
          offset: Offset((1 - reactionProgress) * reactionSide * 7, 0),
          child: Transform.rotate(
            angle: reactionEmphasis * reactionSide * 0.0018,
            alignment: Alignment.bottomCenter,
            child: Transform(
              key: const Key('story-character-breathing-motion'),
              transform: Matrix4.diagonal3Values(
                1 - breathing * 0.0007,
                1 + breathing * 0.0022 + reactionEmphasis * 0.004,
                1,
              ),
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _AcademyPcTerminal extends StatelessWidget {
  const _AcademyPcTerminal({
    required this.poweredOn,
    required this.stockAppOpen,
    required this.playerController,
    required this.companyController,
    required this.creationError,
    required this.onTogglePower,
    required this.onOpenStockApp,
    required this.onCloseStockApp,
    required this.onChanged,
    required this.onStartTutorial,
    required this.onExit,
  });

  final bool poweredOn;
  final bool stockAppOpen;
  final TextEditingController playerController;
  final TextEditingController companyController;
  final String? creationError;
  final VoidCallback onTogglePower;
  final VoidCallback onOpenStockApp;
  final VoidCallback onCloseStockApp;
  final VoidCallback onChanged;
  final VoidCallback onStartTutorial;
  final VoidCallback onExit;

  bool get _canStart =>
      playerController.text.trim().isNotEmpty &&
      companyController.text.trim().isNotEmpty;

  InputDecoration _inputDecoration(String label, String hint) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF9FB6CB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF9FB6CB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2D79C7), width: 2),
        ),
      );

  Widget _header() => Row(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFD8C8A8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          '좌석 06 · CRT-06',
          style: TextStyle(
            color: Color(0xFF4B4335),
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      const Spacer(),
      Icon(
        poweredOn ? Icons.circle : Icons.circle_outlined,
        size: 11,
        color: poweredOn ? const Color(0xFF4BD37B) : const Color(0xFF807A70),
      ),
      const SizedBox(width: 5),
      Text(
        poweredOn ? '전원 ON' : '전원 OFF',
        key: const Key('academy-pc-power-status'),
        style: TextStyle(
          color: poweredOn ? const Color(0xFF217C45) : const Color(0xFF6F6A61),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
      if (poweredOn) ...[
        const SizedBox(width: 4),
        IconButton(
          key: const Key('academy-pc-power-off'),
          tooltip: 'PC 전원 끄기',
          visualDensity: VisualDensity.compact,
          onPressed: onTogglePower,
          icon: const Icon(Icons.power_settings_new_rounded, size: 19),
          color: const Color(0xFFC44848),
        ),
      ],
    ],
  );

  Widget _poweredOff() => Column(
    key: const Key('academy-pc-powered-off'),
    children: [
      Container(
        width: double.infinity,
        height: 92,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF111419),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF756D60), width: 5),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8)],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.power_off_rounded, color: Color(0xFF656A70), size: 30),
            SizedBox(height: 4),
            Text(
              '화면 신호 없음',
              style: TextStyle(
                color: Color(0xFF777D84),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: TextButton(
              key: const Key('orientation-exit-button'),
              onPressed: onExit,
              child: const Text('처음 화면으로'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              key: const Key('academy-pc-power-toggle'),
              onPressed: onTogglePower,
              icon: const Icon(Icons.power_settings_new_rounded),
              label: const Text('PC 전원 켜기'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                backgroundColor: const Color(0xFF2D79C7),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _desktop() => Container(
    key: const Key('academy-pc-desktop'),
    width: double.infinity,
    height: 150,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3D6B92), Color(0xFF75A6C7)],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF756D60), width: 5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '프로젝트 데시멀 · 06번 실습 PC',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            shadows: [Shadow(color: Colors.black45, blurRadius: 3)],
          ),
        ),
        const Spacer(),
        Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            key: const Key('academy-stock-app-icon'),
            onTap: onOpenStockApp,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 122,
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFFF8FCFF), Color(0xFFE2F2F3)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFD7E1)),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x4D0C2338),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Color(0x4DFFFFFF),
                    blurRadius: 2,
                    offset: Offset(0, -1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.asset(
                      'assets/images/stock_practice_app_icon_v1.png',
                      key: const Key('academy-stock-app-icon-image'),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      isAntiAlias: true,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    '주식실습',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        const Text(
          '시작 → 프로그램 → 주식실습',
          style: TextStyle(
            color: Color(0xFFEAF4FF),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _stockSetup() => Container(
    key: const Key('academy-stock-setup-screen'),
    width: double.infinity,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F6FA),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF8FA9BF), width: 2),
    ),
    child: Column(
      children: [
        Row(
          children: [
            IconButton(
              key: const Key('academy-stock-app-back'),
              tooltip: '바탕화면으로',
              visualDensity: VisualDensity.compact,
              onPressed: onCloseStockApp,
              icon: const Icon(Icons.arrow_back_rounded, size: 19),
            ),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '데시멀 주식실습',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '한빛통신 · 거래일 시세와 호가 연동',
                    style: TextStyle(
                      color: Color(0xFF536A96),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.lock_rounded, size: 17, color: Color(0xFF258257)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('academy-player-name-input'),
          controller: playerController,
          readOnly: true,
          maxLength: 12,
          textInputAction: TextInputAction.next,
          onChanged: (_) => onChanged(),
          decoration: _inputDecoration('운용자', '프롤로그에서 정한 이름'),
        ),
        const SizedBox(height: 7),
        TextField(
          key: const Key('academy-company-name-input'),
          controller: companyController,
          maxLength: 20,
          textInputAction: TextInputAction.done,
          onChanged: (_) => onChanged(),
          onSubmitted: (_) {
            if (_canStart) onStartTutorial();
          },
          decoration: _inputDecoration('투자장부 이름', '예: 데시멀 첫 장부'),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5D9),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: const Color(0xFFE4C779)),
          ),
          child: const Text(
            '국가원금 50,000원 · 기록형 원칙 · 확정이익 20% 국가 환수 / 80% 자립적립',
            key: Key('academy-state-account-rule'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6D571A),
              fontSize: 9,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (creationError != null) ...[
          const SizedBox(height: 6),
          Text(
            creationError!,
            key: const Key('academy-pc-creation-error'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFC53F4B),
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('academy-start-market-tutorial'),
            onPressed: _canStart ? onStartTutorial : null,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('국가계좌 만들고 실시간 주식 실습 시작'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              backgroundColor: const Color(0xFFCE3E4E),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    key: const Key('orientation-complete-card'),
    duration: const Duration(milliseconds: 220),
    width: double.infinity,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0xFFE9E3D4),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF9A8F7D), width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        _header(),
        const SizedBox(height: 7),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: !poweredOn
              ? _poweredOff()
              : stockAppOpen
              ? _stockSetup()
              : _desktop(),
        ),
      ],
    ),
  );
}

class _SceneLabel extends StatelessWidget {
  const _SceneLabel({
    required this.date,
    required this.location,
    required this.progress,
  });

  final String date;
  final String location;
  final double progress;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
    child: Column(
      children: [
        Row(
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xD9292B3A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x66FFFFFF)),
                ),
                child: Text(
                  '⌂  $location',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              date,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 3,
            value: progress,
            backgroundColor: const Color(0x55FFFFFF),
            valueColor: const AlwaysStoppedAnimation(_yellow),
          ),
        ),
      ],
    ),
  );
}

_NovelDialogueState? _activeNovelDialogueState;

const _decimalCohortSpeakers = <String>{
  '김학준',
  '김서아',
  '이지안',
  '최이서',
  '정아린',
  '박하은',
  '한수아',
  '오지우',
  '윤채아',
};

String _dialogueSpeakerName(String speaker) => switch (speaker) {
  '한규진 국정원장' => '한규진',
  '임서희 경제안보국장' => '임서희',
  '도윤석 기획조정관' => '도윤석',
  '조민경 권익감사관' => '조민경',
  '차은주 선발관' => '차은주',
  '오경태 시설관리관' => '오경태',
  '한서윤 운영관' => '한서윤',
  '윤하린 은행원' => '윤하린',
  _ => speaker,
};

String _dialogueSpeakerAffiliation(String speaker, String playerName) {
  if (speaker == '이야기') return 'PROJECT DECIMAL';
  if (speaker == '한규진 국정원장') return '국가정보원';
  if (speaker == '임서희 경제안보국장') return '국가정보원 · 경제안보국';
  if (speaker == '도윤석 기획조정관') return '국가정보원 · 기획조정실';
  if (speaker == '조민경 권익감사관') return '국가정보원 · 권익감사실';
  if (speaker == '차은주 선발관') return '프로젝트 데시멀 · 선발팀';
  if (speaker == '오경태 시설관리관') return '프로젝트 데시멀 · 시설관리';
  if (speaker == '한서윤 운영관') return '프로젝트 데시멀 · 운영관';
  if (speaker == '윤하린 은행원') return '새천년은행 · 개인금융';
  if (speaker == '데시멀 실습 PC') return '프로젝트 데시멀';
  if (speaker == '거절한 후보') return '장학 적성검사 응시자';
  if (_decimalCohortSpeakers.contains(speaker) ||
      (playerName.isNotEmpty && speaker == playerName)) {
    return '프로젝트 데시멀 · 제6기';
  }
  return '';
}

class _NovelDialogue extends StatefulWidget {
  const _NovelDialogue({
    super.key,
    required this.speaker,
    this.playerName = '',
    required this.line,
    this.narration = false,
    this.stageDirection,
    this.onContinue,
    this.continueKey,
    this.choices = const [],
    this.child,
  });

  final String speaker;
  final String playerName;
  final String line;
  final bool narration;
  final String? stageDirection;
  final VoidCallback? onContinue;
  final Key? continueKey;
  final List<_NovelChoice> choices;
  final Widget? child;

  @override
  State<_NovelDialogue> createState() => _NovelDialogueState();
}

class _NovelDialogueState extends State<_NovelDialogue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _typingController;

  bool get _typingComplete => _typingController.isCompleted;

  Duration _typingDuration(String line) => Duration(
    milliseconds: math.min(1400, math.max(180, line.length * 14)).toInt(),
  );

  @override
  void initState() {
    super.initState();
    _activeNovelDialogueState = this;
    _typingController = AnimationController(
      vsync: this,
      duration: _typingDuration(widget.line),
    )..addListener(() => setState(() {}));
    _typingController.forward();
  }

  @override
  void didUpdateWidget(covariant _NovelDialogue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.line != widget.line) {
      _typingController
        ..duration = _typingDuration(widget.line)
        ..reset()
        ..forward();
    }
  }

  void _handleExternalTap() {
    widget.onContinue?.call();
  }

  @override
  void dispose() {
    if (identical(_activeNovelDialogueState, this)) {
      _activeNovelDialogueState = null;
    }
    _typingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleCharacters = _typingComplete
        ? widget.line.length
        : (widget.line.length * _typingController.value).floor();
    final visibleLine = widget.line.substring(
      0,
      math.min(visibleCharacters, widget.line.length),
    );
    final speakerName = _dialogueSpeakerName(widget.speaker);
    final affiliation = _dialogueSpeakerAffiliation(
      widget.speaker,
      widget.playerName.trim(),
    );
    return GestureDetector(
      key: widget.onContinue == null
          ? null
          : widget.continueKey ?? const Key('story-continue'),
      behavior: HitTestBehavior.opaque,
      onTap: _handleExternalTap,
      child: Container(
        key: const Key('story-dialogue-panel'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 13, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                key: const Key('story-speaker-chip'),
                label: affiliation.isEmpty
                    ? widget.speaker
                    : '${widget.speaker}, $affiliation',
                child: ExcludeSemantics(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        speakerName,
                        key: const Key('story-speaker-name'),
                        style: const TextStyle(
                          color: Color(0xFFF8FBFF),
                          fontFamily: 'Pretendard',
                          fontSize: 18,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.45,
                          shadows: [
                            Shadow(
                              color: Color(0xB8000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      if (affiliation.isNotEmpty) ...[
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            affiliation,
                            key: const Key('story-speaker-affiliation'),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF62C9F6),
                              fontFamily: 'Pretendard',
                              fontSize: 11.5,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.25,
                              shadows: [
                                Shadow(
                                  color: Color(0xB8000000),
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const SizedBox(
                key: Key('story-dialogue-divider'),
                width: double.infinity,
                height: 9,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xAA9CB5C5),
                          Color(0x668AA8BC),
                          Color(0x009CB5C5),
                        ],
                        stops: [0, 0.7, 1],
                      ),
                    ),
                    child: SizedBox(width: double.infinity, height: 1),
                  ),
                ),
              ),
              Semantics(
                liveRegion: true,
                label: widget.line,
                child: Text(
                  visibleLine,
                  key: const Key('story-line-text'),
                  style: const TextStyle(
                    color: Color(0xFFF9FCFF),
                    fontFamily: 'Pretendard',
                    fontSize: 15.5,
                    height: 1.48,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    shadows: [
                      Shadow(
                        color: Color(0xE8000000),
                        blurRadius: 5,
                        offset: Offset(0, 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              if (_typingComplete && widget.choices.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...widget.choices.map(
                  (choice) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: choice,
                  ),
                ),
              ],
              if (_typingComplete && widget.child != null) ...[
                const SizedBox(height: 10),
                widget.child!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NovelChoice extends StatelessWidget {
  const _NovelChoice({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        minimumSize: const Size.fromHeight(46),
        foregroundColor: _ink,
        backgroundColor: const Color(0xEFFFFFFF),
        side: const BorderSide(color: Color(0xFFD8BE91)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const Icon(Icons.chevron_right_rounded, color: _coral),
        ],
      ),
    ),
  );
}
