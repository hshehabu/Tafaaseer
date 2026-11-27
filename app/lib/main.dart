import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/logging/app_log.dart';
import 'core/logging/frame_stats.dart';
import 'core/storage/preferences_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FrameStats.start(); // no-op unless built with --dart-define=TAFASEER_PERF=true

  // Preferences are tiny and needed for the first frame (theme, font sizes).
  final preferences = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(),
  );

  runApp(
    ProviderScope(
      overrides: [preferencesProvider.overrideWithValue(preferences)],
      observers: const [AppProviderObserver()],
      // Everything is local: a failure will not fix itself by retrying.
      retry: (_, _) => null,
      child: const TafaseerApp(),
    ),
  );
}
