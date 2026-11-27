import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/fonts/quran_font_loader.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_palette.dart';
import '../../domain/entities/mushaf_page.dart';
import '../../domain/entities/surah.dart';
import '../providers/quran_providers.dart';

/// One Madani mushaf page: 15 lines that fill the width, like the print.
///
/// The page is laid out once per size/theme ([_PageLayout]) and drawn by one
/// [CustomPainter]. Changing the highlighted ayah only repaints. A long-press
/// anywhere on a word reports that word's ayah.
class MushafPageView extends ConsumerStatefulWidget {
  const MushafPageView({
    super.key,
    required this.pageNumber,
    required this.highlightedAyahId,
    required this.onAyahLongPress,
    this.onTap,
  });

  final int pageNumber;
  final int? highlightedAyahId;
  final ValueChanged<int> onAyahLongPress;

  /// A plain tap anywhere on the page (the reader uses it to show or hide its bar).
  final VoidCallback? onTap;

  @override
  ConsumerState<MushafPageView> createState() => _MushafPageViewState();
}

class _MushafPageViewState extends ConsumerState<MushafPageView> {
  _PageLayout _layoutFor(MushafPage page, Size size, AppPalette palette, String bismillah, List<Surah> surahs) {
    final key = _LayoutCache.key(page.number, size, palette, bismillah);
    final layout = _LayoutCache.get(key) ??
        _LayoutCache.put(key, _PageLayout(page: page, size: size, palette: palette, bismillah: bismillah, surahs: surahs));
    _prepareNeighbours(page.number, size, palette, bismillah, surahs);
    return layout;
  }

  /// Lays out the next and previous pages while the phone is idle (right after
  /// a page settles), so a swipe only draws pages that are already prepared.
  /// Shaping a page of Hafs text takes ~30 ms on a mid-range phone: done during
  /// a swipe, that is a visible stutter.
  void _prepareNeighbours(int number, Size size, AppPalette palette, String bismillah, List<Surah> surahs) {
    final repository = ref.read(quranRepositoryProvider);
    for (final n in [number + 1, number - 1]) {
      if (n < 1 || n > MushafConfig.pageCount) continue;
      final key = _LayoutCache.key(n, size, palette, bismillah);
      if (_LayoutCache.contains(key)) continue;
      SchedulerBinding.instance.scheduleTask(() {
        if (_LayoutCache.contains(key)) return;
        final page = repository.getPage(n);
        _LayoutCache.put(key, _PageLayout(page: page, size: size, palette: palette, bismillah: bismillah, surahs: surahs));
      }, Priority.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(mushafPageProvider(widget.pageNumber));
    final bismillah = ref.watch(bismillahProvider).value ?? '';
    final surahs = ref.watch(surahsProvider).value ?? const <Surah>[];
    final palette = AppPalette.of(context);

    return LayoutBuilder(
      builder: (context, box) {
        final layout = _layoutFor(page, box.biggest, palette, bismillah, surahs);
        return Semantics(
          label: layout.semanticsLabel,
          hint: AppStrings.longPressHint,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            onLongPressStart: (details) {
              final ayahId = layout.ayahAt(details.localPosition);
              if (ayahId == null) return;
              Feedback.forLongPress(context);
              widget.onAyahLongPress(ayahId);
            },
            child: CustomPaint(
              size: box.biggest,
              painter: _PagePainter(layout, widget.highlightedAyahId),
            ),
          ),
        );
      },
    );
  }
}

/// Recently laid-out pages, shared by every page widget: the page on screen,
/// its prepared neighbours, and the last few visited.
abstract final class _LayoutCache {
  static const _capacity = 7;
  static final _entries = <String, _PageLayout>{}; // insertion-ordered: oldest first

  static String key(int page, Size size, AppPalette palette, String bismillah) =>
      '$page|${size.width}|${size.height}|${identityHashCode(palette)}|${bismillah.hashCode}';

  static bool contains(String key) => _entries.containsKey(key);

  static _PageLayout? get(String key) {
    final layout = _entries.remove(key);
    if (layout != null) _entries[key] = layout; // most recently used
    return layout;
  }

  /// Evicted layouts are left to the garbage collector rather than disposed,
  /// in case a page widget is still drawing one for a last frame.
  static _PageLayout put(String key, _PageLayout layout) {
    _entries[key] = layout;
    while (_entries.length > _capacity) {
      _entries.remove(_entries.keys.first);
    }
    return layout;
  }
}

/// Everything measured for one page at one size: word positions, painters.
class _PageLayout {
  _PageLayout({
    required this.page,
    required this.size,
    required this.palette,
    required this.bismillah,
    required List<Surah> surahs,
  }) {
    _build(surahs);
  }

