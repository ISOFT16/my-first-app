import 'package:flutter/material.dart';

import '../browser_state.dart';
import '../url_utils.dart';

/// Стартовая страница новой вкладки — как у Chrome на Pixel.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.state, required this.incognito});

  final BrowserState state;
  final bool incognito;

  static final _defaults = [
    PageEntry(title: 'Google', url: 'https://www.google.com'),
    PageEntry(title: 'YouTube', url: 'https://www.youtube.com'),
    PageEntry(title: 'Википедия', url: 'https://ru.wikipedia.org'),
    PageEntry(title: 'GitHub', url: 'https://github.com'),
    PageEntry(title: 'Новости', url: 'https://news.google.com'),
    PageEntry(title: 'Карты', url: 'https://maps.google.com'),
    PageEntry(title: 'Перевод', url: 'https://translate.google.com'),
    PageEntry(title: 'Погода', url: 'https://www.google.com/search?q=погода'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final shortcuts = [...state.bookmarks, ..._defaults].take(8).toList();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (incognito) ...[
                Icon(Icons.privacy_tip_outlined, size: 72, color: scheme.onSurfaceVariant),
                const SizedBox(height: 16),
                Text('Режим инкогнито', style: text.headlineMedium),
                const SizedBox(height: 12),
                Text(
                  'История, файлы cookie и данные сайтов не сохраняются после закрытия вкладки.',
                  textAlign: TextAlign.center,
                  style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ] else ...[
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text('🦊', style: TextStyle(fontSize: 52)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Fox Browser',
                  style: text.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SearchBar(
                hintText: 'Поиск в ${state.searchEngine.label} или URL',
                leading: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.search),
                ),
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
                padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
                constraints: const BoxConstraints(minHeight: 56),
                onSubmitted: state.openInput,
                textInputAction: TextInputAction.go,
              ),
              if (!incognito) ...[
                const SizedBox(height: 36),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 16,
                  children: [
                    for (final s in shortcuts) _Shortcut(entry: s, onTap: () => state.openInput(s.url)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({required this.entry, required this.onTap});

  final PageEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final host = displayHost(entry.url);
    final letter = (entry.title.isNotEmpty ? entry.title : host).characters.firstOrNull?.toUpperCase() ?? '?';
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: scheme.secondaryContainer,
                foregroundColor: scheme.onSecondaryContainer,
                child: Text(letter, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              Text(
                entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
