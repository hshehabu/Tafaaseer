import 'package:flutter/material.dart';

import '../config/app_config.dart';

/// Mushaf text in the KFGQPC Hafs font. Shows the string exactly as given:
/// no normalisation, no rewriting of marks (see docs/v1-scope.md).
class QuranText extends StatelessWidget {
  const QuranText(
    this.text, {
    super.key,
    required this.fontSize,
    this.color,
    this.textAlign = TextAlign.start,
    this.maxLines,
  });

  final String text;
  final double fontSize;
  final Color? color;
  final TextAlign textAlign;
  final int? maxLines;

  static TextStyle style({required double fontSize, Color? color}) => TextStyle(
    fontFamily: QuranFontConfig.family,
    fontFamilyFallback: QuranFontConfig.fallback,
    fontSize: fontSize,
    height: 2.1,
    color: color,
  );

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: textAlign,
    textDirection: TextDirection.rtl,
    maxLines: maxLines,
    overflow: maxLines == null ? null : TextOverflow.ellipsis,
    style: style(fontSize: fontSize, color: color),
  );
}
