import 'dart:convert';

import 'package:http/http.dart' as http;

/// Одно сообщение в чате Fox AI.
class AiMessage {
  AiMessage({required this.fromUser, required this.text, this.isError = false});

  final bool fromUser;
  final String text;
  final bool isError;

  Map<String, dynamic> toJson() => {'u': fromUser, 't': text};

  factory AiMessage.fromJson(Map<String, dynamic> j) =>
      AiMessage(fromUser: j['u'] == true, text: j['t'] as String? ?? '');
}

class FoxAiException implements Exception {
  FoxAiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Бесплатный режим ограничен: примерно один ответ в 45 секунд.
class FoxAiRateLimit extends FoxAiException {
  FoxAiRateLimit(this.seconds) : super('Бесплатный Fox AI отвечает раз в 45 секунд. Подождите $seconds сек.');
  final int seconds;
}

/// Fox AI — ИИ-помощник Fox Browser.
///
/// По умолчанию работает бесплатно и без ключа через открытый сервис
/// Pollinations (text.pollinations.ai). В настройках можно подключить любой
/// свой OpenAI-совместимый сервер (адрес, ключ, модель).
class FoxAi {
  static const systemPrompt =
      'Ты — Fox AI, умный и дружелюбный ИИ-помощник, встроенный в браузер Fox Browser. '
      'Тебя зовут Fox AI, твой символ — лиса. '
      'Отвечай на любые вопросы пользователя: учёба, наука, программирование, советы, '
      'тексты, переводы, идеи, рецепты, здоровье и всё остальное. '
      'Отвечай на языке пользователя (по умолчанию — по-русски), понятно, тепло и по делу. '
      'Не используй разметку Markdown (звёздочки, решётки, таблицы) — пиши обычным текстом, '
      'списки оформляй через «•». Код можно приводить как есть. '
      'Если не знаешь точного ответа — честно скажи об этом.';

  static const _freeChatUrl = 'https://text.pollinations.ai/openai';
  static const _freeTextUrl = 'https://text.pollinations.ai/';
  static const _timeout = Duration(seconds: 90);

  final http.Client _client = http.Client();

  /// Отправляет историю чата и возвращает ответ Fox AI.
  Future<String> ask(
    List<AiMessage> history, {
    String base = '',
    String key = '',
    String model = '',
  }) async {
    final usable = history.where((m) => !m.isError).toList();
    final recent = usable.length > 20 ? usable.sublist(usable.length - 20) : usable;
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      for (final m in recent) {'role': m.fromUser ? 'user' : 'assistant', 'content': m.text},
    ];

    // Свой сервер из настроек.
    if (base.trim().isNotEmpty) {
      return _chatCompletions(
        _join(base.trim(), 'chat/completions'),
        messages,
        model.trim().isEmpty ? 'gpt-4o-mini' : model.trim(),
        key.trim(),
      );
    }

    // Бесплатный режим: сначала OpenAI-совместимый метод, потом простой текстовый.
    try {
      return await _chatCompletions(
        _freeChatUrl,
        messages,
        'openai',
        '',
        extra: {'referrer': 'foxbrowser', 'private': true},
      );
    } on FoxAiRateLimit {
      rethrow;
    } catch (_) {
      final question = recent.lastWhere((m) => m.fromUser).text;
      final uri = Uri.parse('$_freeTextUrl${Uri.encodeComponent(question)}').replace(
        queryParameters: {
          'model': 'openai',
          'system': systemPrompt,
          'private': 'true',
          'referrer': 'foxbrowser',
        },
      );
      final r = await _client.get(uri).timeout(_timeout);
      final body = utf8.decode(r.bodyBytes).trim();
      _checkRateLimit(r.statusCode, body);
      if (r.statusCode != 200 || body.isEmpty) {
        throw FoxAiException('Fox AI сейчас недоступен (код ${r.statusCode}). Попробуйте ещё раз чуть позже.');
      }
      return clean(body);
    }
  }

  Future<String> _chatCompletions(
    String url,
    List<Map<String, String>> messages,
    String model,
    String key, {
    Map<String, Object> extra = const {},
  }) async {
    final r = await _client
        .post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            if (key.isNotEmpty) 'Authorization': 'Bearer $key',
          },
          body: jsonEncode({'model': model, 'messages': messages, ...extra}),
        )
        .timeout(_timeout);
    final text = utf8.decode(r.bodyBytes);
    _checkRateLimit(r.statusCode, text);
    if (r.statusCode != 200) {
      throw FoxAiException('Сервер ИИ ответил ошибкой ${r.statusCode}.');
    }
    final data = jsonDecode(text);
    String? content;
    if (data is Map) {
      final choices = data['choices'];
      if (choices is List && choices.isNotEmpty && choices.first is Map) {
        final message = (choices.first as Map)['message'];
        if (message is Map && message['content'] is String) content = message['content'] as String;
      }
    }
    if (content == null || content.trim().isEmpty) {
      throw FoxAiException('Сервер ИИ прислал пустой ответ.');
    }
    return clean(content);
  }

  static void _checkRateLimit(int status, String body) {
    if (status == 402 || status == 429 || body.contains('Free limit reached')) {
      final m = RegExp(r'wait (\d+) second').firstMatch(body);
      throw FoxAiRateLimit(int.tryParse(m?.group(1) ?? '') ?? 45);
    }
  }

  static String _join(String base, String path) =>
      base.endsWith('/') ? '$base$path' : '$base/$path';

  /// Убирает Markdown-разметку и рекламные подписи бесплатного сервиса.
  static String clean(String s) {
    var t = s.replaceAll('\r\n', '\n');
    final ad = RegExp(r'\n-{3,}[ \t]*\n[^\n]*pollinations', caseSensitive: false).firstMatch(t);
    if (ad != null && ad.start > 0) t = t.substring(0, ad.start);
    t = t.replaceAll('**', '').replaceAll('__', '');
    t = t.replaceAll(RegExp(r'^#{1,6}[ \t]*', multiLine: true), '');
    t = t.replaceAll(RegExp(r'^[ \t]*[-*][ \t]+', multiLine: true), '• ');
    return t.trim();
  }
}
