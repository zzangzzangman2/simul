enum StoryTrait { stability, innovation, analysis, control }

enum OperatingPrinciple { reportLosses, noHotTips, keepCash }

class StoryState {
  static const academyLevelKeys = <int, String>{
    1: 'firstLight',
    2: 'smallLedger',
    3: 'hiddenValue',
    4: 'marketGrain',
    5: 'ownersSeat',
    6: 'myName',
  };
  static const academyLevelTitles = <int, String>{
    1: '첫빛',
    2: '작은 장부',
    3: '숨은 가치',
    4: '시장의 결',
    5: '주인의 자리',
    6: '내 이름',
  };

  const StoryState({
    required this.playerName,
    required this.playerBirthYear,
    required this.introChoice,
    required this.startingTrait,
    required this.operatingPrinciple,
    required this.householdStability,
    required this.schoolBalance,
    required this.roomLevel,
    required this.accountAuthorityLevel,
    required this.stateAccountHolder,
    required this.storyFlags,
    required this.seenStoryEventIds,
    required this.companyCultureTags,
  });

  final String playerName;
  final int playerBirthYear;
  final String introChoice;
  final StoryTrait startingTrait;
  final OperatingPrinciple operatingPrinciple;
  final int householdStability;
  final int schoolBalance;
  final int roomLevel;
  final int accountAuthorityLevel;
  final String stateAccountHolder;
  final Map<String, dynamic> storyFlags;
  final List<String> seenStoryEventIds;
  final List<String> companyCultureTags;

  /// Academy students use Korean year-age: a 1987-born sixth-cohort student is
  /// fourteen in 2000.
  int ageOn(DateTime date) =>
      (date.year - playerBirthYear + 1).clamp(0, 200).toInt();

