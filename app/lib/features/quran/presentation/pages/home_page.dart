import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../bookmarks/presentation/pages/bookmarks_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../providers/quran_providers.dart';
import '../widgets/jump_to_ayah_dialog.dart';
import '../widgets/juz_list.dart';
import '../widgets/surah_list.dart';
import 'reader_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  /// Once per app launch: reopen the mushaf where the reader left off. The
  /// index stays underneath, so Back still leads to it.
  static bool _resumed = false;

  /// True for the single frame before the reader opens on top: the index
  /// isn't drawn then, so it never flashes before the mushaf.
  bool _resuming = false;

  @override
  void initState() {
    super.initState();
    if (_resumed) return;
    _resumed = true;
    final last = ref.read(lastPositionProvider);
    if (last == null) return;
    _resuming = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push(ReaderPage.resumeRoute(last));
      setState(() => _resuming = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_resuming) return ColoredBox(color: Theme.of(context).scaffoldBackgroundColor);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.appName),
          actions: [
            IconButton(
              tooltip: AppStrings.jumpToAyah,
              icon: const Icon(Icons.search),
              onPressed: () async {
                final target = await showJumpToAyahDialog(context);
                if (target != null && context.mounted) await Navigator.of(context).push(ReaderPage.route(target, highlight: true));
              },
            ),
            IconButton(
              tooltip: AppStrings.bookmarks,
              icon: const Icon(Icons.bookmarks_outlined),
              onPressed: () => Navigator.of(context).push(BookmarksPage.route()),
            ),
            IconButton(
              tooltip: AppStrings.settings,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.of(context).push(SettingsPage.route()),
            ),
          ],
          bottom: const TabBar(tabs: [Tab(text: AppStrings.surahsTab), Tab(text: AppStrings.juzTab)]),
        ),
        body: const TabBarView(children: [SurahList(), JuzList()]),
      ),
    );
  }
}
