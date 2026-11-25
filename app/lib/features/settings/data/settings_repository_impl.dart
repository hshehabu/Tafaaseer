import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/reader_settings.dart';
import '../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static const _theme = 'settings.theme';
  static const _tafsirFont = 'settings.tafsir_font_size';
  static const _lineHeight = 'settings.tafsir_line_height';
  static const _tashkeel = 'settings.show_tashkeel';
  static const _hideIsnad = 'settings.hide_isnad';
  static const _hintSeen = 'settings.tafsir_hint_seen';

  @override
  ReaderSettings load() {
    const defaults = ReaderSettings();
    final themeName = _prefs.getString(_theme);
    return ReaderSettings(
      theme: ThemePreference.values.firstWhere((t) => t.name == themeName, orElse: () => defaults.theme),
      tafsirFontSize: _prefs.getDouble(_tafsirFont) ?? defaults.tafsirFontSize,
      tafsirLineHeight: _prefs.getDouble(_lineHeight) ?? defaults.tafsirLineHeight,
      showTashkeel: _prefs.getBool(_tashkeel) ?? defaults.showTashkeel,
      hideIsnad: _prefs.getBool(_hideIsnad) ?? defaults.hideIsnad,
      tafsirHintSeen: _prefs.getBool(_hintSeen) ?? defaults.tafsirHintSeen,
    );
  }

  @override
  Future<void> save(ReaderSettings s) async {
    await Future.wait([
      _prefs.setString(_theme, s.theme.name),
      _prefs.setDouble(_tafsirFont, s.tafsirFontSize),
      _prefs.setDouble(_lineHeight, s.tafsirLineHeight),
      _prefs.setBool(_tashkeel, s.showTashkeel),
      _prefs.setBool(_hideIsnad, s.hideIsnad),
      _prefs.setBool(_hintSeen, s.tafsirHintSeen),
    ]);
  }
}
