const phoneMessengerPlayerId = 'player';
const phoneMessengerDailySendLimit = 3;
const phoneMessengerMaxMessageLength = 80;
const phoneMessengerHistoryLimit = 256;

class PhoneContactDefinition {
  const PhoneContactDefinition({
    required this.id,
    required this.name,
    required this.personalityLabel,
    required this.accentValue,
    required this.openingMessage,
    required this.stockReply,
    required this.classReply,
    required this.casualReply,
    required this.fallbackReply,
    required this.boundaryReply,
    required this.suggestions,
  });

  final String id;
  final String name;
  final String personalityLabel;
  final int accentValue;
  final String openingMessage;
  final String stockReply;
  final String classReply;
  final String casualReply;
  final String fallbackReply;
  final String boundaryReply;
  final List<String> suggestions;
}

const phoneMessengerContacts = <PhoneContactDefinition>[
  PhoneContactDefinition(
    id: 'kim_hakjun',
    name: '김학준',
    personalityLabel: '규칙·계산형',
    accentValue: 0xFF5D7FA3,
    openingMessage: '야, 장 끝나면 손익표 서로 확인하자. 계산 틀리면 바로 말해.',
    stockReply: '수익률만 보지 말고 수수료까지 넣어. 숫자 하나 빠지면 결론도 바뀌잖아.',
    classReply: '나는 순서 다시 적는 중. 헷갈린 데 있으면 같이 맞춰 보자.',
    casualReply: '지금 장부 정리 중. 다 하면 탁구 한 판은 가능.',
    fallbackReply: '무슨 뜻인지는 알겠어. 근데 기준 하나만 더 정확히 말해 봐.',
    boundaryReply: '그 말은 별로다. 장난이어도 선은 지키자.',
    suggestions: ['오늘 뭐 샀어?', '실습 이해됐어?', '지금 뭐 해?'],
  ),
  PhoneContactDefinition(
    id: 'kim_seoa',
    name: '김서아',
    personalityLabel: 'ISFJ · 약속과 기록',
    accentValue: 0xFFF38B96,
    openingMessage: '단톡 공지 놓친 거 있으면 말해 줘. 내가 오늘 날짜로 적어 둘게.',
    stockReply: '오늘 오른 것보다 전에 한 약속을 계속 지킨 회사인지 먼저 보고 있어.',
    classReply: '아까 운영관이 말한 순서 적어 뒀어. 필요한 부분만 사진처럼 다시 써 줄까?',
    casualReply: '공용 컵 채워 두고 있었어. 너 밥은 먹었어?',
    fallbackReply: '응, 기억해 둘게. 그런데 이건 오늘만 그런 건지 계속 그런 건지도 알려 줘.',
    boundaryReply: '그런 말은 기록으로 남겨도 괜찮은 말인지 한 번 생각해 줬으면 해.',
    suggestions: ['오늘 종목 어땠어?', '실습 기록 보여 줘', '밥 먹었어?'],
  ),
  PhoneContactDefinition(
    id: 'lee_jian',
    name: '이지안',
    personalityLabel: 'ISTP · 원인과 실험',
    accentValue: 0xFF77BCE8,
    openingMessage: '컴퓨터 또 멈추면 전원부터 누르지 말고 불러. 원인 지워져.',
    stockReply: '광고 말고 실제 제품부터 봐. 작동이 별로면 숫자도 오래 못 버텨.',
    classReply: '설명만 보면 더 헷갈려. 화면 켜고 한 번 직접 해 보면 돼.',
    casualReply: '드라이버 찾는 중. 아까 여기 뒀는데 누가 옮겼나.',
    fallbackReply: '말로는 모르겠어. 확인할 수 있는 방법 있으면 해 보자.',
    boundaryReply: '그 얘긴 싫어. 계속하면 답 안 할 거야.',
    suggestions: ['무슨 종목 봐?', '컴퓨터 좀 봐 줘', '뭐 하고 있어?'],
  ),
  PhoneContactDefinition(
    id: 'choi_iseo',
    name: '최이서',
    personalityLabel: 'ISFP · 감각과 경계',
    accentValue: 0xFFB58CE8,
    openingMessage: '네 이름표 색 골라 놨어. 마음에 안 들면 그냥 말해. 다시 하면 돼.',
    stockReply: '사람들이 한 번 사고 끝인지, 계속 쓰고 싶은지가 더 궁금해.',
    classReply: '화면 색이 너무 세서 오래 보면 눈 아파. 내용은 직접 해 보니까 알겠어.',
    casualReply: '실 정리하고 있어. 조용해서 지금은 좀 좋다.',
    fallbackReply: '음… 나는 그건 별로야. 네가 좋아하는 이유는 듣고 싶어.',
    boundaryReply: '그 말 불편해. 내 선은 내가 정할게.',
    suggestions: ['어떤 회사가 좋아?', '실습 어땠어?', '이름표 고마워'],
  ),
  PhoneContactDefinition(
    id: 'jung_arin',
    name: '정아린',
    personalityLabel: 'ESTJ · 실행과 마감',
    accentValue: 0xFFFF9466,
    openingMessage: '내일 준비물 오늘 아홉 시 전에 확인해. 아침에 찾으면 무조건 늦어.',
    stockReply: '계획 말고 실적부터. 이번 분기 약속한 납기 지켰는지 확인했어?',
    classReply: '헷갈린 부분 세 개만 적어. 여덟 시 반에 같이 끝내자.',
    casualReply: '내일 시간표 짜는 중. 놀 거면 몇 시까지인지 먼저 정해.',
    fallbackReply: '그래서 지금 할 건 뭐야? 하나만 정하면 바로 도와줄게.',
    boundaryReply: '그 말 취소해. 장난이어도 안 되는 건 안 되는 거야.',
    suggestions: ['오늘 투자 평가해 줘', '실습 복기 같이 해', '잠깐 놀자'],
  ),
  PhoneContactDefinition(
    id: 'park_haeun',
    name: '박하은',
    personalityLabel: 'ENFJ · 배려와 합의',
    accentValue: 0xFFFF7F9B,
    openingMessage: '오늘 조용했던 사람들 괜찮은지 궁금해. 너도 힘든 거 있으면 말해 줘.',
    stockReply: '대표 말도 보지만 직원들이 실제로 오래 남는 회사인지 같이 보고 싶어.',
    classReply: '모르는 거 말해도 괜찮아. 우리 중에 같은 데서 막힌 사람 분명 있을걸?',
    casualReply: '다들 저녁 먹었는지 보고 있었어. 근데 나도 이제 좀 쉬려고.',
    fallbackReply: '네가 원하는 게 조언인지 그냥 들어 주는 건지 먼저 말해 줄래?',
    boundaryReply: '나는 그 말 듣기 불편해. 서로 싫다는 말은 멈춰 주자.',
    suggestions: ['오늘 투자 어땠어?', '나 실습 막혔어', '하은이는 괜찮아?'],
  ),
  PhoneContactDefinition(
    id: 'han_sua',
    name: '한수아',
    personalityLabel: 'ENFP · 가능성과 사람',
    accentValue: 0xFFFF6F91,
    openingMessage: '야 오늘 다들 표정 봤어? 종가 뜨자마자 단체로 뇌정지 온 거 웃겼어ㅋㅋ',
    stockReply: '지금 느좋인 건 맞는데 다시 사는 사람이 진짜 늘었는지도 보자. 나 또 신났나 봐.',
    classReply: '잠깐, 나도 거기서 막혔어! 둘이 틀리면 덜 쪽팔리니까 같이 다시 해 보자.',
    casualReply: '나 간식 뭐 먹을지 다섯 개째 고민 중. 이게 오늘 제일 어려운 선택임.',
    fallbackReply: '오, 그러면 반대 가능성도 있지 않아? 잠깐만, 생각 하나 더 났어.',
    boundaryReply: '그건 안 웃겨. 장난 말고 다른 얘기하자.',
    suggestions: ['오늘 종목 느낌 어때?', '나도 실습 헷갈려', '뭐 먹을래?'],
  ),
  PhoneContactDefinition(
    id: 'oh_jiwoo',
    name: '오지우',
    personalityLabel: 'ENTP · 가설과 반례',
    accentValue: 0xFF45B7A7,
    openingMessage: '지우 방송국 개국. 첫 속보: 우리 반 손익표 공개 직전 긴장감 최고조.',
    stockReply: '속보 정정. 싼 종목이 아니라 다들 피하는 이유를 우리가 모르는 걸 수도 있습니다.',
    classReply: '가정해 보자. 설명이 어려운 게 아니라 예시가 이상했던 거면? 다른 걸로 시험해 보자.',
    casualReply: '라디오 주파수 잡는 중. 지금은 잡음 80, 음악 20. 꽤 힙함.',
    fallbackReply: '반대로 생각하면? 네 말이 맞으려면 틀려야 하는 조건부터 찾아보자.',
    boundaryReply: '방송 중단. 그건 토론거리도 장난도 아니야.',
    suggestions: ['오늘 종목 반론해 봐', '실습 설명 이상하지?', '방송국 뭐 해?'],
  ),
  PhoneContactDefinition(
    id: 'yoon_chaea',
    name: '윤채아',
    personalityLabel: 'INTJ · 구조와 장기 전략',
    accentValue: 0xFF727FBE,
    openingMessage: '오늘 결과표는 저장해 둬. 하루 순위보다 한 달 패턴이 더 중요하니까.',
    stockReply: '오늘 가격만 보면 안 돼. 왜 이 가격이 됐고 그 이유가 끝났는지부터 봐.',
    classReply: '나는 전제부터 다시 적는 중이야. 중간 하나를 빼면 결론이 전부 달라져.',
    casualReply: '영수증 날짜별로 정리 중. 끝나면 잠깐은 이야기할 수 있어.',
    fallbackReply: '결론은 이해했어. 그 결론에 쓴 가정을 하나만 더 말해 줘.',
    boundaryReply: '그 말에는 답하지 않을게. 서로 지켜야 할 기준이 있어.',
    suggestions: ['오늘 가격 분석해 줘', '실습 핵심이 뭐야?', '잠깐 얘기할래?'],
  ),
];

