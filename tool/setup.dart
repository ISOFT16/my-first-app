// Генерирует папки android/, ios/, windows/ и настраивает их для Fox Browser.
// Запуск из корня проекта:  dart run tool/setup.dart
import 'dart:io';

Future<void> main() async {
  stdout.writeln('🦊 Fox Browser: создаю платформенные проекты...');
  final result = await Process.run(
    'flutter',
    [
      'create',
      '--platforms=android,ios,windows',
      '--org', 'com.foxbrowser',
      '--project-name', 'fox_browser',
      '.',
    ],
    runInShell: true,
  );
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) exit(result.exitCode);

  _patchAndroid();
  _patchIos();
  _patchWindows();

  // Своя иконка приложения (assets/icon.png) для Android, iOS и Windows.
  for (final cmd in [
    ['flutter', 'pub', 'get'],
    ['dart', 'run', 'flutter_launcher_icons'],
  ]) {
    final r = await Process.run(cmd.first, cmd.sublist(1), runInShell: true);
    stdout.write(r.stdout);
    stderr.write(r.stderr);
    if (r.exitCode != 0) exit(r.exitCode);
  }

  // flutter create кладёт свой пример теста, который ссылается на MyApp.
  final sample = File('test/widget_test.dart');
  if (sample.existsSync() && sample.readAsStringSync().contains('MyApp')) sample.deleteSync();

  stdout.writeln('✅ Готово. Теперь: flutter pub get && flutter run');
}

void _edit(String path, String Function(String) change) {
  final file = File(path);
  if (!file.existsSync()) {
    stdout.writeln('⚠️  Не найден $path — пропускаю');
    return;
  }
  file.writeAsStringSync(change(file.readAsStringSync()));
  stdout.writeln('   настроен $path');
}

void _patchAndroid() {
  _edit('android/app/src/main/AndroidManifest.xml', (s) {
    if (!s.contains('android.permission.INTERNET')) {
      s = s.replaceFirst(
        '<application',
        '<uses-permission android:name="android.permission.INTERNET"/>\n    <application',
      );
    }
    s = s.replaceFirst(RegExp(r'android:label="[^"]*"'), 'android:label="Fox Browser"');
    if (!s.contains('usesCleartextTraffic')) {
      s = s.replaceFirst(
        'android:label="Fox Browser"',
        'android:label="Fox Browser"\n        android:usesCleartextTraffic="true"',
      );
    }
    return s;
  });
}

void _patchIos() {
  _edit('ios/Runner/Info.plist', (s) {
    s = s.replaceFirstMapped(
      RegExp(r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)'),
      (m) => '${m[1]}Fox Browser${m[2]}',
    );
    if (!s.contains('NSAppTransportSecurity')) {
      final i = s.lastIndexOf('</dict>');
      s = '${s.substring(0, i)}\t<key>NSAppTransportSecurity</key>\n'
          '\t<dict>\n\t\t<key>NSAllowsArbitraryLoads</key>\n\t\t<true/>\n\t</dict>\n'
          '${s.substring(i)}';
    }
    return s;
  });
}

void _patchWindows() {
  _edit('windows/runner/main.cpp', (s) => s.replaceAll('L"fox_browser"', 'L"Fox Browser"'));
}
