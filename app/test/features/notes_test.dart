import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tafaseer/core/domain/ayah_ref.dart';
import 'package:tafaseer/core/storage/preferences_provider.dart';
import 'package:tafaseer/features/notes/data/notes_repository_impl.dart';
import 'package:tafaseer/features/notes/presentation/providers/notes_providers.dart';

import '../helpers/test_preferences.dart';

void main() {
  test('writing a note saves it; blank text removes it (and with it the pill)', () async {
    final prefs = await createTestPreferences();
    final container = ProviderContainer(overrides: [preferencesProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);
    const ayah = AyahRef(2, 255);
    final notes = container.read(notesProvider.notifier);

    notes.write(ayah, 'آية الكرسي');
    expect(container.read(noteProvider(ayah)), 'آية الكرسي');
    expect(NotesRepositoryImpl(prefs).load(), {ayah: 'آية الكرسي'});

    notes.write(ayah, '   \n ');
    expect(container.read(noteProvider(ayah)), isNull);
    expect(NotesRepositoryImpl(prefs).load(), isEmpty);
  });

  test('unreadable stored notes start empty instead of crashing', () async {
    final prefs = await createTestPreferences();
    await prefs.setString('notes.v1', '{not json');
    expect(NotesRepositoryImpl(prefs).load(), isEmpty);
    await prefs.setString('notes.v1', '{"2:255": "ok", "bad": "x", "1:1": ""}');
    expect(NotesRepositoryImpl(prefs).load(), {const AyahRef(2, 255): 'ok'});
  });
}
