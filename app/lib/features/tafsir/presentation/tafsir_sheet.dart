import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/arabic/arabic_text.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../bookmarks/presentation/providers/bookmarks_providers.dart';
import '../../quran/domain/entities/ayah.dart';
import '../../quran/presentation/providers/quran_providers.dart';
import '../../settings/presentation/settings_providers.dart';
import '../domain/entities/tafsir_entry.dart';
import '../domain/usecases/get_ayah_tafsirs.dart';
import 'providers/tafsir_providers.dart';
import 'widgets/tafsir_paragraph_view.dart';

/// Opens the tafsir sheet for [ayah]. This is the tafsir feature's public entry
/// point; the reader calls it on long-press (E1, E2). [onAyahChanged] fires when
/// the reader steps to the next or previous ayah inside the sheet, so the
/// mushaf page can move its highlight.
Future<void> showTafsirSheet(BuildContext context, {required Ayah ayah, ValueChanged<Ayah>? onAyahChanged}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Light enough that the highlighted ayah stays visible above the sheet.
    barrierColor: Colors.black.withValues(alpha: 0.12),
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 1,
      snap: true,
      snapSizes: const [0.55],
      builder: (context, scrollController) =>
          TafsirSheet(initialAyah: ayah, scrollController: scrollController, onAyahChanged: onAyahChanged),
    ),
  );
}

class TafsirSheet extends ConsumerStatefulWidget {
  const TafsirSheet({super.key, required this.initialAyah, required this.scrollController, this.onAyahChanged});

  final Ayah initialAyah;
  final ScrollController scrollController;
  final ValueChanged<Ayah>? onAyahChanged;

  @override
  ConsumerState<TafsirSheet> createState() => _TafsirSheetState();
}

class _TafsirSheetState extends ConsumerState<TafsirSheet> {
  late Ayah _ayah = widget.initialAyah;

  /// The tafsir the reader picked; null means "the default" (al-Muyassar).
  /// Kept when stepping to the next ayah, so someone reading al-Tabari stays in al-Tabari.
  int? _selectedSourceId;
  int? _shownEntryId;

  ScrollController get _scroll => widget.scrollController;

  TafsirEntry _selected(AyahTafsirs tafsirs) {
    final picked = tafsirs.entries.where((e) => e.source.id == _selectedSourceId);
    return picked.isNotEmpty ? picked.first : tafsirs.entries[tafsirs.initialIndex];
  }

  void _rememberScroll() {
    final id = _shownEntryId;
    if (id != null && _scroll.hasClients) ref.read(tafsirScrollMemoryProvider)[id] = _scroll.offset;
  }

  void _selectSource(int sourceId) {
    _rememberScroll();
    setState(() => _selectedSourceId = sourceId);
  }

  Future<void> _step(int delta) async {
    final next = await ref.read(quranRepositoryProvider).getAyahById(_ayah.id + delta);
    if (next == null || !mounted) return;
    _rememberScroll();
    setState(() => _ayah = next);
    widget.onAyahChanged?.call(next);
  }

  /// After a different entry appears, restore where the reader was in it (E7).
  void _restoreScroll(int entryId) {
    if (_shownEntryId == entryId) return;
    _shownEntryId = entryId;
    final offset = ref.read(tafsirScrollMemoryProvider)[entryId] ?? 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(offset.clamp(0, _scroll.position.maxScrollExtent));
    });
  }

  @override
  Widget build(BuildContext context) {
    final tafsirsAsync = ref.watch(ayahTafsirsProvider(_ayah.id));
    final settings = ref.watch(settingsProvider);
    final options = TafsirTextOptions(
      fontSize: settings.tafsirFontSize,
      lineHeight: settings.tafsirLineHeight,
      showTashkeel: settings.showTashkeel,
      hideIsnad: settings.hideIsnad,
    );

    // The sheet gets its own messenger so "copied" appears above the sheet,
    // not behind it on the reader page.
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: switch (tafsirsAsync) {
          AsyncData(:final value) when value.isEmpty => const _Message(AppStrings.noTafsir),
          AsyncData(:final value) => _buildContent(value, options),
          AsyncError() => const _Message(AppStrings.tafsirLoadFailed),
          _ => const SizedBox.shrink(), // index lookup takes ~0.1 ms; no spinner flash
        },
      ),
    );
  }

  Widget _buildContent(AyahTafsirs tafsirs, TafsirTextOptions options) {
    final entry = _selected(tafsirs);
    final documentAsync = ref.watch(tafsirDocumentProvider(entry.id));
    final paragraphs = documentAsync.value?.paragraphs;
    if (paragraphs != null) _restoreScroll(entry.id);

    return CustomScrollView(
      controller: _scroll,
      slivers: [
        PinnedHeaderSliver(
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SheetHeader(
                  ayah: _ayah,
                  entry: entry,
                  hideIsnad: options.hideIsnad,
                  onPrevious: _ayah.id > 1 ? () => _step(-1) : null,
                  onNext: _ayah.id < 6236 ? () => _step(1) : null,
                ),
                _SourcePills(
                  entries: tafsirs.entries,
                  selected: entry,
                  hideIsnad: options.hideIsnad,
                  onSelected: _selectSource,
                ),
                const Divider(height: 1),
              ],
            ),
          ),
        ),
        switch (documentAsync) {
          AsyncError() => const SliverFillRemaining(hasScrollBody: false, child: _Message(AppStrings.tafsirLoadFailed)),
          _ when paragraphs == null => const SliverToBoxAdapter(child: LinearProgressIndicator(minHeight: 2)),
          _ => SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
            sliver: SliverList.builder(
              itemCount: paragraphs.length,
              // Built lazily: al-Qurtubi's longest entry has ~100k characters.
              itemBuilder: (context, i) => TafsirParagraphView(
                key: ValueKey('${entry.id}-$i'),
                paragraph: paragraphs[i],
                options: options,
              ),
            ),
          ),
        },
      ],
    );
  }
}

