enum FamilyPortraitPose { neutral, expressive, concerned, action }

abstract final class FamilyPortraitAssets {
  static const father = <FamilyPortraitPose, String>{
    FamilyPortraitPose.neutral:
        'assets/images/character_prologue_father_neutral_cartoon_v4.png',
    FamilyPortraitPose.expressive:
        'assets/images/character_prologue_father_skeptical_cartoon_v4.png',
    FamilyPortraitPose.concerned:
        'assets/images/character_prologue_father_concerned_cartoon_v4.png',
    FamilyPortraitPose.action:
        'assets/images/character_prologue_father_worn_serious_cartoon_v4.png',
  };

  static const mother = <FamilyPortraitPose, String>{
    FamilyPortraitPose.neutral:
        'assets/images/character_prologue_mother_neutral_cartoon_v4.png',
    FamilyPortraitPose.expressive:
        'assets/images/character_prologue_mother_warm_cartoon_v4.png',
    FamilyPortraitPose.concerned:
        'assets/images/character_prologue_mother_concerned_cartoon_v4.png',
    FamilyPortraitPose.action:
        'assets/images/character_prologue_mother_worn_homewear_cartoon_v4.png',
  };

  static const sister = <FamilyPortraitPose, String>{
    FamilyPortraitPose.neutral:
        'assets/images/character_prologue_sister_neutral_cartoon_v4.png',
    FamilyPortraitPose.expressive:
        'assets/images/character_prologue_sister_teasing_cartoon_v4.png',
    FamilyPortraitPose.concerned:
        'assets/images/character_prologue_sister_concerned_cartoon_v4.png',
    FamilyPortraitPose.action:
        'assets/images/character_prologue_sister_worn_homewear_cartoon_v4.png',
  };

  static const hero = <FamilyPortraitPose, String>{
    FamilyPortraitPose.neutral:
        'assets/images/character_prologue_hero_neutral_cartoon_v4.png',
    FamilyPortraitPose.expressive:
        'assets/images/character_prologue_hero_curious_cartoon_v4.png',
    FamilyPortraitPose.concerned:
        'assets/images/character_prologue_hero_determined_cartoon_v4.png',
    FamilyPortraitPose.action:
        'assets/images/character_prologue_hero_patched_hoodie_cartoon_v4.png',
  };

  static const grandfather = <FamilyPortraitPose, String>{
    FamilyPortraitPose.neutral:
        'assets/images/character_prologue_grandfather_neutral_cartoon_v4.png',
    FamilyPortraitPose.expressive:
        'assets/images/character_prologue_grandfather_questioning_cartoon_v4.png',
    FamilyPortraitPose.concerned:
        'assets/images/character_prologue_grandfather_approving_cartoon_v4.png',
    FamilyPortraitPose.action:
        'assets/images/character_prologue_grandfather_worn_vest_cartoon_v4.png',
  };

  static String pose(
    Map<FamilyPortraitPose, String> character,
    FamilyPortraitPose pose,
  ) => character[pose]!;
}
