import '../entities/tafsir_document.dart';
import '../entities/tafsir_entry.dart';
import '../entities/tafsir_source.dart';

abstract interface class TafsirRepository {
  Future<List<TafsirSource>> getSources();

  /// Every tafsir's entry for this ayah (by global ayah id), in pill order.
  /// Cheap: no text is decoded.
  Future<List<TafsirEntry>> getEntriesForAyah(int ayahId);

  /// The decoded text of one entry. Recently used documents are cached.
  Future<TafsirDocument> getDocument(int entryId);
}
