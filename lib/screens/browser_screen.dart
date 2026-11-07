import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../browser_state.dart';
import '../theme.dart';
import '../widgets/home_page.dart';
import '../widgets/omnibox.dart';
import '../widgets/tab_webview.dart';
import 'fox_ai_screen.dart';
import 'pages_list_screen.dart';
import 'settings_screen.dart';
import 'tabs_screen.dart';

class BrowserScreen extends StatelessWidget {
  const BrowserScreen({super.key, required this.state});

  final BrowserState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final tab = state.current;
        final content = PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (!state.handleSystemBack()) SystemNavigator.pop();
          },
          child: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: SafeArea(
                    bottom: false,
                    child: IndexedStack(
                      index: state.currentIndex,
                      children: [
                        for (final t in state.tabs)
                          KeyedSubtree(
                            key: ValueKey(t.id),
                            child: Builder(
                              builder: (context) {
                                final page = t.isHome
                                    ? HomePage(state: state, incognito: t.incognito)
                                    : TabWebView(tab: t, state: state);
                                return t.incognito
                                    ? Theme(
                                        data: buildTheme(incognitoScheme()),
                                        child: Material(child: page),
                                      )
                                    : page;
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                _BottomBar(state: state),
              ],
            ),
          ),
        );
        // Theme всегда в дереве, чтобы при переключении вкладок не пересоздавались страницы.
        return Theme(
          data: tab.incognito ? buildTheme(incognitoScheme()) : Theme.of(context),
          child: content,
        );
      },
    );
  }
}

/// Нижняя панель Fox: кнопка назад, адресная капсула, вкладки, меню.
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.state});

  final BrowserState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tab = state.current;
    final wide = MediaQuery.sizeOf(context).width >= 700;
    final loading = !tab.isHome && tab.progress < 100;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: SizedBox(
                height: 3,
                child: loading
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(value: tab.progress / 100, minHeight: 3),
                      )
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Row(
                children: [
                  _RoundButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    tooltip: 'Назад',
                    onPressed: (tab.canGoBack || !tab.isHome) ? state.back : null,
                  ),
                  if (wide) ...[
                    const SizedBox(width: 6),
                    _RoundButton(
                      icon: Icons.arrow_forward_ios_rounded,
                      tooltip: 'Вперёд',
                      onPressed: tab.canGoForward ? state.forward : null,
                    ),
                    const SizedBox(width: 6),
                    _RoundButton(icon: Icons.cottage_outlined, tooltip: 'Домой', onPressed: state.goHome),
                  ],
                  const SizedBox(width: 8),
                  Expanded(child: Omnibox(state: state)),
                  const SizedBox(width: 8),
                  _TabsButton(
                    count: state.tabs.length,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => TabsScreen(state: state)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _RoundButton(
                    icon: Icons.grid_view_rounded,
                    tooltip: 'Меню',
                    filled: true,
                    onPressed: () => showFoxMenu(context, state),
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

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = filled ? scheme.primary : scheme.surfaceContainerHigh;
    final fg = filled ? scheme.onPrimary : scheme.onSurface;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 44,
            child: Icon(icon, size: 19, color: onPressed == null ? fg.withValues(alpha: 0.35) : fg),
          ),
        ),
      ),
    );
  }
}

/// Счётчик вкладок — две сложенные «карточки» с цифрой.
class _TabsButton extends StatelessWidget {
  const _TabsButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Вкладки',
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: const Offset(4, -4),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: scheme.secondary.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.primary, width: 1.6),
                ),
                child: Text(
                  count > 99 ? '∞' : '$count',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: scheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Меню Fox — сетка плиток вместо обычного списка.
void showFoxMenu(BuildContext context, BrowserState state) {
  final tab = state.current;
  final nav = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);

  void act(VoidCallback f) {
    nav.pop();
    f();
  }

  void open(Widget screen) => act(() => nav.push(MaterialPageRoute(builder: (_) => screen)));

  final bookmarked = state.isBookmarked(tab.url);
  final items = <_MenuItem>[
    _MenuItem(Icons.add_rounded, 'Новая', () => act(state.newTab)),
    _MenuItem(Icons.visibility_off_rounded, 'Тайная', () => act(() => state.newTab(incognito: true))),
    _MenuItem(Icons.cottage_outlined, 'Домой', () => act(state.goHome)),
    _MenuItem(Icons.arrow_forward_ios_rounded, 'Вперёд', tab.canGoForward ? () => act(state.forward) : null),
    _MenuItem(
      bookmarked ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
      bookmarked ? 'Убрать' : 'В закладки',
      tab.isHome ? null : () => act(state.toggleBookmark),
    ),
    _MenuItem(Icons.collections_bookmark_outlined, 'Закладки',
        () => open(PagesListScreen(state: state, kind: PagesKind.bookmarks))),
    _MenuItem(Icons.schedule_rounded, 'История',
        () => open(PagesListScreen(state: state, kind: PagesKind.history))),
    _MenuItem(
      Icons.link_rounded,
      'Ссылка',
      tab.isHome
          ? null
          : () => act(() {
                Clipboard.setData(ClipboardData(text: tab.url!));
                messenger.showSnackBar(const SnackBar(content: Text('Ссылка скопирована')));
              }),
    ),
  ];

  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.92,
                children: [for (final i in items) _MenuTile(item: i)],
              ),
              const SizedBox(height: 12),
              Material(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(18),
                child: ListTile(
                  iconColor: scheme.onPrimary,
                  textColor: scheme.onPrimary,
                  leading: const Icon(Icons.auto_awesome_rounded),
                  title: const Text('Fox AI', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('Спросите что угодно', style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.8))),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => open(FoxAiScreen(state: state)),
                ),
              ),
              const SizedBox(height: 8),
              Material(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(18),
                child: ListTile(
                  leading: const Icon(Icons.tune_rounded),
                  title: const Text('Настройки'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => open(SettingsScreen(state: state)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _MenuItem {
  const _MenuItem(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item});

  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = item.onTap != null;
    final fg = enabled ? scheme.onSurface : scheme.onSurface.withValues(alpha: 0.35);
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: item.onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: enabled ? scheme.primary : fg, size: 24),
            const SizedBox(height: 6),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
            ),
          ],
        ),
      ),
    );
  }
}
