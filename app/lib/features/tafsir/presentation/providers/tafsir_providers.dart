import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_providers.dart';
import '../../data/datasources/tafsir_local_data_source.dart';
import '../../data/repositories/tafsir_repository_impl.dart';
import '../../domain/entities/tafsir_document.dart';
import '../../domain/repositories/tafsir_repository.dart';
import '../../domain/usecases/build_share_text.dart';
import '../../domain/usecases/get_ayah_tafsirs.dart';

// Wiring: data source -> repository -> use cases. Tests override
// readyContentDatabaseProvider (or tafsirRepositoryProvider) and nothing else.

final tafsirRepositoryProvider = Provider<TafsirRepository>(
  (ref) => TafsirRepositoryImpl(TafsirLocalDataSource(ref.watch(readyContentDatabaseProvider))),
);

final getAyahTafsirsProvider = Provider((ref) => GetAyahTafsirs(ref.watch(tafsirRepositoryProvider)));

final buildShareTextProvider = Provider((ref) => const BuildShareText());

/// The pills for one ayah (by global id). Disposed when the sheet closes.
final ayahTafsirsProvider = FutureProvider.autoDispose.family<AyahTafsirs, int>(
  (ref, ayahId) => ref.watch(getAyahTafsirsProvider)(ayahId),
);

/// The decoded text of one entry. The repository keeps its own cache, so
/// re-opening an entry after this provider is disposed is still instant.
final tafsirDocumentProvider = FutureProvider.autoDispose.family<TafsirDocument, int>(
  (ref, entryId) => ref.watch(tafsirRepositoryProvider).getDocument(entryId),
);

/// Scroll offset per entry for this session, so returning to a long entry
/// resumes where the reader was (E7).
final tafsirScrollMemoryProvider = Provider<Map<int, double>>((ref) => {});
