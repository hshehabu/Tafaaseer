import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_providers.dart';
import '../../core/fonts/quran_font_loader.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/logging/app_log.dart';

/// Everything that must be ready before the first real screen:
/// the content database (copied on first launch) and the Quran font.
final appStartupProvider = FutureProvider<void>((ref) async {
  final watch = Stopwatch()..start();
  await Future.wait([ref.watch(contentDatabaseProvider.future), loadQuranFonts()]);
  AppLog.info('startup', 'ready in ${watch.elapsedMilliseconds} ms');
});

/// Shows [child] once startup finished; a progress or error screen before that.
class StartupGate extends ConsumerWidget {
  const StartupGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(appStartupProvider)) {
      AsyncData() => child,
      AsyncError(:final error) => _StartupError(
        error: error,
        onRetry: () {
          ref.invalidate(contentDatabaseProvider);
          ref.invalidate(appStartupProvider);
        },
      ),
      _ => const _StartupProgress(),
    };
  }
}

class _StartupProgress extends StatelessWidget {
  const _StartupProgress();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(AppStrings.preparing, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(AppStrings.preparingFirstRun, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppStrings.startupFailed, style: Theme.of(context).textTheme.titleMedium),
              // The technical reason only in debug builds, where it helps.
              if (kDebugMode) ...[
                const SizedBox(height: 12),
                SelectableText('$error', textDirection: TextDirection.ltr, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              FilledButton(onPressed: onRetry, child: const Text(AppStrings.retry)),
            ],
          ),
        ),
      ),
    );
  }
}
