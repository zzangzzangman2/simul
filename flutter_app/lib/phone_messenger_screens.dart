part of 'main.dart';

const _messengerYellow = Color(0xFFFEE500);
const _messengerSky = Color(0xFFB7C9D5);
const _messengerDark = Color(0xFF2D3037);

String _phoneClock(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:'
    '${(minute % 60).toString().padLeft(2, '0')}';

class PhoneMessengerScreen extends StatefulWidget {
  PhoneMessengerScreen({
    super.key,
    required this.state,
    required this.onMarkRead,
    required this.onSend,
    PhoneAiService? aiService,
  }) : aiService = aiService ?? PhoneAiService();

  final GameState state;
  final Future<PhoneMessengerActionResult> Function(String contactId)
  onMarkRead;
  final Future<PhoneMessengerActionResult> Function(
    String contactId,
    String text,
  )
  onSend;
  final PhoneAiService aiService;

  @override
  State<PhoneMessengerScreen> createState() => _PhoneMessengerScreenState();
}

class _PhoneMessengerScreenState extends State<PhoneMessengerScreen> {
  late GameState _state = widget.state;
  bool _opening = false;
  bool _checkingAiConfiguration = true;
  PhoneAiConfiguration? _aiConfiguration;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadAiConfiguration(showPrompt: true));
    });
  }

  Future<void> _loadAiConfiguration({required bool showPrompt}) async {
    final configuration = await widget.aiService.loadConfiguration();
    if (!mounted) return;
    setState(() {
      _aiConfiguration = configuration;
      _checkingAiConfiguration = false;
    });
    if (showPrompt && configuration.shouldPrompt) {
      await _showAiRegistration();
    }
  }

  Future<void> _showAiRegistration() async {
    final result = await showDialog<PhoneAiKeyRegistrationResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _PhoneAiRegistrationDialog(aiService: widget.aiService),
    );
    if (!mounted) return;
    await _loadAiConfiguration(showPrompt: false);
    if (!mounted || result == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _openAiSettings() async {
    final configuration = _aiConfiguration;
    if (configuration == null || !configuration.personalKeyConfigured) {
      await _showAiRegistration();
      return;
    }

    final removePersonalKey = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gemini 자연 대화'),
        content: Text(
          configuration.serverConfigured
              ? '서버에 Gemini가 연결되어 있어 동기별 성격과 최근 대화 맥락을 더 자연스럽게 반영합니다.'
              : '이 기기에 등록한 개인 키로 동기별 성격과 최근 대화 맥락을 더 자연스럽게 반영합니다.',
        ),
        actions: [
          if (configuration.personalKeyConfigured)
            TextButton(
              key: const Key('phone-ai-key-delete-button'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('개인 키 삭제'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (removePersonalKey != true) return;
    await widget.aiService.clearPersonalApiKey();
    await widget.aiService.dismissRegistrationPrompt();
    if (!mounted) return;
    await _loadAiConfiguration(showPrompt: false);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('이 기기의 Gemini 키를 삭제했습니다.')));
  }

  Future<void> _openThread(PhoneContactDefinition contact) async {
    if (_opening) return;
    setState(() => _opening = true);
    final readResult = await widget.onMarkRead(contact.id);
    if (!mounted) return;
    if (readResult.success) _state = readResult.state;
    setState(() => _opening = false);
    final latest = await Navigator.of(context).push<GameState>(
      _gameSceneRoute<GameState>(
        PhoneChatScreen(state: _state, contact: contact, onSend: widget.onSend),
      ),
    );
    if (latest != null && mounted) setState(() => _state = latest);
  }

  @override
  Widget build(BuildContext context) {
    final contacts = [...phoneMessengerContacts]
      ..sort((left, right) {
        final leftMessage = _state.phoneMessenger.lastMessageFor(left.id);
        final rightMessage = _state.phoneMessenger.lastMessageFor(right.id);
        final dayOrder = (rightMessage?.day ?? 0).compareTo(
          leftMessage?.day ?? 0,
        );
        if (dayOrder != 0) return dayOrder;
        return (rightMessage?.marketMinute ?? 0).compareTo(
          leftMessage?.marketMinute ?? 0,
        );
      });
    final unread = _state.phoneMessenger.totalUnread;
    return Scaffold(
      key: const Key('phone-messenger-screen'),
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Column(
          children: [
            _PhoneStatusBar(state: _state),
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              color: _messengerYellow,
              child: Row(
                children: [
                  IconButton(
                    key: const Key('phone-messenger-back-button'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  const SizedBox(width: 2),
                  const Expanded(
                    child: Text(
                      '데시멀톡',
                      style: TextStyle(
                        color: _messengerDark,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('phone-ai-settings-button'),
                    tooltip: 'Gemini 자연 대화 설정',
                    onPressed: _checkingAiConfiguration
                        ? null
                        : _openAiSettings,
                    icon: Icon(
                      _aiConfiguration?.personalKeyConfigured == true
                          ? Icons.auto_awesome_rounded
                          : Icons.key_rounded,
                      color: _aiConfiguration?.personalKeyConfigured == true
                          ? const Color(0xFF256B50)
                          : _messengerDark,
                    ),
                  ),
                  if (unread > 0)
                    Container(
                      key: const Key('phone-messenger-total-unread'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE85252),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 9),
              color: Colors.white,
              child: const Text(
                '데시멀 동기 채팅 · 답장은 하루에 친구별 3번',
                style: TextStyle(
                  color: Color(0xFF777777),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (_aiConfiguration case final configuration?
                when !configuration.personalKeyConfigured)
              _PhoneAiSetupBanner(onTap: _showAiRegistration),
            Expanded(
              child: ListView.separated(
                key: const Key('phone-messenger-contact-list'),
                itemCount: contacts.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  indent: 78,
                  color: Color(0xFFE6E6E6),
                ),
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  final message = _state.phoneMessenger.lastMessageFor(
                    contact.id,
                  );
                  final contactUnread = _state.phoneMessenger.unreadFor(
                    contact.id,
                  );
                  return InkWell(
                    key: Key('phone-contact-${contact.id}'),
                    onTap: _opening ? null : () => _openThread(contact),
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(14, 11, 13, 11),
                      child: Row(
                        children: [
                          _PhoneAvatar(contact: contact, size: 50),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        contact.name,
                                        style: const TextStyle(
                                          color: Color(0xFF252525),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      message == null
                                          ? ''
                                          : _phoneClock(message.marketMinute),
                                      style: const TextStyle(
                                        color: Color(0xFFA0A0A0),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        message?.text ?? '아직 대화가 없습니다.',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF777777),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (contactUnread > 0) ...[
                                      const SizedBox(width: 7),
                                      Container(
                                        key: Key('phone-unread-${contact.id}'),
                                        constraints: const BoxConstraints(
                                          minWidth: 20,
                                          minHeight: 20,
                                        ),
                                        alignment: Alignment.center,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE85252),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$contactUnread',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              height: 58,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E2E2))),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _PhoneBottomItem(
                    icon: Icons.chat_bubble_rounded,
                    label: '채팅',
                    selected: true,
                  ),
                  _PhoneBottomItem(
                    icon: Icons.people_alt_outlined,
                    label: '친구 9',
                  ),
                  _PhoneBottomItem(
                    icon: Icons.more_horiz_rounded,
                    label: '더보기',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneAiSetupBanner extends StatelessWidget {
  const _PhoneAiSetupBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFFF4C7),
    child: InkWell(
      key: const Key('phone-ai-setup-banner'),
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.fromLTRB(15, 9, 12, 9),
        child: Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 20,
              color: Color(0xFF725C00),
            ),
            SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '더 실감 나는 대화 켜기',
                    style: TextStyle(
                      color: Color(0xFF4E4100),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Gemini 키 등록 · 키가 없어도 로컬 대화는 계속됩니다.',
                    style: TextStyle(
                      color: Color(0xFF756A36),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Color(0xFF725C00)),
          ],
        ),
      ),
    ),
  );
}

class _PhoneAiRegistrationDialog extends StatefulWidget {
  const _PhoneAiRegistrationDialog({required this.aiService});

  final PhoneAiService aiService;

  @override
  State<_PhoneAiRegistrationDialog> createState() =>
      _PhoneAiRegistrationDialogState();
}

class _PhoneAiRegistrationDialogState
    extends State<_PhoneAiRegistrationDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await widget.aiService.registerPersonalApiKey(
      _controller.text,
    );
    if (!mounted) return;
    if (!result.success) {
      setState(() {
        _saving = false;
        _error = result.message;
      });
      return;
    }
    Navigator.of(context).pop(result);
  }

  Future<void> _continueLocally() async {
    if (_saving) return;
    await widget.aiService.dismissRegistrationPrompt();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    key: const Key('phone-ai-registration-dialog'),
    insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
    title: const Row(
      children: [
        Icon(Icons.auto_awesome_rounded, color: Color(0xFF7A6500)),
        SizedBox(width: 9),
        Expanded(child: Text('더 실감 나는 대화를 켤까요?')),
      ],
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gemini가 동기별 성격, 관계, 오늘과 누적 손익, 최근 대화 맥락을 바탕으로 답장을 더 자연스럽게 다듬습니다.',
          ),
          const SizedBox(height: 8),
          const Text(
            '키가 없어도 12만 가지 이상의 로컬 대화로 계속 플레이할 수 있습니다.',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B6B6B)),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('phone-ai-key-input'),
            controller: _controller,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            onSubmitted: (_) => _register(),
            decoration: InputDecoration(
              labelText: 'Gemini API 키',
              hintText: 'Google AI Studio에서 발급받은 키',
              errorText: _error,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                key: const Key('phone-ai-key-visibility-button'),
                tooltip: _obscure ? '키 보기' : '키 숨기기',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: Color(0xFF52705D),
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  '키는 이 기기의 보안 저장소에만 보관되며 Git, 게임 세이브, 대화 기록에는 저장되지 않습니다.',
                  style: TextStyle(
                    color: Color(0xFF52705D),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        key: const Key('phone-ai-local-only-button'),
        onPressed: _saving ? null : _continueLocally,
        child: const Text('키 없이 로컬 대화'),
      ),
      FilledButton.icon(
        key: const Key('phone-ai-register-button'),
        onPressed: _saving ? null : _register,
        icon: _saving
            ? const SizedBox.square(
                dimension: 15,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.lock_rounded, size: 17),
        label: Text(_saving ? '등록 중' : '등록하고 시작'),
      ),
    ],
  );
}

class PhoneChatScreen extends StatefulWidget {
  const PhoneChatScreen({
    super.key,
    required this.state,
    required this.contact,
    required this.onSend,
  });

  final GameState state;
  final PhoneContactDefinition contact;
  final Future<PhoneMessengerActionResult> Function(
    String contactId,
    String text,
  )
  onSend;

  @override
  State<PhoneChatScreen> createState() => _PhoneChatScreenState();
}

class _PhoneChatScreenState extends State<PhoneChatScreen> {
  late GameState _state = widget.state;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sending = false;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  Future<void> _send([String? suggested]) async {
    if (_sending) return;
    final text = (suggested ?? _controller.text).trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    final result = await widget.onSend(widget.contact.id, text);
    if (!mounted) return;
    if (!result.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      setState(() => _sending = false);
      return;
    }
    _controller.clear();
    setState(() {
      _state = result.state;
      _sending = false;
    });
    if (result.relationshipChanged) {
      final changes = <String>[
        if (result.affectionDelta != 0) '호감 ${_signed(result.affectionDelta)}',
        if (result.trustDelta != 0) '신뢰 ${_signed(result.trustDelta)}',
        if (result.closenessDelta != 0) '친밀 ${_signed(result.closenessDelta)}',
        if (result.investmentRespectDelta != 0)
          '투자존중 ${_signed(result.investmentRespectDelta)}',
      ];
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(changes.join(' · '))));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  String _signed(int value) => value > 0 ? '+$value' : '$value';

  void _closeChat() {
    if (_allowPop) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(_state);
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = _state.phoneMessenger.messagesFor(widget.contact.id);
    final relationship = cohortGirlProfileById(widget.contact.id) == null
        ? null
        : _state.relationships.progressFor(widget.contact.id);
    final privateMemoryCount = _state.phoneMessenger
        .memoriesFor(widget.contact.id)
        .length;
    final used = _state.phoneMessenger
        .progressFor(widget.contact.id)
        .exchangesForDay(_state.day);
    final limitReached = used >= phoneMessengerDailySendLimit;
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _closeChat();
      },
      child: Scaffold(
        key: Key('phone-chat-${widget.contact.id}'),
        resizeToAvoidBottomInset: true,
        backgroundColor: _messengerSky,
        body: SafeArea(
          child: Column(
            children: [
              _PhoneStatusBar(state: _state, dark: true),
              Container(
                height: 56,
                color: _messengerYellow,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Row(
                  children: [
                    IconButton(
                      key: const Key('phone-chat-back-button'),
                      onPressed: _closeChat,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    _PhoneAvatar(contact: widget.contact, size: 34),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.contact.name,
                            style: const TextStyle(
                              color: _messengerDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            relationship == null
                                ? '${widget.contact.personalityLabel} · '
                                      '1:1 기억 $privateMemoryCount'
                                : '${widget.contact.personalityLabel} · '
                                      '호감 ${relationship.affection} · '
                                      '신뢰 ${relationship.trust} · '
                                      '1:1 기억 $privateMemoryCount',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF6E6532),
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text(
                        '$used / $phoneMessengerDailySendLimit',
                        style: const TextStyle(
                          color: _messengerDark,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  key: const Key('phone-chat-message-list'),
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 13, 12, 16),
                  itemCount: messages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x55717E86),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${_state.currentDate.month}월 ${_state.currentDate.day}일 · 데시멀 연락망',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      );
                    }
                    return _PhoneMessageBubble(
                      message: messages[index - 1],
                      contact: widget.contact,
                    );
                  },
                ),
              ),
              Container(
                color: const Color(0xFFF7F7F7),
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
                child: Column(
                  children: [
                    if (!limitReached)
                      SizedBox(
                        height: 31,
                        child: ListView.separated(
                          key: const Key('phone-chat-suggestions'),
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.contact.suggestions.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 6),
                          itemBuilder: (context, index) {
                            final text = widget.contact.suggestions[index];
                            return ActionChip(
                              key: Key(
                                'phone-suggestion-${widget.contact.id}-$index',
                              ),
                              onPressed: _sending ? null : () => _send(text),
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFD4D4D4)),
                              label: Text(
                                text,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                            );
                          },
                        ),
                      ),
                    if (!limitReached) const SizedBox(height: 6),
                    if (!limitReached)
                      const Padding(
                        key: Key('phone-ai-privacy-notice'),
                        padding: EdgeInsets.only(bottom: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 10,
                              color: Color(0xFF777777),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'AI 답장 실험 중 · 개인정보는 입력하지 마세요',
                              style: TextStyle(
                                color: Color(0xFF777777),
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (limitReached)
                      Container(
                        key: const Key('phone-chat-daily-limit'),
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9E9E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '오늘 대화는 여기까지 · 내일 새 이야기 3번이 열려요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF777777),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const Key('phone-chat-input'),
                              controller: _controller,
                              enabled: !_sending,
                              maxLength: phoneMessengerMaxMessageLength,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _send(),
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: '메시지 입력',
                                filled: true,
                                fillColor: Colors.white,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: const TextStyle(
                                color: Color(0xFF252525),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          IconButton.filled(
                            key: const Key('phone-chat-send-button'),
                            onPressed: _sending ? null : () => _send(),
                            style: IconButton.styleFrom(
                              backgroundColor: _messengerYellow,
                              foregroundColor: _messengerDark,
                            ),
                            icon: _sending
                                ? const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded, size: 19),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneStatusBar extends StatelessWidget {
  const _PhoneStatusBar({required this.state, this.dark = false});

  final GameState state;
  final bool dark;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('phone-status-bar'),
    height: 24,
    padding: const EdgeInsets.symmetric(horizontal: 13),
    color: dark ? const Color(0xFF9EAFBA) : const Color(0xFFF6D900),
    child: Row(
      children: [
        Text(
          _phoneClock(state.marketMinute),
          style: const TextStyle(
            color: _messengerDark,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        const Icon(Icons.signal_cellular_alt_rounded, size: 13),
        const SizedBox(width: 4),
        const Icon(Icons.wifi_rounded, size: 13),
        const SizedBox(width: 4),
        const Icon(Icons.battery_5_bar_rounded, size: 14),
      ],
    ),
  );
}

class _PhoneAvatar extends StatelessWidget {
  const _PhoneAvatar({required this.contact, required this.size});

  final PhoneContactDefinition contact;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Color(contact.accentValue),
      borderRadius: BorderRadius.circular(size * 0.34),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Text(
      contact.name.substring(contact.name.length - 1),
      style: TextStyle(
        color: Colors.white,
        fontSize: size * 0.40,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _PhoneMessageBubble extends StatelessWidget {
  const _PhoneMessageBubble({required this.message, required this.contact});

  final PhoneMessage message;
  final PhoneContactDefinition contact;

  @override
  Widget build(BuildContext context) {
    final fromPlayer = message.isFromPlayer;
    return Padding(
      key: Key('phone-message-${message.id}'),
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: fromPlayer
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!fromPlayer) ...[
            _PhoneAvatar(contact: contact, size: 36),
            const SizedBox(width: 7),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: fromPlayer
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!fromPlayer)
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 3),
                    child: Text(
                      contact.name,
                      style: const TextStyle(
                        color: Color(0xFF3E4A52),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (fromPlayer)
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Text(
                          _phoneClock(message.marketMinute),
                          style: const TextStyle(
                            color: Color(0xFF64747E),
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    Flexible(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 250),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: fromPlayer ? _messengerYellow : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(fromPlayer ? 13 : 3),
                            topRight: Radius.circular(fromPlayer ? 3 : 13),
                            bottomLeft: const Radius.circular(13),
                            bottomRight: const Radius.circular(13),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x19000000),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          message.text,
                          style: const TextStyle(
                            color: Color(0xFF252525),
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (!fromPlayer)
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          _phoneClock(message.marketMinute),
                          style: const TextStyle(
                            color: Color(0xFF64747E),
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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

class _PhoneBottomItem extends StatelessWidget {
  const _PhoneBottomItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        icon,
        size: 21,
        color: selected ? _messengerDark : const Color(0xFFA0A0A0),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: TextStyle(
          color: selected ? _messengerDark : const Color(0xFFA0A0A0),
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}
