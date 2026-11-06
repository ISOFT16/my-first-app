import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../browser_state.dart';
import '../theme.dart';
import '../widgets/home_page.dart';
import '../widgets/omnibox.dart';
import '../widgets/tab_webview.dart';
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
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _TopBar(state: state),
                  SizedBox(
                    height: 3,
                    child: (!tab.isHome && tab.progress < 100)
                        ? LinearProgressIndicator(
                            value: tab.progress / 100,
                            minHeight: 3,
                            backgroundColor: Colors.transparent,
                          )
                        : null,
                  ),
                  Expanded(
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
                                    ? Theme(data: buildTheme(incognitoScheme()), child: Material(child: page))
                                    : page;
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.state});

  final BrowserState state;

  @override
  Widget build(BuildContext context) {
    final tab = state.current;
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 4, 6),
      child: Row(
        children: [
          if (wide) ...[
            IconButton(
              tooltip: 'Назад',
              icon: const Icon(Icons.arrow_back),
              onPressed: (tab.canGoBack || !tab.isHome) ? state.back : null,
            ),
            IconButton(
              tooltip: 'Вперёд',
              icon: const Icon(Icons.arrow_forward),
              onPressed: tab.canGoForward ? state.forward : null,
            ),
            IconButton(
              tooltip: 'Обновить',
              icon: const Icon(Icons.refresh),
              onPressed: tab.isHome ? null : state.reload,
            ),
          ],
          IconButton(
            tooltip: 'Главная',
            icon: const Icon(Icons.home_outlined),
            onPressed: state.goHome,
          ),
          const SizedBox(width: 4),
          Expanded(child: Omnibox(state: state)),
          const SizedBox(width: 4),
          _TabCountButton(
            count: state.tabs.length,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TabsScreen(state: state)),
            ),
          ),
          IconButton(
            tooltip: 'Меню',
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMenu(context),
          ),
        ],
      ),
    );
  }

  void _showMenu(BuildContext context) {
    final tab = state.current;
    final nav = Navigator.of(context);
    void go(Widget screen) {
      nav.pop();
      nav.push(MaterialPageRoute(builder: (_) => screen));
    }

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton.filledTonal(
                  tooltip: 'Назад',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: (tab.canGoBack || !tab.isHome)
                      ? () {
                          nav.pop();
                          state.back();
                        }
                      : null,
                ),
                IconButton.filledTonal(
                  tooltip: 'Вперёд',
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: tab.canGoForward
                      ? () {
                          nav.pop();
                          state.forward();
                        }
                      : null,
                ),
                IconButton.filledTonal(
                  tooltip: 'Закладка',
                  icon: Icon(state.isBookmarked(tab.url) ? Icons.star : Icons.star_border),
                  onPressed: tab.isHome
                      ? null
                      : () {
                          nav.pop();
                          state.toggleBookmark();
                        },
                ),
                IconButton.filledTonal(
                  tooltip: 'Обновить',
                  icon: const Icon(Icons.refresh),
                  onPressed: tab.isHome
                      ? null
                      : () {
                          nav.pop();
                          state.reload();
                        },
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: const Text('Новая вкладка'),
              onTap: () {
                nav.pop();
                state.newTab();
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Новая вкладка инкогнито'),
              onTap: () {
                nav.pop();
                state.newTab(incognito: true);
              },
            ),
            const Divider(indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('История'),
              onTap: () => go(PagesListScreen(state: state, kind: PagesKind.history)),
            ),
            ListTile(
              leading: const Icon(Icons.bookmarks_outlined),
              title: const Text('Закладки'),
              onTap: () => go(PagesListScreen(state: state, kind: PagesKind.bookmarks)),
            ),
            if (!tab.isHome)
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Копировать ссылку'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: tab.url!));
                  nav.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ссылка скопирована')),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Настройки'),
              onTap: () => go(SettingsScreen(state: state)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Кнопка с количеством вкладок — квадратик с цифрой, как в Chrome.
class _TabCountButton extends StatelessWidget {
  const _TabCountButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return IconButton(
      tooltip: 'Вкладки',
      onPressed: onPressed,
      icon: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          count > 99 ? ':D' : '$count',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ),
      ),
    );
  }
}
