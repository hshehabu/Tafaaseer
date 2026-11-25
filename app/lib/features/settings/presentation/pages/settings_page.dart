import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/arabic/arabic_text.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/reader_settings.dart';
import '../settings_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static Route<void> route() => MaterialPageRoute(builder: (_) => const SettingsPage());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListTile(title: Text(AppStrings.theme, style: theme.textTheme.titleSmall)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemePreference>(
              segments: const [
                ButtonSegment(value: ThemePreference.system, label: Text(AppStrings.themeSystem)),
                ButtonSegment(value: ThemePreference.light, label: Text(AppStrings.themeLight)),
                ButtonSegment(value: ThemePreference.sepia, label: Text(AppStrings.themeSepia)),
                ButtonSegment(value: ThemePreference.dark, label: Text(AppStrings.themeDark)),
              ],
              selected: {settings.theme},
              onSelectionChanged: (s) => controller.update((c) => c.copyWith(theme: s.first)),
            ),
          ),
          const SizedBox(height: 12),
          _SliderTile(
            label: AppStrings.tafsirFontSize,
            value: settings.tafsirFontSize,
            range: ReaderSettings.tafsirFontRange,
            display: toArabicDigits(settings.tafsirFontSize.round()),
            onChanged: (v) => controller.update((c) => c.copyWith(tafsirFontSize: v)),
          ),
          _SliderTile(
            label: AppStrings.tafsirLineHeight,
            value: settings.tafsirLineHeight,
            range: ReaderSettings.lineHeightRange,
            display: toArabicDecimal(settings.tafsirLineHeight, 1),
            onChanged: (v) => controller.update((c) => c.copyWith(tafsirLineHeight: v)),
          ),
          SwitchListTile(
            title: const Text(AppStrings.showTashkeel),
            value: settings.showTashkeel,
            onChanged: (v) => controller.update((c) => c.copyWith(showTashkeel: v)),
          ),
          SwitchListTile(
            title: const Text(AppStrings.hideIsnad),
            subtitle: const Text(AppStrings.hideIsnadHint),
            value: settings.hideIsnad,
            onChanged: (v) => controller.update((c) => c.copyWith(hideIsnad: v)),
          ),
          const Divider(height: 32),
          ListTile(
            title: Text(AppStrings.sources, style: theme.textTheme.titleSmall),
            subtitle: const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(AppStrings.sourcesBody),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.value,
    required this.range,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ({double min, double max}) range;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Text(display),
      subtitle: Slider(
        value: value.clamp(range.min, range.max),
        min: range.min,
        max: range.max,
        onChanged: onChanged,
      ),
    );
  }
}
