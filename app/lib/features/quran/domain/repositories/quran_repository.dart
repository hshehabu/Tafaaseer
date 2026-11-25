import '../../../../core/domain/ayah_ref.dart';
import '../entities/ayah.dart';
import '../entities/hizb_start.dart';
import '../entities/mushaf_page.dart';
import '../entities/surah.dart';

abstract interface class QuranRepository {
  /// All 114 surahs in mushaf order.
  Future<List<Surah>> getSurahs();

  /// Null when [ref] does not exist (e.g. 2:300).
  Future<Ayah?> getAyah(AyahRef ref);

  /// By global id (1..6236); used to step to the next or previous ayah.
  Future<Ayah?> getAyahById(int id);

  /// The 60 hizb starts, for the juz/hizb index.
  Future<List<HizbStart>> getHizbStarts();

  /// The bismillah, taken from ayah 1:1 so it matches the mushaf text exactly.
  Future<String> getBismillah();

  /// One mushaf page (1..604). Synchronous on purpose: it is two indexed
  /// queries (~0.2 ms), and a page swipe must never show an empty frame
  /// while a Future resolves.
  MushafPage getPage(int number);

  /// Where [ref] is in the mushaf: its id and the page it starts on.
  /// Null when [ref] does not exist. Synchronous, so the reader can open on
  /// the right page in its first frame.
  ({int ayahId, int page})? locate(AyahRef ref);
}
