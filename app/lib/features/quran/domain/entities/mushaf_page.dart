import 'package:flutter/foundation.dart';

import '../../../../core/domain/ayah_ref.dart';

enum MushafLineKind { ayah, surahTitle, basmala }

/// One word on a mushaf page, or the end-of-ayah number after the last word.
@immutable
class MushafWord {
  const MushafWord({required this.id, required this.ayahId, required this.isAyahEnd, required this.text});

  final int id;
  final int ayahId;

  /// The ayah number, which the KFGQPC Hafs font draws as the end-of-ayah mark.
  final bool isAyahEnd;

  /// KFGQPC Hafs text, shown exactly as stored.
  final String text;
}

@immutable
class MushafLine {
  const MushafLine({required this.number, required this.kind, required this.surah, required this.words});

  /// 1..15
  final int number;
  final MushafLineKind kind;

  /// The surah a title or bismillah line belongs to; 0 on ayah lines.
  final int surah;

  /// Empty on title and bismillah lines.
  final List<MushafWord> words;
}

/// One page of the 604-page Madani mushaf, laid out line by line as printed.
@immutable
class MushafPage {
  const MushafPage({
    required this.number,
    required this.lines,
    required this.firstAyahId,
    required this.firstAyah,
    required this.juz,
    required this.hizb,
  });

  final int number;
  final List<MushafLine> lines;

  /// The first ayah that starts or continues on this page.
  final int firstAyahId;

  /// [firstAyahId] as surah:ayah. Saved as the reading position.
  final AyahRef firstAyah;

  /// Juz and hizb of [firstAyah], for the page header.
  final int juz;
  final int hizb;

  int get surah => firstAyah.surah;

  /// Pages 1 and 2 have fewer lines, centred, as in the printed mushaf.
  bool get isOpening => number <= 2;

  Iterable<MushafWord> get words => lines.expand((l) => l.words);

  bool contains(int ayahId) => words.any((w) => w.ayahId == ayahId);
}
