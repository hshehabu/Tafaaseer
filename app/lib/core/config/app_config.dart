/// Build-time constants. Change these, not literals scattered through the code.
abstract final class ContentDbConfig {
  /// Where the pipeline output is bundled (see ../pipeline/README.md).
  static const assetPath = 'assets/db/tafaseer.db';
  static const fileName = 'tafaseer.db';

  /// Bump whenever an app update ships a new tafaseer.db. The app then
  /// replaces its on-device copy on the next launch.
  static const bundleVersion = 1;

  /// The schema this code understands (PRAGMA user_version of the database).
  static const schemaVersion = 1;
}

abstract final class QuranFontConfig {
  /// Family name the Quran text is styled with.
  static const family = 'KFGQPCHafs';

  /// Optional asset. If the file is missing the app falls back to the system
  /// Arabic font, so the build never breaks over the font.
  static const assetPath = 'assets/fonts/UthmanicHafs.ttf';

  static const fallback = <String>['Noto Naskh Arabic', 'serif'];
}

abstract final class ReadingConfig {
  /// Words per minute for the reading-time badge on each tafsir pill.
  static const wordsPerMinute = 150;
}
