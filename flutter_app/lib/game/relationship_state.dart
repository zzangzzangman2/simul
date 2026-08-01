enum RelationshipActivity { conversation, date }

enum RelationshipStage {
  newClassmate,
  friendly,
  interested,
  close,
  special,
  trusted,
}

extension RelationshipStageLabel on RelationshipStage {
  String get label => switch (this) {
    RelationshipStage.newClassmate => '새 동기',
    RelationshipStage.friendly => '친한 동기',
    RelationshipStage.interested => '신경 쓰이는 사이',
    RelationshipStage.close => '마음을 아는 사이',
    RelationshipStage.special => '특별한 사이',
    RelationshipStage.trusted => '가장 가까운 사이',
  };
}

RelationshipStage relationshipStageFor(int affection) => switch (affection) {
  >= 100 => RelationshipStage.trusted,
  >= 80 => RelationshipStage.special,
  >= 60 => RelationshipStage.close,
  >= 40 => RelationshipStage.interested,
  >= 20 => RelationshipStage.friendly,
  _ => RelationshipStage.newClassmate,
};

const relationshipDateUnlockAffection = 20;
const relationshipMinAffection = 1;
const relationshipMaxAffection = 100;

class RelationshipChoiceDefinition {
  const RelationshipChoiceDefinition({
    required this.id,
    required this.label,
    required this.response,
    required this.affectionDelta,
  });

  final String id;
  final String label;
  final String response;
  final int affectionDelta;
}

class RelationshipSceneDefinition {
  const RelationshipSceneDefinition({
    required this.id,
    required this.activity,
    required this.location,
    required this.title,
    required this.prompt,
    required this.choices,
  });

  final String id;
  final RelationshipActivity activity;
  final String location;
  final String title;
  final String prompt;
  final List<RelationshipChoiceDefinition> choices;
}

class CohortGirlProfile {
  const CohortGirlProfile({
    required this.id,
    required this.name,
    required this.mbti,
    required this.role,
    required this.accentValue,
    required this.portraitAsset,
    required this.conversationScenes,
    required this.dateScene,
  });

  final String id;
  final String name;
  final String mbti;
  final String role;
  final int accentValue;
  final String? portraitAsset;
  final List<RelationshipSceneDefinition> conversationScenes;
  final RelationshipSceneDefinition dateScene;
}

