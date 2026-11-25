import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../storage/preferences_provider.dart';
import 'content_database.dart';
import 'content_database_loader.dart';

/// Loads the content database. Watched once, by the startup gate.
final contentDatabaseProvider = FutureProvider<ContentDatabase>((ref) async {
  final loader = ContentDatabaseLoader(
    loadAsset: rootBundle.load,
    directory: getApplicationCacheDirectory,
    preferences: ref.watch(preferencesProvider),
  );
  final db = await loader.load();
  ref.onDispose(db.close);
  return db;
});

/// Synchronous access for repositories.
///
/// Only read this below the startup gate (lib/app/startup), which renders the
/// app only after [contentDatabaseProvider] has loaded. Tests override it with
/// an in-memory database.
final readyContentDatabaseProvider = Provider<ContentDatabase>(
  (ref) => ref.watch(contentDatabaseProvider).requireValue,
);