  int flagInt(String key, [int fallback = 0]) =>
      (storyFlags[key] as num?)?.toInt() ?? fallback;
  bool flagBool(String key, [bool fallback = false]) =>
      storyFlags[key] as bool? ?? fallback;
  int get startingSeedMoney => flagInt('startingSeedMoney');
  int get earnedSeedMoney => flagInt('earnedSeedMoney');
  int get seedMoneyTotal => startingSeedMoney + earnedSeedMoney;
  bool get orphanageReboot => flagBool('orphanageReboot');
  int get academyLevel => flagInt('academyLevel', orphanageReboot ? 1 : 0);
  int get academyMaxLevel =>
      flagInt('academyMaxLevel', orphanageReboot ? 6 : 0);
  int get expectedSeedAge => academyLevel + 13;
  int academyLevelOn(DateTime date) => orphanageReboot
      ? (ageOn(date) - 13).clamp(1, academyMaxLevel).toInt()
      : academyLevel;
  String academyLevelKeyOn(DateTime date) =>
      academyLevelKeys[academyLevelOn(date)] ?? '';
  String academyLevelTitleOn(DateTime date) =>
      academyLevelTitles[academyLevelOn(date)] ?? '';
  int get stateRecoveryRateBps => flagInt('stateRecoveryRateBps', 2000);
  int get stateRecoveryTotal => flagInt('stateRecoveryTotal');
  int get selfRelianceReserve => flagInt('selfRelianceReserve');
  int get reputation => flagInt('reputation');
  int get externalAum => flagInt('externalAum');
  int get officeTier => flagInt('officeTier');
  bool get fundLaunched => flagBool('fundLaunched');
  bool get tutorialSeen => flagBool('hubTutorialSeen');
  bool get marketTutorialEligible => flagBool('marketTutorialEligible');
  bool get marketTutorialSeen => flagBool('marketTutorialSeen');
  List<Map<String, dynamic>> get newsArchive {
    final raw = storyFlags['newsArchive'];
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  factory StoryState.newPlayer({
    required String playerName,
    required String introChoice,
    required StoryTrait startingTrait,
    required OperatingPrinciple operatingPrinciple,
  }) => StoryState.newOrphanagePlayer(
    playerName: playerName,
    introChoice: introChoice,
    startingTrait: startingTrait,
    operatingPrinciple: operatingPrinciple,
  );

  factory StoryState.newOrphanagePlayer({
    required String playerName,
    required String introChoice,
    required StoryTrait startingTrait,
    required OperatingPrinciple operatingPrinciple,
  }) {
    final traitTrust = switch (startingTrait) {
      StoryTrait.stability => 2,
      StoryTrait.analysis => 1,
      StoryTrait.innovation => 0,
      StoryTrait.control => -1,
    };
    final traitSchool = switch (startingTrait) {
      StoryTrait.analysis => 4,
      StoryTrait.stability => 2,
      StoryTrait.innovation => 1,
      StoryTrait.control => 0,
    };
    return StoryState(
      playerName: playerName.trim(),
      playerBirthYear: 1987,
      introChoice: introChoice,
      startingTrait: startingTrait,
      operatingPrinciple: operatingPrinciple,
      householdStability: 55,
      schoolBalance: 60 + traitSchool,
      roomLevel: 0,
      accountAuthorityLevel: 1,
      stateAccountHolder: 'future_development_fund',
      storyFlags: {
        'prologueComplete': true,
        'orphanageReboot': true,
        'futureDevelopmentCohort': 6,
        'storyAgeMode': 'koreanYearAge',
        'academyProgram': 'seedTrack',
        'academyLevel': 1,
        'academyMaxLevel': 6,
        'academyLevelKey': 'firstLight',
        'academyLevelTitle': '첫빛',
        'seedTrackStartAge': 14,
        'seedTrackCompletionAge': 19,
        'campaignStartDate': '2000-01-02',
        'stateAccountActive': true,
        'stateAccountOwner': '대한민국 미래양성기금',
        'stateRecoveryRateBps': 2000,
        'stateRecoveryTotal': 0,
        'selfRelianceReserve': 0,
        'selfRelianceUnlockAge': 19,
        'isLegalCompany': false,
        'startingSeedMoney': 0,
        'seedMoneySource': '',
        'earnedSeedMoney': 0,
        'cohortTrust': 30 + traitTrust,
        'hakjunAffinity': 30,
        'suaAffinity': 30,
        'teacherTrust': 30,
        'workSessions': 0,
        'workSessionsToday': 0,
        'firstSeedGoalReached': true,
        'firstOrderExecuted': false,
        'reputation': 0,
        'officeTier': 0,
        'fundLaunched': false,
        'externalAum': 0,
        'hubTutorialSeen': false,
        'marketTutorialEligible': true,
        'marketTutorialSeen': false,
        'performanceHistory': <Map<String, dynamic>>[],
        'newsArchive': <Map<String, dynamic>>[],
      },
      seenStoryEventIds: const [
        'PROLOGUE_FUTURE_DEVELOPMENT_PLAN',
        'COHORT_6_STATE_ACCOUNT_ACTIVATED',
      ],
      companyCultureTags: [
        'futureDevelopmentCohort6',
        operatingPrinciple.name,
        startingTrait.name,
        introChoice,
      ],
    );
  }

  factory StoryState.migratedDefault(String companyName) {
    return StoryState.newOrphanagePlayer(
      playerName: '소년',
      introChoice: 'migrated_save',
      startingTrait: StoryTrait.analysis,
      operatingPrinciple: OperatingPrinciple.reportLosses,
    ).copyWith(
      storyFlags: {
        ...StoryState.newOrphanagePlayer(
          playerName: '소년',
          introChoice: 'migrated_save',
          startingTrait: StoryTrait.analysis,
          operatingPrinciple: OperatingPrinciple.reportLosses,
        ).storyFlags,
        'prologueComplete': true,
        'marketTutorialEligible': false,
        'marketTutorialSeen': true,
        'migratedCompanyName': companyName,
      },
    );
  }

  StoryState copyWith({
    int? householdStability,
    int? schoolBalance,
    int? roomLevel,
    int? accountAuthorityLevel,
    String? stateAccountHolder,
    Map<String, dynamic>? storyFlags,
    List<String>? seenStoryEventIds,
    List<String>? companyCultureTags,
  }) {
    return StoryState(
      playerName: playerName,
      playerBirthYear: playerBirthYear,
      introChoice: introChoice,
      startingTrait: startingTrait,
      operatingPrinciple: operatingPrinciple,
      householdStability: (householdStability ?? this.householdStability).clamp(
        0,
        100,
      ),
      schoolBalance: (schoolBalance ?? this.schoolBalance).clamp(0, 100),
      roomLevel: (roomLevel ?? this.roomLevel).clamp(0, 4),
      accountAuthorityLevel:
          (accountAuthorityLevel ?? this.accountAuthorityLevel).clamp(0, 5),
      stateAccountHolder: stateAccountHolder ?? this.stateAccountHolder,
      storyFlags: storyFlags ?? this.storyFlags,
      seenStoryEventIds: seenStoryEventIds ?? this.seenStoryEventIds,
      companyCultureTags: companyCultureTags ?? this.companyCultureTags,
    );
  }

  Map<String, dynamic> toJson() => {
    'playerName': playerName,
    'playerBirthYear': playerBirthYear,
    'introChoice': introChoice,
    'startingTrait': startingTrait.name,
    'operatingPrinciple': operatingPrinciple.name,
    'householdStability': householdStability,
    'schoolBalance': schoolBalance,
    'roomLevel': roomLevel,
    'accountAuthorityLevel': accountAuthorityLevel,
    'stateAccountHolder': stateAccountHolder,
    'storyFlags': storyFlags,
    'seenStoryEventIds': seenStoryEventIds,
    'companyCultureTags': companyCultureTags,
  };

  static int _migratedPlayerBirthYear(Map<String, dynamic> json) {
    return 1987;
  }

  static Map<String, dynamic> _migratedStoryFlags(Map<String, dynamic> json) {
    final stored =
        (json['storyFlags'] as Map?)?.cast<String, dynamic>() ?? const {};
    final migrated = Map<String, dynamic>.from(stored);
    final storedLevel = (migrated['academyLevel'] as num?)?.toInt() ?? 1;
    final academyLevel = storedLevel.clamp(1, 6).toInt();
    migrated
      ..['futureDevelopmentCohort'] = 6
      ..['orphanageReboot'] = true
      ..['storyAgeMode'] = 'koreanYearAge'
      ..['academyProgram'] = 'seedTrack'
      ..['academyLevel'] = academyLevel
      ..['academyMaxLevel'] = 6
      ..['academyLevelKey'] = academyLevelKeys[academyLevel]
      ..['academyLevelTitle'] = academyLevelTitles[academyLevel]
      ..['seedTrackStartAge'] = 14
      ..['seedTrackCompletionAge'] = 19
      ..['selfRelianceUnlockAge'] = 19
      ..['stateAccountActive'] = true
      ..['stateAccountOwner'] = '대한민국 미래양성기금'
      ..['seedMoneySource'] = 'future_development_fund'
      ..putIfAbsent('stateRecoveryRateBps', () => 2000)
      ..putIfAbsent('stateRecoveryTotal', () => 0)
      ..putIfAbsent('selfRelianceReserve', () => 0)
      ..putIfAbsent('cohortTrust', () => 30)
      ..putIfAbsent('hakjunAffinity', () => 30)
      ..putIfAbsent('suaAffinity', () => 30)
      ..putIfAbsent('teacherTrust', () => 30)
      ..remove('academyTuitionDebt')
      ..remove('academyTuitionOriginal')
      ..remove('academyTuitionPaidByFather')
      ..remove('academyTuitionRepaidDay')
      ..remove('guardianConsent')
      ..remove('fatherOperationsAdvisor')
      ..remove('seedMoneySourceLegacy');
    if (<String>{
      'mother',
      'father',
      'sibling',
      'grandfather',
    }.contains(migrated['activeResearchHelper'])) {
      migrated
        ..remove('activeResearchHelper')
        ..remove('activeResearchHelperDay')
        ..remove('researchBonusPct');
    }
    return migrated;
  }

  factory StoryState.fromJson(
    Map<String, dynamic> json, {
    required String companyName,
  }) {
    if (json.isEmpty) return StoryState.migratedDefault(companyName);
    return StoryState(
      playerName: json['playerName'] as String? ?? '소년',
      playerBirthYear: _migratedPlayerBirthYear(json),
      introChoice: json['introChoice'] as String? ?? 'migrated_save',
      startingTrait: StoryTrait.values.firstWhere(
        (value) => value.name == json['startingTrait'],
        orElse: () => StoryTrait.analysis,
      ),
      operatingPrinciple: OperatingPrinciple.values.firstWhere(
        (value) => value.name == json['operatingPrinciple'],
        orElse: () => OperatingPrinciple.reportLosses,
      ),
      householdStability: (json['householdStability'] as num?)?.toInt() ?? 55,
      schoolBalance: (json['schoolBalance'] as num?)?.toInt() ?? 60,
      roomLevel: (json['roomLevel'] as num?)?.toInt() ?? 0,
      accountAuthorityLevel:
          (json['accountAuthorityLevel'] as num?)?.toInt() ?? 0,
      stateAccountHolder: 'future_development_fund',
      storyFlags: _migratedStoryFlags(json),
      seenStoryEventIds: ((json['seenStoryEventIds'] as List?) ?? const [])
          .whereType<String>()
          .where(
            (id) => !const <String>{
              'HOME_FATHER_TOOLS',
              'HOME_SISTER_DESK',
              'HOME_GRANDFATHER_BEDDING',
              'HOME_MOTHER_FLOOR',
              'HOME_MOTHER_RICE',
              'HOME_FAMILY_FRIDGE',
            }.contains(id),
          )
          .toList(growable: false),
      companyCultureTags: ((json['companyCultureTags'] as List?) ?? const [])
          .cast<String>(),
    );
  }
}