const cohortGirlProfiles = <CohortGirlProfile>[
  CohortGirlProfile(
    id: 'kim_seoa',
    name: '김서아',
    mbti: 'ISFJ',
    role: '기록으로 약속을 지키는 생활실 서기',
    accentValue: 0xFFF38B96,
    portraitAsset:
        'assets/images/production_soft_painted/kim_seoa/01_neutral_notebook_v1.png',
    conversationScenes: <RelationshipSceneDefinition>[
      RelationshipSceneDefinition(
        id: 'seoa_note',
        activity: RelationshipActivity.conversation,
        location: '공용 생활실',
        title: '번진 대여 장부',
        prompt: '서아가 물에 번진 대여 장부를 들고 작은 한숨을 쉰다. 몇 줄은 이름이 안 보인다.',
        choices: <RelationshipChoiceDefinition>[
          RelationshipChoiceDefinition(
            id: 'rebuild_together',
            label: '기억나는 사람부터 같이 다시 적자.',
            response: '“응. 의심부터 하는 것보다 확인하면서 적는 게 낫지.” 서아가 네 쪽으로 장부를 돌린다.',
            affectionDelta: 5,
          ),
          RelationshipChoiceDefinition(
            id: 'praise_handwriting',
            label: '그래도 네 글씨는 진짜 알아보기 쉽다.',
            response: '“지금 그게 중요한가 싶긴 한데… 고마워.” 서아의 입꼬리가 살짝 올라간다.',
            affectionDelta: 3,
          ),
          RelationshipChoiceDefinition(
            id: 'ignore_record',
            label: '몇 줄쯤 없어도 아무도 모르지 않을까?',
            response: '“그래서 적는 건데.” 서아가 장부를 자기 쪽으로 당긴다.',
            affectionDelta: -2,
          ),
        ],
      ),
      RelationshipSceneDefinition(
        id: 'seoa_promise',
        activity: RelationshipActivity.conversation,
        location: '기숙사',
        title: '잊힌 청소 약속',
        prompt: '서아가 비어 있는 청소 담당 칸을 가리킨다. 누군가 구두로 맡았지만 이름을 안 적었다.',
        choices: <RelationshipChoiceDefinition>[
          RelationshipChoiceDefinition(
            id: 'own_and_write',
            label: '내가 할게. 이번엔 이름까지 적자.',
            response: '“좋아. 말이랑 기록이 같으면 나도 안 불안해.” 서아가 펜을 건넨다.',
            affectionDelta: 5,
          ),
          RelationshipChoiceDefinition(
            id: 'ask_memory',
            label: '누가 말했는지 같이 떠올려 볼까?',
            response: '“그것도 괜찮아. 몰아붙이지 말고 한 명씩 물어보자.”',
            affectionDelta: 3,
          ),
          RelationshipChoiceDefinition(
            id: 'blame_someone',
            label: '안 적은 사람이 잘못한 거지.',
            response: '“잘못부터 정하면 아무도 솔직하게 말 안 해.” 서아가 표를 덮는다.',
            affectionDelta: -2,
          ),
        ],
      ),
    ],
    dateScene: RelationshipSceneDefinition(
      id: 'seoa_stationery_date',
      activity: RelationshipActivity.date,
      location: '학교 앞 문구점',
      title: '둘이 고르는 새 장부',
      prompt: '서아가 종이 두께가 다른 공책을 번갈아 만져 본다. “오래 쓸 거면 뭘 골라야 할까?”',
      choices: <RelationshipChoiceDefinition>[
        RelationshipChoiceDefinition(
          id: 'choose_together',
          label: '네가 적고, 내가 넘겨 보면서 같이 고르자.',
          response: '“같이 쓸 장부 같네.” 서아가 웃으며 가장 튼튼한 공책을 집는다.',
          affectionDelta: 8,
        ),
        RelationshipChoiceDefinition(
          id: 'trust_choice',
          label: '서아가 오래 쓸 수 있는 걸로 골라.',
          response: '“내가 좋아하는 것까지 기억해 주네.” 서아가 표지를 한참 바라본다.',
          affectionDelta: 5,
        ),
        RelationshipChoiceDefinition(
          id: 'rush_purchase',
          label: '다 똑같아 보이는데 제일 싼 걸로 가자.',
          response: '“같이 고르러 온 의미가 없잖아.” 서아가 공책을 다시 내려놓는다.',
          affectionDelta: -3,
        ),
      ],
    ),
  ),
  CohortGirlProfile(
    id: 'lee_jian',
    name: '이지안',
    mbti: 'ISTP',
    role: '직접 시험해 원인을 찾는 수리 담당',
    accentValue: 0xFF77BCE8,
    portraitAsset:
        'assets/images/production_soft_painted/lee_jian/01_neutral_screwdriver_v1.png',
    conversationScenes: <RelationshipSceneDefinition>[
      RelationshipSceneDefinition(
        id: 'jian_radio',
        activity: RelationshipActivity.conversation,
        location: '공용 생활실',
        title: '소리가 끊기는 라디오',
        prompt: '지안이 라디오 뒷판을 열어 둔 채 안테나를 조금씩 움직이고 있다.',
        choices: <RelationshipChoiceDefinition>[
          RelationshipChoiceDefinition(
            id: 'test_signal',
            label: '내가 안테나 잡을게. 어디서 끊기는지 말해 줘.',
            response: '“좋아. 말보다 이게 빠르지.” 지안이 네 손의 위치를 눈금처럼 확인한다.',
            affectionDelta: 5,
          ),
          RelationshipChoiceDefinition(
            id: 'ask_cause',
            label: '지금 제일 의심되는 부품이 뭐야?',
            response: '“접점. 근데 아직 확정은 아니야.” 지안이 드라이버를 네게 보여 준다.',
            affectionDelta: 3,
          ),
          RelationshipChoiceDefinition(
            id: 'pretend_fix',
            label: '그냥 세게 치면 켜지는 거 아냐?',
            response: '“그러다 진짜 고장 나.” 지안이 라디오를 네 손에서 멀리 둔다.',
            affectionDelta: -2,
          ),
        ],
      ),
      RelationshipSceneDefinition(
        id: 'jian_outlet',
        activity: RelationshipActivity.conversation,
        location: 'PC 실습실',
        title: '헐거운 콘센트',
        prompt: '지안이 사용 금지 표시를 붙인 콘센트 앞에 쪼그려 앉아 있다.',
        choices: <RelationshipChoiceDefinition>[
          RelationshipChoiceDefinition(
            id: 'guard_and_report',
            label: '아무도 못 쓰게 내가 보고 있을게. 선생님께 같이 말하자.',
            response: '“그럼 안전하게 확인할 수 있겠다.” 지안이 처음으로 고개를 편하게 든다.',
            affectionDelta: 5,
          ),
          RelationshipChoiceDefinition(
            id: 'fetch_tool',
            label: '필요한 공구 있으면 가져올까?',
            response: '“절연 장갑부터. 순서 알고 물어본 건 괜찮네.”',
            affectionDelta: 3,
          ),
          RelationshipChoiceDefinition(
            id: 'touch_outlet',
            label: '내가 한번 눌러 볼까?',
            response: '“손 떼.” 지안이 짧게 말하고 네 앞을 막는다.',
            affectionDelta: -2,
          ),
        ],
      ),
    ],
    dateScene: RelationshipSceneDefinition(
      id: 'jian_electronics_date',
      activity: RelationshipActivity.date,
      location: '세운상가 전자부품점',
      title: '둘만의 부품 구경',
      prompt: '지안이 낡은 부품 상자를 발견하고 눈을 빛낸다. “이 안에 쓸 만한 게 있을지도 몰라.”',
      choices: <RelationshipChoiceDefinition>[
        RelationshipChoiceDefinition(
          id: 'sort_parts',
          label: '규격 읽어 줘. 내가 같은 것끼리 나눌게.',
          response: '“손 빠르네. 다음 상자도 같이 보자.” 지안이 자연스럽게 네 옆에 붙는다.',
          affectionDelta: 8,
        ),
        RelationshipChoiceDefinition(
          id: 'ask_demo',
          label: '하나 고르면 나중에 어떻게 쓰는지 보여 줘.',
          response: '“보여 주는 건 쉬워. 네가 직접 해 보면 더 빠르고.”',
          affectionDelta: 5,
        ),
        RelationshipChoiceDefinition(
          id: 'buy_pretty',
          label: '예쁜 색 부품이면 아무거나 사자.',
          response: '“부품은 색으로 작동 안 해.” 지안이 상자를 닫는다.',
          affectionDelta: -3,
        ),
      ],
    ),
  ),
  CohortGirlProfile(
    id: 'choi_iseo',
    name: '최이서',
    mbti: 'ISFP',
    role: '손작업과 개인 경계를 지키는 제작자',
    accentValue: 0xFFB58CE8,
    portraitAsset:
        'assets/images/production_soft_painted/choi_iseo/01_base_thread_v1.png',
    conversationScenes: <RelationshipSceneDefinition>[
      RelationshipSceneDefinition(
        id: 'iseo_name_tag',
        activity: RelationshipActivity.conversation,
        location: '기숙사',
        title: '색실 이름표',
        prompt: '이서가 네 이름표 위에 실 세 가지를 올려놓는다. “너는 어떤 색이 편해?”',
        choices: <RelationshipChoiceDefinition>[
          RelationshipChoiceDefinition(
            id: 'choose_feeling',
            label: '이 색. 매일 봐도 마음이 편할 것 같아.',
            response: '“응, 네가 직접 고른 게 제일 좋아.” 이서가 그 실을 조심스럽게 꿴다.',
            affectionDelta: 5,
          ),
          RelationshipChoiceDefinition(
            id: 'trust_artist',
            label: '이서가 보기 좋은 조합도 궁금해.',
            response: '“내 취향도 물어보는 거야? 그럼 두 색만 섞어 볼게.”',
            affectionDelta: 3,
          ),
          RelationshipChoiceDefinition(
            id: 'dismiss_color',
            label: '아무 색이나 해. 별 차이 없잖아.',
            response: '“너한테 차이 없으면 오늘은 안 만들어도 되겠다.”',
            affectionDelta: -2,
          ),
        ],
      ),
      RelationshipSceneDefinition(
        id: 'iseo_locker',
        activity: RelationshipActivity.conversation,
        location: '공용 생활실',
        title: '사물함 표시',
        prompt: '이서가 개인 사물함과 공용 칸을 구분할 작은 표식을 만들고 있다.',
        choices: <RelationshipChoiceDefinition>[
          RelationshipChoiceDefinition(
            id: 'ask_boundary',
            label: '어디까지가 네 칸인지 먼저 알려 줘.',
            response: '“그렇게 물어보면 편해.” 이서가 선을 직접 짚어 준다.',
            affectionDelta: 5,
          ),
          RelationshipChoiceDefinition(
            id: 'offer_material',
            label: '남는 종이 필요하면 내 거 써도 돼.',
            response: '“고마워. 쓸 때 먼저 말할게.”',
            affectionDelta: 3,
          ),
          RelationshipChoiceDefinition(
            id: 'move_things',
            label: '내가 보기 좋게 물건부터 옮겨 줄게.',
            response: '“아니, 묻고 만져 줘.” 이서가 네 손보다 먼저 사물함을 닫는다.',
            affectionDelta: -2,
          ),
        ],
      ),
    ],
    dateScene: RelationshipSceneDefinition(
      id: 'iseo_fabric_date',
      activity: RelationshipActivity.date,
      location: '동대문 원단 골목',
      title: '천과 단추 사이',
      prompt: '이서가 색이 조금씩 다른 천 조각을 햇빛에 비춰 본다. “사진으로 볼 때랑 완전 다르지?”',
      choices: <RelationshipChoiceDefinition>[
        RelationshipChoiceDefinition(
          id: 'compare_texture',
          label: '응. 눈 감고 만져 보고 서로 느낌 말해 볼까?',
          response: '“그거 재밌겠다.” 이서가 웃으며 네 손바닥 위에 천 조각을 올린다.',
          affectionDelta: 8,
        ),
        RelationshipChoiceDefinition(
          id: 'ask_favorite',
          label: '이서가 제일 만들고 싶은 건 어떤 천이야?',
          response: '“내가 만들고 싶은 거? 그건 좀 오래 얘기할 수 있어.”',
          affectionDelta: 5,
        ),
        RelationshipChoiceDefinition(
          id: 'rank_taste',
          label: '비싼 천이 무조건 제일 좋은 거지?',
          response: '“쓰는 사람이 불편하면 비싸도 별로야.” 이서가 고개를 젓는다.',
          affectionDelta: -3,
        ),
      ],
    ),
  ),
  CohortGirlProfile(
    id: 'jung_arin',
    name: '정아린',
    mbti: 'ESTJ',
    role: '시간표와 실행 순서를 잡는 현장 반장',
    accentValue: 0xFFFF9466,
    portraitAsset:
        'assets/images/production_soft_painted/jung_arin/01_base_cheeky_v1.png',
    conversationScenes: <RelationshipSceneDefinition>[
      RelationshipSceneDefinition(
        id: 'arin_schedule',
        activity: RelationshipActivity.conversation,
        location: '중앙 복도',
        title: '비어 있는 담당 칸',
        prompt: '아린이 내일 준비표를 들고 네 앞을 막는다. “이 일, 담당이 아직 없어.”',
        choices: <RelationshipChoiceDefinition>[
          RelationshipChoiceDefinition(
            id: 'take_deadline',
            label: '내가 맡을게. 아홉 시까지 끝내면 되지?',
            response: '“딱 그 말이 필요했어.” 아린이 네 이름 옆에 시간을 적는다.',
            affectionDelta: 5,
          ),
          RelationshipChoiceDefinition(
            id: 'split_task',
            label: '반씩 나누면 더 빨리 끝나지 않을까?',
            response: '“좋아. 네가 앞쪽, 내가 뒤쪽. 끝나면 서로 확인.”',
            affectionDelta: 3,
          ),
          RelationshipChoiceDefinition(
            id: 'delay_answer',
            label: '내일 기분 봐서 하면 안 돼?',
            response: '“그래서 계속 비어 있잖아.” 아린이 다른 이름을 찾는다.',
            affectionDelta: -2,
          ),
        ],
      ),
      RelationshipSceneDefinition(
        id: 'arin_morning',
        activity: RelationshipActivity.conversation,
        location: '미래양성원 본관 앞',
        title: '아침 운동 약속',
        prompt: '아린이 운동화 끈을 다시 묶으며 묻는다. “내일도 같이 뛸 거면 몇 시?”',
        choices: <RelationshipChoiceDefinition>[
          RelationshipChoiceDefinition(
            id: 'set_alarm',
            label: '일곱 시. 내가 먼저 나와 있을게.',
            response: '“말 바꾸기 없기다.” 아린이 만족한 듯 손목시계를 맞춘다.',
            affectionDelta: 5,
          ),
          RelationshipChoiceDefinition(
            id: 'ask_pace',
            label: '일곱 시 반은 어때? 대신 네 속도에 맞출게.',
            response: '“협상은 구체적이네. 좋아, 일곱 시 반.”',
            affectionDelta: 3,
          ),
          RelationshipChoiceDefinition(
            id: 'wake_me',
            label: '네가 계속 깨워 주면 나갈게.',
            response: '“세 번까지만 깨운다고 했지. 네 준비는 네 몫이야.”',
            affectionDelta: -2,
          ),
        ],
      ),
    ],
    dateScene: RelationshipSceneDefinition(
      id: 'arin_snack_date',
      activity: RelationshipActivity.date,
      location: '학교 앞 분식집',
      title: '계획 없는 한 시간',
      prompt: '주문을 마친 아린이 빈 종이를 꺼내려다 멈춘다. “오늘도 계획표 만들면 좀 이상하겠지?”',
      choices: <RelationshipChoiceDefinition>[
        RelationshipChoiceDefinition(
          id: 'one_rule',
          label: '오늘 규칙은 하나. 같이 맛있게 먹기.',
          response: '“그 정도 계획은 마음에 들어.” 아린이 종이를 접고 떡볶이를 네 쪽으로 민다.',
          affectionDelta: 8,
        ),
        RelationshipChoiceDefinition(
          id: 'plan_next',
          label: '먹고 나서 다음에 어디 갈지만 정하자.',
          response: '“다음도 있다는 뜻이네.” 아린이 괜히 시계를 다시 본다.',
          affectionDelta: 5,
        ),
        RelationshipChoiceDefinition(
          id: 'mock_schedule',
          label: '데이트까지 시간표 짜는 건 너무 빡세지.',
          response: '“물어본 내가 바보네.” 아린이 접은 종이를 가방에 넣는다.',
          affectionDelta: -3,
        ),
      ],
    ),
  ),
  CohortGirlProfile(
    id: 'park_haeun',
    name: '박하은',
    mbti: 'ENFJ',
    role: '말 못 한 불편을 합의로 바꾸는 조정자',
    accentValue: 0xFFFF7F9B,
    portraitAsset:
        'assets/images/production_soft_painted/park_haeun/01_base_wave_v1.png',
    conversationScenes: <RelationshipSceneDefinition>[
      RelationshipSceneDefinition(
        id: 'haeun_medicine',
        activity: RelationshipActivity.conversation,
        location: '기숙사',
        title: '남은 감기약',
        prompt: '하은이 아픈 친구를 챙기고 돌아와 약 봉투를 정리한다. 정작 자기 저녁은 못 먹었다.',
        choices: <RelationshipChoiceDefinition>[
          RelationshipChoiceDefinition(
            id: 'ask_need',
            label: '지금 하은이는 뭘 해 주면 제일 편해?',
            response: '“내가 필요한 것도 물어봐 주네.” 하은이 잠시 생각하다 같이 밥을 먹자고 한다.',
            affectionDelta: 5,
          ),
          RelationshipChoiceDefinition(
            id: 'bring_food',
            label: '밥부터 가져올게. 여기서 잠깐 쉬어.',
            response: '“고마워. 이번엔 나도 도움받을게.”',
            affectionDelta: 3,
          ),
          RelationshipChoiceDefinition(
            id: 'praise_sacrifice',
            label: '역시 하은이는 계속 남 챙겨야 어울려.',
            response: '“나도 계속 괜찮은 건 아니야.” 하은이 약 봉투를 세게 접는다.',
            affectionDelta: -2,
          ),
        ],
      ),
      RelationshipSceneDefinition(
        id: 'haeun_meeting',
        activity: RelationshipActivity.conversation,
        location: '공용 생활실',
        title: '조용한 사람의 의견',
        prompt: '생활실 회의가 끝났지만 하은은 아직 말하지 않은 친구 쪽을 계속 본다.',
        choices: <RelationshipChoiceDefinition>[
          RelationshipChoiceDefinition(
            id: 'give_floor',
            label: '끝내기 전에 그 친구한테 직접 물어보자.',
            response: '“응. 대신 대답을 재촉하진 말자.” 하은이 네 옆에 자리를 만든다.',
            affectionDelta: 5,
          ),
          RelationshipChoiceDefinition(
            id: 'write_option',
            label: '말하기 어렵다면 종이에 적게 하는 건 어때?',
            response: '“그 방법 좋다. 선택지가 하나 더 생겼네.”',
            affectionDelta: 3,
          ),
          RelationshipChoiceDefinition(
            id: 'assume_yes',
            label: '반대 안 했으면 찬성한 거겠지.',
            response: '“말 못 한 거랑 찬성은 달라.” 하은이 바로 고개를 젓는다.',
            affectionDelta: -2,
          ),
        ],
      ),
    ],
    dateScene: RelationshipSceneDefinition(
      id: 'haeun_bookstore_date',
      activity: RelationshipActivity.date,
      location: '종로 작은 서점',
      title: '서로에게 고르는 책',
      prompt: '하은이 책 한 권을 들었다 놓으며 웃는다. “남한테 추천하는 건 쉬운데, 내 건 어렵다.”',
      choices: <RelationshipChoiceDefinition>[
        RelationshipChoiceDefinition(
          id: 'choose_each',
          label: '그럼 서로 한 권씩 골라 주고 이유도 말해 주자.',
          response: '“나도 네가 보는 내가 궁금해.” 하은이 아주 천천히 책장을 넘긴다.',
          affectionDelta: 8,
        ),
        RelationshipChoiceDefinition(
          id: 'ask_own_taste',
          label: '오늘은 남 생각 말고 네가 읽고 싶은 걸 골라.',
          response: '“그 말 들으니까 갑자기 고르고 싶어졌어.”',
          affectionDelta: 5,
        ),
        RelationshipChoiceDefinition(
          id: 'choose_for_her',
          label: '하은이는 이런 착한 이야기 좋아하잖아.',
          response: '“내 취향까지 먼저 정하지는 말아 줘.” 하은이 책을 제자리에 꽂는다.',
          affectionDelta: -3,
        ),
      ],
    ),
  ),
  CohortGirlProfile(
    id: 'han_sua',
    name: '한수아',
    mbti: 'ENFP',
    role: '사람 반응에서 가능성을 읽는 분위기 촉진자',
    accentValue: 0xFFE84F69,
    portraitAsset:
        'assets/images/production_soft_painted/han_sua/01_neutral_v1.png',
    conversationScenes: <RelationshipSceneDefinition>[
      RelationshipSceneDefinition(
        id: 'sua_rumor',
        activity: RelationshipActivity.conversation,
        location: '공용 생활실',
        title: '새 간식 소문',
        prompt: '수아가 매점에서 새 과자가 순삭됐다는 얘기를 들었다며 눈을 반짝인다.',
        choices: <RelationshipChoiceDefinition>[
          RelationshipChoiceDefinition(
            id: 'test_story',
            label: '왜 인기인지 같이 먹어 보고 사람들한테도 물어보자.',
            response: '“바로 그거지. 느낌이랑 증거 둘 다 챙기기!” 수아가 손바닥을 내민다.',
            affectionDelta: 5,
          ),
          RelationshipChoiceDefinition(
            id: 'enjoy_hype',
            label: '그 정도면 진짜 맛있긴 한가 보다.',
            response: '“그치? 근데 우리 기대만 너무 커진 건 아닌지도 봐야 돼.”',
            affectionDelta: 3,
          ),
          RelationshipChoiceDefinition(
            id: 'dismiss_people',
            label: '애들 반응이 투자랑 무슨 상관이야.',
            response: '“사는 사람이 애들인데 왜 상관없어?” 수아가 입을 삐죽인다.',
            affectionDelta: -2,
          ),
        ],
      ),
      RelationshipSceneDefinition(
        id: 'sua_idea',
        activity: RelationshipActivity.conversation,
        location: '미래양성원 본관 앞',
        title: '갑자기 떠오른 장터',
        prompt: '수아가 학생들이 직접 만든 물건을 파는 하루 장터를 열자며 말을 쏟아낸다.',
        choices: <RelationshipChoiceDefinition>[
          RelationshipChoiceDefinition(
            id: 'pick_one_step',
            label: '재밌다. 오늘은 참가할 사람부터 물어보자.',
            response: '“내 아이디어 안 꺾고 첫 단계를 잡아 주네.” 수아가 네 이름을 첫 줄에 쓴다.',
            affectionDelta: 5,
          ),
          RelationshipChoiceDefinition(
            id: 'expand_idea',
            label: '라디오 홍보도 붙이면 더 재밌겠다.',
            response: '“지우까지 끼면 진짜 커지겠는데?” 수아의 말이 더 빨라진다.',
            affectionDelta: 3,
          ),
          RelationshipChoiceDefinition(
            id: 'call_unrealistic',
            label: '또 시작만 하고 끝은 못 낼 것 같은데.',
            response: '“틀린 말일 수도 없어서 더 킹받네.” 수아가 웃지 못하고 시선을 돌린다.',
            affectionDelta: -2,
          ),
        ],
      ),
    ],
    dateScene: RelationshipSceneDefinition(
      id: 'sua_market_date',
      activity: RelationshipActivity.date,
      location: '종로 노점 거리',
      title: '둘이 걷는 간식 탐험',
      prompt: '수아가 붕어빵과 호떡 사이에서 진지하게 고민한다. “둘 다 먹으면 저녁은 망하겠지?”',
      choices: <RelationshipChoiceDefinition>[
        RelationshipChoiceDefinition(
          id: 'share_both',
          label: '하나씩 사서 반씩 나눠 먹자. 데이터도 두 배.',
          response: '“데이트에 데이터 얹는 거 느좋인데?” 수아가 웃으며 네 팔을 가볍게 친다.',
          affectionDelta: 8,
        ),
        RelationshipChoiceDefinition(
          id: 'follow_face',
          label: '지금 네 표정은 호떡 쪽인데?',
          response: '“내 표정 읽었어? 좀 하는데.” 수아가 호떡집으로 방향을 튼다.',
          affectionDelta: 5,
        ),
        RelationshipChoiceDefinition(
          id: 'calculate_only',
          label: '싼 걸 하나만 사. 그게 효율적이야.',
          response: '“오늘은 효율 말고 같이 노는 날인 줄 알았는데.”',
          affectionDelta: -3,
        ),
      ],
    ),
  ),
  CohortGirlProfile(
    id: 'oh_jiwoo',
    name: '오지우',
    mbti: 'ENTP',
    role: '신호와 잡음을 뒤집는 방송·반례 담당',
    accentValue: 0xFF56C9B6,
    portraitAsset:
        'assets/images/production_soft_painted/oh_jiwoo/01_alert_neutral_v1.png',
    conversationScenes: <RelationshipSceneDefinition>[
      RelationshipSceneDefinition(
        id: 'jiwoo_broadcast',
        activity: RelationshipActivity.conversation,
        location: '공용 생활실',
        title: '지우 방송국 속보',
        prompt: '지우가 숟가락을 마이크처럼 들고 “오늘 청소 당번 실종 사건”을 중계한다.',
        choices: <RelationshipChoiceDefinition>[
          RelationshipChoiceDefinition(
            id: 'counter_report',
            label: '정정 보도. 당번은 지금 빗자루를 찾는 중입니다.',
            response: '“오, 현장 기자 합격.” 지우가 웃으며 마이크를 네게 넘긴다.',
            affectionDelta: 5,
          ),
          RelationshipChoiceDefinition(
            id: 'ask_evidence',
            label: '실종이라고 할 증거는 확보했습니까?',
            response: '“날카로운 질문입니다. 제보자를 보호하겠습니다.”',
            affectionDelta: 3,
          ),
          RelationshipChoiceDefinition(
            id: 'shut_down',
            label: '시끄러워. 그런 장난 좀 그만해.',
            response: '“방송 종료.” 지우가 웃음을 지우고 숟가락을 내려놓는다.',
            affectionDelta: -2,
          ),
        ],
      ),
      RelationshipSceneDefinition(
        id: 'jiwoo_hypothesis',
        activity: RelationshipActivity.conversation,
        location: 'PC 실습실',
        title: '반대 가설 세 개',
        prompt: '지우가 한빛통신 가격이 내린 이유를 서로 반대되는 세 가지 가설로 적어 놨다.',
        choices: <RelationshipChoiceDefinition>[
          RelationshipChoiceDefinition(
            id: 'choose_test',
            label: '셋 중에 내일 확인할 수 있는 것부터 고르자.',
            response: '“가설을 안 죽이고 결론은 내네. 너 좀 괜찮다.”',
            affectionDelta: 5,
          ),
          RelationshipChoiceDefinition(
            id: 'add_counter',
            label: '세 가설이 다 틀렸을 가능성도 있지?',
            response: '“그 질문 때문에 네 번째 줄을 비워 뒀지.” 지우가 펜을 건넨다.',
            affectionDelta: 3,
          ),
          RelationshipChoiceDefinition(
            id: 'pick_random',
            label: '그냥 제일 재밌는 걸 정답으로 하자.',
            response: '“재미는 출발이고 정답은 검증이지.” 지우가 의외로 진지해진다.',
            affectionDelta: -2,
          ),
        ],
      ),
    ],
    dateScene: RelationshipSceneDefinition(
      id: 'jiwoo_record_date',
      activity: RelationshipActivity.date,
      location: '종로 음반·라디오점',
      title: '둘만의 주파수',
      prompt: '지우가 헤드폰 한쪽을 내민다. “같은 노래 듣고 완전 다른 평을 해 보는 거야.”',
      choices: <RelationshipChoiceDefinition>[
        RelationshipChoiceDefinition(
          id: 'accept_debate',
          label: '좋아. 끝나고 서로 평 바꿔서 변론까지.',
          response: '“데이트 상대가 아니라 고정 패널을 데려왔네.” 지우가 헤드폰을 네 귀에 씌운다.',
          affectionDelta: 8,
        ),
        RelationshipChoiceDefinition(
          id: 'share_first',
          label: '지우 생각부터 듣고 내 반론 말할게.',
          response: '“순서까지 주는 거야? 그럼 진짜 솔직하게 말한다.”',
          affectionDelta: 5,
        ),
        RelationshipChoiceDefinition(
          id: 'agree_everything',
          label: '나는 그냥 네 말에 다 맞다고 할게.',
          response: '“그건 같이 듣는 게 아니라 메아리잖아.” 지우가 헤드폰을 거둔다.',
          affectionDelta: -3,
        ),
      ],
    ),
  ),
  CohortGirlProfile(
    id: 'yoon_chaea',
    name: '윤채아',
    mbti: 'INTJ',
    role: '가격 뒤 구조를 잇는 장기 전략가',
    accentValue: 0xFF727FBE,
    portraitAsset:
        'assets/images/production_soft_painted/yoon_chaea/01_neutral_tie_v1.png',
    conversationScenes: <RelationshipSceneDefinition>[
      RelationshipSceneDefinition(
        id: 'chaea_receipt',
        activity: RelationshipActivity.conversation,
        location: '공용 생활실',
        title: '날짜가 다른 영수증',
        prompt: '채아가 같은 물건의 영수증 세 장을 날짜순으로 펼쳐 놓고 가격이 바뀐 이유를 찾고 있다.',
        choices: <RelationshipChoiceDefinition>[
          RelationshipChoiceDefinition(
            id: 'ask_structure',
            label: '가게 차이보다 날짜에 공통으로 바뀐 게 있는지 볼까?',
            response: '“내가 보던 구조랑 같은 방향이야.” 채아가 네 앞에 빈 종이를 놓는다.',
            affectionDelta: 5,
          ),
          RelationshipChoiceDefinition(
            id: 'ask_assumption',
            label: '지금 네 가설에서 제일 약한 전제는 뭐야?',
            response: '“그걸 물어볼 줄은 몰랐어.” 채아가 잠시 생각한 뒤 천천히 설명한다.',
            affectionDelta: 3,
          ),
          RelationshipChoiceDefinition(
            id: 'use_latest_only',
            label: '제일 최근 것만 보면 되는 거 아냐?',
            response: '“변한 이유를 버리면 다음 가격도 못 봐.” 채아가 영수증을 다시 모은다.',
            affectionDelta: -2,
          ),
        ],
      ),
      RelationshipSceneDefinition(
        id: 'chaea_selection',
        activity: RelationshipActivity.conversation,
        location: '중앙 복도',
        title: '우리 열 명을 뽑은 이유',
        prompt: '채아가 제6기 선발표를 보며 말한다. “점수만으로 뽑은 명단 같지는 않아.”',
        choices: <RelationshipChoiceDefinition>[
          RelationshipChoiceDefinition(
            id: 'map_patterns',
            label: '각자 잘하는 역할을 표로 묶으면 기준이 보일지도 몰라.',
            response: '“좋아. 네가 사람 쪽을 적어. 나는 구조를 볼게.”',
            affectionDelta: 5,
          ),
          RelationshipChoiceDefinition(
            id: 'ask_next_step',
            label: '기준을 알면 그다음엔 뭘 할 생각이야?',
            response: '“그 질문이 먼저였어야 했네.” 채아가 너를 똑바로 본다.',
            affectionDelta: 3,
          ),
          RelationshipChoiceDefinition(
            id: 'call_paranoid',
            label: '너무 깊게 생각하는 거 아니야?',
            response: '“그럴 수도 있지. 그래서 근거를 찾는 거야.” 채아가 대화를 접는다.',
            affectionDelta: -2,
          ),
        ],
      ),
    ],
    dateScene: RelationshipSceneDefinition(
      id: 'chaea_used_book_date',
      activity: RelationshipActivity.date,
      location: '청계천 헌책방',
      title: '오래된 책의 가격',
      prompt: '채아가 같은 책의 서로 다른 가격표를 보여 준다. “낡은 쪽이 더 비싼 이유가 뭘까?”',
      choices: <RelationshipChoiceDefinition>[
        RelationshipChoiceDefinition(
          id: 'build_theory',
          label: '판본·메모·희소성으로 가설 세우고 주인아저씨께 확인하자.',
          response: '“데이트하면서도 검증까지 하네.” 채아가 드물게 소리 내어 웃는다.',
          affectionDelta: 8,
        ),
        RelationshipChoiceDefinition(
          id: 'ask_her_view',
          label: '채아는 어떤 이유라고 봤어? 중간 생각도 듣고 싶어.',
          response: '“결론 말고 중간을 묻는 사람은 처음이야.” 채아가 책을 네 쪽으로 기울인다.',
          affectionDelta: 5,
        ),
        RelationshipChoiceDefinition(
          id: 'tease_analysis',
          label: '데이트에서도 가격 분석만 하네.',
          response: '“같이 궁금해할 줄 알았어.” 채아가 책을 덮는다.',
          affectionDelta: -3,
        ),
      ],
    ),
  ),
];

