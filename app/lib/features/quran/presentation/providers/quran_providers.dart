import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_providers.dart';
import '../../../../core/domain/ayah_ref.dart';
import '../../../../core/storage/preferences_provider.dart';
import '../../data/datasources/quran_local_data_source.dart';
import '../../data/repositories/quran_repository_impl.dart';
import '../../data/repositories/reading_position_repository_impl.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/hizb_start.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/quran_repository.dart';
import '../../domain/repositories/reading_position_repository.dart';
import '../../domain/usecases/resolve_ayah_ref.dart';

// Wiring: data source -> repository. Other features read Quran data only
// through quranRepositoryProvider and the providers below (domain types).

final quranRepositoryProvider = Provider<QuranRepository>(
  (ref) => QuranRepositoryImpl(QuranLocalDataSource(ref.watch(readyContentDatabaseProvider))),
);

final readingPositionRepositoryProvider = Provider<ReadingPositionRepository>(
  (ref) => ReadingPositionRepositoryImpl(ref.watch(preferencesProvider)),
);

final resolveAyahRefProvider = Provider((ref) => const ResolveAyahRef());

final surahsProvider = FutureProvider<List<Surah>>((ref) => ref.watch(quranRepositoryProvider).getSurahs());

final hizbStartsProvider = FutureProvider<List<HizbStart>>(
  (ref) => ref.watch(quranRepositoryProvider).getHizbStarts(),
);

final bismillahProvider = FutureProvider<String>((ref) => ref.watch(quranRepositoryProvider).getBismillah());

/// Ayahs of one surah. Kept while the reader is open, dropped after.
final surahAyahsProvider = FutureProvider.autoDispose.family<List<Ayah>, int>(
  (ref, surahId) => ref.watch(quranRepositoryProvider).getAyahs(surahId),
);

/// One ayah by reference (bookmarks list).
final ayahByRefProvider = FutureProvider.autoDispose.family<Ayah?, AyahRef>(
  (ref, ayahRef) => ref.watch(quranRepositoryProvider).getAyah(ayahRef),
);

final lastPositionProvider = NotifierProvider<LastPositionController, AyahRef?>(LastPositionController.new);

class LastPositionController extends Notifier<AyahRef?> {
  @override
  AyahRef? build() => ref.watch(readingPositionRepositoryProvider).load();

  void update(AyahRef position) {
    if (position == state) return;
    state = position;
    ref.read(readingPositionRepositoryProvider).save(position).ignore();
  }
}