  final MushafPage page;
  final Size size;
  final AppPalette palette;
  final String bismillah;

  late final double lineHeight;
  late final double fontSize;
  late final double top;
  final List<_PlacedWord> words = [];
  final List<_Decoration> decorations = [];
  late final String semanticsLabel;

  TextStyle _quranStyle(double size) => TextStyle(
    fontFamily: QuranFontConfig.family,
    fontFamilyFallback: QuranFontConfig.fallback,
    fontSize: size,
    height: 1,
    color: palette.mushafInk,
  );

  TextPainter _painter(String text, TextStyle style) =>
      TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.rtl, maxLines: 1)..layout();

  void _build(List<Surah> surahs) {
    lineHeight = size.height / MushafConfig.linesPerPage;
    // Each ayah line is measured once at the base size, to pick the page's font size.
    final base = math.min(lineHeight / 1.75, size.width / MushafFontScale.typicalLinePerFontPx);
    final baseStyle = _quranStyle(base);
    final widthAtBase = <MushafLine, double>{
      for (final line in page.lines.where((l) => l.kind == MushafLineKind.ayah))
        line: _measure(line.words.map((w) => w.text).join(' '), baseStyle),
    };
    fontSize = _pageFontSize(base, widthAtBase.values.toList());
    // The two opening pages have fewer lines; they sit in the middle.
    top = page.isOpening ? (size.height - page.lines.length * lineHeight) / 2 : 0;

    final style = _quranStyle(fontSize);
    final spaceWidth = _measure(' ', style);
    final labels = <String>[];

    for (var i = 0; i < page.lines.length; i++) {
      final line = page.lines[i];
      final y = top + i * lineHeight;
      switch (line.kind) {
        case MushafLineKind.ayah:
          _placeLine(line, y, style, spaceWidth);
          labels.add(line.words.map((w) => w.text).join(' '));
        case MushafLineKind.surahTitle:
          final name = line.surah <= surahs.length ? surahs[line.surah - 1].nameAr : '';
          final title = AppStrings.surahPrefix(name);
          decorations.add(QuranFonts.decorations ? _ornateTitle(y, line.surah) : _plainTitle(y, title));
          labels.add(title);
        case MushafLineKind.basmala:
          if (QuranFonts.decorations) {
            // The calligraphic bismillah of the printed mushaf.
            decorations.add(_Decoration(y, [
              _fitted('﷽', QuranFontConfig.commonFamily, maxWidth: size.width * 0.5, maxHeight: lineHeight * 0.72),
            ]));
          } else if (bismillah.isNotEmpty) {
            decorations.add(_Decoration(y, [_painter(bismillah, style)]));
          }
          labels.add(bismillah);
      }
    }
    semanticsLabel = labels.join('\n');
  }

  /// The printed mushaf's surah header: QUL's ornate frame ("header" in the
  /// quran-common font) with the surah's name in calligraphy on top.
  _Decoration _ornateTitle(double y, int surah) {
    final frame = _fitted('header', QuranFontConfig.commonFamily, maxWidth: size.width, maxHeight: lineHeight * 0.96);
    // "surah014" draws the name and "surah-icon" draws "سورة"; laid out left to
    // right, the icon lands on the right, where Arabic reading starts.
    final name = _fitted(
      'surah${surah.toString().padLeft(3, '0')} surah-icon',
      QuranFontConfig.surahNamesFamily,
      maxWidth: frame.width * 0.42,
      maxHeight: frame.height * 0.62,
      direction: TextDirection.ltr,
    );
    return _Decoration(y, [frame, name]);
  }

  /// Without the decoration fonts: a simple double frame with the name in Amiri.
  _Decoration _plainTitle(double y, String title) => _Decoration(
    y,
    [
      _painter(
        title,
        TextStyle(
          fontFamily: UiFonts.classical,
          fontSize: fontSize * 0.82,
          fontWeight: FontWeight.w700,
          height: 1,
          color: palette.mushafInk,
        ),
      ),
    ],
    plainFrame: true,
  );