PhoneContactDefinition? phoneContactById(String id) {
  for (final contact in phoneMessengerContacts) {
    if (contact.id == id) return contact;
  }
  return null;
}

String phoneReplyFor(PhoneContactDefinition contact, String rawText) {
  final text = rawText.toLowerCase();
  const boundaryKeywords = <String>['야한', '벗어', '키스', '몸매', '죽어', '꺼져', '멍청'];
  if (boundaryKeywords.any(text.contains)) return contact.boundaryReply;

  const stockKeywords = <String>[
    '주식',
    '종목',
    '투자',
    '매수',
    '매도',
    '수익',
    '손해',
    '손익',
    '가격',
    '회사',
  ];
  if (stockKeywords.any(text.contains)) return contact.stockReply;

  const classKeywords = <String>[
    '실습',
    '선생',
    '공부',
    '복습',
    '숙제',
    '컴퓨터',
    'pc',
    '헷갈',
    '모르',
  ];
  if (classKeywords.any(text.contains)) return contact.classReply;

  const casualKeywords = <String>[
    '안녕',
    '뭐 해',
    '뭐해',
    '심심',
    '밥',
    '먹',
    '놀',
    '자냐',
    '잘 자',
    '고마워',
    '괜찮',
  ];
  if (casualKeywords.any(text.contains)) return contact.casualReply;
  return contact.fallbackReply;
}

