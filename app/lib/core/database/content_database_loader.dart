import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../error/app_exception.dart';
import '../logging/app_log.dart';
import 'content_database.dart';

/// Gets the bundled database onto the device and opens it.
///
/// SQLite needs a real file, so the asset is copied once (and again when
/// [ContentDbConfig.bundleVersion] changes). The copy goes into the cache
/// directory on purpose: the data can always be rebuilt from the APK, it must
/// not count against Android's 25 MB backup quota, and if the OS clears the
/// cache the next launch simply copies it again.
class ContentDatabaseLoader {
  ContentDatabaseLoader({
    required this.loadAsset,
    required this.directory,
    required this.preferences,
  });

  final Future<ByteData> Function(String assetPath) loadAsset;
  final Future<Directory> Function() directory;
  final SharedPreferencesWithCache preferences;

  static const _versionKey = 'content_db_bundle_version';
  static const _tag = 'db';

  Future<ContentDatabase> load() async {
    final dir = await directory();
    final file = File(p.join(dir.path, ContentDbConfig.fileName));
    AppLog.info(_tag, 'database file: ${file.path}');

    final upToDate = preferences.getInt(_versionKey) == ContentDbConfig.bundleVersion && file.existsSync();
    if (!upToDate) await _copyAsset(file);

    try {
      // `await` matters: without it the error escapes this try/catch.
      return await _open(file, copied: !upToDate);
    } on ContentDatabaseException catch (e) {
      if (!upToDate) rethrow; // a fresh copy that fails to open will fail again
      AppLog.error(_tag, 'existing copy unusable, copying again', e);
      await _copyAsset(file);
      return _open(file, copied: true);
    }
  }

  Future<ContentDatabase> _open(File file, {required bool copied}) async {
    final db = AppLog.timed(_tag, 'opened', () => ContentDatabase.open(file.path));
    if (copied) await preferences.setInt(_versionKey, ContentDbConfig.bundleVersion);
    return db;
  }

  /// Writes to a temporary file first, so a crash mid-copy never leaves a
  /// half-written database behind.
  Future<void> _copyAsset(File target) async {
    final watch = Stopwatch()..start();
    final ByteData data;
    try {
      data = await loadAsset(ContentDbConfig.assetPath);
    } catch (e) {
      throw ContentDatabaseException(
        '${ContentDbConfig.assetPath} is missing from the build. '
        'Run the pipeline first: see app/README.md',
        e,
      );
    }
    await target.parent.create(recursive: true);
    final temp = File('${target.path}.tmp');
    await temp.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
    if (target.existsSync()) await target.delete();
    await temp.rename(target.path);
    AppLog.info(_tag, 'copied ${(data.lengthInBytes / 1e6).toStringAsFixed(1)} MB in ${watch.elapsedMilliseconds} ms');
  }
}
