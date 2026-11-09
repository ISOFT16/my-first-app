import 'package:flutter/material.dart';

import '../browser_state.dart';
import '../url_utils.dart';
import '../widgets/app_logo.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state});

  final BrowserState state;

  void _editAiServer(BuildContext context) => _editAiServerDialog(context, state);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final text = Theme.of(context).textTheme;
        return Scaffold(
          appBar: AppBar(title: const Text('Настройки')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              // Карточка «о браузере».
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    const AppLogo(size: 64),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vigil Browser', style: text.titleLarge),
                          const SizedBox(height: 2),
                          Text('версия 2.0 · чёрная', style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _Section(
                title: 'Поиск',
                children: [
                  for (final e in SearchEngine.values)
                    ListTile(
                      title: Text(e.label),
                      leading: Icon(
                        e == state.searchEngine ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      ),
                      onTap: () => state.setSearchEngine(e),
                    ),
                ],
              ),
              _Section(
                title: 'Vigil AI',
                children: [
                  ListTile(
                    leading: const Icon(Icons.auto_awesome_rounded),
                    title: const Text('Сервер ИИ'),
                    subtitle: Text(state.aiBase.isEmpty
                        ? 'Бесплатный (без ключа)'
                        : 'Свой: ${state.aiBase}'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _editAiServer(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded),
                    title: const Text('Очистить чат Vigil AI'),
                    subtitle: Text('Сообщений: ${state.aiChat.length}'),
                    onTap: state.aiChat.isEmpty
                        ? null
                        : () {
                            state.aiChat.clear();
                            state.saveAiChat();
                            state.touch();
                          },
                  ),
                ],
              ),
              _Section(
                title: 'Приватность',
                children: [
                  ListTile(
                    leading: const Icon(Icons.auto_delete_outlined),
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
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> _editAiServerDialog(BuildContext context, BrowserState state) async {
  final base = TextEditingController(text: state.aiBase);
  final key = TextEditingController(text: state.aiKey);
  final model = TextEditingController(text: state.aiModel);
  final save = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      icon: const Icon(Icons.auto_awesome_rounded),
      title: const Text('Сервер Vigil AI'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Оставьте адрес пустым — Vigil AI будет работать бесплатно без ключа. '
              'Или укажите любой OpenAI-совместимый сервер со своим ключом.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: base,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Адрес API',
                hintText: 'https://api.openai.com/v1',
              ),
            ),
            TextField(
              controller: key,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Ключ API'),
            ),
            TextField(
              controller: model,
              decoration: const InputDecoration(labelText: 'Модель', hintText: 'gpt-4o-mini'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            base.clear();
            key.clear();
            model.clear();
            Navigator.pop(c, true);
          },
          child: const Text('Бесплатный'),
        ),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Сохранить')),
      ],
    ),
  );
  if (save ?? false) {
    state.setAiServer(base: base.text, key: key.text, model: model.text);
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}
