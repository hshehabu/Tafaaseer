import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/arabic/arabic_text.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/tafsir_document.dart';

/// Reading options that change how a paragraph is drawn.
@immutable
class TafsirTextOptions {
  const TafsirTextOptions({
    required this.fontSize,
    required this.lineHeight,
    required this.showTashkeel,
    required this.hideIsnad,
  });

  final double fontSize;
  final double lineHeight;
  final bool showTashkeel;
  final bool hideIsnad;
}

/// One paragraph of a tafsir entry. Stateful only to remember which collapsed
/// narrator chains the reader opened.
class TafsirParagraphView extends StatefulWidget {
  const TafsirParagraphView({super.key, required this.paragraph, required this.options});

  final TafsirParagraph paragraph;
  final TafsirTextOptions options;

  @override
  State<TafsirParagraphView> createState() => _TafsirParagraphViewState();
}

class _TafsirParagraphViewState extends State<TafsirParagraphView> {
  final _openedIsnads = <int>{};

  String _display(String text) => widget.options.showTashkeel ? text : stripTashkeel(text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final o = widget.options;
    final base = theme.textTheme.bodyLarge!.copyWith(fontSize: o.fontSize, height: o.lineHeight);
    final p = widget.paragraph;

    return switch (p.kind) {
      ParagraphKind.divider => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Divider(indent: 64, endIndent: 64, color: colors.outlineVariant),
      ),
      ParagraphKind.heading => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 4),
        child: Text.rich(
          TextSpan(children: _spans(context, base)),
          style: base.copyWith(fontWeight: FontWeight.w700, fontSize: o.fontSize * 1.05, color: colors.primary),
        ),
      ),
      ParagraphKind.poem => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            for (final half in p.hemistichs)
              Text(_display(half), textAlign: TextAlign.center, style: base.copyWith(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
      ParagraphKind.editorNote => Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.editorNote, style: theme.textTheme.labelMedium?.copyWith(color: colors.primary)),
            const SizedBox(height: 4),
            Text(
              _display(p.spans.map((s) => s.text).join(' ')),
              style: base.copyWith(fontSize: o.fontSize * 0.9, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
      ParagraphKind.paragraph => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text.rich(TextSpan(children: _spans(context, base)), style: base, textAlign: TextAlign.justify),
      ),
    };
  }

  List<InlineSpan> _spans(BuildContext context, TextStyle base) {
    final colors = Theme.of(context).colorScheme;
    final spans = <InlineSpan>[];
    for (var i = 0; i < widget.paragraph.spans.length; i++) {
      final s = widget.paragraph.spans[i];
      switch (s.kind) {
        case SpanKind.text:
          spans.add(TextSpan(text: _display(s.text)));
        case SpanKind.quran:
          // Quran quotes keep their diacritics and are set apart by colour and ﴿ ﴾.
          spans.add(TextSpan(
            text: '﴿${s.text}﴾',
            style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600),
          ));
        case SpanKind.reference:
          spans.add(TextSpan(
            text: s.text,
            style: TextStyle(fontSize: base.fontSize! * 0.8, color: colors.onSurfaceVariant),
          ));
        case SpanKind.isnad:
          if (widget.options.hideIsnad && !_openedIsnads.contains(i)) {
            spans.add(WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: _InlineChip(
                label: AppStrings.isnad,
                onTap: () => setState(() => _openedIsnads.add(i)),
              ),
            ));
          } else {
            spans.add(TextSpan(text: _display(s.text), style: TextStyle(color: colors.onSurfaceVariant)));
          }
        case SpanKind.note:
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: _NoteMarker(note: _display(s.text)),
          ));
      }
    }
    return spans;
  }
}

class _InlineChip extends StatelessWidget {
  const _InlineChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          decoration: BoxDecoration(
            color: colors.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$label …',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colors.onSecondaryContainer),
          ),
        ),
      ),
    );
  }
}

/// A small superscript marker; tapping it shows the editor's footnote (C2).
class _NoteMarker extends StatelessWidget {
  const _NoteMarker({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: AppStrings.footnote,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onTap: () => showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(AppStrings.footnote),
            content: SingleChildScrollView(child: Text(note)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Icon(Icons.info_outline, size: 14, color: colors.tertiary),
        ),
      ),
    );
  }
}
