import 'package:sqlite3/sqlite3.dart';

import '../../../../core/domain/ayah_ref.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/hizb_start.dart';
import '../../domain/entities/mushaf_page.dart';
import '../../domain/entities/surah.dart';

/// Row -> entity mapping. Column names match ../../../../../pipeline (schema v2).
abstract final class QuranRowMappers {
  static Surah surah(Row r) => Surah(
    id: r['id'] as int,
    nameAr: r['name_ar'] as String,
    nameTranslit: r['name_translit'] as String,
    revelation: r['revelation'] == 'meccan' ? Revelation.meccan : Revelation.medinan,
    ayahCount: r['ayah_count'] as int,
    firstAyahId: r['first_ayah_id'] as int,
    startPage: r['start_page'] as int,
  );

  static Ayah ayah(Row r) => Ayah(
    id: r['id'] as int,
    surah: r['surah'] as int,
    number: r['ayah'] as int,
    text: r['text'] as String,
    juz: r['juz'] as int,
    hizb: r['hizb'] as int,
    page: r['page'] as int,
    sajda: r['sajda'] == 1,
  );

  static HizbStart hizbStart(Row r) => HizbStart(
    hizb: r['hizb'] as int,
    juz: r['juz'] as int,
    ref: AyahRef(r['surah'] as int, r['ayah'] as int),
    surahName: r['name_ar'] as String,
  );

  static MushafWord mushafWord(Row r) => MushafWord(
    id: r['id'] as int,
    ayahId: r['ayah_id'] as int,
    isAyahEnd: r['is_end'] == 1,
    text: r['text'] as String,
  );

  static MushafLineKind lineKind(String kind) => switch (kind) {
    'surah' => MushafLineKind.surahTitle,
    'basmala' => MushafLineKind.basmala,
    _ => MushafLineKind.ayah,
  };
}
