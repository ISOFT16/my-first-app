import 'package:flutter/material.dart';

/// Официальный шрифт Google Sans, встроен в приложение (assets/fonts).
const foxFont = 'Google Sans';

/// Палитра «песок и кофе» — осталась для мини-игры «Лис в бегах» (ностальгия).
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

/// Фирменный красный Vigil — для немногих акцентов.
const vigilRed = Color(0xFFE5161C);

/// Палитра Vigil Browser: чёрный, белый и немного красного.
class VigilPalette {
  static const black = Color(0xFF000000);
  static const coal = Color(0xFF0E0E0E);
  static const graphite = Color(0xFF161616);
  static const smoke = Color(0xFF1E1E1E);
  static const ash = Color(0xFF2A2A2A);
  static const white = Color(0xFFF2F2F2);
  static const grey = Color(0xFF9E9E9E);

  /// Плитки быстрого доступа — оттенки графита.
  static const tiles = [
    Color(0xFF1C1C1C),
    Color(0xFF222222),
    Color(0xFF191919),
    Color(0xFF262626),
    Color(0xFF1F1F1F),
    Color(0xFF242424),
  ];
}

ColorScheme vigilScheme() => const ColorScheme(
      brightness: Brightness.dark,
      primary: VigilPalette.white,
      onPrimary: VigilPalette.black,
      primaryContainer: VigilPalette.smoke,
      onPrimaryContainer: Colors.white,
      secondary: VigilPalette.grey,
      onSecondary: VigilPalette.black,
      secondaryContainer: VigilPalette.graphite,
      onSecondaryContainer: Colors.white,
      tertiary: vigilRed,
      onTertiary: Colors.white,
      error: Color(0xFFFF5A5A),
      onError: VigilPalette.black,
      errorContainer: Color(0xFF3A0D0F),
      onErrorContainer: Color(0xFFFFDADA),
      surface: VigilPalette.black,
      onSurface: VigilPalette.white,
      onSurfaceVariant: VigilPalette.grey,
      surfaceContainerLowest: Color(0xFF0A0A0A),
      surfaceContainerLow: VigilPalette.coal,
      surfaceContainer: Color(0xFF111111),
      surfaceContainerHigh: VigilPalette.smoke,
      surfaceContainerHighest: VigilPalette.ash,
      outline: Color(0xFF3A3A3A),
      outlineVariant: Color(0xFF232323),
      inverseSurface: VigilPalette.white,
      onInverseSurface: VigilPalette.black,
      inversePrimary: VigilPalette.black,
      shadow: Colors.black,
      surfaceTint: Colors.transparent,
    );

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

/// Тайная вкладка — чёрный с холодным оттенком.
ColorScheme incognitoScheme() => vigilScheme().copyWith(
      primary: const Color(0xFFC9CCD6),
      surface: const Color(0xFF05060A),
      surfaceContainer: const Color(0xFF0E1016),
      surfaceContainerHigh: const Color(0xFF181B24),
      surfaceContainerHighest: const Color(0xFF22262F),
      secondaryContainer: const Color(0xFF181B24),
    );

ThemeData buildTheme(ColorScheme scheme) {
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: foxFont);
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
      color: scheme.tertiary,
      linearTrackColor: Colors.transparent,
    ),
  );
}
