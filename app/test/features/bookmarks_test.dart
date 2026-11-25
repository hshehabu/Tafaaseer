import 'package:flutter_test/flutter_test.dart';
import 'package:tafaseer/core/domain/ayah_ref.dart';
import 'package:tafaseer/features/bookmarks/data/bookmarks_repository_impl.dart';
import 'package:tafaseer/features/bookmarks/domain/usecases/toggle_bookmark.dart';

import '../helpers/test_preferences.dart';

void main() {
  final now = DateTime.utc(2026, 11, 24);
  final toggle = ToggleBookmark(clock: () => now);

  test('toggle adds to the top, then removes', () {
    var list = toggle(const [], const AyahRef(2, 255));
    list = toggle(list, const AyahRef(1, 1));
    expect(list.map((b) => b.ref), [const AyahRef(1, 1), const AyahRef(2, 255)]);
    list = toggle(list, const AyahRef(2, 255));
    expect(list.map((b) => b.ref), [const AyahRef(1, 1)]);
  });

  test('repository round-trips and skips unreadable items', () async {
    final prefs = await createTestPreferences();
    final repo = BookmarksRepositoryImpl(prefs);
    await repo.save(toggle(const [], const AyahRef(2, 255)));
    expect(repo.load().single.ref, const AyahRef(2, 255));
    expect(repo.load().single.createdAt.toUtc(), now);

    await prefs.setStringList('bookmarks.v1', ['garbage', '3:7|0']);
    expect(repo.load().map((b) => b.ref), [const AyahRef(3, 7)]);
  });
}