CohortGirlProfile? cohortGirlProfileById(String id) {
  for (final profile in cohortGirlProfiles) {
    if (profile.id == id) return profile;
  }
  return null;
}

RelationshipSceneDefinition relationshipSceneFor({
  required CohortGirlProfile profile,
  required RelationshipActivity activity,
  required int day,
}) {
  if (activity == RelationshipActivity.date) return profile.dateScene;
  final index = (day - 1).abs() % profile.conversationScenes.length;
  return profile.conversationScenes[index];
}

class GirlRelationshipProgress {
  const GirlRelationshipProgress({
    this.affection = relationshipMinAffection,
    this.lastInteractionDay = 0,
    this.conversationCount = 0,
    this.dateCount = 0,
  });

  final int affection;
  final int lastInteractionDay;
  final int conversationCount;
  final int dateCount;

  RelationshipStage get stage => relationshipStageFor(affection);
  bool get dateUnlocked => affection >= relationshipDateUnlockAffection;

  GirlRelationshipProgress copyWith({
    int? affection,
    int? lastInteractionDay,
    int? conversationCount,
    int? dateCount,
  }) => GirlRelationshipProgress(
    affection: (affection ?? this.affection).clamp(
      relationshipMinAffection,
      relationshipMaxAffection,
    ),
    lastInteractionDay: lastInteractionDay ?? this.lastInteractionDay,
    conversationCount: conversationCount ?? this.conversationCount,
    dateCount: dateCount ?? this.dateCount,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'affection': affection,
    'lastInteractionDay': lastInteractionDay,
    'conversationCount': conversationCount,
    'dateCount': dateCount,
  };

