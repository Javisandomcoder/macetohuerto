import 'package:flutter/material.dart';

ThemeData buildLightTheme(Color seed) {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
    useMaterial3: true,
  );
  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: base.colorScheme.surface,
      foregroundColor: base.colorScheme.onSurface,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: base.colorScheme.surfaceTint,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: base.colorScheme.surfaceContainerHighest.withOpacity(0.20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: base.colorScheme.primary, width: 1.6),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: base.colorScheme.primary,
      foregroundColor: base.colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
      TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
    }),
  );
}

ThemeData buildDarkTheme(Color seed) {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
    useMaterial3: true,
  );
  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: base.colorScheme.surface,
      foregroundColor: base.colorScheme.onSurface,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: base.colorScheme.surfaceTint,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: base.colorScheme.surfaceContainerHighest.withOpacity(0.12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: base.colorScheme.primary, width: 1.6),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: base.colorScheme.primary,
      foregroundColor: base.colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
      TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
    }),
  );
}
