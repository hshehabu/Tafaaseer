import 'package:flutter/services.dart';

import '../config/app_config.dart';
import '../logging/app_log.dart';

/// Registers the KFGQPC Hafs font if its file is bundled.
///
/// Loading at runtime (instead of declaring it in pubspec.yaml) keeps the build
/// working before the font file is added; the Quran text then uses
/// [QuranFontConfig.fallback]. Returns whether the font was loaded.
Future<bool> loadQuranFont({AssetBundle? bundle}) async {
  try {
    final data = (bundle ?? rootBundle).load(QuranFontConfig.assetPath);
    final loader = FontLoader(QuranFontConfig.family)..addFont(data);
    await loader.load();
    AppLog.info('font', '${QuranFontConfig.family} loaded');
    return true;
  } catch (e) {
    AppLog.error('font', '${QuranFontConfig.assetPath} not bundled; using the system Arabic font', e);
    return false;
  }
}
