import 'package:flutter/foundation.dart';

/// One of the six tafsir books.
@immutable
class TafsirSource {
  const TafsirSource({
    required this.id,
    required this.slug,
    required this.name,
    required this.shortName,
    required this.author,
    required this.diedHijri,
    required this.sortOrder,
    required this.isDefault,
  });

  final int id;
  final String slug;
  final String name;

  /// Label on the pill, e.g. "ابن كثير".
  final String shortName;
  final String author;
  final int? diedHijri;

  /// Pill order: al-Muyassar first, then shortest to longest.
  final int sortOrder;

  /// Selected when the sheet opens (al-Muyassar, decision E4).
  final bool isDefault;

  @override
  bool operator ==(Object other) => other is TafsirSource && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
