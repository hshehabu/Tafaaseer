import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/ayah_ref.dart';
import '../../../../core/storage/preferences_provider.dart';
import '../../data/bookmarks_repository_impl.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/repositories/bookmarks_repository.dart';
import '../../domain/usecases/toggle_bookmark.dart';

final bookmarksRepositoryProvider = Provider<BookmarksRepository>(
  (ref) => BookmarksRepositoryImpl(ref.watch(preferencesProvider)),
);

final toggleBookmarkProvider = Provider((ref) => const ToggleBookmark());

final bookmarksProvider = NotifierProvider<BookmarksController, List<Bookmark>>(BookmarksController.new);

class BookmarksController extends Notifier<List<Bookmark>> {
  @override
  List<Bookmark> build() => ref.watch(bookmarksRepositoryProvider).load();

  /// Returns true when the ayah is now bookmarked.
  bool toggle(AyahRef ayah) {
    state = ref.read(toggleBookmarkProvider)(state, ayah);
    ref.read(bookmarksRepositoryProvider).save(state).ignore();
    return state.any((b) => b.ref == ayah);
  }
}

/// Rebuilds only the widgets showing this ayah when its bookmark changes.
final isBookmarkedProvider = Provider.family<bool, AyahRef>(
  (ref, ayah) => ref.watch(bookmarksProvider.select((list) => list.any((b) => b.ref == ayah))),
);
