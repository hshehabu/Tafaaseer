import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tafaseer/features/tafsir/domain/entities/tafsir_document.dart';
import 'package:tafaseer/features/tafsir/presentation/widgets/tafsir_paragraph_view.dart';

void main() {
  const paragraph = TafsirParagraph(ParagraphKind.paragraph, [
    TafsirSpan(SpanKind.isnad, 'حدثنا بشر، قال: ثنا يزيد، '),
    TafsirSpan(SpanKind.text, 'عَنْ قَتَادَةَ قال: كذا.'),
  ]);

  Future<void> pump(WidgetTester tester, {required bool hideIsnad, bool showTashkeel = true}) => tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Material(
          child: TafsirParagraphView(
            paragraph: paragraph,
            options: TafsirTextOptions(
              fontSize: 18,
              lineHeight: 1.8,
              showTashkeel: showTashkeel,
              hideIsnad: hideIsnad,
            ),
          ),
        ),
      ),
    ),
  );

  String allText(WidgetTester tester) =>
      tester.widgetList<RichText>(find.byType(RichText)).map((r) => r.text.toPlainText()).join('|');

  testWidgets('a hidden isnad shows as a chip and opens on tap', (tester) async {
    await pump(tester, hideIsnad: true);
    expect(allText(tester), isNot(contains('حدثنا بشر')));
    expect(find.textContaining('السند'), findsOneWidget);

    await tester.tap(find.textContaining('السند'));
    await tester.pump();
    expect(allText(tester), contains('حدثنا بشر'));
  });

  testWidgets('the tashkeel setting strips diacritics from tafsir text', (tester) async {
    await pump(tester, hideIsnad: false, showTashkeel: false);
    expect(allText(tester), contains('عن قتادة'));
  });
}
