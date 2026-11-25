import 'package:flutter_test/flutter_test.dart';
import 'package:tafaseer/core/database/content_database.dart';
import 'package:tafaseer/core/domain/ayah_ref.dart';
import 'package:tafaseer/features/tafsir/data/codec/tafsir_body_codec.dart';
import 'package:tafaseer/features/tafsir/data/datasources/tafsir_local_data_source.dart';
import 'package:tafaseer/features/tafsir/data/repositories/tafsir_repository_impl.dart';
import 'package:tafaseer/features/tafsir/domain/entities/tafsir_document.dart';
import 'package:tafaseer/features/tafsir/domain/usecases/build_share_text.dart';
import 'package:tafaseer/features/tafsir/domain/usecases/get_ayah_tafsirs.dart';

import '../helpers/content_db_fixture.dart';

void main() {
  late ContentDatabase db;
  late TafsirRepositoryImpl repo;

  setUp(() {
    db = openFixtureDatabase();
    repo = TafsirRepositoryImpl(TafsirLocalDataSource(db), cacheSize: 2);
  });

  tearDown(() => db.close());

  group('repository', () {
    test('entries for an ayah come in pill order with their range', () async {
      final entries = await repo.getEntriesForAyah(10); // 2:3
      expect(entries.map((e) => e.source.slug), ['muyassar', 'tabari']);
      expect(entries[0].coversRange, isFalse);
      expect(entries[1].first, const AyahRef(2, 1));
      expect(entries[1].last, const AyahRef(2, 5));
      expect(entries[1].readingMinutes(hideIsnad: false), 6); // 900 words / 150
      expect(entries[1].readingMinutes(hideIsnad: true), 4);
    });

    test('an ayah without tafsir has no entries', () async {
      expect(await repo.getEntriesForAyah(1), isEmpty);
    });

    test('documents decode into typed paragraphs and spans', () async {
      final doc = await repo.getDocument(2001);
      expect(doc.paragraphs.map((p) => p.kind), [ParagraphKind.heading, ParagraphKind.paragraph]);
      expect(doc.paragraphs[1].spans.map((s) => s.kind), [SpanKind.isnad, SpanKind.text, SpanKind.note]);
    });

    test('documents are cached (same instance until evicted)', () async {
      final a = await repo.getDocument(2001);
      expect(identical(await repo.getDocument(2001), a), isTrue);
      await repo.getDocument(1008);
      await repo.getDocument(1009); // cache size 2: 2001 is evicted
      expect(identical(await repo.getDocument(2001), a), isFalse);
    });
  });

  test('GetAyahTafsirs opens on the default tafsir (al-Muyassar)', () async {
    final result = await GetAyahTafsirs(repo)(10);
    expect(result.entries[result.initialIndex].source.slug, 'muyassar');
  });

  test('codec rejects a damaged body', () {
    expect(() => TafsirBodyCodec.decode(encodeBody([])..[0] = 0), throwsA(anything));
  });

  group('plain text and share text', () {
    test('quotes get their brackets back, notes are dropped, isnad is optional', () async {
      final doc = await repo.getDocument(2001);
      expect(doc.toPlainText(includeIsnad: false), 'القول في تأويل قوله: ﴿الم﴾\n\nعن قتادة قال: كذا.');
      expect(doc.toPlainText(includeIsnad: true), contains('حدثنا بشر'));
    });

    test('share text has the ayah, its reference and the tafsir range', () async {
      final entry = (await repo.getEntriesForAyah(10))[1];
      final text = const BuildShareText()(
        ayahText: 'آية ٣',
        surahName: 'البقرة',
        ayahNumber: 3,
        entry: entry,
        document: await repo.getDocument(entry.id),
        includeIsnad: false,
      );
      expect(text, startsWith('﴿آية﴾ [البقرة: ٣]\n\nجامع البيان (البقرة ١–٥):\n'));
    });
  });
}
