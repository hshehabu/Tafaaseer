import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/arabic/arabic_text.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_palette.dart';
import '../../domain/entities/hizb_start.dart';
import '../pages/reader_page.dart';
import '../providers/quran_providers.dart';
import 'surah_list.dart';

/// 30 juz, each with its two hizbs (D3).
class JuzList extends ConsumerWidget {
  const JuzList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hizbs = ref.watch(hizbStartsProvider).value ?? const <HizbStart>[];
    final byJuz = <int, List<HizbStart>>{};
    for (final h in hizbs) {
      (byJuz[h.juz] ??= []).add(h);
    }
    final juzNumbers = byJuz.keys.toList()..sort();
    final palette = AppPalette.of(context);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: juzNumbers.length,
      itemBuilder: (context, i) {
        final juz = juzNumbers[i];
        final starts = byJuz[juz]!;
        final first = starts.first;
        return InkWell(
          onTap: () => Navigator.of(context).push(ReaderPage.route(first.ref)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                NumberTile(number: juz),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.juz(toArabicDigits(juz)),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: palette.title),
                      ),
                      Text(
                        '${first.surahName} ${toArabicDigits(first.ref.ayah)}',
                        style: TextStyle(fontSize: 13, color: palette.muted),
                      ),
                    ],
                  ),
                ),
                for (final h in starts) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    label: Text(AppStrings.hizb(toArabicDigits(h.hizb))),
                    onPressed: () => Navigator.of(context).push(ReaderPage.route(h.ref)),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
