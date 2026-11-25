import 'package:sqlite3/sqlite3.dart';

import '../../../../core/domain/ayah_ref.dart';
import '../../domain/entities/tafsir_entry.dart';
import '../../domain/entities/tafsir_source.dart';

abstract final class TafsirRowMappers {
  static TafsirSource source(Row r) => TafsirSource(
    id: r['t_id'] as int,
    slug: r['slug'] as String,
    name: r['name_ar'] as String,
    shortName: r['short_name_ar'] as String,
    author: r['author_ar'] as String,
    diedHijri: r['died_hijri'] as int?,
    sortOrder: r['sort_order'] as int,
    isDefault: r['is_default'] == 1,
  );

  static TafsirEntry entry(Row r) => TafsirEntry(
    id: r['id'] as int,
    source: source(r),
    first: AyahRef(r['first_surah'] as int, r['first_ayah'] as int),
    last: AyahRef(r['last_surah'] as int, r['last_ayah'] as int),
    words: r['words'] as int,
    wordsWithoutIsnad: r['words_without_isnad'] as int,
  );
}
