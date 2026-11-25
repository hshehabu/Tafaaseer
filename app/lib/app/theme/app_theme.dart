import 'package:flutter/material.dart';

import '../../features/settings/domain/entities/reader_settings.dart';

/// Light, dark and sepia themes (D7), built from one seed colour.
abstract final class AppTheme {
  static const _seed = Color(0xFF1E6B5C); // deep green-teal

  static ThemeData light() => _build(ColorScheme.fromSeed(seedColor: _seed));

  static ThemeData dark() => _build(ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark));

  /// Warm paper tones for long reading sessions.
  static ThemeData sepia() => _build(
    ColorScheme.fromSeed(
      seedColor: const Color(0xFF8A6A3B),
      surface: const Color(0xFFF6EEDC),
      onSurface: const Color(0xFF3B2F1E),
    ),
  );

  static ThemeData _build(ColorScheme colors) => ThemeData(
    colorScheme: colors,
    scaffoldBackgroundColor: colors.surface,
    appBarTheme: AppBarTheme(backgroundColor: colors.surface, scrolledUnderElevation: 1),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: colors.surfaceContainerLow),
  );

  /// (light theme, dark theme, mode) for MaterialApp.
  static (ThemeData, ThemeData, ThemeMode) forPreference(ThemePreference preference) => switch (preference) {
    ThemePreference.system => (light(), dark(), ThemeMode.system),
    ThemePreference.light => (light(), dark(), ThemeMode.light),
    ThemePreference.dark => (light(), dark(), ThemeMode.dark),
    ThemePreference.sepia => (sepia(), dark(), ThemeMode.light),
  };
}
