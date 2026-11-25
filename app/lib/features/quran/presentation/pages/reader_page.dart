import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../../core/domain/ayah_ref.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../settings/presentation/settings_providers.dart';
import '../../../tafsir/presentation/tafsir_sheet.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/surah.dart';
import '../providers/quran_providers.dart';
import '../widgets/ayah_tile.dart';
import '../widgets/surah_banner.dart';

/// One surah as a verse list (D1). Opens at [initialAyah] when given (D4, D5).
class ReaderPage extends ConsumerStatefulWidget {
  const ReaderPage({super.key, required this.surahId, this.initialAyah});

  final int surahId;
  final int? initialAyah;

  static Route<void> route(AyahRef ref) => MaterialPageRoute(
    builder: (_) => ReaderPage(surahId: ref.surah, initialAyah: ref.ayah > 1 ? ref.ayah : null),
  );

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  final _positions = ItemPositionsListener.create();
  Timer? _saveTimer;
  int? _highlighted;

  // List layout: [banner, ayah 1 .. ayah n, footer]. Ayah k sits at index k.
  static const _bannerItems = 1;

  @override
  void initState() {
    super.initState();
    _highlighted = widget.initialAyah;
    if (_highlighted != null) {
      Timer(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _highlighted = null);
      });
    }
    _positions.itemPositions.addListener(_onScroll);
  }

  @override
  void dispose() {
    _positions.itemPositions.removeListener(_onScroll);
    _saveTimer?.cancel();
    super.dispose();
  }

  /// Saves the first fully visible ayah, at most every half second (D5).
  void _onScroll() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      final visible = _positions.itemPositions.value.where((p) => p.itemTrailingEdge > 0.1).map((p) => p.index);
      if (visible.isEmpty) return;
      final ayah = visible.reduce((a, b) => a < b ? a : b).clamp(1, 999);
      ref.read(lastPositionProvider.notifier).update(AyahRef(widget.surahId, ayah));
    });
  }

  @override
  Widget build(BuildContext context) {
    final surahs = ref.watch(surahsProvider).value;
    final ayahsAsync = ref.watch(surahAyahsProvider(widget.surahId));
    final surah = surahs?[widget.surahId - 1];

    return Scaffold(
      appBar: AppBar(title: Text(surah == null ? '' : AppStrings.surahPrefix(surah.nameAr))),
      body: switch (ayahsAsync) {
        AsyncData(:final value) when surah != null => _buildList(surah, value, surahs!),
        AsyncError(:final error) => Center(child: Text('$error')),
        _ => const SizedBox.shrink(),
      },
    );
  }

  Widget _buildList(Surah surah, List<Ayah> ayahs, List<Surah> surahs) {
    final showHint = !ref.watch(settingsProvider.select((s) => s.tafsirHintSeen));
    final initialIndex = (widget.initialAyah ?? 0).clamp(0, ayahs.length);

    return ScrollablePositionedList.builder(
      itemCount: ayahs.length + _bannerItems + 1,
      initialScrollIndex: initialIndex,
      itemPositionsListener: _positions,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            children: [
              SurahBanner(surah: surah),
              if (showHint) const _LongPressHint(),
            ],
          );
        }
        if (index > ayahs.length) return _SurahNavigation(surah: surah, surahs: surahs);
        final ayah = ayahs[index - _bannerItems];
        return AyahTile(
          ayah: ayah,
          highlighted: ayah.number == _highlighted,
          onLongPress: () => showTafsirSheet(context, ayah: ayah),
        );
      },
    );
  }
}

class _LongPressHint extends ConsumerWidget {
  const _LongPressHint();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      color: colors.secondaryContainer,
      child: ListTile(
        leading: Icon(Icons.touch_app_outlined, color: colors.onSecondaryContainer),
        title: Text(AppStrings.longPressHint, style: TextStyle(color: colors.onSecondaryContainer)),
        trailing: TextButton(
          onPressed: () => ref.read(settingsProvider.notifier).update((s) => s.copyWith(tafsirHintSeen: true)),
          child: const Text(AppStrings.gotIt),
        ),
      ),
    );
  }
}

class _SurahNavigation extends StatelessWidget {
  const _SurahNavigation({required this.surah, required this.surahs});

  final Surah surah;
  final List<Surah> surahs;

  @override
  Widget build(BuildContext context) {
    void open(int id) => Navigator.of(context).pushReplacement(ReaderPage.route(AyahRef(id, 1)));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Row(
        children: [
          if (surah.id > 1)
            TextButton.icon(
              onPressed: () => open(surah.id - 1),
              icon: const Icon(Icons.chevron_left),
              label: Text('${AppStrings.previousSurah}: ${surahs[surah.id - 2].nameAr}'),
            ),
          const Spacer(),
          if (surah.id < surahs.length)
            TextButton.icon(
              onPressed: () => open(surah.id + 1),
              icon: const Icon(Icons.chevron_right),
              iconAlignment: IconAlignment.end,
              label: Text('${AppStrings.nextSurah}: ${surahs[surah.id].nameAr}'),
            ),
        ],
      ),
    );
  }
}
