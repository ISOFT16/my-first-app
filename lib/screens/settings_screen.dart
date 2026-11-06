import 'package:flutter/material.dart';

import '../browser_state.dart';
import '../url_utils.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state});

  final BrowserState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final header = Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.primary);
        return Scaffold(
          appBar: AppBar(title: const Text('Настройки')),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Оформление', style: header),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto), label: Text('Авто')),
                    ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Светлая')),
                    ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Тёмная')),
                  ],
                  selected: {state.themeMode},
                  onSelectionChanged: (s) => state.setThemeMode(s.first),
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.palette_outlined),
                title: const Text('Цвета Material You'),
                subtitle: const Text('Брать цвета из обоев (Android 12+). Иначе — лисий оранжевый.'),
                value: state.useDynamicColor,
                onChanged: state.setDynamicColor,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text('Поисковая система', style: header),
              ),
              for (final e in SearchEngine.values)
                ListTile(
                  leading: const Icon(Icons.travel_explore),
                  title: Text(e.label),
                  trailing: e == state.searchEngine
                      ? Icon(Icons.check_circle, color: scheme.primary)
                      : null,
                  onTap: () => state.setSearchEngine(e),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text('Конфиденциальность', style: header),
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep_outlined),
                title: const Text('Очистить историю'),
                subtitle: Text('Записей: ${state.history.length}'),
                onTap: state.history.isEmpty
                    ? null
                    : () {
                        state.clearHistory();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('История очищена')),
                        );
                      },
              ),
              const SizedBox(height: 16),
              const AboutListTile(
                icon: Text('🦊', style: TextStyle(fontSize: 22)),
                applicationName: 'Fox Browser',
                applicationVersion: '1.0.0',
                applicationLegalese: 'Браузер в стиле Google Pixel для Android, iOS и Windows.',
                child: Text('О Fox Browser'),
              ),
            ],
          ),
        );
      },
    );
  }
}
