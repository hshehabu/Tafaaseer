import 'package:sqlite3/sqlite3.dart';

import '../../../../core/database/content_database.dart';

/// The only place that knows the SQL for Quran tables. Returns raw rows;
/// mapping to entities happens in the models.
class QuranLocalDataSource {
  const QuranLocalDataSource(this._db);

  final ContentDatabase _db;

  static const _ayahColumns = 'id, surah, ayah, text, juz, hizb, page, sajda';

  ResultSet surahs() => _db.select('''
    SELECT s.id, s.name_ar, s.name_translit, s.revelation, s.ayah_count, s.first_ayah_id, a.page AS start_page
    FROM surahs s JOIN ayahs a ON a.id = s.first_ayah_id
    ORDER BY s.id
  ''');

  Row? ayah(int surah, int ayah) =>
      _db.select('SELECT $_ayahColumns FROM ayahs WHERE surah = ? AND ayah = ?', [surah, ayah]).firstOrNull;

  Row? ayahById(int id) => _db.select('SELECT $_ayahColumns FROM ayahs WHERE id = ?', [id]).firstOrNull;

  /// First ayah of every hizb (60 rows).
  ResultSet hizbStarts() => _db.select('''
    SELECT a.hizb, a.juz, a.surah, a.ayah, s.name_ar
    FROM ayahs a JOIN surahs s ON s.id = a.surah
    WHERE a.id IN (SELECT min(id) FROM ayahs GROUP BY hizb)
    ORDER BY a.hizb
  ''');

  /// The lines of one mushaf page, top to bottom.
  ResultSet mushafLines(int page) => _db.select(
    'SELECT line, kind, surah, first_word, last_word FROM mushaf_lines WHERE page = ? ORDER BY line',
    [page],
  );

  /// Words by id range (one page's words are consecutive).
  ResultSet mushafWords(int firstId, int lastId) => _db.select(
    'SELECT id, ayah_id, is_end, text FROM mushaf_words WHERE id BETWEEN ? AND ? ORDER BY id',
    [firstId, lastId],
  );
}
