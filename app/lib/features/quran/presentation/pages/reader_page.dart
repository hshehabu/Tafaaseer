import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/arabic/arabic_text.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/domain/ayah_ref.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../settings/presentation/settings_providers.dart';
import '../../../tafsir/presentation/tafsir_sheet.dart';
import '../../domain/entities/mushaf_page.dart';
import '../providers/quran_providers.dart';
import '../widgets/jump_to_ayah_dialog.dart';
import '../widgets/mushaf_page_view.dart';

/// The Madani mushaf, page by page (v2). Long-press an ayah to open its tafsir.
class ReaderPage extends ConsumerStatefulWidget {
  const ReaderPage({super.key, required this.target, this.highlight = false});

  /// The ayah to open at; the reader shows the page it starts on.
  final AyahRef target;

  /// Briefly highlight [target] (after a jump or from a bookmark).
  final bool highlight;

  static Route<void> route(AyahRef target, {bool highlight = false}) => MaterialPageRoute(
    builder: (_) => ReaderPage(target: target, highlight: highlight),
  );

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  late final PageController _controller;
  late int _page;
  int? _highlighted;
  Timer? _saveTimer;
  Timer? _highlightTimer;
  Timer? _hintTimer;
  bool _hintVisible = true;

  /// Only the mushaf text: the top bar is hidden (toggled by a tap on the page).
  bool _immersive = false;

  /// The system bars' insets, kept at the largest seen. In focus mode Android
  /// hides the bars and reports zero insets; keeping the space they had stops
  /// the mushaf text from jumping or resizing when focus mode toggles.
  double _topInset = 0;
  double _bottomInset = 0;

  @override
  void initState() {
    super.initState();
    final repository = ref.read(quranRepositoryProvider);
    final location = repository.locate(widget.target);
    _page = location?.page ?? 1;
    _controller = PageController(initialPage: _page - 1);
    // One font size for every page, measured on a few ordinary pages with the real font.
    MushafFontScale.measure([
      for (final n in const [50, 150, 300, 450, 580]) repository.getPage(n),
    ]);
    if (widget.highlight && location != null) _flashHighlight(location.ayahId);
    _scheduleSave(); // the page it opens on counts as read too
    // The hint covers the bottom lines, so it only stays a few seconds.
    _hintTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _hintVisible = false);
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _highlightTimer?.cancel();
    _hintTimer?.cancel();
    _controller.dispose();
    // Leaving the reader always brings the status and navigation bars back.
    if (_immersive) SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /// A tap on the page: focus mode hides our bar and the phone's status and
  /// navigation bars, leaving only the mushaf (as in Tarteel); another tap shows them.
  void _toggleFocus() {
    setState(() => _immersive = !_immersive);
    SystemChrome.setEnabledSystemUIMode(_immersive ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge);
  }

