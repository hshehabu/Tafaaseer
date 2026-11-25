import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One place for logs. Every line is tagged, e.g. `[tafaseer.db] copied in 812 ms`,
/// so `flutter run` output can be filtered with the tag.
abstract final class AppLog {
  static void info(String tag, String message) {
    developer.log(message, name: 'tafaseer.$tag');
    if (kDebugMode) debugPrint('[tafaseer.$tag] $message');
  }

  static void error(String tag, String message, [Object? error, StackTrace? stack]) {
    developer.log(message, name: 'tafaseer.$tag', error: error, stackTrace: stack, level: 1000);
    if (kDebugMode) debugPrint('[tafaseer.$tag] ERROR $message${error == null ? '' : ': $error'}');
  }

  /// Runs [body] and logs how long it took. Use it around anything that might be slow.
  static T timed<T>(String tag, String label, T Function() body) {
    final watch = Stopwatch()..start();
    final result = body();
    info(tag, '$label in ${watch.elapsedMicroseconds / 1000} ms');
    return result;
  }
}

/// Logs every provider that fails, with the provider's name.
final class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver();

  @override
  void providerDidFail(ProviderObserverContext context, Object error, StackTrace stackTrace) {
    AppLog.error('provider', '${context.provider} failed', error, stackTrace);
  }
}
