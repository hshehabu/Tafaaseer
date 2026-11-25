import 'package:sqlite3/sqlite3.dart';

import '../config/app_config.dart';
import '../error/app_exception.dart';

/// Read-only connection to the bundled content database (Quran + tafsirs).
///
/// Queries run synchronously through FFI: no platform channel, no copying
/// rows across isolates. Every query in the app is a primary-key lookup that
/// takes well under a millisecond, so this is the fastest option. Prepared
/// statements are cached per SQL string.
class ContentDatabase {
  ContentDatabase(this._db);

  /// Opens [path] read-only and checks it is a database this code understands.
  factory ContentDatabase.open(String path) {
    final Database db;
    try {
      db = sqlite3.open(path, mode: OpenMode.readOnly);
    } on SqliteException catch (e) {
      throw ContentDatabaseException('cannot open $path', e);
    }
    final content = ContentDatabase(db);
    try {
      content.validate();
    } catch (_) {
      content.close();
      rethrow;
    }
    return content;
  }

  final Database _db;
  final Map<String, PreparedStatement> _statements = {};

  int get schemaVersion => _db.userVersion;

  /// Throws [ContentDatabaseException] when the file is not a usable content database.
  void validate() {
    try {
      if (schemaVersion != ContentDbConfig.schemaVersion) {
        throw ContentDatabaseException(
          'schema version $schemaVersion, app expects ${ContentDbConfig.schemaVersion}',
        );
      }
      final ayahs = _db.select('SELECT count(*) AS n FROM ayahs').first['n'] as int;
      if (ayahs != 6236) throw ContentDatabaseException('database has $ayahs ayahs, expected 6236');
    } on SqliteException catch (e) {
      throw ContentDatabaseException('database is corrupt', e);
    }
  }

  ResultSet select(String sql, [List<Object?> parameters = const []]) {
    final statement = _statements.putIfAbsent(sql, () => _db.prepare(sql));
    return statement.select(parameters);
  }

  /// Values of the `meta` table (build date, sources), for the debug/about screen.
  Map<String, String> meta() => {
    for (final row in select('SELECT key, value FROM meta')) row['key'] as String: row['value'] as String,
  };

  void close() {
    for (final statement in _statements.values) {
      statement.close();
    }
    _statements.clear();
    _db.close();
  }
}
