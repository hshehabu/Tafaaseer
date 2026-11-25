import 'dart:convert';
import 'dart:io' show zlib;
import 'dart:isolate';
import 'dart:typed_data';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/tafsir_document.dart';

/// Decodes tafsir_entries.body: zlib-compressed UTF-8 JSON, body format v1
/// (documented in pipeline/README.md).
abstract final class TafsirBodyCodec {
  /// Bodies larger than this are decoded on a background isolate so the UI
  /// never drops frames. 16 KB compressed is roughly 60 KB of text; most
  /// entries are far smaller and decode inline in about a millisecond.
  static const isolateThresholdBytes = 16 * 1024;

  static const _paragraphKinds = {
    'p': ParagraphKind.paragraph,
    'h': ParagraphKind.heading,
    'poem': ParagraphKind.poem,
    'hr': ParagraphKind.divider,
    'ed': ParagraphKind.editorNote,
  };

  static const _spanKinds = [SpanKind.text, SpanKind.quran, SpanKind.isnad, SpanKind.note, SpanKind.reference];

  static Future<TafsirDocument> decodeAsync(Uint8List body) =>
      body.length > isolateThresholdBytes ? Isolate.run(() => decode(body)) : Future.value(decode(body));

  static TafsirDocument decode(Uint8List body) {
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(zlib.decode(body)));
    } on FormatException catch (e) {
      throw ContentDatabaseException('unreadable tafsir body', e);
    }
    if (json is! Map<String, Object?> || json['v'] != 1) {
      throw ContentDatabaseException('unsupported tafsir body format: ${json is Map ? json['v'] : json.runtimeType}');
    }
    final paragraphs = <TafsirParagraph>[];
    for (final raw in json['p']! as List<Object?>) {
      final p = raw! as Map<String, Object?>;
      final spans = <TafsirSpan>[
        for (final s in p['s']! as List<Object?>)
          if (s case [final int kind, final String text] when kind < _spanKinds.length) TafsirSpan(_spanKinds[kind], text),
      ];
      paragraphs.add(TafsirParagraph(_paragraphKinds[p['k']] ?? ParagraphKind.paragraph, spans));
    }
    return TafsirDocument(paragraphs);
  }
}
