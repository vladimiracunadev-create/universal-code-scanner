import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData light({bool highContrast = false, bool largeControls = false, bool reduceMotion = false}) =>
      _build(Brightness.light, highContrast: highContrast, largeControls: largeControls, reduceMotion: reduceMotion);

  static ThemeData dark({bool highContrast = false, bool largeControls = false, bool reduceMotion = false}) =>
      _build(Brightness.dark, highContrast: highContrast, largeControls: largeControls, reduceMotion: reduceMotion);

  static ThemeData _build(
    Brightness brightness, {
    required bool highContrast,
    required bool largeControls,
    required bool reduceMotion,
  }) {
    final Color seed = brightness == Brightness.light ? const Color(0xFF006B66) : const Color(0xFF5BD7CD);
    final ColorScheme colors = ColorScheme.fromSeed(seedColor: seed, brightness: brightness, contrastLevel: highContrast ? 1.0 : 0.0);
    return ThemeData(
      colorScheme: colors,
      useMaterial3: true,
      scaffoldBackgroundColor: colors.surface,
      visualDensity: largeControls ? const VisualDensity(horizontal: 1, vertical: 1) : VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: reduceMotion
          ? const PageTransitionsTheme(builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: _NoTransitionsBuilder(),
              TargetPlatform.iOS: _NoTransitionsBuilder(),
              TargetPlatform.macOS: _NoTransitionsBuilder(),
              TargetPlatform.windows: _NoTransitionsBuilder(),
              TargetPlatform.linux: _NoTransitionsBuilder(),
              TargetPlatform.fuchsia: _NoTransitionsBuilder(),
            })
          : const PageTransitionsTheme(),
      cardTheme: CardThemeData(
        elevation: highContrast ? 1 : 0,
        shape: RoundedRectangleBorder(
          side: highContrast ? BorderSide(color: colors.outline, width: 1.5) : BorderSide.none,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}

class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();
  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) => child;
}
