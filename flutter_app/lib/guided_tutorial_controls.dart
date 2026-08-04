part of 'main.dart';

class _GuidedTutorialSkipButton extends StatefulWidget {
  const _GuidedTutorialSkipButton({
    required this.buttonKey,
    required this.dialogKey,
    required this.cancelKey,
    required this.confirmKey,
    required this.description,
    required this.onSkip,
  });

  final Key buttonKey;
  final Key dialogKey;
  final Key cancelKey;
  final Key confirmKey;
  final String description;
  final Future<void> Function() onSkip;

  @override
  State<_GuidedTutorialSkipButton> createState() =>
      _GuidedTutorialSkipButtonState();
}

class _GuidedTutorialSkipButtonState extends State<_GuidedTutorialSkipButton> {
  bool _busy = false;

  Future<void> _requestSkip() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xB3000000),
      builder: (dialogContext) => AlertDialog(
        key: widget.dialogKey,
        title: const Text('튜토리얼을 건너뛸까요?'),
        content: Text(widget.description),
        actions: [
          TextButton(
            key: widget.cancelKey,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('계속 배우기'),
          ),
          FilledButton(
            key: widget.confirmKey,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('건너뛰기'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.onSkip();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    minimum: const EdgeInsets.only(top: 8, right: 10),
    child: Material(
      color: const Color(0xE61B2435),
      elevation: 8,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: widget.buttonKey,
        onTap: _busy ? null : _requestSkip,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_busy)
                const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(
                  Icons.fast_forward_rounded,
                  size: 15,
                  color: Colors.white,
                ),
              const SizedBox(width: 5),
              const Text(
                '튜토리얼 건너뛰기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
