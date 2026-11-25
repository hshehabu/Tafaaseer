import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/domain/ayah_ref.dart';
import '../../domain/repositories/reading_position_repository.dart';

class ReadingPositionRepositoryImpl implements ReadingPositionRepository {
  const ReadingPositionRepositoryImpl(this._prefs);

  final SharedPreferencesWithCache _prefs;
  static const _key = 'reading.last_position';

  @override
  AyahRef? load() {
    final stored = _prefs.getString(_key);
    return stored == null ? null : AyahRef.tryParse(stored);
  }

  @override
  Future<void> save(AyahRef ref) => _prefs.setString(_key, ref.key);
}
