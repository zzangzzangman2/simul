part of 'main.dart';

enum GameAudioScene {
  silent,
  title,
  mystery,
  somber,
  hub,
  finance,
  relationship,
  market,
  action,
  horseRacing,
  casino,
}

enum GameSfx {
  tap,
  select,
  confirm,
  error,
  open,
  close,
  back,
  toggle,
  notification,
  messageSend,
  crtGlitch,
  tick,
  bookOpen,
  pageFlip,
  bookClose,
  paperPlace,
  paperRustle,
  coins,
  coinsLarge,
  doorOpen,
  doorClose,
  metalLatch,
  footstep,
  raceBell,
  impactSoft,
  impactMetal,
  impactWood,
  cardShuffle,
  cardSlide,
  cardPlace,
  chipLay,
  chipsHandle,
  chipsCollide,
  diceShake,
  diceThrow,
  crowdVictory,
}

enum GameLoopSfx { horseGallop, raceCrowd }

class _GameAudioSceneConfig {
  const _GameAudioSceneConfig(this.asset, this.volume);

  final String? asset;
  final double volume;
}

extension on GameAudioScene {
  _GameAudioSceneConfig get audioConfig => switch (this) {
    GameAudioScene.silent => const _GameAudioSceneConfig(null, 0),
    GameAudioScene.title => const _GameAudioSceneConfig(
      'audio/bgm/title_gentle_theme.ogg',
      0.28,
    ),
    GameAudioScene.mystery => const _GameAudioSceneConfig(
      'audio/bgm/story_hesitation.ogg',
      0.25,
    ),
    GameAudioScene.somber => const _GameAudioSceneConfig(
      'audio/bgm/story_piano_sad.ogg',
      0.25,
    ),
    GameAudioScene.hub => const _GameAudioSceneConfig(
      'audio/bgm/hub_gentle_brew.ogg',
      0.25,
    ),
    GameAudioScene.finance => const _GameAudioSceneConfig(
      'audio/bgm/finance_sakuya.ogg',
      0.23,
    ),
    GameAudioScene.relationship => const _GameAudioSceneConfig(
      'audio/bgm/relationship_raindrop.ogg',
      0.24,
    ),
    GameAudioScene.market => const _GameAudioSceneConfig(
      'audio/bgm/market_portside_cafe.ogg',
      0.24,
    ),
    GameAudioScene.action => const _GameAudioSceneConfig(
      'audio/bgm/action_strategy.ogg',
      0.27,
    ),
    GameAudioScene.horseRacing => const _GameAudioSceneConfig(
      'audio/bgm/horse_racing_prairie4.ogg',
      0.24,
    ),
    GameAudioScene.casino => const _GameAudioSceneConfig(
      'audio/bgm/casino_taisho.ogg',
      0.24,
    ),
  };
}

class _GameSfxConfig {
  const _GameSfxConfig(this.asset, this.volume);

  final String asset;
  final double volume;
}

