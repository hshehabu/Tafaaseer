import '../entities/reader_settings.dart';

abstract interface class SettingsRepository {
  /// Synchronous: preferences are cached in memory, so the first frame already
  /// has the right theme and font sizes.
  ReaderSettings load();

  Future<void> save(ReaderSettings settings);
}
