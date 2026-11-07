import 'package:flutter/material.dart';

import '../browser_state.dart';
import '../theme.dart';
import '../url_utils.dart';
import '../widgets/fox_logo.dart';

/// Обзор вкладок Fox: карточки с цветной «крышкой» и нижняя капсула действий.
class TabsScreen extends StatelessWidget {
  const TabsScreen({super.key, required this.state});

  final BrowserState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final text = Theme.of(context).textTheme;
        return Scaffold(
          appBar: AppBar(
            title: Text('Вкладки · ${state.tabs.length}'),
            actions: [
              IconButton(
                tooltip: 'Закрыть все',
                icon: const Icon(Icons.layers_clear_rounded),
                onPressed: state.closeAllTabs,
              ),
            ],
          ),
          body: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.82,
            ),
            itemCount: state.tabs.length,
            itemBuilder: (context, i) {
              final tab = state.tabs[i];
              final selected = i == state.currentIndex;
              final cap = tab.incognito
                  ? const Color(0xFF4A4D3E)
                  : FoxPalette.tiles[i % FoxPalette.tiles.length];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: selected ? scheme.primary : scheme.outlineVariant,
                    width: selected ? 2.5 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: () {
                      state.selectTab(i);
                      Navigator.pop(context);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          color: cap,
                          padding: const EdgeInsets.fromLTRB(12, 4, 2, 4),
                          child: Row(
                            children: [
                              if (tab.incognito)
                                const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(Icons.visibility_off_rounded, size: 14, color: Colors.white70),
                                ),
                              Expanded(
                                child: Text(
                                  tab.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: tab.incognito ? Colors.white : FoxPalette.espresso,
                                  ),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: tab.incognito ? Colors.white : FoxPalette.espresso,
                                ),
                                onPressed: () => state.closeTab(i),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: tab.isHome
                                ? const FoxLogo(size: 56)
                                : Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: cap.withValues(alpha: 0.5),
                                          child: Text(
                                            displayHost(tab.url).characters.firstOrNull?.toUpperCase() ?? '?',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: scheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          displayHost(tab.url),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Новая вкладка'),
                        onPressed: () {
                          state.newTab();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        icon: const Icon(Icons.visibility_off_rounded),
                        label: const Text('Тайная'),
                        onPressed: () {
                          state.newTab(incognito: true);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
