import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/arabic/arabic_text.dart';
import '../../../../core/l10n/app_strings.dart';
import '../pages/reader_page.dart';
import '../providers/quran_providers.dart';

/// "Continue reading" from the last saved position (D5). Hidden on first run.
class ContinueReadingCard extends ConsumerWidget {
  const ContinueReadingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(lastPositionProvider);
    final surahs = ref.watch(surahsProvider).value;
    if (position == null || surahs == null || position.surah > surahs.length) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: colors.primaryContainer,
      child: ListTile(
        leading: Icon(Icons.auto_stories_outlined, color: colors.onPrimaryContainer),
        title: Text(AppStrings.continueReading, style: TextStyle(color: colors.onPrimaryContainer)),
        subtitle: Text(
          '${AppStrings.surahPrefix(surahs[position.surah - 1].nameAr)} · ${toArabicDigits(position.ayah)}',
          style: TextStyle(color: colors.onPrimaryContainer),
        ),
        onTap: () => Navigator.of(context).push(ReaderPage.route(position)),
      ),
    );
  }
}
