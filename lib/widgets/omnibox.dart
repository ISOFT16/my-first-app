import 'package:flutter/material.dart';

import '../browser_state.dart';
import '../url_utils.dart';

/// Адресная строка-«пилюля» в стиле Pixel.
class Omnibox extends StatefulWidget {
  const Omnibox({super.key, required this.state});

  final BrowserState state;

  @override
  State<Omnibox> createState() => _OmniboxState();
}

class _OmniboxState extends State<Omnibox> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  BrowserTab get tab => widget.state.current;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
    _syncText();
  }

  @override
  void didUpdateWidget(covariant Omnibox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus) _syncText();
  }

  void _syncText() => _controller.text = displayHost(tab.url);

  void _onFocusChange() {
    if (_focus.hasFocus) {
      _controller.text = tab.url ?? '';
      _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
    } else {
      _syncText();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  IconData get _leadingIcon {
    if (_focus.hasFocus || tab.isHome) return Icons.search;
    if (tab.incognito) return Icons.privacy_tip_outlined;
    return (tab.url?.startsWith('https://') ?? false) ? Icons.lock_outline : Icons.info_outline;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(_leadingIcon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              autocorrect: false,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Поиск или URL',
                hintStyle: TextStyle(color: scheme.onSurfaceVariant),
              ),
              onSubmitted: (value) {
                widget.state.openInput(value);
                _focus.unfocus();
              },
            ),
          ),
          if (_focus.hasFocus && _controller.text.isNotEmpty)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => setState(_controller.clear),
            )
          else if (!tab.isHome)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Закладка',
              icon: Icon(
                widget.state.isBookmarked(tab.url) ? Icons.star : Icons.star_border,
                size: 22,
                color: widget.state.isBookmarked(tab.url) ? scheme.primary : scheme.onSurfaceVariant,
              ),
              onPressed: widget.state.toggleBookmark,
            ),
        ],
      ),
    );
  }
}