extension on GameSfx {
  _GameSfxConfig get audioConfig => switch (this) {
    GameSfx.tap => const _GameSfxConfig('audio/sfx/ui_click.ogg', 0.10),
    GameSfx.select => const _GameSfxConfig('audio/sfx/ui_select.ogg', 0.25),
    GameSfx.confirm => const _GameSfxConfig('audio/sfx/ui_confirm.ogg', 0.42),
    GameSfx.error => const _GameSfxConfig('audio/sfx/ui_error.ogg', 0.38),
    GameSfx.open => const _GameSfxConfig('audio/sfx/ui_open.ogg', 0.30),
    GameSfx.close => const _GameSfxConfig('audio/sfx/ui_close.ogg', 0.28),
    GameSfx.back => const _GameSfxConfig('audio/sfx/ui_back.ogg', 0.25),
    GameSfx.toggle => const _GameSfxConfig('audio/sfx/ui_switch.ogg', 0.23),
    GameSfx.notification => const _GameSfxConfig(
      'audio/sfx/notification.ogg',
      0.38,
    ),
    GameSfx.messageSend => const _GameSfxConfig(
      'audio/sfx/message_send.ogg',
      0.34,
    ),
    GameSfx.crtGlitch => const _GameSfxConfig('audio/sfx/crt_glitch.ogg', 0.27),
    GameSfx.tick => const _GameSfxConfig('audio/sfx/ui_tick.ogg', 0.18),
    GameSfx.bookOpen => const _GameSfxConfig('audio/sfx/book_open.ogg', 0.38),
    GameSfx.pageFlip => const _GameSfxConfig('audio/sfx/page_flip.ogg', 0.32),
    GameSfx.bookClose => const _GameSfxConfig('audio/sfx/book_close.ogg', 0.38),
    GameSfx.paperPlace => const _GameSfxConfig(
      'audio/sfx/paper_place.ogg',
      0.35,
    ),
    GameSfx.paperRustle => const _GameSfxConfig(
      'audio/sfx/paper_rustle.ogg',
      0.32,
    ),
    GameSfx.coins => const _GameSfxConfig('audio/sfx/coins.ogg', 0.38),
    GameSfx.coinsLarge => const _GameSfxConfig(
      'audio/sfx/coins_large.ogg',
      0.45,
    ),
    GameSfx.doorOpen => const _GameSfxConfig('audio/sfx/door_open.ogg', 0.34),
    GameSfx.doorClose => const _GameSfxConfig('audio/sfx/door_close.ogg', 0.34),
    GameSfx.metalLatch => const _GameSfxConfig(
      'audio/sfx/metal_latch.ogg',
      0.36,
    ),
    GameSfx.footstep => const _GameSfxConfig('audio/sfx/footstep_1.ogg', 0.26),
    GameSfx.raceBell => const _GameSfxConfig('audio/sfx/race_bell.ogg', 0.55),
    GameSfx.impactSoft => const _GameSfxConfig(
      'audio/sfx/impact_soft.ogg',
      0.36,
    ),
    GameSfx.impactMetal => const _GameSfxConfig(
      'audio/sfx/impact_metal.ogg',
      0.42,
    ),
    GameSfx.impactWood => const _GameSfxConfig(
      'audio/sfx/impact_wood.ogg',
      0.42,
    ),
    GameSfx.cardShuffle => const _GameSfxConfig(
      'audio/sfx/card_shuffle.ogg',
      0.42,
    ),
    GameSfx.cardSlide => const _GameSfxConfig('audio/sfx/card_slide.ogg', 0.38),
    GameSfx.cardPlace => const _GameSfxConfig('audio/sfx/card_place.ogg', 0.42),
    GameSfx.chipLay => const _GameSfxConfig('audio/sfx/chip_lay.ogg', 0.42),
    GameSfx.chipsHandle => const _GameSfxConfig(
      'audio/sfx/chips_handle.ogg',
      0.42,
    ),
    GameSfx.chipsCollide => const _GameSfxConfig(
      'audio/sfx/chips_collide.ogg',
      0.44,
    ),
    GameSfx.diceShake => const _GameSfxConfig('audio/sfx/dice_shake.ogg', 0.42),
    GameSfx.diceThrow => const _GameSfxConfig('audio/sfx/dice_throw.ogg', 0.46),
    GameSfx.crowdVictory => const _GameSfxConfig(
      'audio/sfx/crowd_victory.ogg',
      0.56,
    ),
  };
}

extension on GameLoopSfx {
  _GameSfxConfig get audioConfig => switch (this) {
    GameLoopSfx.horseGallop => const _GameSfxConfig(
      'audio/sfx/horse_gallop_loop.ogg',
      0.43,
    ),
    GameLoopSfx.raceCrowd => const _GameSfxConfig(
      'audio/sfx/crowd_ambience.ogg',
      0.10,
    ),
  };
}

class _AudioSceneRegistration {
  const _AudioSceneRegistration(this.token, this.scene);

  final Object token;
  final GameAudioScene scene;
}

class GameAudio {
  GameAudio._();

  static final GameAudio instance = GameAudio._();

  // Every music source, including visual-novel music, goes through this one
  // player. A new track is never started until the previous track has stopped.
  final AudioPlayer _bgmPlayer = AudioPlayer(playerId: 'project-decimal-bgm');
  final List<AudioPlayer> _sfxPlayers = List<AudioPlayer>.generate(
    8,
    (_) => AudioPlayer(),
  );
  final List<_AudioSceneRegistration> _sceneStack = [];
  final Map<GameLoopSfx, AudioPlayer> _loopPlayers = {};
  final Set<GameLoopSfx> _requestedLoops = {};
  final Map<GameSfx, DateTime> _lastSfxAt = {};

  int _nextSfxPlayer = 0;
  bool _unlocked = false;
  bool _dialogueBgmOverrideActive = false;
  String? _dialogueBgmAsset;
  double _dialogueBgmVolume = 0;
  String? _playingBgmAsset;
  double _playingBgmVolume = 0;
  Future<void> _bgmSyncChain = Future<void>.value();

  GameAudioScene get desiredScene =>
      _sceneStack.isEmpty ? GameAudioScene.silent : _sceneStack.last.scene;

  void registerScene(Object token, GameAudioScene scene) {
    _sceneStack.removeWhere((entry) => identical(entry.token, token));
    _sceneStack.add(_AudioSceneRegistration(token, scene));
    _scheduleBgmSync();
  }

  void updateScene(Object token, GameAudioScene scene) {
    final index = _sceneStack.indexWhere(
      (entry) => identical(entry.token, token),
    );
    if (index < 0) {
      registerScene(token, scene);
      return;
    }
    _sceneStack[index] = _AudioSceneRegistration(token, scene);
    _scheduleBgmSync();
  }

