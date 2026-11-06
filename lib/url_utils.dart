/// Поисковые системы, доступные в настройках.
enum SearchEngine {
  google('Google', 'https://www.google.com/search?q='),
  duckDuckGo('DuckDuckGo', 'https://duckduckgo.com/?q='),
  bing('Bing', 'https://www.bing.com/search?q='),
  yandex('Яндекс', 'https://yandex.ru/search/?text=');

  const SearchEngine(this.label, this.queryUrl);
  final String label;
  final String queryUrl;
}

final _scheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:');
final _hostLike = RegExp(r'^(localhost|[\w-]+(\.[\w-]+)+|\d{1,3}(\.\d{1,3}){3})(:\d+)?(/.*)?$');

/// Превращает ввод из адресной строки в URL: адрес сайта или поисковый запрос.
String resolveInput(String input, SearchEngine engine) {
  final text = input.trim();
  if (text.isEmpty) return '';
  if (_scheme.hasMatch(text) && !text.contains(' ') &&
      (text.contains('://') || text.startsWith('about:') || text.startsWith('data:'))) {
    return text;
  }
  if (!text.contains(' ') && _hostLike.hasMatch(text)) {
    return 'https://$text';
  }
  return engine.queryUrl + Uri.encodeQueryComponent(text);
}

/// Короткое представление адреса для адресной строки (как в Chrome на Pixel).
String displayHost(String? url) {
  if (url == null || url.isEmpty) return '';
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host.isEmpty) return url;
  return uri.host.startsWith('www.') ? uri.host.substring(4) : uri.host;
}
