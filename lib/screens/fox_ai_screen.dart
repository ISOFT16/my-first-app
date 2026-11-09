import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ai/fox_ai.dart';
import '../theme.dart';
import '../browser_state.dart';
import '../widgets/app_logo.dart';

/// Чат с Vigil AI в стиле браузера.
class FoxAiScreen extends StatefulWidget {
  const FoxAiScreen({super.key, required this.state});

  final BrowserState state;

  @override
  State<FoxAiScreen> createState() => _FoxAiScreenState();
}

class _FoxAiScreenState extends State<FoxAiScreen> {
  final _ai = FoxAi();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _thinking = false;
  int _wait = 0; // секунд до следующей попытки при бесплатном лимите
  Timer? _countdown;

  static const _suggestions = [
    'Объясни простыми словами, как работает интернет',
    'Придумай быстрый рецепт ужина',
    'Помоги решить задачу по математике',
    'Переведи на английский: «Хорошего дня!»',
    'Дай 5 идей, чем заняться в выходные',
    'Напиши короткое поздравление с днём рождения',
  ];

  List<AiMessage> get _chat => widget.state.aiChat;

  @override
  void dispose() {
    _countdown?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _thinking) return;
    _input.clear();
    setState(() {
      _chat.add(AiMessage(fromUser: true, text: text));
      _thinking = true;
    });
    _scrollDown();
    AiMessage reply;
    try {
      String? answer;
      for (var attempt = 0; answer == null; attempt++) {
        try {
          answer = await _ai.ask(
            _chat,
            base: widget.state.aiBase,
            key: widget.state.aiKey,
            model: widget.state.aiModel,
          );
        } on FoxAiRateLimit catch (e) {
          // Бесплатный лимит: лиса сама подождёт и спросит ещё раз.
          if (attempt >= 2 || !mounted) rethrow;
          await _waitFor(e.seconds + 1);
          if (!mounted) return;
        }
      }
      reply = AiMessage(fromUser: false, text: answer!);
    } catch (e) {
      final msg = e is FoxAiException
          ? e.message
          : 'Не получилось связаться с Vigil AI. Проверьте интернет и попробуйте ещё раз.';
      reply = AiMessage(fromUser: false, text: msg, isError: true);
    }
    if (!mounted) return;
    setState(() {
      _chat.add(reply);
      _thinking = false;
    });
    widget.state.saveAiChat();
    _scrollDown();
  }

  Future<void> _waitFor(int seconds) async {
    setState(() => _wait = seconds);
    _countdown?.cancel();
    final done = Completer<void>();
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        if (!done.isCompleted) done.complete();
        return;
      }
      setState(() => _wait = max(0, _wait - 1));
      if (_wait <= 0) {
        t.cancel();
        if (!done.isCompleted) done.complete();
      }
    });
    await done.future;
  }

  void _retry() {
    if (_chat.isNotEmpty && _chat.last.isError) {
      _chat.removeLast();
      final lastUser = _chat.lastWhere((m) => m.fromUser, orElse: () => AiMessage(fromUser: true, text: ''));
      if (lastUser.text.isNotEmpty) {
        _chat.remove(lastUser);
        _send(lastUser.text);
      }
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _newChat() {
    setState(_chat.clear);
    widget.state.saveAiChat();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 28),
            const SizedBox(width: 8),
            Text.rich(TextSpan(children: [
              TextSpan(text: 'vigil', style: const TextStyle(fontWeight: FontWeight.w800, color: vigilRed)),
              const TextSpan(text: ' ai', style: TextStyle(fontWeight: FontWeight.w400)),
            ])),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Новый чат',
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: _chat.isEmpty || _thinking ? null : _newChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _chat.isEmpty
                ? _EmptyState(suggestions: _suggestions, onPick: _send)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                    itemCount: _chat.length + (_thinking ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _chat.length) return _ThinkingBubble(wait: _wait);
                      final m = _chat[i];
                      return _Bubble(
                        message: m,
                        onRetry: (m.isError && i == _chat.length - 1) ? _retry : null,
                      );
                    },
                  ),
          ),
          _Composer(controller: _input, busy: _thinking, onSend: () => _send()),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.suggestions, required this.onPick});

  final List<String> suggestions;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const AppLogo(size: 72),
              ),
              const SizedBox(height: 18),
              Text('Привет! Я Vigil AI', style: text.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(
                'Спросите меня о чём угодно — объясню, посоветую, переведу или придумаю.',
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 26),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final s in suggestions)
                    ActionChip(
                      label: Text(s),
                      avatar: Icon(Icons.auto_awesome_rounded, size: 16, color: scheme.primary),
                      backgroundColor: scheme.surfaceContainerLowest,
                      side: BorderSide(color: scheme.outlineVariant),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onPressed: () => onPick(s),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, this.onRetry});

  final AiMessage message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = message.fromUser;
    final maxW = min(MediaQuery.sizeOf(context).width * 0.82, 620.0);

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxW),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: user
            ? scheme.primary
            : message.isError
                ? scheme.errorContainer.withValues(alpha: 0.35)
                : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(22),
          topRight: const Radius.circular(22),
          bottomLeft: Radius.circular(user ? 22 : 6),
          bottomRight: Radius.circular(user ? 6 : 22),
        ),
        border: user ? null : Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            message.text,
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
              color: user ? scheme.onPrimary : scheme.onSurface,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Повторить'),
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: user ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!user) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: AppLogo(size: 26),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: message.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Скопировано')),
                );
              },
              child: bubble,
            ),
          ),
        ],
      ),
    );
  }
}

/// «Лиса думает» — три прыгающие точки.
class _ThinkingBubble extends StatefulWidget {
  const _ThinkingBubble({this.wait = 0});

  final int wait;

  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const AppLogo(size: 26),
          const SizedBox(width: 6),
          if (widget.wait > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Text(
                'Лиса переводит дух… отвечу через ${widget.wait} сек',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            )
          else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++)
                    Transform.translate(
                      offset: Offset(0, -4 * max(0.0, sin((_c.value * 2 * pi) - i * 0.8))),
                      child: Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.busy, required this.onSend});

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(color: scheme.shadow.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    cursorColor: scheme.primary,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Спросите Vigil AI…',
                      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: busy ? scheme.surfaceContainerHigh : vigilRed,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: busy ? null : onSend,
                  child: SizedBox.square(
                    dimension: 48,
                    child: busy
                        ? Padding(
                            padding: const EdgeInsets.all(14),
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: scheme.primary),
                          )
                        : const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
