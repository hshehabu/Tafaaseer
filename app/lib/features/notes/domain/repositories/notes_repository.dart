import '../../../../core/domain/ayah_ref.dart';

/// The reader's own notes, one per ayah, kept on the device.
abstract interface class NotesRepository {
  /// Every note, keyed by ayah.
  Map<AyahRef, String> load();

  Future<void> save(Map<AyahRef, String> notes);
}
