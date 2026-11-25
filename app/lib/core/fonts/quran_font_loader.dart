import 'package:flutter/services.dart';

import '../config/app_config.dart';
import '../logging/app_log.dart';

/// Which of the optional mushaf fonts loaded. The page falls back to plain
/// text for anything that is missing.
abstract final class QuranFonts {
  static bool hafs = false;

  /// The ornate surah header frame, the calligraphic bismillah and surah names.
  static bool decorations = false;
}

/// Registers the mushaf fonts if their files are bundled.
///
/// Loading at runtime (instead of declaring them in pubspec.yaml) keeps the
/// build working before the files are added (`py -m tafaseer_pipeline font`).
Future<void> loadQuranFonts({AssetBundle? bundle}) async {
  final assets = bundle ?? rootBundle;
  final results = await Future.wait([
    _load(assets, QuranFontConfig.family, QuranFontConfig.assetPath),
    _load(assets, QuranFontConfig.commonFamily, QuranFontConfig.commonAssetPath),
    _load(assets, QuranFontConfig.surahNamesFamily, QuranFontConfig.surahNamesAssetPath),
  ]);
  QuranFonts.hafs = results[0];
  QuranFonts.decorations = results[1] && results[2];
}

Future<bool> _load(AssetBundle assets, String family, String path) async {
  try {
    final loader = FontLoader(family)..addFont(assets.load(path));
    await loader.load();
    AppLog.info('font', '$family loaded');
    return true;
  } catch (e) {
    AppLog.error('font', '$path not bundled; run `py -m tafaseer_pipeline font`', e);
    return false;
  }
}
