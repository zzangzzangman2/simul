enum StoryTrait { stability, innovation, analysis, control }

enum FamilyRule { reportLosses, noHotTips, keepCash }

class StoryState {
  const StoryState({
    required this.playerName,
    required this.playerBirthYear,
    required this.introChoice,
    required this.startingTrait,
    required this.familyRule,
    required this.familyTrust,
    required this.motherAffinity,
    required this.fatherAffinity,
    required this.siblingAffinity,
    required this.grandfatherAffinity,
    required this.householdStability,
    required this.schoolBalance,
    required this.roomLevel,
    required this.accountAuthorityLevel,
    required this.guardianAccountHolder,
    required this.storyFlags,
    required this.seenStoryEventIds,
    required this.companyCultureTags,
  });

  final String playerName;
  final int playerBirthYear;
  final String introChoice;
  final StoryTrait startingTrait;
  final FamilyRule familyRule;
  final int familyTrust;
  final int motherAffinity;
  final int fatherAffinity;
  final int siblingAffinity;
  final int grandfatherAffinity;
  final int householdStability;
  final int schoolBalance;
  final int roomLevel;
  final int accountAuthorityLevel;
  final String guardianAccountHolder;
  final Map<String, dynamic> storyFlags;
  final List<String> seenStoryEventIds;
  final List<String> companyCultureTags;

  factory StoryState.newPlayer({
    required String playerName,
    required String introChoice,
    required StoryTrait startingTrait,
    required FamilyRule familyRule,
  }) {
    return StoryState(
      playerName: playerName.trim(),
      playerBirthYear: 1989,
      introChoice: introChoice,
      startingTrait: startingTrait,
      familyRule: familyRule,
      familyTrust: 30,
      motherAffinity: familyRule == FamilyRule.reportLosses ? 33 : 30,
      fatherAffinity: familyRule == FamilyRule.noHotTips ? 33 : 30,
      siblingAffinity: 30,
      grandfatherAffinity: familyRule == FamilyRule.keepCash ? 33 : 30,
      householdStability: 55,
      schoolBalance: 60,
      roomLevel: 0,
      accountAuthorityLevel: 1,
      guardianAccountHolder: 'mother',
      storyFlags: const {
        'prologueComplete': true,
        'guardianConsent': true,
        'isLegalCompany': false,
      },
      seenStoryEventIds: const ['PROLOGUE_MILLENNIUM'],
      companyCultureTags: [familyRule.name],
    );
  }

  factory StoryState.migratedDefault(String companyName) {
    return StoryState.newPlayer(
      playerName: '소년',
      introChoice: 'migrated_save',
      startingTrait: StoryTrait.analysis,
      familyRule: FamilyRule.reportLosses,
    ).copyWith(
      storyFlags: {
        'prologueComplete': true,
        'guardianConsent': true,
        'isLegalCompany': false,
        'migratedCompanyName': companyName,
      },
    );
  }

  StoryState copyWith({
    int? familyTrust,
    int? motherAffinity,
    int? fatherAffinity,
    int? siblingAffinity,
    int? grandfatherAffinity,
    int? householdStability,
    int? schoolBalance,
    int? roomLevel,
    int? accountAuthorityLevel,
    Map<String, dynamic>? storyFlags,
    List<String>? seenStoryEventIds,
    List<String>? companyCultureTags,
  }) {
    return StoryState(
      playerName: playerName,
      playerBirthYear: playerBirthYear,
      introChoice: introChoice,
      startingTrait: startingTrait,
      familyRule: familyRule,
      familyTrust: (familyTrust ?? this.familyTrust).clamp(0, 100),
      motherAffinity: (motherAffinity ?? this.motherAffinity).clamp(0, 100),
      fatherAffinity: (fatherAffinity ?? this.fatherAffinity).clamp(0, 100),
      siblingAffinity: (siblingAffinity ?? this.siblingAffinity).clamp(0, 100),
      grandfatherAffinity: (grandfatherAffinity ?? this.grandfatherAffinity)
          .clamp(0, 100),
      householdStability: (householdStability ?? this.householdStability).clamp(
        0,
        100,
      ),
      schoolBalance: (schoolBalance ?? this.schoolBalance).clamp(0, 100),
      roomLevel: (roomLevel ?? this.roomLevel).clamp(0, 4),
      accountAuthorityLevel:
          (accountAuthorityLevel ?? this.accountAuthorityLevel).clamp(0, 5),
      guardianAccountHolder: guardianAccountHolder,
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
    'familyRule': familyRule.name,
    'familyTrust': familyTrust,
    'motherAffinity': motherAffinity,
    'fatherAffinity': fatherAffinity,
    'siblingAffinity': siblingAffinity,
    'grandfatherAffinity': grandfatherAffinity,
    'householdStability': householdStability,
    'schoolBalance': schoolBalance,
    'roomLevel': roomLevel,
    'accountAuthorityLevel': accountAuthorityLevel,
    'guardianAccountHolder': guardianAccountHolder,
    'storyFlags': storyFlags,
    'seenStoryEventIds': seenStoryEventIds,
    'companyCultureTags': companyCultureTags,
  };

  factory StoryState.fromJson(
    Map<String, dynamic> json, {
    required String companyName,
  }) {
    if (json.isEmpty) return StoryState.migratedDefault(companyName);
    return StoryState(
      playerName: json['playerName'] as String? ?? '소년',
      playerBirthYear: (json['playerBirthYear'] as num?)?.toInt() ?? 1989,
      introChoice: json['introChoice'] as String? ?? 'migrated_save',
      startingTrait: StoryTrait.values.firstWhere(
        (value) => value.name == json['startingTrait'],
        orElse: () => StoryTrait.analysis,
      ),
      familyRule: FamilyRule.values.firstWhere(
        (value) => value.name == json['familyRule'],
        orElse: () => FamilyRule.reportLosses,
      ),
      familyTrust: (json['familyTrust'] as num?)?.toInt() ?? 30,
      motherAffinity: (json['motherAffinity'] as num?)?.toInt() ?? 30,
      fatherAffinity: (json['fatherAffinity'] as num?)?.toInt() ?? 30,
      siblingAffinity: (json['siblingAffinity'] as num?)?.toInt() ?? 30,
      grandfatherAffinity: (json['grandfatherAffinity'] as num?)?.toInt() ?? 30,
      householdStability: (json['householdStability'] as num?)?.toInt() ?? 55,
      schoolBalance: (json['schoolBalance'] as num?)?.toInt() ?? 60,
      roomLevel: (json['roomLevel'] as num?)?.toInt() ?? 0,
      accountAuthorityLevel:
          (json['accountAuthorityLevel'] as num?)?.toInt() ?? 1,
      guardianAccountHolder:
          json['guardianAccountHolder'] as String? ?? 'mother',
      storyFlags:
          (json['storyFlags'] as Map?)?.cast<String, dynamic>() ?? const {},
      seenStoryEventIds: ((json['seenStoryEventIds'] as List?) ?? const [])
          .cast<String>(),
      companyCultureTags: ((json['companyCultureTags'] as List?) ?? const [])
          .cast<String>(),
    );
  }
}
