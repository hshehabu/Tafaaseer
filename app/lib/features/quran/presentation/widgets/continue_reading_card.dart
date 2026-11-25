import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/arabic/arabic_text.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_palette.dart';
import '../pages/reader_page.dart';
import '../providers/quran_providers.dart';

/// "Continue reading" from the last saved page (D5). Hidden on first run.
class ContinueReadingCard extends ConsumerWidget {
  const ContinueReadingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(lastPositionProvider);
    final surahs = ref.watch(surahsProvider).value;
    if (position == null || surahs == null || position.surah > surahs.length) return const SizedBox.shrink();
    final page = ref.read(quranRepositoryProvider).locate(position)?.page;

    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Material(
        color: palette.controlSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppPalette.radius),
          side: BorderSide(color: palette.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppPalette.radius),
          onTap: () => Navigator.of(context).push(ReaderPage.route(position)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.auto_stories_outlined, color: palette.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.continueReading,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: palette.title),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.joinFacts([
                          AppStrings.surahPrefix(surahs[position.surah - 1].nameAr),
                          if (page != null) AppStrings.pageNumber(toArabicDigits(page)),
                        ]),
                        style: TextStyle(fontSize: 13, color: palette.muted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left, color: palette.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
