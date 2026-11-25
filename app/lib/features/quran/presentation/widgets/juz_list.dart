import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/arabic/arabic_text.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/hizb_start.dart';
import '../pages/reader_page.dart';
import '../providers/quran_providers.dart';

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

    return ListView.builder(
      itemCount: juzNumbers.length,
      itemBuilder: (context, i) {
        final juz = juzNumbers[i];
        final starts = byJuz[juz]!;
        final first = starts.first;
        return ListTile(
          title: Text(AppStrings.juz(toArabicDigits(juz))),
          subtitle: Text('${first.surahName} ${toArabicDigits(first.ref.ayah)}'),
          onTap: () => Navigator.of(context).push(ReaderPage.route(first.ref)),
          trailing: Wrap(
            spacing: 6,
            children: [
              for (final h in starts)
                ActionChip(
                  label: Text(AppStrings.hizb(toArabicDigits(h.hizb))),
                  onPressed: () => Navigator.of(context).push(ReaderPage.route(h.ref)),
                ),
            ],
          ),
        );
      },
    );
  }
}
