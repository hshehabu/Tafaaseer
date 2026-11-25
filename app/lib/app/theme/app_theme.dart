import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_palette.dart';
import '../../features/settings/domain/entities/reader_settings.dart';

/// Light, dark and sepia themes (D7) in the Dusty Green design system:
/// flat surfaces, 1px borders instead of shadows, 4.8px corners, Tajawal.
abstract final class AppTheme {
  static ThemeData light() => build(AppPalette.light);

  static ThemeData dark() => build(AppPalette.dark);

  static ThemeData sepia() => build(AppPalette.sepia);

  static ThemeData build(AppPalette p) {
    final colors = ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: p.secondaryNeutral,
      onPrimaryContainer: p.primaryDark,
      secondary: p.primary,
      onSecondary: p.onPrimary,
      secondaryContainer: p.secondaryNeutral,
      onSecondaryContainer: p.primaryDark,
      tertiary: p.primary,
      onTertiary: p.onPrimary,
      error: p.destructive,
      onError: p.onPrimary,
      surface: p.canvas,
      onSurface: p.body,
      onSurfaceVariant: p.muted,
      surfaceContainerLowest: p.canvas,
      surfaceContainerLow: p.canvas,
      surfaceContainer: p.controlSurface,
      surfaceContainerHigh: p.controlSurface,
      surfaceContainerHighest: p.secondaryNeutral,
      outline: p.border,
      outlineVariant: p.border,
      inverseSurface: p.toast,
      onInverseSurface: p.onToast,
      shadow: Colors.transparent,
    );
    const radius = BorderRadius.all(Radius.circular(AppPalette.radius));
    final border = BorderSide(color: p.border);
    final base = ThemeData(useMaterial3: true, colorScheme: colors, fontFamily: UiFonts.interface);
    final text = base.textTheme.apply(bodyColor: p.body, displayColor: p.title);

    return base.copyWith(
      extensions: [p],
      scaffoldBackgroundColor: p.canvas,
      textTheme: text.copyWith(
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: p.title),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: p.title),
        titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: p.muted),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      dividerTheme: DividerThemeData(color: p.secondaryNeutral, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: p.canvas,
        foregroundColor: p.title,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: p.secondaryNeutral)),
        titleTextStyle: TextStyle(
          fontFamily: UiFonts.interface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: p.title,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: p.canvas,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: radius, side: border),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.muted,
        titleTextStyle: TextStyle(
          fontFamily: UiFonts.interface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: p.title,
        ),
        subtitleTextStyle: TextStyle(fontFamily: UiFonts.interface, fontSize: 13, color: p.muted),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.primary,
        unselectedLabelColor: p.muted,
        indicatorColor: p.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: p.secondaryNeutral,
        labelStyle: const TextStyle(fontFamily: UiFonts.interface, fontSize: 15, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontFamily: UiFonts.interface, fontSize: 15),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.controlSurface,
        selectedColor: p.secondaryNeutral,
        side: border,
        shape: const RoundedRectangleBorder(borderRadius: radius),
        labelStyle: TextStyle(fontFamily: UiFonts.interface, fontSize: 13, fontWeight: FontWeight.w600, color: p.body),
        secondaryLabelStyle: TextStyle(
          fontFamily: UiFonts.interface,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: p.primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        showCheckmark: false,
        elevation: 0,
        pressElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          shape: const RoundedRectangleBorder(borderRadius: radius),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: p.controlSurface,
          foregroundColor: p.muted,
          side: BorderSide(color: p.secondaryBorder),
          shape: const RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          shape: const RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: p.canvas,
          foregroundColor: p.body,
          selectedBackgroundColor: p.secondaryNeutral,
          selectedForegroundColor: p.primaryDark,
          side: border,
          shape: const RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.onPrimary : p.muted),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.primary : p.controlSurface,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.primary : p.secondaryBorder,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.primary,
        inactiveTrackColor: p.secondaryNeutral,
        thumbColor: p.primary,
        overlayColor: p.primary.withValues(alpha: 0.12),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.canvas,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: radius, side: border),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.canvas,
        modalBackgroundColor: p.canvas,
        elevation: 0,
        modalElevation: 0,
        dragHandleColor: p.secondaryBorder,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppPalette.sheetRadius)),
          side: border,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.toast,
        contentTextStyle: TextStyle(fontFamily: UiFonts.interface, color: p.onToast),
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.controlSurface,
        border: OutlineInputBorder(borderRadius: radius, borderSide: border),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: border),
        focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: p.primary, width: 1.5)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary, linearTrackColor: p.secondaryNeutral),
      iconTheme: IconThemeData(color: p.title),
    );
  }

  /// (light theme, dark theme, mode) for MaterialApp.
  static (ThemeData, ThemeData, ThemeMode) forPreference(ThemePreference preference) => switch (preference) {
    ThemePreference.system => (light(), dark(), ThemeMode.system),
    ThemePreference.light => (light(), dark(), ThemeMode.light),
    ThemePreference.dark => (light(), dark(), ThemeMode.dark),
    ThemePreference.sepia => (sepia(), dark(), ThemeMode.light),
  };
}