class PhoneMessage {
  const PhoneMessage({
    required this.id,
    required this.contactId,
    required this.senderId,
    required this.text,
    required this.day,
    required this.marketMinute,
    required this.read,
  });

  final String id;
  final String contactId;
  final String senderId;
  final String text;
  final int day;
  final int marketMinute;
  final bool read;

  bool get isFromPlayer => senderId == phoneMessengerPlayerId;

  PhoneMessage copyWith({bool? read}) => PhoneMessage(
    id: id,
    contactId: contactId,
    senderId: senderId,
    text: text,
    day: day,
    marketMinute: marketMinute,
    read: read ?? this.read,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'contactId': contactId,
    'senderId': senderId,
    'text': text,
    'day': day,
    'marketMinute': marketMinute,
    'read': read,
  };

  factory PhoneMessage.fromJson(Map<String, dynamic> json) => PhoneMessage(
    id: json['id'] as String? ?? '',
    contactId: json['contactId'] as String? ?? '',
    senderId: json['senderId'] as String? ?? '',
    text: json['text'] as String? ?? '',
    day: ((json['day'] as num?)?.toInt() ?? 1).clamp(1, 0x7fffffff),
    marketMinute: ((json['marketMinute'] as num?)?.toInt() ?? 480).clamp(
      0,
      1439,
    ),
    read: json['read'] == true,
  );
}

class PhoneThreadProgress {
  const PhoneThreadProgress({
    required this.contactId,
    this.lastExchangeDay = -1,
    this.exchangesOnLastDay = 0,
    this.totalExchanges = 0,
  });

  final String contactId;
  final int lastExchangeDay;
  final int exchangesOnLastDay;
  final int totalExchanges;

  int exchangesForDay(int day) => lastExchangeDay == day
      ? exchangesOnLastDay.clamp(0, phoneMessengerDailySendLimit)
      : 0;

  PhoneThreadProgress recordExchange(int day) => PhoneThreadProgress(
    contactId: contactId,
    lastExchangeDay: day,
    exchangesOnLastDay: (exchangesForDay(day) + 1).clamp(
      0,
      phoneMessengerDailySendLimit,
    ),
    totalExchanges: (totalExchanges + 1).clamp(0, 0x7fffffff),
  );

