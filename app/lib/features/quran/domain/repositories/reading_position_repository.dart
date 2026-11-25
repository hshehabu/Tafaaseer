import '../../../../core/domain/ayah_ref.dart';

/// Where the reader stopped, for "continue reading" (D5).
abstract interface class ReadingPositionRepository {
  AyahRef? load();

  Future<void> save(AyahRef ref);
}
