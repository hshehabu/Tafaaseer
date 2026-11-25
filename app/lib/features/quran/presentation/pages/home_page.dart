import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../bookmarks/presentation/pages/bookmarks_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../widgets/jump_to_ayah_dialog.dart';
import '../widgets/juz_list.dart';
import '../widgets/surah_list.dart';
import 'reader_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                if (target != null && context.mounted) await Navigator.of(context).push(ReaderPage.route(target));
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
