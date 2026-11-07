import 'package:flutter_test/flutter_test.dart';
import 'package:fox_browser/ai/fox_ai.dart';

void main() {
  test('очистка Markdown в ответе Fox AI', () {
    const raw = '## Заголовок\n**Жирный** текст\n- пункт один\n* пункт два\n\n---\nSupport Pollinations.AI: реклама';
    expect(FoxAi.clean(raw), 'Заголовок\nЖирный текст\n• пункт один\n• пункт два');
  });

  test('сообщение сохраняется и читается', () {
    final m = AiMessage(fromUser: true, text: 'Привет');
    final back = AiMessage.fromJson(m.toJson());
    expect(back.fromUser, isTrue);
    expect(back.text, 'Привет');
  });
}
