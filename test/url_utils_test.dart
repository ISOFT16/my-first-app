import 'package:flutter_test/flutter_test.dart';
import 'package:fox_browser/url_utils.dart';

void main() {
  const g = SearchEngine.google;

  test('адрес сайта превращается в https', () {
    expect(resolveInput('example.com', g), 'https://example.com');
    expect(resolveInput('ru.wikipedia.org/wiki/Лиса', g), 'https://ru.wikipedia.org/wiki/Лиса');
    expect(resolveInput('localhost:8080', g), 'https://localhost:8080');
  });

  test('полный URL остаётся как есть', () {
    expect(resolveInput('http://example.com/a?b=1', g), 'http://example.com/a?b=1');
    expect(resolveInput('about:blank', g), 'about:blank');
  });

  test('текст уходит в поиск', () {
    expect(resolveInput('рыжая лиса', g), 'https://www.google.com/search?q=%D1%80%D1%8B%D0%B6%D0%B0%D1%8F+%D0%BB%D0%B8%D1%81%D0%B0');
    expect(resolveInput('flutter', SearchEngine.duckDuckGo), 'https://duckduckgo.com/?q=flutter');
  });

  test('пустой ввод', () {
    expect(resolveInput('   ', g), '');
  });

  test('короткий адрес для адресной строки', () {
    expect(displayHost('https://www.google.com/search?q=1'), 'google.com');
    expect(displayHost(null), '');
  });
}
