import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small key-value user data (settings, bookmarks, reading position).
///
/// Created in main() before runApp so reads are synchronous everywhere, then
/// injected with an override. User data never goes into the content database,
/// which is replaced on app updates.
final preferencesProvider = Provider<SharedPreferencesWithCache>(
  (ref) => throw UnimplementedError('preferencesProvider is overridden in main()'),
);
