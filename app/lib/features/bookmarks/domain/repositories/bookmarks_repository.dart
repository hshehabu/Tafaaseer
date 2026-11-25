import '../entities/bookmark.dart';

abstract interface class BookmarksRepository {
  /// Newest first.
  List<Bookmark> load();

  Future<void> save(List<Bookmark> bookmarks);
}
