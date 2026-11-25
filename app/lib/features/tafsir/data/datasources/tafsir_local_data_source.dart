import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';

import '../../../../core/database/content_database.dart';

/// The only place that knows the SQL for tafsir tables.
class TafsirLocalDataSource {
  const TafsirLocalDataSource(this._db);

  final ContentDatabase _db;

  static const _sourceColumns = '''
    t.id AS t_id, t.slug, t.name_ar, t.short_name_ar, t.author_ar, t.died_hijri, t.sort_order, t.is_default''';

  ResultSet sources() => _db.select('SELECT $_sourceColumns FROM tafsirs t ORDER BY t.sort_order');

  /// One row per tafsir for the ayah. Uses the (ayah_id, tafsir_id) primary
  /// key: an index seek, about 0.1 ms with every join.
  ResultSet entriesForAyah(int ayahId) => _db.select('''
    SELECT e.id, e.words, e.words_without_isnad, $_sourceColumns,
           f.surah AS first_surah, f.ayah AS first_ayah, l.surah AS last_surah, l.ayah AS last_ayah
    FROM tafsir_ayahs ta
    JOIN tafsir_entries e ON e.id = ta.entry_id
    JOIN tafsirs t ON t.id = ta.tafsir_id
    JOIN ayahs f ON f.id = e.first_ayah_id
    JOIN ayahs l ON l.id = e.last_ayah_id
    WHERE ta.ayah_id = ?
    ORDER BY t.sort_order
  ''', [ayahId]);

  /// The compressed body of one entry, or null if the id is unknown.
  Uint8List? body(int entryId) =>
      _db.select('SELECT body FROM tafsir_entries WHERE id = ?', [entryId]).firstOrNull?['body'] as Uint8List?;
}