  void unregisterScene(Object token) {
    _sceneStack.removeWhere((entry) => identical(entry.token, token));
    _scheduleBgmSync();
  }

  void setDialogueBgm(String asset, {required double volume}) {
    final normalized = asset.trim();
    _dialogueBgmOverrideActive = true;
    _dialogueBgmAsset = normalized.isEmpty ? null : normalized;
    _dialogueBgmVolume = volume.clamp(0, 1).toDouble();
    _scheduleBgmSync();
  }

  void clearDialogueBgm() {
    _dialogueBgmOverrideActive = false;
    _dialogueBgmAsset = null;
    _dialogueBgmVolume = 0;
    _scheduleBgmSync();
  }

  void handleUserGesture() {
    if (!_unlocked) {
      _unlocked = true;
      _scheduleBgmSync(force: true);
      for (final effect in _requestedLoops) {
        unawaited(_playLoop(effect));
      }
    }
    playSfx(GameSfx.tap);
  }

  void playSfx(GameSfx effect, {double volumeScale = 1}) {
    if (!_unlocked) return;
    final now = DateTime.now();
    final lastPlayed = _lastSfxAt[effect];
    final cooldown = effect == GameSfx.tap ? 45 : 28;
    if (lastPlayed != null &&
        now.difference(lastPlayed).inMilliseconds < cooldown) {
      return;
    }
    _lastSfxAt[effect] = now;
    final config = effect.audioConfig;
    final player = _sfxPlayers[_nextSfxPlayer];
    _nextSfxPlayer = (_nextSfxPlayer + 1) % _sfxPlayers.length;
    unawaited(_playSfx(player, config, volumeScale));
  }

  /// Three-layer race surge cue assembled from the project's existing sounds:
  /// air cut, hoof impact, then a short activation chime.
  void playRaceSurgeSfx({bool decisive = false}) {
    if (!_unlocked) return;
    playSfx(GameSfx.messageSend, volumeScale: decisive ? 1.0 : 0.78);
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 34), () {
        playSfx(GameSfx.impactSoft, volumeScale: decisive ? 0.95 : 0.68);
      }),
    );
    if (decisive) {
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 82), () {
          playSfx(GameSfx.notification, volumeScale: 0.72);
        }),
      );
    }
  }

  void startLoop(GameLoopSfx effect) {
    _requestedLoops.add(effect);
    if (_unlocked) unawaited(_playLoop(effect));
  }

  void stopLoop(GameLoopSfx effect) {
    _requestedLoops.remove(effect);
    final player = _loopPlayers[effect];
    if (player != null) unawaited(player.stop());
  }

  Future<void> _playLoop(GameLoopSfx effect) async {
    if (!_requestedLoops.contains(effect)) return;
    final config = effect.audioConfig;
    final player = _loopPlayers.putIfAbsent(effect, AudioPlayer.new);
    try {
      await player.stop();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(config.volume);
      await player.play(AssetSource(config.asset));
    } catch (_) {
      // Keep gameplay running if audio is unavailable in a test backend.
    }
  }

  Future<void> _playSfx(
    AudioPlayer player,
    _GameSfxConfig config,
    double volumeScale,
  ) async {
    try {
      await player.stop();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume((config.volume * volumeScale).clamp(0, 1));
      await player.play(AssetSource(config.asset));
    } catch (_) {
      // Audio can be unavailable in headless widget tests or before a browser
      // grants playback permission. The next real user gesture retries it.
    }
  }

  _GameAudioSceneConfig get _desiredBgmConfig => _dialogueBgmOverrideActive
      ? _GameAudioSceneConfig(_dialogueBgmAsset, _dialogueBgmVolume)
      : desiredScene.audioConfig;

  void _scheduleBgmSync({bool force = false}) {
    _bgmSyncChain = _bgmSyncChain.then(
      (_) => _syncBgm(force: force),
      onError: (_) => _syncBgm(force: force),
    );
  }

  Future<void> _syncBgm({bool force = false}) async {
    if (!_unlocked) return;
    var nextConfig = _desiredBgmConfig;
    if (!force && nextConfig.asset == _playingBgmAsset) {
      if (_playingBgmAsset != null && nextConfig.volume != _playingBgmVolume) {
        await _bgmPlayer.setVolume(nextConfig.volume);
        _playingBgmVolume = nextConfig.volume;
      }
      return;
    }

    try {
      if (_playingBgmAsset != null) {
        const fadeOutSteps = 6;
        for (var step = fadeOutSteps - 1; step >= 0; step--) {
          await _bgmPlayer.setVolume(_playingBgmVolume * (step / fadeOutSteps));
          await Future<void>.delayed(const Duration(milliseconds: 24));
        }
      }
      await _bgmPlayer.stop();
      _playingBgmAsset = null;
      _playingBgmVolume = 0;

      // Scene changes can arrive during the fade-out. Read the latest desired
      // track only after the old one is fully stopped.
      nextConfig = _desiredBgmConfig;
      final nextAsset = nextConfig.asset;
      if (nextAsset == null) return;

      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(0);
      await _bgmPlayer.play(AssetSource(nextAsset));
      _playingBgmAsset = nextAsset;
      _playingBgmVolume = nextConfig.volume;

      const fadeInSteps = 8;
      for (var step = 1; step <= fadeInSteps; step++) {
        await _bgmPlayer.setVolume(nextConfig.volume * (step / fadeInSteps));
        await Future<void>.delayed(const Duration(milliseconds: 24));
      }
    } catch (_) {
      // Keep gameplay usable if an OS/browser audio backend rejects playback.
      try {
        await _bgmPlayer.stop();
      } catch (_) {}
      _playingBgmAsset = null;
      _playingBgmVolume = 0;
    }
  }
}

