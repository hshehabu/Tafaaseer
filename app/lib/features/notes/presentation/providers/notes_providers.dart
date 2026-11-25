import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/ayah_ref.dart';
import '../../../../core/storage/preferences_provider.dart';
import '../../data/notes_repository_impl.dart';
import '../../domain/repositories/notes_repository.dart';

final notesRepositoryProvider = Provider<NotesRepository>(
  (ref) => NotesRepositoryImpl(ref.watch(preferencesProvider)),
);

final notesProvider = NotifierProvider<NotesController, Map<AyahRef, String>>(NotesController.new);

class NotesController extends Notifier<Map<AyahRef, String>> {
  @override
  Map<AyahRef, String> build() => ref.watch(notesRepositoryProvider).load();

  /// Saves [text] for [ayah]. Blank text removes the note, and with it the note pill.
  void write(AyahRef ayah, String text) {
    final next = {...state};
    if (text.trim().isEmpty) {
      if (next.remove(ayah) == null) return;
    } else {
      if (next[ayah] == text) return;
      next[ayah] = text;
    }
    state = Map.unmodifiable(next);
    ref.read(notesRepositoryProvider).save(state).ignore();
  }
}

/// The note on one ayah, or null. Rebuilds only widgets showing that ayah.
final noteProvider = Provider.family<String?, AyahRef>(
  (ref, ayah) => ref.watch(notesProvider.select((notes) => notes[ayah])),
);
