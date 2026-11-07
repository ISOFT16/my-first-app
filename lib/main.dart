import 'package:flutter/material.dart';

import 'browser_state.dart';
import 'screens/browser_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        title: 'Fox Browser',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(foxLightScheme()),
        darkTheme: buildTheme(foxDarkScheme()),
        themeMode: state.themeMode,
        home: BrowserScreen(state: state),
      ),
    );
  }
}
