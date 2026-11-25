import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/arabic/arabic_text.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/quran_text.dart';
import '../../../settings/presentation/settings_providers.dart';
import '../../domain/entities/surah.dart';
import '../providers/quran_providers.dart';

/// Surah title, its facts, and the bismillah (taken from ayah 1:1).
class SurahBanner extends ConsumerWidget {
  const SurahBanner({super.key, required this.surah});

  final Surah surah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fontSize = ref.watch(settingsProvider.select((s) => s.quranFontSize));
    final bismillah = surah.showsBismillahHeader ? ref.watch(bismillahProvider).value : null;
    final kind = surah.revelation == Revelation.meccan ? AppStrings.meccan : AppStrings.medinan;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(AppStrings.surahPrefix(surah.nameAr), style: theme.textTheme.headlineSmall),
                Text(
                  '$kind · ${AppStrings.ayahCount(toArabicDigits(surah.ayahCount))}',
                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (bismillah != null) ...[
            const SizedBox(height: 12),
            QuranText(bismillah, fontSize: fontSize, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
