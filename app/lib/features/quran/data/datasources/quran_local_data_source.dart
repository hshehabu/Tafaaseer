import 'package:sqlite3/sqlite3.dart';

import '../../../../core/database/content_database.dart';

/// The only place that knows the SQL for Quran tables. Returns raw rows;
/// mapping to entities happens in the models.
class QuranLocalDataSource {
  const QuranLocalDataSource(this._db);

  final ContentDatabase _db;

  static const _ayahColumns = 'id, surah, ayah, text, juz, hizb, page, sajda';

  ResultSet surahs() => _db.select(
    'SELECT id, name_ar, name_translit, revelation, ayah_count, first_ayah_id FROM surahs ORDER BY id',
  );

  ResultSet ayahsOfSurah(int surahId) =>
      _db.select('SELECT $_ayahColumns FROM ayahs WHERE surah = ? ORDER BY ayah', [surahId]);

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
}
