import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/arabic/arabic_text.dart';
import '../../../../core/domain/ayah_ref.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/surah.dart';
import '../pages/reader_page.dart';
import '../providers/quran_providers.dart';
import 'continue_reading_card.dart';

/// Surah index (D2), with "continue reading" on top (D5).
class SurahList extends ConsumerWidget {
  const SurahList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahs = ref.watch(surahsProvider).value ?? const <Surah>[];
    return ListView.builder(
      itemCount: surahs.length + 1,
      itemBuilder: (context, i) => i == 0 ? const ContinueReadingCard() : _SurahTile(surah: surahs[i - 1]),
    );
  }
}

class _SurahTile extends StatelessWidget {
  const _SurahTile({required this.surah});

  final Surah surah;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kind = surah.revelation == Revelation.meccan ? AppStrings.meccan : AppStrings.medinan;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Text(toArabicDigits(surah.id), style: TextStyle(color: theme.colorScheme.onSecondaryContainer)),
      ),
      title: Text(surah.nameAr, style: theme.textTheme.titleMedium),
      subtitle: Text('$kind · ${AppStrings.ayahCount(toArabicDigits(surah.ayahCount))}'),
      trailing: Text(surah.nameTranslit, style: theme.textTheme.bodySmall, textDirection: TextDirection.ltr),
      onTap: () => Navigator.of(context).push(ReaderPage.route(AyahRef(surah.id, 1))),
    );
  }
}
