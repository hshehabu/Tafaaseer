import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:tafaseer/core/config/app_config.dart';
import 'package:tafaseer/core/database/content_database_loader.dart';
import 'package:tafaseer/core/error/app_exception.dart';

import '../helpers/content_db_fixture.dart';
import '../helpers/test_preferences.dart';

void main() {
  late Directory temp;
  late Uint8List assetBytes;
  var assetLoads = 0;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('tafaseer_loader_');
    final source = p.join(temp.path, 'asset.db');
    final db = sqlite3.open(source);
    populateFixture(db);
    db.close();
    assetBytes = File(source).readAsBytesSync();
    assetLoads = 0;
  });

  tearDown(() => temp.deleteSync(recursive: true));

  Future<ContentDatabaseLoader> loader({Uint8List? bytes}) async => ContentDatabaseLoader(
    loadAsset: (_) async {
      assetLoads++;
      return ByteData.sublistView(bytes ?? assetBytes);
    },
    directory: () async => Directory(p.join(temp.path, 'cache')),
    preferences: await createTestPreferences(),
  );

  test('copies once, then opens the existing copy', () async {
    final first = await loader();
    (await first.load()).close();
    expect(assetLoads, 1);

    (await first.load()).close();
    expect(assetLoads, 1, reason: 'second launch must not copy again');
  });

  test('copies again when the existing file is corrupt', () async {
    final l = await loader();
    (await l.load()).close();
    File(p.join(temp.path, 'cache', ContentDbConfig.fileName)).writeAsStringSync('not a database');

    final db = await l.load();
    expect(db.schemaVersion, ContentDbConfig.schemaVersion);
    db.close();
    expect(assetLoads, 2);
  });

  test('a corrupt asset fails with a clear error', () async {
    final l = await loader(bytes: Uint8List.fromList(List.filled(4096, 7)));
    await expectLater(l.load(), throwsA(isA<ContentDatabaseException>()));
  });
}
