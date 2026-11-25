import 'package:flutter/foundation.dart';

enum ThemePreference { system, light, dark, sepia }

@immutable
class ReaderSettings {
  const ReaderSettings({
    this.theme = ThemePreference.system,
    this.tafsirFontSize = 18,
    this.tafsirLineHeight = 1.9,
    this.showTashkeel = true,
    this.hideIsnad = false,
    this.tafsirHintSeen = false,
  });

  static const tafsirFontRange = (min: 14.0, max: 30.0);
  static const lineHeightRange = (min: 1.4, max: 2.6);

  final ThemePreference theme;
  final double tafsirFontSize;
  final double tafsirLineHeight;

  /// Show diacritics in tafsir text (C3). Quran quotes always keep them.
  final bool showTashkeel;

  /// Collapse chains of narrators into a tappable marker (C1).
  final bool hideIsnad;

  /// The one-time "long-press an ayah" hint was dismissed (E1).
  final bool tafsirHintSeen;

  ReaderSettings copyWith({
    ThemePreference? theme,
    double? tafsirFontSize,
    double? tafsirLineHeight,
    bool? showTashkeel,
    bool? hideIsnad,
    bool? tafsirHintSeen,
  }) => ReaderSettings(
    theme: theme ?? this.theme,
    tafsirFontSize: tafsirFontSize ?? this.tafsirFontSize,
    tafsirLineHeight: tafsirLineHeight ?? this.tafsirLineHeight,
    showTashkeel: showTashkeel ?? this.showTashkeel,
    hideIsnad: hideIsnad ?? this.hideIsnad,
    tafsirHintSeen: tafsirHintSeen ?? this.tafsirHintSeen,
  );

  @override
  bool operator ==(Object other) =>
      other is ReaderSettings &&
      other.theme == theme &&
      other.tafsirFontSize == tafsirFontSize &&
      other.tafsirLineHeight == tafsirLineHeight &&
      other.showTashkeel == showTashkeel &&
      other.hideIsnad == hideIsnad &&
      other.tafsirHintSeen == tafsirHintSeen;

  @override
  int get hashCode => Object.hash(
    theme,
    tafsirFontSize,
    tafsirLineHeight,
    showTashkeel,
    hideIsnad,
    tafsirHintSeen,
  );
}
