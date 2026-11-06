import 'package:flutter/material.dart';

import '../browser_state.dart';
import '../url_utils.dart';

enum PagesKind { history, bookmarks }

/// Список истории или закладок.
class PagesListScreen extends StatelessWidget {
  const PagesListScreen({super.key, required this.state, required this.kind});

  final BrowserState state;
  final PagesKind kind;

  @override
  Widget build(BuildContext context) {
    final isHistory = kind == PagesKind.history;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final items = isHistory ? state.history : state.bookmarks;
        final scheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: Text(isHistory ? 'История' : 'Закладки'),
            actions: [
              if (isHistory && items.isNotEmpty)
                TextButton(
                  onPressed: () => _confirmClear(context),
                  child: const Text('Очистить'),
                ),
            ],
          ),
          body: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isHistory ? Icons.history : Icons.bookmarks_outlined,
                          size: 64, color: scheme.outline),
                      const SizedBox(height: 12),
                      Text(isHistory ? 'История пуста' : 'Закладок пока нет'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final e = items[i];
                    return Dismissible(
                      key: ValueKey('${e.url}-${e.time.millisecondsSinceEpoch}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        child: Icon(Icons.delete_outline, color: scheme.error),
                      ),
                      onDismissed: (_) =>
                          isHistory ? state.removeHistory(e) : state.removeBookmark(e),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: scheme.secondaryContainer,
                          foregroundColor: scheme.onSecondaryContainer,
                          child: Text(displayHost(e.url).characters.firstOrNull?.toUpperCase() ?? '?'),
                        ),
                        title: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          isHistory ? '${displayHost(e.url)} · ${_time(e.time)}' : displayHost(e.url),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          state.openInput(e.url);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  String _time(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(t.day)}.${two(t.month)} ${two(t.hour)}:${two(t.minute)}';
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.delete_sweep_outlined),
        title: const Text('Очистить историю?'),
        content: const Text('Все записи истории будут удалены.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Очистить')),
        ],
      ),
    );
    if (ok ?? false) state.clearHistory();
  }
}
