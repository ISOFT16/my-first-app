# 🦊 Fox Browser

Кроссплатформенный браузер в **собственном стиле «песок и кофе»**: тёплые бежевые тона, свой геометрический логотип-лиса и адресная строка внизу экрана.
Один код на **Flutter** собирается для **Android**, **iPhone (iOS)** и **Windows**.

## Возможности

- 🎨 Собственный дизайн: песочно-бежевая палитра, логотип-лиса из геометрических фигур,
  адресная капсула и кнопки внизу экрана, меню из плиток, приветствие на стартовой странице.
- 🎮 Пасхалка: нажмите 5 раз на «fox browser» на стартовой странице — откроется игра «Лис в бегах» (7 уровней).
- 🔤 Официальный шрифт **Google Sans** (открытая лицензия SIL OFL, файл лицензии — `assets/fonts/OFL.txt`).
- 🌗 Темы «Песок» (светлая), «Кофе» (тёмная) и «Авто».
- 🗂️ Вкладки с обзором в виде сетки карточек (как в Chrome).
- 🕶️ «Тайная вкладка» (инкогнито) в оливково-тёмных тонах: история и cookie не сохраняются.
- ⭐ Закладки, 🕘 история (с удалением свайпом и очисткой).
- 🔎 Выбор поисковой системы: Google, DuckDuckGo, Bing, Яндекс.
- 🏠 Стартовая страница с поиском и быстрыми ярлыками.
- ↩️ Системная кнопка «Назад» на Android, свайп назад на iPhone, жест «потянуть для обновления».
- 🖥️ На широком экране (Windows, планшет) кнопки «Назад/Вперёд/Обновить» прямо в панели.

## Как собрать

### Вариант 1 — автоматически через GitHub (ничего не нужно устанавливать)

При каждом push GitHub Actions собирает все три версии (`.github/workflows/build.yml`).
Откройте вкладку **Actions** → последний запуск → внизу раздел **Artifacts**:

| Файл | Платформа | Как установить |
|---|---|---|
| `FoxBrowser-android` | Android | распаковать и установить `app-release.apk` |
| `FoxBrowser-windows` | Windows 10/11 | распаковать и запустить `fox_browser.exe` |
| `FoxBrowser-ios-unsigned` | iPhone | неподписанный `.ipa`: ставится через AltStore/Sideloadly, для App Store нужен аккаунт Apple Developer |

### Вариант 2 — на своём компьютере

1. Установите [Flutter](https://docs.flutter.dev/get-started/install) (3.27 или новее).
2. В папке проекта:

```bash
dart run tool/setup.dart   # создаёт android/, ios/, windows/ и настраивает их
flutter pub get
flutter run                # запуск на подключённом телефоне или эмуляторе
```

Сборка релиза:

```bash
flutter build apk --release      # Android
flutter build windows --release  # Windows (нужна Visual Studio с «Разработка классических приложений на C++»)
flutter build ios --release      # iPhone (только на Mac с Xcode)
```

> Для Windows нужен WebView2 Runtime — он уже встроен в Windows 10/11 (если нет, его можно скачать у Microsoft).

## Структура

```
lib/
  main.dart                  — запуск приложения
  theme.dart                 — палитра «песок и кофе»
  browser_state.dart         — вкладки, история, закладки, настройки
  url_utils.dart             — адрес или поисковый запрос
  screens/
    browser_screen.dart      — главный экран: адресная строка, меню
    tabs_screen.dart         — обзор вкладок
    pages_list_screen.dart   — история и закладки
    settings_screen.dart     — настройки
  widgets/
    omnibox.dart             — адресная строка
    home_page.dart           — стартовая страница
    tab_webview.dart         — веб-движок вкладки
    fox_logo.dart            — логотип-лиса
assets/icon.png              — иконка приложения
tool/setup.dart              — генерация и настройка платформ
```

Веб-движок: [`flutter_inappwebview`](https://pub.dev/packages/flutter_inappwebview) —
Android System WebView (Chromium) на Android, WebKit на iOS, Microsoft Edge WebView2 на Windows.
