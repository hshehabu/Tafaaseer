import 'package:flutter_test/flutter_test.dart';
import 'package:tafaseer/core/database/content_database.dart';
import 'package:tafaseer/core/domain/ayah_ref.dart';
import 'package:tafaseer/features/quran/data/datasources/quran_local_data_source.dart';
import 'package:tafaseer/features/quran/data/repositories/quran_repository_impl.dart';
import 'package:tafaseer/features/quran/domain/entities/mushaf_page.dart';
import 'package:tafaseer/features/quran/domain/entities/surah.dart';
import 'package:tafaseer/features/quran/domain/usecases/resolve_ayah_ref.dart';

import '../helpers/content_db_fixture.dart';

void main() {
  late ContentDatabase db;
  late QuranRepositoryImpl repo;

  setUp(() {
    db = openFixtureDatabase();
    repo = QuranRepositoryImpl(QuranLocalDataSource(db));
  });

  tearDown(() => db.close());

  test('surahs in order with their facts', () async {
    final surahs = await repo.getSurahs();
    expect(surahs.map((s) => s.ayahCount), [7, 9, 6220]);
    expect(surahs[1].revelation, Revelation.medinan);
    expect(surahs[1].firstAyahId, 8);
    expect(surahs[0].showsBismillahHeader, isFalse);
  });

  test('ayahs by reference and by global id', () async {
    expect((await repo.getAyah(const AyahRef(2, 3)))!.id, 10);
    expect((await repo.getAyahById(10))!.ref, const AyahRef(2, 3));
    expect(await repo.getAyah(const AyahRef(2, 99)), isNull);
  });

  test('bismillah comes from 1:1 without its ayah number', () async {
    expect(await repo.getBismillah(), 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ');
  });

  test('hizb starts', () async {
    final hizbs = await repo.getHizbStarts();
    expect(hizbs.map((h) => (h.hizb, h.ref)), [(1, const AyahRef(1, 1)), (2, const AyahRef(3, 1))]);
  });

  test('ResolveAyahRef checks real surah lengths', () async {
    final surahs = await repo.getSurahs();
    const resolve = ResolveAyahRef();
    expect(resolve('2:9', surahs), const AyahRef(2, 9));
    expect(resolve('2:10', surahs), isNull);
    expect(resolve('4:1', surahs), isNull);
  });

  group('mushaf pages', () {
    test('a page has its lines in order, with title and bismillah lines', () {
      final page = repo.getPage(2);
      expect(page.lines.map((l) => l.kind).take(3), [
        MushafLineKind.surahTitle,
        MushafLineKind.basmala,
        MushafLineKind.ayah,
      ]);
      expect(page.lines.first.surah, 2);
      expect(page.lines.length, 11);
      expect(page.lines[2].words.map((w) => (w.ayahId, w.isAyahEnd)), [(8, false), (8, true)]);
      expect(page.firstAyah, const AyahRef(2, 1));
      expect((page.surah, page.juz, page.hizb), (2, 1, 1));
      expect(page.isOpening, isTrue);
      expect(page.contains(16), isTrue);
      expect(page.contains(17), isFalse);
    });

    test('pages are cached, and out-of-range pages fail clearly', () {
      expect(identical(repo.getPage(3), repo.getPage(3)), isTrue);
      expect(() => repo.getPage(0), throwsA(anything));
      expect(() => repo.getPage(605), throwsA(anything));
    });

    test('locate finds the page an ayah starts on', () {
      expect(repo.locate(const AyahRef(2, 5)), (ayahId: 12, page: 2));
      expect(repo.locate(const AyahRef(3, 1)), (ayahId: 17, page: 3));
      expect(repo.locate(const AyahRef(2, 99)), isNull);
    });
  });
}
