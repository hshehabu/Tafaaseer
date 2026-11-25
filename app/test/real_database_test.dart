// Runs against the real bundled database (assets/db/tafaseer.db, built by
// ../pipeline). Skipped when the file is absent, e.g. on a fresh checkout.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tafaseer/core/config/app_config.dart';
import 'package:tafaseer/core/database/content_database.dart';
import 'package:tafaseer/core/domain/ayah_ref.dart';
import 'package:tafaseer/features/quran/data/datasources/quran_local_data_source.dart';
import 'package:tafaseer/features/quran/data/repositories/quran_repository_impl.dart';
import 'package:tafaseer/features/quran/domain/entities/mushaf_page.dart';
import 'package:tafaseer/features/tafsir/data/datasources/tafsir_local_data_source.dart';
import 'package:tafaseer/features/tafsir/data/repositories/tafsir_repository_impl.dart';
import 'package:tafaseer/features/tafsir/domain/usecases/get_ayah_tafsirs.dart';

void main() {
  final file = File(ContentDbConfig.assetPath);
  final skip = file.existsSync() ? false : 'no ${ContentDbConfig.assetPath}; run the pipeline';

  late ContentDatabase db;
  setUpAll(() {
    if (file.existsSync()) db = ContentDatabase.open(file.path);
  });
  tearDownAll(() {
    if (file.existsSync()) db.close();
  });

  test('opens and validates', () {
    expect(db.schemaVersion, ContentDbConfig.schemaVersion);
    expect(db.meta()['schema_version'], '${ContentDbConfig.schemaVersion}');
  }, skip: skip);

  test('all 604 mushaf pages load, with every ayah on them in order', () {
    final quran = QuranRepositoryImpl(QuranLocalDataSource(db));
    final watch = Stopwatch()..start();
    var expectedAyah = 1;
    var titles = 0;
    for (var n = 1; n <= MushafConfig.pageCount; n++) {
      final page = quran.getPage(n);
      expect(page.lines.length, n <= 2 ? lessThan(MushafConfig.linesPerPage) : MushafConfig.linesPerPage);
      for (final line in page.lines) {
        if (line.kind == MushafLineKind.surahTitle) titles++;
        for (final word in line.words) {
          // Ayahs never skip; an ayah may continue from the previous line or page.
          expect(word.ayahId, anyOf(expectedAyah, expectedAyah + 1), reason: 'page $n');
          expectedAyah = word.ayahId;
        }
      }
    }
    expect(expectedAyah, 6236);
    expect(titles, 114);
    // ignore: avoid_print
    print('all pages loaded in ${watch.elapsedMilliseconds} ms (host machine)');
    expect(quran.locate(const AyahRef(2, 255))?.page, 42);
  }, skip: skip);

  test('every tafsir answers for sample ayahs, al-Muyassar first, all bodies decode', () async {
    final quran = QuranRepositoryImpl(QuranLocalDataSource(db));
    final tafsir = TafsirRepositoryImpl(TafsirLocalDataSource(db));
    final watch = Stopwatch();
    var slowestDecodeMs = 0;

    for (final ref in const [AyahRef(1, 1), AyahRef(2, 255), AyahRef(4, 43), AyahRef(17, 30), AyahRef(114, 6)]) {
      final ayah = (await quran.getAyah(ref))!;
      watch.reset();
      watch.start();
      final pills = await GetAyahTafsirs(tafsir)(ayah.id);
      final lookupUs = watch.elapsedMicroseconds;
      expect(pills.entries.length, 6, reason: '$ref');
      expect(pills.entries[pills.initialIndex].source.slug, 'muyassar');
      expect(lookupUs, lessThan(20000), reason: 'pill lookup for $ref took $lookupUs µs');

      for (final entry in pills.entries) {
        watch.reset();
        watch.start();
        final doc = await tafsir.getDocument(entry.id);
        final ms = watch.elapsedMilliseconds;
        if (ms > slowestDecodeMs) slowestDecodeMs = ms;
        expect(doc.isEmpty, isFalse, reason: '${entry.source.slug} $ref');
      }
    }
    // ignore: avoid_print
    print('slowest decode (host machine): $slowestDecodeMs ms');
  }, skip: skip);

  test('no ayah text contains a dotted circle (U+25CC)', () {
    final bad = db.select("SELECT count(*) AS n FROM ayahs WHERE text LIKE '%' || char(9676) || '%'").first['n'];
    expect(bad, 0);
  }, skip: skip);
}
