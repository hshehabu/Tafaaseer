import 'package:flutter/foundation.dart';

/// The cleaned text of one tafsir entry: paragraphs made of typed spans.
/// Mirrors the pipeline's body format v1 (pipeline/README.md).
enum ParagraphKind { paragraph, heading, poem, divider, editorNote }

enum SpanKind { text, quran, isnad, note, reference }

@immutable
class TafsirSpan {
  const TafsirSpan(this.kind, this.text);

  final SpanKind kind;
  final String text;
}

@immutable
class TafsirParagraph {
  const TafsirParagraph(this.kind, this.spans);

  final ParagraphKind kind;
  final List<TafsirSpan> spans;

  /// A poem line's two halves ("صدر ... عجز").
  List<String> get hemistichs => spans
      .where((s) => s.kind != SpanKind.note)
      .map((s) => s.text)
      .join()
      .split(RegExp(r'\s*(?:\.\.\.|…)\s*'))
      .where((h) => h.trim().isNotEmpty)
      .toList();
}

@immutable
class TafsirDocument {
  const TafsirDocument(this.paragraphs);

  final List<TafsirParagraph> paragraphs;

  bool get isEmpty => paragraphs.isEmpty;

  /// Plain text for copy and share. Quran quotes get their ﴿ ﴾ back,
  /// footnotes are left out, narrator chains follow [includeIsnad].
  String toPlainText({required bool includeIsnad}) {
    final buffer = StringBuffer();
    for (final p in paragraphs) {
      if (p.kind == ParagraphKind.divider) continue;
      final line = StringBuffer();
      for (final s in p.spans) {
        switch (s.kind) {
          case SpanKind.text || SpanKind.reference:
            line.write(s.text);
          case SpanKind.quran:
            line.write('﴿${s.text}﴾');
          case SpanKind.isnad:
            if (includeIsnad) line.write(s.text);
          case SpanKind.note:
            if (p.kind == ParagraphKind.editorNote) line.write(s.text);
        }
      }
      final text = line.toString().trim();
      if (text.isEmpty) continue;
      if (buffer.isNotEmpty) buffer.write('\n\n');
      buffer.write(text);
    }
    return buffer.toString();
  }
}
