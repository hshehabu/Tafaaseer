import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Fresh, empty, in-memory preferences for one test.
Future<SharedPreferencesWithCache> createTestPreferences() {
  SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  return SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
}
