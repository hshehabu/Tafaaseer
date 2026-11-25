import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_strings.dart';
import '../features/quran/presentation/pages/home_page.dart';
import '../features/settings/presentation/settings_providers.dart';
import 'startup/app_startup.dart';
import 'theme/app_theme.dart';

class TafaseerApp extends ConsumerWidget {
  const TafaseerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (light, dark, mode) = AppTheme.forPreference(ref.watch(settingsProvider.select((s) => s.theme)));
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      // Arabic only (A3): right-to-left layout everywhere.
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: light,
      darkTheme: dark,
      themeMode: mode,
      home: const StartupGate(child: HomePage()),
    );
  }
}
