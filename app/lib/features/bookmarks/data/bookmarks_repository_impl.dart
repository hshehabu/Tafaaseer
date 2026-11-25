import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/domain/ayah_ref.dart';
import '../../../core/logging/app_log.dart';
import '../domain/entities/bookmark.dart';
import '../domain/repositories/bookmarks_repository.dart';

/// Stored as a string list of "surah:ayah|epochMillis", newest first.
/// Readable with any preferences inspector, which keeps debugging simple.
class BookmarksRepositoryImpl implements BookmarksRepository {
  const BookmarksRepositoryImpl(this._prefs);

  final SharedPreferencesWithCache _prefs;
  static const _key = 'bookmarks.v1';

  @override
  List<Bookmark> load() {
    final stored = _prefs.getStringList(_key) ?? const [];
    final bookmarks = <Bookmark>[];
    for (final item in stored) {
      final parts = item.split('|');
      final ref = AyahRef.tryParse(parts.first);
      if (ref == null) {
        AppLog.error('bookmarks', 'skipping unreadable bookmark "$item"');
        continue;
      }
      final millis = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      bookmarks.add(Bookmark(ref: ref, createdAt: DateTime.fromMillisecondsSinceEpoch(millis)));
    }
    return bookmarks;
  }

  @override
  Future<void> save(List<Bookmark> bookmarks) => _prefs.setStringList(
    _key,
    [for (final b in bookmarks) '${b.ref.key}|${b.createdAt.millisecondsSinceEpoch}'],
  );
}