  Map<String, dynamic> toJson() => {
    'contactId': contactId,
    'lastExchangeDay': lastExchangeDay,
    'exchangesOnLastDay': exchangesOnLastDay,
    'totalExchanges': totalExchanges,
  };

  factory PhoneThreadProgress.fromJson(Map<String, dynamic> json) =>
      PhoneThreadProgress(
        contactId: json['contactId'] as String? ?? '',
        lastExchangeDay: (json['lastExchangeDay'] as num?)?.toInt() ?? -1,
        exchangesOnLastDay: ((json['exchangesOnLastDay'] as num?)?.toInt() ?? 0)
            .clamp(0, phoneMessengerDailySendLimit),
        totalExchanges: ((json['totalExchanges'] as num?)?.toInt() ?? 0).clamp(
          0,
          0x7fffffff,
        ),
      );
}

class PhoneMessengerState {
  const PhoneMessengerState({
    required this.messages,
    required this.progressByContact,
  });

  factory PhoneMessengerState.initial() => PhoneMessengerState(
    messages: [
      for (var index = 0; index < phoneMessengerContacts.length; index++)
        PhoneMessage(
          id: 'phone-opening-${phoneMessengerContacts[index].id}',
          contactId: phoneMessengerContacts[index].id,
          senderId: phoneMessengerContacts[index].id,
          text: phoneMessengerContacts[index].openingMessage,
          day: 1,
          marketMinute: 480 + index,
          read: false,
        ),
    ],
    progressByContact: {
      for (final contact in phoneMessengerContacts)
        contact.id: PhoneThreadProgress(contactId: contact.id),
    },
  );

  final List<PhoneMessage> messages;
  final Map<String, PhoneThreadProgress> progressByContact;

  List<PhoneMessage> messagesFor(String contactId) => messages
      .where((message) => message.contactId == contactId)
      .toList(growable: false);

  PhoneMessage? lastMessageFor(String contactId) {
    for (final message in messages.reversed) {
      if (message.contactId == contactId) return message;
    }
    return null;
  }

  int unreadFor(String contactId) => messages
      .where(
        (message) =>
            message.contactId == contactId &&
            !message.isFromPlayer &&
            !message.read,
      )
      .length;

  int get totalUnread => messages
      .where((message) => !message.isFromPlayer && !message.read)
      .length;

  PhoneThreadProgress progressFor(String contactId) =>
      progressByContact[contactId] ?? PhoneThreadProgress(contactId: contactId);

  PhoneMessengerState copyWith({
    List<PhoneMessage>? messages,
    Map<String, PhoneThreadProgress>? progressByContact,
  }) => PhoneMessengerState(
    messages: messages ?? this.messages,
    progressByContact: progressByContact ?? this.progressByContact,
  );

  Map<String, dynamic> toJson() => {
    'messages': messages.map((message) => message.toJson()).toList(),
    'progressByContact': {
      for (final entry in progressByContact.entries)
        entry.key: entry.value.toJson(),
    },
  };

  factory PhoneMessengerState.fromJson(Map<String, dynamic> json) {
    final validIds = phoneMessengerContacts
        .map((contact) => contact.id)
        .toSet();
    final parsedMessages = ((json['messages'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (message) => PhoneMessage.fromJson(message.cast<String, dynamic>()),
        )
        .where(
          (message) =>
              message.id.isNotEmpty &&
              message.text.isNotEmpty &&
              message.text.length <= phoneMessengerMaxMessageLength * 3 &&
              validIds.contains(message.contactId) &&
              (message.senderId == phoneMessengerPlayerId ||
                  message.senderId == message.contactId),
        )
        .toList(growable: false);
    final messages = parsedMessages.isEmpty
        ? PhoneMessengerState.initial().messages
        : parsedMessages.length <= phoneMessengerHistoryLimit
        ? parsedMessages
        : parsedMessages.sublist(
            parsedMessages.length - phoneMessengerHistoryLimit,
          );

    final rawProgress = (json['progressByContact'] as Map?) ?? const {};
    final progress = <String, PhoneThreadProgress>{};
    for (final entry in rawProgress.entries) {
      final id = entry.key.toString();
      if (!validIds.contains(id) || entry.value is! Map) continue;
      progress[id] = PhoneThreadProgress.fromJson(
        (entry.value as Map).cast<String, dynamic>(),
      );
    }
    for (final contact in phoneMessengerContacts) {
      progress.putIfAbsent(
        contact.id,
        () => PhoneThreadProgress(contactId: contact.id),
      );
    }
    return PhoneMessengerState(
      messages: List<PhoneMessage>.unmodifiable(messages),
      progressByContact: Map<String, PhoneThreadProgress>.unmodifiable(
        progress,
      ),
    );
  }
}
