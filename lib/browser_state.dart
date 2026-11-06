import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'url_utils.dart';

/// Запись истории или закладка.
class PageEntry {
  PageEntry({required this.title, required this.url, DateTime? time})
      : time = time ?? DateTime.now();

  final String title;
  final String url;
  final DateTime time;

  Map<String, dynamic> toJson() =>
      {'title': title, 'url': url, 'time': time.millisecondsSinceEpoch};

  factory PageEntry.fromJson(Map<String, dynamic> j) => PageEntry(
        title: j['title'] as String? ?? '',
        url: j['url'] as String? ?? '',
        time: DateTime.fromMillisecondsSinceEpoch(j['time'] as int? ?? 0),
      );
}

/// Одна вкладка браузера.
class BrowserTab {
  BrowserTab({this.url, this.incognito = false})
      : id = '${DateTime.now().microsecondsSinceEpoch}-${_counter++}';

  static int _counter = 0;

  final String id;
  final bool incognito;
  String? url;
  String title = 'Новая вкладка';
  int progress = 100;
  bool canGoBack = false;
  bool canGoForward = false;
  InAppWebViewController? controller;

  bool get isHome => url == null;
}

/// Всё состояние браузера: вкладки, настройки, история, закладки.
class BrowserState extends ChangeNotifier {
  static const _kTheme = 'theme';
  static const _kEngine = 'engine';
  static const _kDynamic = 'dynamic_color';
  static const _kHistory = 'history';
  static const _kBookmarks = 'bookmarks';
  static const _maxHistory = 500;

  late SharedPreferences _prefs;

  /// Отдельный сигнал для смены темы, чтобы не перестраивать MaterialApp при каждой загрузке.
  final settingsTick = ValueNotifier<int>(0);

  final List<BrowserTab> tabs = [];
  int currentIndex = 0;

  ThemeMode themeMode = ThemeMode.system;
  SearchEngine searchEngine = SearchEngine.google;
  bool useDynamicColor = true;
  List<PageEntry> history = [];
  List<PageEntry> bookmarks = [];

  BrowserTab get current => tabs[currentIndex];

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    themeMode = ThemeMode.values[(_prefs.getInt(_kTheme) ?? 0).clamp(0, 2)];
    final engine = _prefs.getInt(_kEngine) ?? 0;
    searchEngine = SearchEngine.values[engine.clamp(0, SearchEngine.values.length - 1)];
    useDynamicColor = _prefs.getBool(_kDynamic) ?? true;
    history = _readList(_kHistory);
    bookmarks = _readList(_kBookmarks);
    tabs.add(BrowserTab());
  }

  List<PageEntry> _readList(String key) {
    try {
      final raw = _prefs.getString(key);
      if (raw == null) return [];
      return (jsonDecode(raw) as List)
          .map((e) => PageEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _writeList(String key, List<PageEntry> list) =>
      _prefs.setString(key, jsonEncode(list.map((e) => e.toJson()).toList()));

  /// Сообщить интерфейсу, что данные вкладки изменились.
  void touch() => notifyListeners();

  // ---------- Навигация ----------

  void openInput(String input) {
    final url = resolveInput(input, searchEngine);
    if (url.isEmpty) return;
    final tab = current;
    if (!tab.isHome && tab.controller != null) {
      tab.controller!.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
      tab.url = url;
    } else {
      tab.url = url;
      tab.title = displayHost(url);
      tab.progress = 0;
    }
    notifyListeners();
  }

  void goHome() {
    final tab = current;
    tab
      ..url = null
      ..controller = null
      ..title = 'Новая вкладка'
      ..progress = 100
      ..canGoBack = false
      ..canGoForward = false;
    notifyListeners();
  }

  void back() {
    final tab = current;
    if (tab.canGoBack) {
      tab.controller?.goBack();
    } else if (!tab.isHome) {
      goHome();
    }
  }

  void forward() => current.controller?.goForward();
  void reload() => current.controller?.reload();

  /// Обработка системной кнопки «Назад». Возвращает false, если пора закрыть приложение.
  bool handleSystemBack() {
    final tab = current;
    if (tab.canGoBack || !tab.isHome) {
      back();
      return true;
    }
    if (tabs.length > 1) {
      closeTab(currentIndex);
      return true;
    }
    return false;
  }

  // ---------- Вкладки ----------

  void newTab({bool incognito = false, String? url}) {
    tabs.add(BrowserTab(incognito: incognito, url: url));
    currentIndex = tabs.length - 1;
    notifyListeners();
  }

  void selectTab(int index) {
    currentIndex = index;
    notifyListeners();
  }

  void closeTab(int index) {
    tabs.removeAt(index);
    if (tabs.isEmpty) tabs.add(BrowserTab());
    if (currentIndex >= tabs.length) currentIndex = tabs.length - 1;
    if (index < currentIndex) currentIndex--;
    notifyListeners();
  }

  void closeAllTabs() {
    tabs
      ..clear()
      ..add(BrowserTab());
    currentIndex = 0;
    notifyListeners();
  }

  // ---------- История и закладки ----------

  void recordVisit(BrowserTab tab, String? title, String? url) {
    if (tab.incognito || url == null || !url.startsWith('http')) return;
    if (history.isNotEmpty && history.first.url == url) {
      history.removeAt(0);
    }
    history.insert(0, PageEntry(title: (title?.isNotEmpty ?? false) ? title! : url, url: url));
    if (history.length > _maxHistory) history.removeRange(_maxHistory, history.length);
    _writeList(_kHistory, history);
  }

  void clearHistory() {
    history.clear();
    _writeList(_kHistory, history);
    notifyListeners();
  }

  void removeHistory(PageEntry e) {
    history.remove(e);
    _writeList(_kHistory, history);
    notifyListeners();
  }

  bool isBookmarked(String? url) => url != null && bookmarks.any((b) => b.url == url);

  void toggleBookmark() {
    final tab = current;
    final url = tab.url;
    if (url == null) return;
    if (isBookmarked(url)) {
      bookmarks.removeWhere((b) => b.url == url);
    } else {
      bookmarks.insert(0, PageEntry(title: tab.title, url: url));
    }
    _writeList(_kBookmarks, bookmarks);
    notifyListeners();
  }

  void removeBookmark(PageEntry e) {
    bookmarks.remove(e);
    _writeList(_kBookmarks, bookmarks);
    notifyListeners();
  }

  // ---------- Настройки ----------

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    _prefs.setInt(_kTheme, mode.index);
    settingsTick.value++;
    notifyListeners();
  }

  void setDynamicColor(bool value) {
    useDynamicColor = value;
    _prefs.setBool(_kDynamic, value);
    settingsTick.value++;
    notifyListeners();
  }

  void setSearchEngine(SearchEngine engine) {
    searchEngine = engine;
    _prefs.setInt(_kEngine, engine.index);
    notifyListeners();
  }
}
