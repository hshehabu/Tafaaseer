import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/quran_text.dart';
import '../../../bookmarks/presentation/providers/bookmarks_providers.dart';
import '../../../settings/presentation/settings_providers.dart';
import '../../domain/entities/ayah.dart';

/// One ayah in the verse list. Long-press opens its tafsir (E1).
class AyahTile extends ConsumerWidget {
  const AyahTile({super.key, required this.ayah, required this.onLongPress, this.highlighted = false});

  final Ayah ayah;
  final VoidCallback onLongPress;
  final bool highlighted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final fontSize = ref.watch(settingsProvider.select((s) => s.quranFontSize));
    final bookmarked = ref.watch(isBookmarkedProvider(ayah.ref));

    return Semantics(
      // TalkBack / VoiceOver users reach the tafsir with the long-press action (F6).
      onLongPressHint: AppStrings.showTafsirAction,
      child: InkWell(
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          color: highlighted ? colors.primaryContainer.withValues(alpha: 0.45) : Colors.transparent,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Stack(
            children: [
              QuranText(ayah.text, fontSize: fontSize, textAlign: TextAlign.justify),
              if (bookmarked)
                PositionedDirectional(
                  top: 0,
                  end: -6,
                  child: Icon(Icons.bookmark, size: 18, color: colors.tertiary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
