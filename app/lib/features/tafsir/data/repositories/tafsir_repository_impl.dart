import '../../../../core/error/app_exception.dart';
import '../../../../core/logging/app_log.dart';
import '../../domain/entities/tafsir_document.dart';
import '../../domain/entities/tafsir_entry.dart';
import '../../domain/entities/tafsir_source.dart';
import '../../domain/repositories/tafsir_repository.dart';
import '../codec/tafsir_body_codec.dart';
import '../datasources/tafsir_local_data_source.dart';
import '../models/tafsir_row_mappers.dart';

class TafsirRepositoryImpl implements TafsirRepository {
  TafsirRepositoryImpl(this._source, {this.cacheSize = 24});

  final TafsirLocalDataSource _source;

  /// How many decoded documents to keep. Switching pills or stepping back to
  /// an ayah is then instant. Worst case (24 long al-Tabari entries) is a few MB.
  final int cacheSize;

  final _documents = <int, TafsirDocument>{}; // a LinkedHashMap: insertion order = least recently used first
  List<TafsirSource>? _sources;

  @override
  Future<List<TafsirSource>> getSources() async =>
      _sources ??= List.unmodifiable(_source.sources().map(TafsirRowMappers.source));

  @override
  Future<List<TafsirEntry>> getEntriesForAyah(int ayahId) async =>
      _source.entriesForAyah(ayahId).map(TafsirRowMappers.entry).toList(growable: false);

  @override
  Future<TafsirDocument> getDocument(int entryId) async {
    final cached = _documents.remove(entryId);
    if (cached != null) return _documents[entryId] = cached;

    final body = _source.body(entryId);
    if (body == null) throw ContentNotFoundException('tafsir entry $entryId');
    final watch = Stopwatch()..start();
    final document = await TafsirBodyCodec.decodeAsync(body);
    AppLog.info('tafsir', 'entry $entryId: ${body.length} B decoded in ${watch.elapsedMilliseconds} ms');

    _documents[entryId] = document;
    if (_documents.length > cacheSize) _documents.remove(_documents.keys.first);
    return document;
  }
}