  factory GirlRelationshipProgress.fromJson(Map<String, dynamic> json) =>
      GirlRelationshipProgress(
        affection:
            ((json['affection'] as num?)?.toInt() ?? relationshipMinAffection)
                .clamp(relationshipMinAffection, relationshipMaxAffection),
        lastInteractionDay: ((json['lastInteractionDay'] as num?)?.toInt() ?? 0)
            .clamp(0, 0x7fffffff),
        conversationCount: ((json['conversationCount'] as num?)?.toInt() ?? 0)
            .clamp(0, 0x7fffffff),
        dateCount: ((json['dateCount'] as num?)?.toInt() ?? 0).clamp(
          0,
          0x7fffffff,
        ),
      );
}

class RelationshipMemory {
  const RelationshipMemory({
    required this.day,
    required this.girlId,
    required this.activity,
    required this.sceneId,
    required this.choiceId,
    required this.affectionDelta,
    required this.affectionAfter,
  });

  final int day;
  final String girlId;
  final RelationshipActivity activity;
  final String sceneId;
  final String choiceId;
  final int affectionDelta;
  final int affectionAfter;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'day': day,
    'girlId': girlId,
    'activity': activity.name,
    'sceneId': sceneId,
    'choiceId': choiceId,
    'affectionDelta': affectionDelta,
    'affectionAfter': affectionAfter,
  };

  factory RelationshipMemory.fromJson(Map<String, dynamic> json) =>
      RelationshipMemory(
        day: ((json['day'] as num?)?.toInt() ?? 0).clamp(0, 0x7fffffff),
        girlId: json['girlId'] as String? ?? '',
        activity: RelationshipActivity.values.firstWhere(
          (value) => value.name == json['activity'],
          orElse: () => RelationshipActivity.conversation,
        ),
        sceneId: json['sceneId'] as String? ?? '',
        choiceId: json['choiceId'] as String? ?? '',
        affectionDelta: ((json['affectionDelta'] as num?)?.toInt() ?? 0).clamp(
          -relationshipMaxAffection,
          relationshipMaxAffection,
        ),
        affectionAfter:
            ((json['affectionAfter'] as num?)?.toInt() ??
                    relationshipMinAffection)
                .clamp(relationshipMinAffection, relationshipMaxAffection),
      );
}

