import 'package:flutter_test/flutter_test.dart';
import 'package:tafaseer/core/arabic/arabic_text.dart';
import 'package:tafaseer/core/domain/ayah_ref.dart';

void main() {
  group('AyahRef.tryParse', () {
    test('accepts western and Arabic digits and common separators', () {
      expect(AyahRef.tryParse('2:255'), const AyahRef(2, 255));
      expect(AyahRef.tryParse(' ٢:٢٥٥ '), const AyahRef(2, 255));
      expect(AyahRef.tryParse('2 255'), const AyahRef(2, 255));
      expect(AyahRef.tryParse('112/1'), const AyahRef(112, 1));
    });

    test('rejects anything else', () {
      expect(AyahRef.tryParse('البقرة'), isNull);
      expect(AyahRef.tryParse('2:'), isNull);
      expect(AyahRef.tryParse(''), isNull);
    });
  });

  group('Arabic text', () {
    test('stripTashkeel removes diacritics but keeps letters', () {
      expect(stripTashkeel('بِسْمِ اللَّهِ'), 'بسم الله');
    });

    test('toArabicDigits', () {
      expect(toArabicDigits(255), '٢٥٥');
      expect(toArabicDigits(0), '٠');
    });

    test('withoutAyahNumber drops the trailing number of KFGQPC text', () {
      expect(withoutAyahNumber('بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ١'), 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ');
      expect(withoutAyahNumber('وَهُوَ ٱلۡعَلِيُّ ٱلۡعَظِيمُ ٢٥٥'), 'وَهُوَ ٱلۡعَلِيُّ ٱلۡعَظِيمُ');
    });
  });

  test('foldForSearch ignores diacritics, alef forms and digit scripts', () {
    expect(foldForSearch('الأَنْعَام'), foldForSearch('الانعام'));
    expect(foldForSearch('سورة البقرة'), 'سوره البقره');
    expect(foldForSearch('٢٥٥'), '255');
  });
}
