import 'package:flutter/material.dart';

import '../browser_state.dart';
import '../theme.dart';
import '../url_utils.dart';
import 'fox_logo.dart';

/// Стартовая страница Fox: приветствие, поиск и плитки любимых сайтов.
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

  static const _months = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];
  static const _weekdays = [
    'понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота', 'воскресенье',
  ];

  String _greeting(DateTime now) {
    final h = now.hour;
    if (h >= 5 && h < 12) return 'Доброе утро';
    if (h >= 12 && h < 18) return 'Добрый день';
    if (h >= 18 && h < 23) return 'Добрый вечер';
    return 'Доброй ночи';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();
    final shortcuts = [...state.bookmarks, ..._defaults].take(8).toList();

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Шапка с логотипом.
              Row(
                children: [
                  const FoxLogo(size: 40),
                  const SizedBox(width: 10),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: 'fox',
                        style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: scheme.primary),
                      ),
                      TextSpan(
                        text: ' browser',
                        style: text.titleLarge?.copyWith(fontWeight: FontWeight.w300),
                      ),
                    ]),
                  ),
                  const Spacer(),
                  if (incognito)
                    Chip(
                      avatar: Icon(Icons.visibility_off_rounded, size: 16, color: scheme.primary),
                      label: const Text('тайная вкладка'),
                      side: BorderSide.none,
                      backgroundColor: scheme.surfaceContainerHigh,
                    ),
                ],
              ),
              const SizedBox(height: 40),
              if (incognito) ...[
                Text('Здесь никто\nне подсмотрит', style: text.headlineLarge),
                const SizedBox(height: 12),
                Text(
                  'История, cookie и данные сайтов исчезнут, как только вы закроете эту вкладку.',
                  style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ] else ...[
                Text(_greeting(now), style: text.headlineLarge),
                const SizedBox(height: 4),
                Text(
                  '${_weekdays[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}',
                  style: text.titleMedium?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w400),
                ),
              ],
              const SizedBox(height: 28),
              _SearchCapsule(state: state),
              if (!incognito) ...[
                const SizedBox(height: 36),
                Text(
                  'ЛЮБИМЫЕ МЕСТА',
                  style: text.labelMedium?.copyWith(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.78,
                  children: [
                    for (var i = 0; i < shortcuts.length; i++)
                      _Tile(
                        entry: shortcuts[i],
                        color: FoxPalette.tiles[i % FoxPalette.tiles.length],
                        onTap: () => state.openInput(shortcuts[i].url),
                      ),
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

class _SearchCapsule extends StatelessWidget {
  const _SearchCapsule({required this.state});

  final BrowserState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 58,
      padding: const EdgeInsets.only(left: 20, right: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(29),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(color: scheme.shadow.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              textInputAction: TextInputAction.search,
              cursorColor: scheme.primary,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Найти в ${state.searchEngine.label}…',
                hintStyle: TextStyle(color: scheme.onSurfaceVariant),
              ),
              onSubmitted: state.openInput,
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
            child: Icon(Icons.search_rounded, color: scheme.onPrimary),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.entry, required this.color, required this.onTap});

  final PageEntry entry;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final host = displayHost(entry.url);
    final letter = (entry.title.isNotEmpty ? entry.title : host).characters.firstOrNull?.toUpperCase() ?? '?';
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                letter,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: FoxPalette.espresso,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            entry.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