  /// [text] in [family], as large as fits in [maxWidth] x [maxHeight].
  TextPainter _fitted(
    String text,
    String family, {
    required double maxWidth,
    required double maxHeight,
    TextDirection direction = TextDirection.rtl,
  }) {
    TextPainter make(double fontSize) => TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontFamily: family, fontSize: fontSize, height: 1, color: palette.mushafInk),
      ),
      textDirection: direction,
      maxLines: 1,
    )..layout();
    final probe = make(100);
    final scale = math.min(maxWidth / probe.width, maxHeight / probe.height);
    probe.dispose();
    return make(100 * scale);
  }

  /// One base size for the whole mushaf (from a typical line), nudged per page
  /// so that a page of short lines doesn't look sparse. The nudge is small
  /// enough (-6%..+8%) that swiping between pages doesn't show a jump.
  double _pageFontSize(double base, List<double> widths) {
    final heightLimit = lineHeight / 1.6;
    if (page.isOpening || widths.length < 4) return base;
    widths.sort();
    final typical = widths[(widths.length * _typicalQuantile).floor().clamp(0, widths.length - 1)];
    final fitted = base * size.width / typical;
    return math.min(fitted.clamp(base * 0.94, base * 1.08), heightLimit);
  }

  double _measure(String text, TextStyle style) {
    final p = _painter(text, style);
    final width = p.width;
    p.dispose();
    return width;
  }

  void _placeLine(MushafLine line, double y, TextStyle style, double spaceWidth) {
    var painters = [for (final w in line.words) _painter(w.text, style)];
    var natural = painters.fold<double>(0, (sum, p) => sum + p.width) + spaceWidth * (painters.length - 1);
    var space = spaceWidth;

    if (natural > size.width && painters.length > 1) {
      // A wide line: first tighten the spaces (down to half of normal, so an ayah mark never touches a word)...
      final wordsWidth = natural - space * (painters.length - 1);
      space = math.max(space * 0.5, (size.width - wordsWidth) / (painters.length - 1));
      natural = wordsWidth + space * (painters.length - 1);
    }
    if (natural > size.width) {
      // ...and only if that is not enough, shrink this one line a little.
      for (final p in painters) {
        p.dispose();
      }
      final shrunk = _quranStyle(style.fontSize! * size.width / natural * 0.995);
      painters = [for (final w in line.words) _painter(w.text, shrunk)];
      final wordsWidth = painters.fold<double>(0, (sum, p) => sum + p.width);
      space = painters.length > 1 ? (size.width - wordsWidth) / (painters.length - 1) : 0;
      natural = wordsWidth + space * (painters.length - 1);
    }

    // Short lines (the end of a surah, the last page) are centred as in print; the rest are justified
    // by spreading the extra width over the gaps. Letters are never stretched.
    final centred = page.isOpening || painters.length < 2 || natural < size.width * 0.6;
    final gap = centred ? space : (size.width - (natural - space * (painters.length - 1))) / (painters.length - 1);
    final lineWidth = centred ? natural : size.width;
    // Right to left: the first word starts at the right edge of the line.
    var x = (size.width + lineWidth) / 2;
    for (var i = 0; i < painters.length; i++) {
      final p = painters[i];
      x -= p.width;
      words.add(_PlacedWord(
        word: line.words[i],
        painter: p,
        rect: Rect.fromLTWH(x, y, p.width, lineHeight),
        joinRight: i > 0 && line.words[i - 1].ayahId == line.words[i].ayahId ? gap : 0,
      ));
      x -= gap;
    }
  }

  /// The ayah under [point], with the gaps between words counted as part of
  /// the words around them so a long-press never falls through.
  int? ayahAt(Offset point) {
    _PlacedWord? best;
    var bestDistance = double.infinity;
    for (final w in words) {
      if (point.dy < w.rect.top || point.dy > w.rect.bottom) continue;
      final dx = point.dx < w.rect.left
          ? w.rect.left - point.dx
          : point.dx > w.rect.right
          ? point.dx - w.rect.right
          : 0.0;
      if (dx < bestDistance) {
        bestDistance = dx;
        best = w;
      }
    }
    return best != null && bestDistance <= lineHeight ? best.word.ayahId : null;
  }

  void dispose() {
    for (final w in words) {
      w.painter.dispose();
    }
    for (final d in decorations) {
      for (final p in d.layers) {
        p.dispose();
      }
    }
  }
}

/// One word, its painter, and where it is on the page.
class _PlacedWord {
  _PlacedWord({required this.word, required this.painter, required this.rect, required this.joinRight});

  final MushafWord word;
  final TextPainter painter;
  final Rect rect;

  /// The gap to the word on the right when that word is in the same ayah, so
  /// a highlight runs on without breaks; 0 otherwise.
  final double joinRight;
}

