import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tafaseer/app/theme/app_theme.dart';
import 'package:tafaseer/core/database/content_database.dart';
import 'package:tafaseer/core/database/database_providers.dart';
import 'package:tafaseer/features/quran/presentation/widgets/mushaf_page_view.dart';

import '../helpers/content_db_fixture.dart';

void main() {
  late ContentDatabase db;
  setUp(() => db = openFixtureDatabase());
  tearDown(() => db.close());

  // Page 2 of the fixture: 11 lines (title, bismillah, ayahs 8..16), centred
  // vertically because it is an opening page.
  const size = Size(400, 540); // fits the 800 x 600 test window
  const lineHeight = 540 / 15;
  const top = (540 - 11 * lineHeight) / 2;

  Future<List<int>> pumpPage(WidgetTester tester) async {
    final pressed = <int>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [readyContentDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Center(
              child: SizedBox.fromSize(
                size: size,
                child: MushafPageView(pageNumber: 2, highlightedAyahId: null, onAyahLongPress: pressed.add),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return pressed;
  }

  Offset lineCentre(WidgetTester tester, int lineIndex) {
    final origin = tester.getTopLeft(find.byType(MushafPageView));
    return origin + Offset(size.width / 2, top + (lineIndex + 0.5) * lineHeight);
  }

  testWidgets('long-pressing a line reports the ayah on it', (tester) async {
    final pressed = await pumpPage(tester);
    await tester.longPressAt(lineCentre(tester, 2)); // first ayah line: 2:1, id 8
    await tester.longPressAt(lineCentre(tester, 10)); // last line: 2:9, id 16
    expect(pressed, [8, 16]);
  });

  testWidgets('long-pressing the title or bismillah line does nothing', (tester) async {
    final pressed = await pumpPage(tester);
    await tester.longPressAt(lineCentre(tester, 0));
    await tester.longPressAt(lineCentre(tester, 1));
    expect(pressed, isEmpty);
  });
}
