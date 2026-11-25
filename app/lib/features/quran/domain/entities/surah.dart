import 'package:flutter/foundation.dart';

enum Revelation { meccan, medinan }

@immutable
class Surah {
  const Surah({
    required this.id,
    required this.nameAr,
    required this.nameTranslit,
    required this.revelation,
    required this.ayahCount,
    required this.firstAyahId,
  });

  final int id;
  final String nameAr;
  final String nameTranslit;
  final Revelation revelation;
  final int ayahCount;

  /// Global id (1..6236) of this surah's first ayah.
  final int firstAyahId;

  /// Al-Fatihah's bismillah is its first ayah, and at-Tawbah has none.
  bool get showsBismillahHeader => id != 1 && id != 9;

  @override
  bool operator ==(Object other) => other is Surah && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
