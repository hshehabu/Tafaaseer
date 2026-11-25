import '../../../../core/arabic/arabic_text.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/domain/ayah_ref.dart';
import '../../../../core/error/app_exception.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/hizb_start.dart';
import '../../domain/entities/mushaf_page.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/quran_repository.dart';
import '../datasources/quran_local_data_source.dart';
import '../models/quran_row_mappers.dart';

class QuranRepositoryImpl implements QuranRepository {
  QuranRepositoryImpl(this._source);

  final QuranLocalDataSource _source;

  // Small, immutable, read constantly: kept for the app's lifetime.
  List<Surah>? _surahs;
  List<HizbStart>? _hizbStarts;
  String? _bismillah;

  /// The pages around the one on screen, so swiping back and forth costs nothing.
  final _pages = <int, MushafPage>{}; // insertion-ordered: oldest first
  static const _pageCacheSize = 8;

  @override
  Future<List<Surah>> getSurahs() async =>
      _surahs ??= List.unmodifiable(_source.surahs().map(QuranRowMappers.surah));

  @override
  Future<Ayah?> getAyah(AyahRef ref) async {
    final row = _source.ayah(ref.surah, ref.ayah);
    return row == null ? null : QuranRowMappers.ayah(row);
  }

  @override
  Future<Ayah?> getAyahById(int id) async {
    final row = _source.ayahById(id);
    return row == null ? null : QuranRowMappers.ayah(row);
  }

  @override
  Future<List<HizbStart>> getHizbStarts() async =>
      _hizbStarts ??= List.unmodifiable(_source.hizbStarts().map(QuranRowMappers.hizbStart));

  @override
  Future<String> getBismillah() async {
    if (_bismillah != null) return _bismillah!;
    final first = _source.ayah(1, 1);
    if (first == null) throw const ContentNotFoundException('ayah 1:1');
    return _bismillah = withoutAyahNumber(first['text'] as String);
  }

  @override
  ({int ayahId, int page})? locate(AyahRef ref) {
    final row = _source.ayah(ref.surah, ref.ayah);
    return row == null ? null : (ayahId: row['id'] as int, page: row['page'] as int);
  }

  @override
  MushafPage getPage(int number) {
    final cached = _pages.remove(number);
    if (cached != null) return _pages[number] = cached; // move to most recent
    final page = _loadPage(number);
    _pages[number] = page;
    if (_pages.length > _pageCacheSize) _pages.remove(_pages.keys.first);
    return page;
  }

  MushafPage _loadPage(int number) {
    if (number < 1 || number > MushafConfig.pageCount) throw ContentNotFoundException('page $number');
    final lineRows = _source.mushafLines(number);
    final ayahLines = lineRows.where((r) => r['kind'] == 'ayah');
    if (ayahLines.isEmpty) throw ContentNotFoundException('page $number');

    final words = _source
        .mushafWords(ayahLines.first['first_word'] as int, ayahLines.last['last_word'] as int)
        .map(QuranRowMappers.mushafWord)
        .toList(growable: false);
    final firstWordId = words.first.id;

    final lines = [
      for (final r in lineRows)
        MushafLine(
          number: r['line'] as int,
          kind: QuranRowMappers.lineKind(r['kind'] as String),
          surah: r['surah'] as int,
          words: r['kind'] == 'ayah'
              ? List.unmodifiable(
                  words.sublist((r['first_word'] as int) - firstWordId, (r['last_word'] as int) - firstWordId + 1),
                )
              : const [],
        ),
    ];

    final first = _source.ayahById(words.first.ayahId);
    if (first == null) throw ContentNotFoundException('ayah ${words.first.ayahId}');
    return MushafPage(
      number: number,
      lines: List.unmodifiable(lines),
      firstAyahId: words.first.ayahId,
      firstAyah: AyahRef(first['surah'] as int, first['ayah'] as int),
      juz: first['juz'] as int,
      hizb: first['hizb'] as int,
    );
  }
}
