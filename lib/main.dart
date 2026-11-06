import 'package:dynamic_color/dynamic_color.dart';
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
      builder: (context, _, __) => DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) {
          final useDynamic =
              state.useDynamicColor && lightDynamic != null && darkDynamic != null;
          final light = useDynamic
              ? lightDynamic.harmonized()
              : ColorScheme.fromSeed(seedColor: foxOrange);
          final dark = useDynamic
              ? darkDynamic.harmonized()
              : ColorScheme.fromSeed(seedColor: foxOrange, brightness: Brightness.dark);
          return MaterialApp(
            title: 'Fox Browser',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(light),
            darkTheme: buildTheme(dark),
            themeMode: state.themeMode,
            home: BrowserScreen(state: state),
          );
        },
      ),
    );
  }
}
