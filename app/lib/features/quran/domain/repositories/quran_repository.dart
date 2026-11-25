import '../../../../core/domain/ayah_ref.dart';
import '../entities/ayah.dart';
import '../entities/hizb_start.dart';
import '../entities/surah.dart';

abstract interface class QuranRepository {
  /// All 114 surahs in mushaf order.
  Future<List<Surah>> getSurahs();

  Future<List<Ayah>> getAyahs(int surahId);

  /// Null when [ref] does not exist (e.g. 2:300).
  Future<Ayah?> getAyah(AyahRef ref);

  /// By global id (1..6236); used to step to the next or previous ayah.
  Future<Ayah?> getAyahById(int id);

  /// The 60 hizb starts, for the juz/hizb index.
  Future<List<HizbStart>> getHizbStarts();

  /// The bismillah header, taken from ayah 1:1 so it matches the mushaf text exactly.
  Future<String> getBismillah();
}