/// A title or bismillah line: painters drawn centred on top of each other.
class _Decoration {
  _Decoration(this.y, this.layers, {this.plainFrame = false});

  final double y;
  final List<TextPainter> layers;

  /// Draw the fallback frame (when the decoration fonts are missing).
  final bool plainFrame;
}

class _PagePainter extends CustomPainter {
  _PagePainter(this.layout, this.highlightedAyahId);

  final _PageLayout layout;
  final int? highlightedAyahId;

  @override
  void paint(Canvas canvas, Size size) {
    final lh = layout.lineHeight;
    final palette = layout.palette;

    if (highlightedAyahId != null) {
      // One rounded box per run of the ayah's words on a line, so the highlight has no seams.
      final paint = Paint()..color = palette.mushafHighlight;
      Rect? run;
      void flush() {
        if (run != null) {
          canvas.drawRRect(RRect.fromRectAndRadius(run!, const Radius.circular(AppPalette.radius)), paint);
        }
        run = null;
      }

      for (final w in layout.words) {
        if (w.word.ayahId != highlightedAyahId) {
          flush();
          continue;
        }
        final rect = Rect.fromLTRB(w.rect.left, w.rect.top + lh * 0.06, w.rect.right, w.rect.bottom - lh * 0.06);
        if (run != null && run!.top == rect.top) {
          run = run!.expandToInclude(rect); // same line: extend the box over the gap
        } else {
          flush();
          run = rect;
        }
      }
      flush();
    }

    for (final w in layout.words) {
      final p = w.painter;
      p.paint(canvas, Offset(w.rect.left, w.rect.top + (lh - p.height) / 2));
    }

    for (final d in layout.decorations) {
      if (d.plainFrame) _paintTitleFrame(canvas, size, d.y, lh, palette);
      for (final p in d.layers) {
        p.paint(canvas, Offset((size.width - p.width) / 2, d.y + (lh - p.height) / 2));
      }
    }
  }

  /// A simple double frame, like the surah headers of the printed mushaf.
  void _paintTitleFrame(Canvas canvas, Size size, double y, double lh, AppPalette palette) {
    final outer = Rect.fromLTRB(0, y + lh * 0.1, size.width, y + lh * 0.9);
    final inner = outer.deflate(lh * 0.08);
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(outer, const Radius.circular(AppPalette.radius)),
        Paint()..color = palette.secondaryNeutral,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(outer, const Radius.circular(AppPalette.radius)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = palette.primary,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(inner, const Radius.circular(AppPalette.radius / 2)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = palette.primary.withValues(alpha: 0.6),
      );
  }

  @override
  bool shouldRepaint(_PagePainter old) => old.layout != layout || old.highlightedAyahId != highlightedAyahId;
}

/// The line width the font is sized for, as a quantile of all lines (0.75:
/// wider lines tighten their gaps, and only the widest few shrink a little).
const _typicalQuantile = 0.75;

/// How wide a typical mushaf line is per pixel of font size, measured once
/// with the real font, so every page starts from the same font size.
abstract final class MushafFontScale {
  static double? _typicalLinePerFontPx;

  /// A safe default until [measure] runs.
  static double get typicalLinePerFontPx => _typicalLinePerFontPx ?? 17.3;

  /// Call once, before the first page is drawn, with a few ordinary pages.
  /// The font is sized for the 75th-percentile line (measured over the whole
  /// mushaf: median 16.2, p75 17.4, p99 20.4 font-px). Wider lines tighten
  /// their spaces, and only the widest few shrink a little.
  static void measure(Iterable<MushafPage> samples) {
    if (_typicalLinePerFontPx != null) return;
    const probe = 100.0;
    const style = TextStyle(
      fontFamily: QuranFontConfig.family,
      fontFamilyFallback: QuranFontConfig.fallback,
      fontSize: probe,
      height: 1,
    );
    final widths = <double>[];
    for (final page in samples) {
      for (final line in page.lines.where((l) => l.kind == MushafLineKind.ayah)) {
        final painter = TextPainter(
          text: TextSpan(text: line.words.map((w) => w.text).join(' '), style: style),
          textDirection: TextDirection.rtl,
          maxLines: 1,
        )..layout();
        widths.add(painter.width);
        painter.dispose();
      }
    }
    if (widths.isEmpty) return;
    widths.sort();
    _typicalLinePerFontPx = widths[(widths.length * _typicalQuantile).floor().clamp(0, widths.length - 1)] / probe;
  }
}
