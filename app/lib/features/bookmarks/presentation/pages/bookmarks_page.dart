import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/arabic/arabic_text.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/quran_text.dart';
import '../../../quran/presentation/pages/reader_page.dart';
import '../../../quran/presentation/providers/quran_providers.dart';
import '../../domain/entities/bookmark.dart';
import '../providers/bookmarks_providers.dart';

class BookmarksPage extends ConsumerWidget {
  const BookmarksPage({super.key});

  static Route<void> route() => MaterialPageRoute(builder: (_) => const BookmarksPage());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarksProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.bookmarks)),
      body: bookmarks.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(AppStrings.noBookmarks, textAlign: TextAlign.center),
              ),
            )
          : ListView.separated(
              itemCount: bookmarks.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) => _BookmarkTile(bookmark: bookmarks[i]),
            ),
    );
  }
}

class _BookmarkTile extends ConsumerWidget {
  const _BookmarkTile({required this.bookmark});

  final Bookmark bookmark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahs = ref.watch(surahsProvider).value;
    final ayah = ref.watch(ayahByRefProvider(bookmark.ref)).value;
    final name = surahs == null ? '' : surahs[bookmark.ref.surah - 1].nameAr;

    return Dismissible(
      key: ValueKey(bookmark.ref),
      onDismissed: (_) => ref.read(bookmarksProvider.notifier).toggle(bookmark.ref),
      background: ColoredBox(color: Theme.of(context).colorScheme.errorContainer),
      child: ListTile(
        title: Text('$name ${toArabicDigits(bookmark.ref.ayah)}'),
        subtitle: ayah == null ? null : QuranText(ayah.text, fontSize: 18, maxLines: 2),
        onTap: () => Navigator.of(context).push(ReaderPage.route(bookmark.ref)),
      ),
    );
  }
}
