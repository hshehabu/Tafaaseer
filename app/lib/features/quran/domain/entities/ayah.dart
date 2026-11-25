import 'package:flutter/foundation.dart';

import '../../../../core/domain/ayah_ref.dart';

@immutable
class Ayah {
  const Ayah({
    required this.id,
    required this.surah,
    required this.number,
    required this.text,
    required this.juz,
    required this.hizb,
    required this.page,
    required this.sajda,
  });

  /// Global id, 1..6236 in mushaf order. Neighbouring ayahs differ by one.
  final int id;
  final int surah;
  final int number;

  /// KFGQPC Hafs text, shown exactly as stored. Ends with the ayah number,
  /// which the KFGQPC font draws as the end-of-ayah ornament.
  final String text;

  final int juz;
  final int hizb;
  final int page;
  final bool sajda;

  AyahRef get ref => AyahRef(surah, number);

  @override
  bool operator ==(Object other) => other is Ayah && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
