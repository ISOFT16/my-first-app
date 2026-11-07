import 'package:flutter/material.dart';

import '../browser_state.dart';
import '../url_utils.dart';

/// Адресная капсула Fox: адрес по центру, слева значок, справа обновление.
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final focused = _focus.hasFocus;
    final secure = tab.url?.startsWith('https://') ?? false;

    IconData leading;
    if (focused || tab.isHome) {
      leading = Icons.search_rounded;
    } else if (tab.incognito) {
      leading = Icons.visibility_off_rounded;
    } else {
      leading = secure ? Icons.lock_rounded : Icons.lock_open_rounded;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 46,
      decoration: BoxDecoration(
        color: focused ? scheme.surfaceContainerLowest : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: focused ? scheme.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.only(left: 14, right: 4),
      child: Row(
        children: [
          Icon(leading, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              textAlign: focused ? TextAlign.start : TextAlign.center,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              autocorrect: false,
              cursorColor: scheme.primary,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: focused ? FontWeight.w400 : FontWeight.w600,
                    letterSpacing: focused ? 0 : 0.3,
                  ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Куда отправимся?',
                hintStyle: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
              ),
              onSubmitted: (value) {
                widget.state.openInput(value);
                _focus.unfocus();
              },
            ),
          ),
          if (focused && _controller.text.isNotEmpty)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.cancel_rounded, size: 20, color: scheme.onSurfaceVariant),
              onPressed: () => setState(_controller.clear),
            )
          else if (!tab.isHome)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Обновить',
              icon: Icon(Icons.refresh_rounded, size: 20, color: scheme.onSurfaceVariant),
              onPressed: widget.state.reload,
            )
          else
            const SizedBox(width: 10),
        ],
      ),
    );
  }
}