class _SheetHeader extends ConsumerWidget {
  const _SheetHeader({
    required this.ayah,
    required this.entry,
    required this.hideIsnad,
    required this.onPrevious,
    required this.onNext,
  });

  final Ayah ayah;
  final TafsirEntry entry;
  final bool hideIsnad;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  Future<String> _shareText(WidgetRef ref) async {
    final surahs = await ref.read(surahsProvider.future);
    final document = await ref.read(tafsirRepositoryProvider).getDocument(entry.id);
    return ref.read(buildShareTextProvider)(
      ayahText: ayah.text,
      surahName: surahs[ayah.surah - 1].nameAr,
      ayahNumber: ayah.number,
      entry: entry,
      document: document,
      includeIsnad: !hideIsnad,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final surahName = ref.watch(surahsProvider).value?[ayah.surah - 1].nameAr ?? '';
    final bookmarked = ref.watch(isBookmarkedProvider(ayah.ref));
    final messenger = ScaffoldMessenger.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 4, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: AppStrings.previousAyah,
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.ayahShort(surahName, toArabicDigits(ayah.number)),
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.coversRange)
                  Text(
                    AppStrings.commentaryRange(
                      '${toArabicDigits(entry.first.ayah)}–${toArabicDigits(entry.last.ayah)}',
                    ),
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: AppStrings.nextAyah,
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton(
            tooltip: AppStrings.copy,
            icon: const Icon(Icons.copy_outlined),
            onPressed: () async {
              final text = await _shareText(ref);
              await Clipboard.setData(ClipboardData(text: text));
              messenger.showSnackBar(const SnackBar(content: Text(AppStrings.copied)));
            },
          ),
          Builder(
            builder: (buttonContext) => IconButton(
              tooltip: AppStrings.share,
              icon: const Icon(Icons.share_outlined),
              onPressed: () async {
                final box = buttonContext.findRenderObject() as RenderBox?;
                final text = await _shareText(ref);
                await SharePlus.instance.share(ShareParams(
                  text: text,
                  sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
                ));
              },
            ),
          ),
          IconButton(
            tooltip: bookmarked ? AppStrings.removeBookmark : AppStrings.bookmark,
            isSelected: bookmarked,
            icon: const Icon(Icons.bookmark_add_outlined),
            selectedIcon: const Icon(Icons.bookmark),
            onPressed: () {
              final added = ref.read(bookmarksProvider.notifier).toggle(ayah.ref);
              messenger.showSnackBar(SnackBar(
                content: Text(added ? AppStrings.bookmarkAdded : AppStrings.bookmarkRemoved),
                duration: const Duration(seconds: 2),
              ));
            },
          ),
        ],
      ),
    );
  }
}

class _SourcePills extends StatelessWidget {
  const _SourcePills({
    required this.entries,
    required this.selected,
    required this.hideIsnad,
    required this.onSelected,
  });

  final List<TafsirEntry> entries;
  final TafsirEntry selected;
  final bool hideIsnad;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final e = entries[i];
          final minutes = toArabicDigits(e.readingMinutes(hideIsnad: hideIsnad));
          final isSelected = e.id == selected.id;
          return ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.source.shortName),
                const SizedBox(width: 8),
                // The reading time is a separate, quieter label: "الميسر ١ د", never "الميسر · ١ د".
                Text(
                  AppStrings.minutes(minutes),
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: palette.muted),
                ),
              ],
            ),
            selected: isSelected,
            showCheckmark: false,
            side: BorderSide(color: isSelected ? palette.secondaryBorder : palette.border),
            onSelected: (_) => onSelected(e.source.id),
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
    ),
  );
}
