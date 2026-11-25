import '../../../../core/domain/ayah_ref.dart';
import '../entities/surah.dart';

/// Validates a typed reference ("2:255") against the real surah lengths (D4).
class ResolveAyahRef {
  const ResolveAyahRef();

  /// Returns the reference if it exists, otherwise null.
  AyahRef? call(String input, List<Surah> surahs) {
    final ref = AyahRef.tryParse(input);
    if (ref == null || ref.surah < 1 || ref.surah > surahs.length) return null;
    final surah = surahs[ref.surah - 1];
    if (ref.ayah < 1 || ref.ayah > surah.ayahCount) return null;
    return ref;
  }
}
