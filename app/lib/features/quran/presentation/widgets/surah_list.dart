import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/arabic/arabic_text.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/domain/ayah_ref.dart';
import '../../../../core/fonts/quran_font_loader.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_palette.dart';
import '../../domain/entities/surah.dart';
import '../pages/reader_page.dart';
import '../providers/quran_providers.dart';
import 'continue_reading_card.dart';

/// Surah index (D2): search, "continue reading" (D5), and the 114 surahs with
/// their names in calligraphy and the page each starts on.
class SurahList extends ConsumerStatefulWidget {
  const SurahList({super.key});

  @override
  ConsumerState<SurahList> createState() => _SurahListState();
}

class _SurahListState extends ConsumerState<SurahList> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Matches the surah number, its name (without diacritics or alef forms), or مكية / مدنية.
  bool _matches(Surah s, String query) {
    if (query.isEmpty) return true;
    if (int.tryParse(query) case final n?) return s.id == n;
    final kind = s.revelation == Revelation.meccan ? AppStrings.meccan : AppStrings.medinan;
    final name = foldForSearch(s.nameAr);
    return name.contains(query) ||
        foldForSearch(kind).startsWith(query) ||
        name.replaceFirst('ال', '').startsWith(query);
  }

  @override
  Widget build(BuildContext context) {
    final surahs = ref.watch(surahsProvider).value ?? const <Surah>[];
    final query = foldForSearch(_query).replaceFirst(RegExp('^سوره\\s*'), '');
    final shown = surahs.where((s) => _matches(s, query)).toList(growable: false);
    final lastRead = ref.watch(lastPositionProvider)?.surah;
    final searching = query.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: AppStrings.surahSearchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searching
                  ? IconButton(
                      tooltip: AppStrings.clear,
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                        _search.clear();
                        _query = '';
                      }),
                    )
                  : null,
              isDense: true,
            ),
          ),
        ),
        if (searching && shown.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              AppStrings.noSurahFound,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppPalette.of(context).muted),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 28),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: shown.length + (searching ? 0 : 1),
            itemBuilder: (context, i) {
              if (!searching && i == 0) return const ContinueReadingCard();
              final surah = shown[i - (searching ? 0 : 1)];
              return _SurahTile(surah: surah, isLastRead: surah.id == lastRead);
            },
          ),
        ),
      ],
    );
  }
}

class _SurahTile extends StatelessWidget {
  const _SurahTile({required this.surah, required this.isLastRead});

  final Surah surah;

  /// The surah of the saved reading position: marked so it is easy to find.
  final bool isLastRead;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final kind = surah.revelation == Revelation.meccan ? AppStrings.meccan : AppStrings.medinan;
    return Material(
      color: isLastRead ? palette.secondaryNeutral : Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(ReaderPage.route(AyahRef(surah.id, 1))),
        child: Container(
          decoration: BoxDecoration(
            border: BorderDirectional(
              start: BorderSide(color: isLastRead ? palette.primary : Colors.transparent, width: 3),
              bottom: BorderSide(color: palette.secondaryNeutral),
            ),
          ),
          padding: const EdgeInsetsDirectional.fromSTEB(17, 8, 20, 8),
          child: Row(
            children: [
              NumberTile(number: surah.id),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SurahName(surah: surah),
                    Text(
                      AppStrings.joinFacts([
                        kind,
                        AppStrings.ayahCount(surah.ayahCount, toArabicDigits(surah.ayahCount)),
                      ]),
                      style: TextStyle(fontSize: 13, color: palette.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.pageShort(toArabicDigits(surah.startPage)),
                style: TextStyle(fontSize: 13, color: palette.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "سُورَةُ البقرة" in QUL's surah-name calligraphy; plain Amiri if that font is missing.
class _SurahName extends StatelessWidget {
  const _SurahName({required this.surah});

  final Surah surah;

  @override
  Widget build(BuildContext context) {
    final color = AppPalette.of(context).title;
    if (!QuranFonts.decorations) {
      return Text(
        surah.nameAr,
        style: TextStyle(
          fontFamily: UiFonts.classical,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.4,
          color: color,
        ),
      );
    }
    return Semantics(
      label: AppStrings.surahPrefix(surah.nameAr),
      excludeSemantics: true,
      // The ligature codes are Latin; laid out left to right, "سورة" lands on the right.
      child: Text(
        'surah${surah.id.toString().padLeft(3, '0')} surah-icon',
        textDirection: TextDirection.ltr,
        style: TextStyle(fontFamily: QuranFontConfig.surahNamesFamily, fontSize: 30, height: 1.25, color: color),
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
