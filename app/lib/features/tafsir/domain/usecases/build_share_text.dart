import '../../../../core/arabic/arabic_text.dart';
import '../entities/tafsir_document.dart';
import '../entities/tafsir_entry.dart';

/// The text that "copy" and "share" in the sheet header produce (E8):
///
///     ﴿ayah text﴾ [البقرة: ٢٥٥]
///
///     تفسير ابن كثير (البقرة ٢٥٥–٢٥٧):
///     ...
class BuildShareText {
  const BuildShareText();

  String call({
    required String ayahText,
    required String surahName,
    required int ayahNumber,
    required TafsirEntry entry,
    required TafsirDocument document,
    required bool includeIsnad,
  }) {
    final reference = '[$surahName: ${toArabicDigits(ayahNumber)}]';
    final range = entry.coversRange
        ? ' ($surahName ${toArabicDigits(entry.first.ayah)}–${toArabicDigits(entry.last.ayah)})'
        : '';
    return '﴿${withoutAyahNumber(ayahText)}﴾ $reference\n\n'
        '${entry.source.name}$range:\n'
        '${document.toPlainText(includeIsnad: includeIsnad)}';
  }
}
