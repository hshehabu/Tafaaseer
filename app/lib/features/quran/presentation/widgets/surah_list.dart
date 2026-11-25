import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/arabic/arabic_text.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/domain/ayah_ref.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_palette.dart';
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
      padding: const EdgeInsets.only(bottom: 28),
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
    final palette = AppPalette.of(context);
    final kind = surah.revelation == Revelation.meccan ? AppStrings.meccan : AppStrings.medinan;
    return InkWell(
      onTap: () => Navigator.of(context).push(ReaderPage.route(AyahRef(surah.id, 1))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            NumberTile(number: surah.id),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.nameAr,
                    style: TextStyle(
                      fontFamily: UiFonts.classical,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      color: palette.title,
                    ),
                  ),
                  Text(
                    AppStrings.joinFacts([kind, AppStrings.ayahCount(surah.ayahCount, toArabicDigits(surah.ayahCount))]),
                    style: TextStyle(fontSize: 13, color: palette.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The square number tile of the design system (36 x 36, 4.8px corners).
class NumberTile extends StatelessWidget {
  const NumberTile({super.key, required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.secondaryNeutral,
        border: Border.all(color: palette.secondaryBorder),
        borderRadius: BorderRadius.circular(AppPalette.radius),
      ),
      child: Text(
        toArabicDigits(number),
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: palette.primaryDark),
      ),
    );
  }
}
