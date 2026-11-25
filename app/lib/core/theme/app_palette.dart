import 'package:flutter/material.dart';

/// Colour tokens of the Dusty Green design system (from the 30 Juz in 7 Days
/// app, see docs/v2-scope.md), in a light, dark and sepia variant.
///
/// Widgets read these through `AppPalette.of(context)` when the Material
/// [ColorScheme] has no matching role (borders, the soft control surface, the
/// mushaf ink and highlight).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.canvas,
    required this.controlSurface,
    required this.secondaryNeutral,
    required this.border,
    required this.secondaryBorder,
    required this.primary,
    required this.primaryDark,
    required this.onPrimary,
    required this.title,
    required this.body,
    required this.muted,
    required this.destructive,
    required this.mushafInk,
    required this.mushafHighlight,
    required this.toast,
    required this.onToast,
  });

  final Brightness brightness;

  /// Screens, sheets and dialogs.
  final Color canvas;

  /// Inactive pills, banners, inputs.
  final Color controlSurface;

  /// Active pill fill, number tiles, completed badges.
  final Color secondaryNeutral;

  /// 1px borders on cards, pills and dividers.
  final Color border;
  final Color secondaryBorder;
  final Color primary;
  final Color primaryDark;
  final Color onPrimary;

  /// Titles and app bar text.
  final Color title;

  /// Reading text.
  final Color body;

  /// Subtitles, badges, hints.
  final Color muted;
  final Color destructive;

  /// Quran text on the mushaf page.
  final Color mushafInk;

  /// Behind the long-pressed ayah on the mushaf page.
  final Color mushafHighlight;
  final Color toast;
  final Color onToast;

  static const radius = 4.8;
  static const sheetRadius = 8.0;

  static AppPalette of(BuildContext context) => Theme.of(context).extension<AppPalette>()!;

  static const light = AppPalette(
    brightness: Brightness.light,
    canvas: Color(0xFFFFFFFF),
    controlSurface: Color(0xFFF3F7F5),
    secondaryNeutral: Color(0xFFE4ECE7),
    border: Color(0xFFCDD9D3),
    secondaryBorder: Color(0xFFBCCDC5),
    primary: Color(0xFF416757),
    primaryDark: Color(0xFF2E4B3E),
    onPrimary: Color(0xFFFFFFFF),
    title: Color(0xFF1E2B25),
    body: Color(0xFF283630),
    muted: Color(0xFF566A61),
    destructive: Color(0xFFB85D43),
    mushafInk: Color(0xFF1E2B25),
    mushafHighlight: Color(0x26416757),
    toast: Color(0xFF1E2B25),
    onToast: Color(0xFFFFFFFF),
  );

  /// Forest charcoal canvas with sage text and borders.
  static const dark = AppPalette(
    brightness: Brightness.dark,
    canvas: Color(0xFF121915),
    controlSurface: Color(0xFF1A231F),
    secondaryNeutral: Color(0xFF233029),
    border: Color(0xFF2E3C35),
    secondaryBorder: Color(0xFF3B4C43),
    primary: Color(0xFF8DB5A3),
    primaryDark: Color(0xFFA9CBBB),
    onPrimary: Color(0xFF10201A),
    title: Color(0xFFE8EFEB),
    body: Color(0xFFD5DFD9),
    muted: Color(0xFF94A79D),
    destructive: Color(0xFFE0896F),
    mushafInk: Color(0xFFE8EFEB),
    mushafHighlight: Color(0x338DB5A3),
    toast: Color(0xFFE8EFEB),
    onToast: Color(0xFF121915),
  );

  /// Warm paper with the same green accents.
  static const sepia = AppPalette(
    brightness: Brightness.light,
    canvas: Color(0xFFF7F1E3),
    controlSurface: Color(0xFFF0E8D5),
    secondaryNeutral: Color(0xFFE7DDC5),
    border: Color(0xFFDCCFB1),
    secondaryBorder: Color(0xFFCDBD99),
    primary: Color(0xFF416757),
    primaryDark: Color(0xFF2E4B3E),
    onPrimary: Color(0xFFFFFFFF),
    title: Color(0xFF2B2416),
    body: Color(0xFF3A3020),
    muted: Color(0xFF6D604B),
    destructive: Color(0xFFB85D43),
    mushafInk: Color(0xFF2B2416),
    mushafHighlight: Color(0x2E416757),
    toast: Color(0xFF2B2416),
    onToast: Color(0xFFF7F1E3),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) => t < 0.5 || other == null ? this : other;
}
