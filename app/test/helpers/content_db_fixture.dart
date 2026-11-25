import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';
import 'package:tafaseer/core/database/content_database.dart';

/// Same tables as ../../../pipeline/tafaseer_pipeline/build.py (schema v1).
const contentSchemaSql = '''
CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
CREATE TABLE surahs (id INTEGER PRIMARY KEY, name_ar TEXT NOT NULL, name_translit TEXT NOT NULL,
  revelation TEXT NOT NULL, ayah_count INTEGER NOT NULL, first_ayah_id INTEGER NOT NULL);
CREATE TABLE ayahs (id INTEGER PRIMARY KEY, surah INTEGER NOT NULL, ayah INTEGER NOT NULL, text TEXT NOT NULL,
  text_simple TEXT NOT NULL, juz INTEGER NOT NULL, hizb INTEGER NOT NULL, rub INTEGER NOT NULL,
  page INTEGER NOT NULL, sajda INTEGER NOT NULL DEFAULT 0, UNIQUE (surah, ayah));
CREATE TABLE tafsirs (id INTEGER PRIMARY KEY, slug TEXT NOT NULL UNIQUE, name_ar TEXT NOT NULL,
  short_name_ar TEXT NOT NULL, author_ar TEXT NOT NULL, died_hijri INTEGER, sort_order INTEGER NOT NULL,
  is_default INTEGER NOT NULL DEFAULT 0, source TEXT NOT NULL, entry_count INTEGER NOT NULL);
CREATE TABLE tafsir_entries (id INTEGER PRIMARY KEY, tafsir_id INTEGER NOT NULL, first_ayah_id INTEGER NOT NULL,
  last_ayah_id INTEGER NOT NULL, words INTEGER NOT NULL, words_without_isnad INTEGER NOT NULL, body BLOB NOT NULL);
CREATE TABLE tafsir_ayahs (ayah_id INTEGER NOT NULL, tafsir_id INTEGER NOT NULL, entry_id INTEGER NOT NULL,
  PRIMARY KEY (ayah_id, tafsir_id)) WITHOUT ROWID;
''';

/// zlib(JSON), exactly like the pipeline writes tafsir_entries.body.
Uint8List encodeBody(List<Map<String, Object?>> paragraphs) =>
    Uint8List.fromList(zlib.encode(utf8.encode(jsonEncode({'v': 1, 'p': paragraphs}))));

/// A small but complete content database:
/// - surah 1 (7 ayahs), surah 2 (9 ayahs), surah 3 (6220 ayahs): 6236 in total, so it passes validation;
/// - two tafsirs: "muyassar" (default, one entry per ayah of surah 2) and
///   "tabari" (shared entries: 2:1–5 and 2:6–9).
void populateFixture(Database db) {
  db.execute(contentSchemaSql);
  db.execute('PRAGMA user_version = 1');
  db.execute("INSERT INTO meta VALUES ('built_at', '2026-11-24T00:00:00Z')");

  const counts = [7, 9, 6220];
  var id = 0;
  final insertSurah = db.prepare('INSERT INTO surahs VALUES (?,?,?,?,?,?)');
  final insertAyah = db.prepare('INSERT INTO ayahs VALUES (?,?,?,?,?,?,?,?,?,?)');
  db.execute('BEGIN');
  for (var s = 1; s <= counts.length; s++) {
    insertSurah.execute([s, 'سورة$s', 'Surah $s', s == 2 ? 'medinan' : 'meccan', counts[s - 1], id + 1]);
    for (var a = 1; a <= counts[s - 1]; a++) {
      id++;
      final text = s == 1 && a == 1 ? 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١' : 'آية $s:$a ${a.toString()}';
      final hizb = id <= 16 ? 1 : 2;
      insertAyah.execute([id, s, a, text, text, 1, hizb, hizb, 1, 0]);
    }
  }
  insertSurah.close();
  insertAyah.close();

  db.execute('''INSERT INTO tafsirs VALUES
    (1, 'muyassar', 'التفسير الميسر', 'الميسر', 'نخبة من العلماء', NULL, 1, 1, 'test', 9),
    (2, 'tabari', 'جامع البيان', 'الطبري', 'الطبري', 310, 2, 0, 'test', 2)''');
  final insertEntry = db.prepare('INSERT INTO tafsir_entries VALUES (?,?,?,?,?,?,?)');
  final insertMap = db.prepare('INSERT INTO tafsir_ayahs VALUES (?,?,?)');
  // Surah 2 is ayah ids 8..16.
  for (var ayahId = 8; ayahId <= 16; ayahId++) {
    final entryId = 1000 + ayahId;
    insertEntry.execute([entryId, 1, ayahId, ayahId, 40, 40, encodeBody([
      {'k': 'p', 's': [[0, 'تفسير ميسر للآية $ayahId']]},
    ])]);
    insertMap.execute([ayahId, 1, entryId]);
  }
  for (final (entryId, first, last) in [(2001, 8, 12), (2002, 13, 16)]) {
    insertEntry.execute([entryId, 2, first, last, 900, 600, encodeBody([
      {'k': 'h', 's': [[0, 'القول في تأويل قوله: '], [1, 'الم']]},
      {'k': 'p', 's': [[2, 'حدثنا بشر، قال: ثنا يزيد، '], [0, 'عن قتادة قال: كذا.'], [3, 'في المطبوعة: كذا.']]},
    ])]);
    for (var ayahId = first; ayahId <= last; ayahId++) {
      insertMap.execute([ayahId, 2, entryId]);
    }
  }
  insertEntry.close();
  insertMap.close();
  db.execute('COMMIT');
}

ContentDatabase openFixtureDatabase() {
  final db = sqlite3.openInMemory();
  populateFixture(db);
  return ContentDatabase(db);
}
