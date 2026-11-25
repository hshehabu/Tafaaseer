import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/domain/ayah_ref.dart';
import 'tafsir_source.dart';

/// One tafsir's commentary for an ayah (or for a range of ayahs it shares).
/// The text itself is loaded separately, see TafsirDocument.
@immutable
class TafsirEntry {
  const TafsirEntry({
    required this.id,
    required this.source,
    required this.first,
    required this.last,
    required this.words,
    required this.wordsWithoutIsnad,
  });

  final int id;
  final TafsirSource source;

  /// The commentary covers first..last (the same ayah when not shared).
  final AyahRef first;
  final AyahRef last;
  final int words;
  final int wordsWithoutIsnad;

  bool get coversRange => first != last;

  /// For the length badge on the pill (E6). At least one minute.
  int readingMinutes({required bool hideIsnad}) {
    final count = hideIsnad ? wordsWithoutIsnad : words;
    return (count / ReadingConfig.wordsPerMinute).ceil().clamp(1, 999);
  }

  @override
  bool operator ==(Object other) => other is TafsirEntry && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
