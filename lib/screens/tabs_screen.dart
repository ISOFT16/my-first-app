import 'package:flutter/material.dart';

import '../browser_state.dart';
import '../url_utils.dart';

/// Обзор открытых вкладок — сетка карточек.
class TabsScreen extends StatelessWidget {
  const TabsScreen({super.key, required this.state});

  final BrowserState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: Text('Вкладки: ${state.tabs.length}'),
            actions: [
              IconButton(
                tooltip: 'Новая вкладка инкогнито',
                icon: const Icon(Icons.privacy_tip_outlined),
                onPressed: () {
                  state.newTab(incognito: true);
                  Navigator.pop(context);
                },
              ),
              PopupMenuButton<String>(
                onSelected: (_) => state.closeAllTabs(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'close', child: Text('Закрыть все вкладки')),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('Новая вкладка'),
            onPressed: () {
              state.newTab();
              Navigator.pop(context);
            },
          ),
          body: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: state.tabs.length,
            itemBuilder: (context, i) {
              final tab = state.tabs[i];
              final selected = i == state.currentIndex;
              return Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: selected
                      ? BorderSide(color: scheme.primary, width: 3)
                      : BorderSide.none,
                ),
                child: InkWell(
                  onTap: () {
                    state.selectTab(i);
                    Navigator.pop(context);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 4, 0, 0),
                        child: Row(
                          children: [
                            Icon(
                              tab.incognito ? Icons.privacy_tip_outlined : Icons.public,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tab.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => state.closeTab(i),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          decoration: BoxDecoration(
                            color: tab.incognito ? const Color(0xFF303134) : scheme.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(12),
                          child: tab.isHome
                              ? const Text('🦊', style: TextStyle(fontSize: 40))
                              : Text(
                                  displayHost(tab.url),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: tab.incognito ? Colors.white70 : scheme.onSurfaceVariant,
                                      ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