class GameAudioSceneScope extends StatefulWidget {
  const GameAudioSceneScope({
    required this.scene,
    required this.child,
    super.key,
  });

  final GameAudioScene scene;
  final Widget child;

  @override
  State<GameAudioSceneScope> createState() => _GameAudioSceneScopeState();
}

class _GameAudioSceneScopeState extends State<GameAudioSceneScope> {
  final Object _token = Object();

  @override
  void initState() {
    super.initState();
    GameAudio.instance.registerScene(_token, widget.scene);
    if (widget.scene != GameAudioScene.silent &&
        widget.scene != GameAudioScene.title) {
      GameAudio.instance.playSfx(GameSfx.open, volumeScale: 0.6);
    }
  }

  @override
  void didUpdateWidget(covariant GameAudioSceneScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene != widget.scene) {
      GameAudio.instance.updateScene(_token, widget.scene);
    }
  }

  @override
  void dispose() {
    GameAudio.instance.unregisterScene(_token);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class GameAudioGestureLayer extends StatefulWidget {
  const GameAudioGestureLayer({required this.child, super.key});

  final Widget child;

  @override
  State<GameAudioGestureLayer> createState() => _GameAudioGestureLayerState();
}

class _GameAudioGestureLayerState extends State<GameAudioGestureLayer> {
  final Map<int, (Offset, DateTime)> _pointerStarts = {};

  void _handlePointerDown(PointerDownEvent event) {
    _pointerStarts[event.pointer] = (event.position, DateTime.now());
  }

  void _handlePointerUp(PointerUpEvent event) {
    final start = _pointerStarts.remove(event.pointer);
    if (start == null) return;
    final moved = (event.position - start.$1).distance;
    final elapsed = DateTime.now().difference(start.$2);
    if (moved <= 14 && elapsed <= const Duration(milliseconds: 650)) {
      GameAudio.instance.handleUserGesture();
    }
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: _handlePointerDown,
    onPointerUp: _handlePointerUp,
    onPointerCancel: (event) => _pointerStarts.remove(event.pointer),
    child: widget.child,
  );
}

GameAudioScene? gameAudioSceneForPage(Widget page) {
  if (page is CasinoScreen) return GameAudioScene.casino;
  if (page is HorseRacingMiniGame) return GameAudioScene.horseRacing;
  if (page is RiderMiniGame) return GameAudioScene.action;
  if (page is StockMarketScreen ||
      page is HomeComputerScreen ||
      page is ShareholderCompanyHubScreen ||
      page is WeeklyPortfolioReviewScreen ||
      page is PortfolioLedgerScreen) {
    return GameAudioScene.market;
  }
  if (page is BankScreen ||
      page is AssetSpendingScreen ||
      page is BusinessManagementScreen ||
      page is LifeCalendarScreen ||
      page is OrganizationScreen ||
      page is DailyWrapUpScreen) {
    return GameAudioScene.finance;
  }
  if (page is RelationshipStatusScreen ||
      page is RelationshipEveningScreen ||
      page is PhoneMessengerScreen ||
      page is PhoneChatScreen ||
      page is CohortDailyResultScreen ||
      page is CohortStandingEventScreen ||
      page is CohortWithdrawalCrisisScreen) {
    return GameAudioScene.relationship;
  }
  if (page is AcademyDecisionScene) return GameAudioScene.mystery;
  if (page is NewsGeneratingScene) return GameAudioScene.action;
  if (page is ApartmentHubScreen ||
      page is HomeImprovementScreen ||
      page is SeedMoneyHubScreen ||
      page is WeekendScheduleScreen) {
    return GameAudioScene.hub;
  }
  if (page is CampaignEndingScreen) return GameAudioScene.somber;
  return null;
}
