import '../../../../core/arabic/arabic_text.dart';
import '../../../../core/domain/ayah_ref.dart';
import '../../../../core/error/app_exception.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/hizb_start.dart';
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

  @override
  Future<List<Surah>> getSurahs() async =>
      _surahs ??= List.unmodifiable(_source.surahs().map(QuranRowMappers.surah));

  @override
  Future<List<Ayah>> getAyahs(int surahId) async {
    final ayahs = _source.ayahsOfSurah(surahId).map(QuranRowMappers.ayah).toList(growable: false);
    if (ayahs.isEmpty) throw ContentNotFoundException('surah $surahId');
    return ayahs;
  }

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
}