class RelationshipState {
  RelationshipState({
    required Map<String, GirlRelationshipProgress> girls,
    this.lastEveningEventDay = 0,
    this.memories = const <RelationshipMemory>[],
  }) : girls = Map<String, GirlRelationshipProgress>.unmodifiable({
         for (final profile in cohortGirlProfiles)
           profile.id: girls[profile.id] ?? const GirlRelationshipProgress(),
       });

  factory RelationshipState.initial() => RelationshipState(girls: const {});

  final Map<String, GirlRelationshipProgress> girls;
  final int lastEveningEventDay;
  final List<RelationshipMemory> memories;

  GirlRelationshipProgress progressFor(String girlId) =>
      girls[girlId] ?? const GirlRelationshipProgress();

  bool completedEveningForDay(int day) => lastEveningEventDay >= day;

  RelationshipState copyWith({
    Map<String, GirlRelationshipProgress>? girls,
    int? lastEveningEventDay,
    List<RelationshipMemory>? memories,
  }) => RelationshipState(
    girls: girls ?? this.girls,
    lastEveningEventDay: lastEveningEventDay ?? this.lastEveningEventDay,
    memories: memories ?? this.memories,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'girls': <String, dynamic>{
      for (final entry in girls.entries) entry.key: entry.value.toJson(),
    },
    'lastEveningEventDay': lastEveningEventDay,
    'memories': memories.map((memory) => memory.toJson()).toList(),
  };

  factory RelationshipState.fromJson(Map<String, dynamic> json) {
    final rawGirls =
        (json['girls'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final parsedGirls = <String, GirlRelationshipProgress>{};
    for (final profile in cohortGirlProfiles) {
      final raw = rawGirls[profile.id];
      parsedGirls[profile.id] = raw is Map
          ? GirlRelationshipProgress.fromJson(raw.cast<String, dynamic>())
          : const GirlRelationshipProgress();
    }
    final validIds = cohortGirlProfiles.map((profile) => profile.id).toSet();
    final memories = ((json['memories'] as List?) ?? const <dynamic>[])
        .whereType<Map>()
        .map(
          (item) => RelationshipMemory.fromJson(item.cast<String, dynamic>()),
        )
        .where((memory) => validIds.contains(memory.girlId))
        .toList(growable: false);
    return RelationshipState(
      girls: parsedGirls,
      lastEveningEventDay: ((json['lastEveningEventDay'] as num?)?.toInt() ?? 0)
          .clamp(0, 0x7fffffff),
      memories: memories.length <= 64
          ? memories
          : memories.sublist(memories.length - 64),
    );
  }
}
