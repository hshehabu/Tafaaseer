import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/domain/ayah_ref.dart';
import '../../../core/logging/app_log.dart';
import '../domain/repositories/notes_repository.dart';

/// Stored as one JSON object, {"2:255": "note text", ...}, under `notes.v1`.
/// Readable with any preferences inspector, like the bookmarks.
class NotesRepositoryImpl implements NotesRepository {
  const NotesRepositoryImpl(this._prefs);

  final SharedPreferencesWithCache _prefs;
  static const _key = 'notes.v1';

  @override
  Map<AyahRef, String> load() {
    final stored = _prefs.getString(_key);
    if (stored == null) return const {};
    try {
      final map = jsonDecode(stored) as Map<String, dynamic>;
      return {
        for (final MapEntry(:key, :value) in map.entries)
          if (AyahRef.tryParse(key) case final ref? when value is String && value.trim().isNotEmpty) ref: value,
      };
    } on FormatException catch (e) {
      AppLog.error('notes', 'notes could not be read; starting empty', e);
      return const {};
    }
  }

  @override
  Future<void> save(Map<AyahRef, String> notes) =>
      _prefs.setString(_key, jsonEncode({for (final MapEntry(:key, :value) in notes.entries) key.key: value}));
}
