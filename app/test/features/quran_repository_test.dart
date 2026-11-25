import 'package:flutter_test/flutter_test.dart';
import 'package:tafaseer/core/database/content_database.dart';
import 'package:tafaseer/core/domain/ayah_ref.dart';
import 'package:tafaseer/features/quran/data/datasources/quran_local_data_source.dart';
import 'package:tafaseer/features/quran/data/repositories/quran_repository_impl.dart';
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

  test('ayahs of a surah, by reference and by global id', () async {
    final ayahs = await repo.getAyahs(2);
    expect(ayahs.map((a) => a.number), List.generate(9, (i) => i + 1));
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
}