  void _flashHighlight(int ayahId) {
    _highlighted = ayahId;
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _highlighted = null);
    });
  }

  void _onPageChanged(int index) {
    setState(() => _page = index + 1);
    _scheduleSave();
  }

  /// Saves the page's first ayah as the reading position (D5), once the reader settles.
  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) ref.read(lastPositionProvider.notifier).update(ref.read(mushafPageProvider(_page)).firstAyah);
    });
  }

  Future<void> _openTafsir(int ayahId) async {
    _highlightTimer?.cancel();
    // The reader found the long-press: the hint has done its job.
    if (!ref.read(settingsProvider).tafsirHintSeen) {
      ref.read(settingsProvider.notifier).update((s) => s.copyWith(tafsirHintSeen: true));
    }
    setState(() => _highlighted = ayahId);
    final ayah = await ref.read(quranRepositoryProvider).getAyahById(ayahId);
    if (ayah == null || !mounted) return;
    await showTafsirSheet(
      context,
      ayah: ayah,
      onAyahChanged: (next) {
        if (!mounted) return;
        setState(() => _highlighted = next.id);
        // Follow the sheet to the next page when the new ayah isn't on this one.
        if (!ref.read(mushafPageProvider(_page)).contains(next.id)) _controller.jumpToPage(next.page - 1);
      },
    );
    if (mounted) setState(() => _highlighted = null);
  }

  Future<void> _jump() async {
    final target = await showJumpToAyahDialog(context);
    if (target == null || !mounted) return;
    final location = ref.read(quranRepositoryProvider).locate(target);
    if (location == null) return;
    setState(() => _flashHighlight(location.ayahId));
    _controller.jumpToPage(location.page - 1);
  }

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(mushafPageProvider(_page));
    final showHint = _hintVisible && !_immersive && !ref.watch(settingsProvider.select((s) => s.tafsirHintSeen));
    final palette = AppPalette.of(context);
    final insets = MediaQuery.paddingOf(context);
    _topInset = math.max(_topInset, insets.top);
    _bottomInset = math.max(_bottomInset, insets.bottom);
    const animation = Duration(milliseconds: 220);

    final bar = AppBar(
      toolbarHeight: _barHeight,
      titleSpacing: 0,
      title: _PageTitle(page: page),
      actions: [
        IconButton(
          tooltip: AppStrings.jumpToAyah,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.search, size: 22),
          onPressed: _jump,
        ),
        const SizedBox(width: 4),
      ],
    );

    // The bar floats over the page instead of taking space from it, so showing
    // or hiding it never resizes the mushaf text (a tap toggles it, as in Tarteel).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: palette.brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(top: _topInset + _barHeight, bottom: _bottomInset),
              // In a right-to-left app the next page sits to the left, as in a printed mushaf.
              child: PageView.builder(
                controller: _controller,
                itemCount: MushafConfig.pageCount,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) => _PageFrame(
                  pageNumber: index + 1,
                  child: MushafPageView(
                    pageNumber: index + 1,
                    highlightedAyahId: _highlighted,
                    onAyahLongPress: _openTafsir,
                    onTap: _toggleFocus,
                  ),
                ),
              ),
            ),
            if (showHint)
              const PositionedDirectional(start: 16, end: 16, bottom: 24, child: SafeArea(child: _LongPressHint())),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: _immersive,
                child: AnimatedSlide(
                  offset: _immersive ? const Offset(0, -1) : Offset.zero,
                  duration: animation,
                  curve: Curves.easeOut,
                  child: AnimatedOpacity(opacity: _immersive ? 0 : 1, duration: animation, child: bar),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The reader's slim top bar: one line, so the mushaf keeps most of the screen.
const _barHeight = 48.0;

class _PageTitle extends ConsumerWidget {
  const _PageTitle({required this.page});

  final MushafPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahs = ref.watch(surahsProvider).value;
    final name = surahs == null ? '' : surahs[page.surah - 1].nameAr;
    final palette = AppPalette.of(context);
    // One line: the surah name, then the juz and page in small muted text.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(fontSize: 17),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          AppStrings.joinFacts([
            AppStrings.juz(toArabicDigits(page.juz)),
            AppStrings.pageShort(toArabicDigits(page.number)),
          ]),
          style: TextStyle(fontSize: 12.5, color: palette.muted),
        ),
      ],
    );
  }
}

/// Page margins and the page number under the text.
class _PageFrame extends StatelessWidget {
  const _PageFrame({required this.pageNumber, required this.child});

  final int pageNumber;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      // Narrow side margins, as in Tarteel: the width sets the mushaf font size.
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
      child: Column(
        children: [
          Expanded(child: child),
          const SizedBox(height: 4),
          Text(toArabicDigits(pageNumber), style: TextStyle(fontSize: 13, color: palette.muted)),
        ],
      ),
    );
  }
}

class _LongPressHint extends ConsumerWidget {
  const _LongPressHint();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.controlSurface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(AppPalette.radius),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
        child: Row(
          children: [
            Icon(Icons.touch_app_outlined, color: palette.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(AppStrings.longPressHint, style: TextStyle(color: palette.title)),
            ),
            TextButton(
              onPressed: () => ref.read(settingsProvider.notifier).update((s) => s.copyWith(tafsirHintSeen: true)),
              child: const Text(AppStrings.gotIt),
            ),
          ],
        ),
      ),
    );
  }
}
