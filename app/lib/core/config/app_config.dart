/// Build-time constants. Change these, not literals scattered through the code.
abstract final class ContentDbConfig {
  /// Where the pipeline output is bundled (see ../pipeline/README.md).
  static const assetPath = 'assets/db/tafaseer.db';
  static const fileName = 'tafaseer.db';

  /// Bump whenever an app update ships a new tafaseer.db. The app then
  /// replaces its on-device copy on the next launch.
  static const bundleVersion = 4;

  /// The schema this code understands (PRAGMA user_version of the database).
  /// Version 2 added the mushaf page layout (mushaf_lines, mushaf_words).
  static const schemaVersion = 2;
}

abstract final class QuranFontConfig {
  /// Family name the Quran text is styled with.
  static const family = 'KFGQPCHafs';

  /// Downloaded by the pipeline (see assets/fonts/README.md). Loaded at runtime
  /// so a missing file shows a clear log line instead of breaking the build.
  static const assetPath = 'assets/fonts/UthmanicHafs.ttf';

  static const fallback = <String>['Amiri', 'serif'];

  /// QUL's "quran-common" font: the ornate surah header frame (ligature
  /// "header") and the calligraphic bismillah (U+FDFD). Optional, like the Hafs font.
  static const commonFamily = 'QuranCommon';
  static const commonAssetPath = 'assets/fonts/QuranCommon.ttf';

  /// QUL's surah-name font (v4): "surah001".."surah114" draw each name in calligraphy.
  static const surahNamesFamily = 'SurahNames';
  static const surahNamesAssetPath = 'assets/fonts/SurahNames.ttf';
}

/// Bundled OFL fonts, declared in pubspec.yaml.
abstract final class UiFonts {
  /// Interface text: titles, buttons, lists (design system).
  static const interface = 'Tajawal';

  /// Tafsir body text: a plain Naskh for long reading.
  static const reading = 'NotoNaskhArabic';

  /// Tafsir headings and surah titles on the mushaf page.
  static const classical = 'Amiri';
}

abstract final class ReadingConfig {
  /// Words per minute for the reading-time badge on each tafsir pill.
  static const wordsPerMinute = 150;
}

abstract final class MushafConfig {
  static const pageCount = 604;
  static const linesPerPage = 15;
}
