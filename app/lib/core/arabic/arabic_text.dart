/// Arabic display helpers. Pure functions, no Flutter imports.
library;

// Harakat, Quranic annotation marks and superscript alef (not tatweel, not letters).
final _tashkeel = RegExp('[ؐ-ًؚ-ٰٟۖ-ۜ۟-۪ۨ-ۭ]');

/// Removes diacritics, for the "hide tashkeel" setting. Never applied to Quran text.
String stripTashkeel(String text) => text.replaceAll(_tashkeel, '');

const _arabicDigits = '٠١٢٣٤٥٦٧٨٩';

/// 255 -> "٢٥٥".
String toArabicDigits(int number) =>
    number.toString().split('').map((c) => _arabicDigits[c.codeUnitAt(0) - 48]).join();

/// 1.9 -> "١٫٩", with the Arabic decimal separator.
String toArabicDecimal(double value, int fractionDigits) => value
    .toStringAsFixed(fractionDigits)
    .split('')
    .map((c) => c == '.' ? '٫' : _arabicDigits[c.codeUnitAt(0) - 48])
    .join();

/// The KFGQPC text ends each ayah with its number ("... ٱلرَّحِيمِ ١"). Removes it.
String withoutAyahNumber(String ayahText) => ayahText.replaceFirst(RegExp(r'\s*[٠-٩]+\s*$'), '');

/// Folds Arabic for forgiving search: no diacritics, one alef, ة = ه, ى = ي,
/// Arabic-Indic digits as Western ones. "الأنعام" and "الانعام" match.
String foldForSearch(String text) {
  final buffer = StringBuffer();
  for (final rune in stripTashkeel(text).runes) {
    final c = String.fromCharCode(rune);
    final digit = _arabicDigits.indexOf(c);
    buffer.write(switch (c) {
      'أ' || 'إ' || 'آ' || 'ٱ' => 'ا',
      'ة' => 'ه',
      'ى' => 'ي',
      _ when digit >= 0 => '$digit',
      _ => c,
    });
  }
  return buffer.toString().trim();
}
