import 'package:flutter/material.dart';

/// Собственная палитра Fox Browser: «песок и кофе».
class FoxPalette {
  // Светлая тема — песок, крем, латте.
  static const sand = Color(0xFFF3EADF);
  static const cream = Color(0xFFFBF6EF);
  static const linen = Color(0xFFEDE2D3);
  static const dune = Color(0xFFE3D4C1);
  static const latte = Color(0xFF8B6B4A);
  static const caramel = Color(0xFFB89B7A);
  static const espresso = Color(0xFF3B2F25);
  static const bark = Color(0xFF6E5A47);

  // Тёмная тема — эспрессо и мокко.
  static const night = Color(0xFF1E1813);
  static const mocha = Color(0xFF29211A);
  static const cocoa = Color(0xFF352B22);
  static const roast = Color(0xFF43362B);
  static const beige = Color(0xFFD9BF9E);
  static const milk = Color(0xFFF1E6D8);

  /// Тёплые оттенки для плиток быстрого доступа.
  static const tiles = [
    Color(0xFFD9BF9E), // песок
    Color(0xFFC9A98B), // глина
    Color(0xFFB7B08F), // олива
    Color(0xFFD4A99A), // терракота
    Color(0xFFBFAE9B), // камень
    Color(0xFFCDB89A), // пшеница
  ];
}

ColorScheme foxLightScheme() => const ColorScheme(
      brightness: Brightness.light,
      primary: FoxPalette.latte,
      onPrimary: FoxPalette.cream,
      primaryContainer: FoxPalette.dune,
      onPrimaryContainer: FoxPalette.espresso,
      secondary: FoxPalette.caramel,
      onSecondary: FoxPalette.espresso,
      secondaryContainer: FoxPalette.linen,
      onSecondaryContainer: FoxPalette.espresso,
      tertiary: Color(0xFF8C7A5B),
      onTertiary: FoxPalette.cream,
      error: Color(0xFFB0473A),
      onError: FoxPalette.cream,
      surface: FoxPalette.sand,
      onSurface: FoxPalette.espresso,
      onSurfaceVariant: FoxPalette.bark,
      surfaceContainerLowest: FoxPalette.cream,
      surfaceContainerLow: Color(0xFFF7F0E7),
      surfaceContainer: FoxPalette.cream,
      surfaceContainerHigh: FoxPalette.linen,
      surfaceContainerHighest: FoxPalette.dune,
      outline: Color(0xFFCBB8A0),
      outlineVariant: Color(0xFFE0D2BF),
      inverseSurface: FoxPalette.espresso,
      onInverseSurface: FoxPalette.sand,
      inversePrimary: FoxPalette.beige,
      shadow: Color(0x333B2F25),
      surfaceTint: Colors.transparent,
    );

ColorScheme foxDarkScheme() => const ColorScheme(
      brightness: Brightness.dark,
      primary: FoxPalette.beige,
      onPrimary: FoxPalette.night,
      primaryContainer: FoxPalette.roast,
      onPrimaryContainer: FoxPalette.milk,
      secondary: FoxPalette.caramel,
      onSecondary: FoxPalette.night,
      secondaryContainer: FoxPalette.cocoa,
      onSecondaryContainer: FoxPalette.milk,
      tertiary: Color(0xFFC8B98F),
      onTertiary: FoxPalette.night,
      error: Color(0xFFE59A8C),
      onError: FoxPalette.night,
      surface: FoxPalette.night,
      onSurface: FoxPalette.milk,
      onSurfaceVariant: Color(0xFFBFAE9B),
      surfaceContainerLowest: Color(0xFF17120E),
      surfaceContainerLow: FoxPalette.mocha,
      surfaceContainer: FoxPalette.mocha,
      surfaceContainerHigh: FoxPalette.cocoa,
      surfaceContainerHighest: FoxPalette.roast,
      outline: Color(0xFF6E5A47),
      outlineVariant: Color(0xFF4A3D31),
      inverseSurface: FoxPalette.milk,
      onInverseSurface: FoxPalette.night,
      inversePrimary: FoxPalette.latte,
      shadow: Colors.black54,
      surfaceTint: Colors.transparent,
    );

/// Инкогнито — тёмный «ночной лес»: оливково-серые тона.
ColorScheme incognitoScheme() => foxDarkScheme().copyWith(
      primary: const Color(0xFFB7B08F),
      surface: const Color(0xFF181A15),
      surfaceContainer: const Color(0xFF22241D),
      surfaceContainerHigh: const Color(0xFF2B2E25),
      surfaceContainerHighest: const Color(0xFF353829),
      secondaryContainer: const Color(0xFF2B2E25),
    );

ThemeData buildTheme(ColorScheme scheme) {
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final text = base.textTheme.apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: text.copyWith(
      headlineLarge: text.headlineLarge?.copyWith(fontWeight: FontWeight.w300, letterSpacing: -0.5),
      headlineMedium: text.headlineMedium?.copyWith(fontWeight: FontWeight.w300, letterSpacing: -0.3),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.2),
      labelLarge: text.labelLarge?.copyWith(letterSpacing: 0.4),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.2),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainer,
      showDragHandle: true,
      dragHandleColor: scheme.outline,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? scheme.onPrimary : scheme.outline,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? scheme.primary : scheme.surfaceContainerHigh,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 0,
      shape: const StadiumBorder(),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: Colors.transparent,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
