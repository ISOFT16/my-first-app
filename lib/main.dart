import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'browser_state.dart';
import 'screens/browser_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  final state = BrowserState();
  await state.load();
  runApp(FoxBrowserApp(state: state));
}

class FoxBrowserApp extends StatelessWidget {
  const FoxBrowserApp({super.key, required this.state});

  final BrowserState state;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: state.settingsTick,
      builder: (context, _, __) => MaterialApp(
        title: 'Vigil Browser',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(vigilScheme()),
        darkTheme: buildTheme(vigilScheme()),
        themeMode: ThemeMode.dark,
        home: BrowserScreen(state: state),
      ),
    );
  }
}
