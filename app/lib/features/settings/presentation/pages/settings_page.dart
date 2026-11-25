import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/arabic/arabic_text.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_palette.dart';
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
            child: _ThemeOptions(
              selected: settings.theme,
              onSelected: (t) => controller.update((c) => c.copyWith(theme: t)),
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
          _TafsirPreview(settings: settings),
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
            subtitle: const Padding(padding: EdgeInsets.only(top: 8), child: Text(AppStrings.sourcesBody)),
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
      subtitle: Slider(value: value.clamp(range.min, range.max), min: range.min, max: range.max, onChanged: onChanged),
    );
  }
}

/// The four theme options as plain text boxes, each in the colours of the
/// theme it switches to. "تلقائي" has no colours of its own (it follows the
/// phone's light or dark mode), so it is a plain box with an auto icon.
class _ThemeOptions extends StatelessWidget {
  const _ThemeOptions({required this.selected, required this.onSelected});

  final ThemePreference selected;
  final ValueChanged<ThemePreference> onSelected;

  static const _options = [
    (ThemePreference.system, AppStrings.themeSystem),
    (ThemePreference.light, AppStrings.themeLight),
    (ThemePreference.sepia, AppStrings.themeSepia),
    (ThemePreference.dark, AppStrings.themeDark),
  ];

  @override
  Widget build(BuildContext context) {
    final current = AppPalette.of(context);
    return Row(
      children: [
        for (final (i, (pref, label)) in _options.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _ThemeTile(
              preference: pref,
              label: label,
              selected: pref == selected,
              accent: current.primary,
              onTap: () => onSelected(pref),
            ),
          ),
        ],
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.preference,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final ThemePreference preference;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (light, dark) = (AppPalette.light, AppPalette.dark);
    final palette = switch (preference) {
      // Automatic has no look of its own: it uses the screen's current colours.
      ThemePreference.system => AppPalette.of(context),
      ThemePreference.light => light,
      ThemePreference.sepia => AppPalette.sepia,
      ThemePreference.dark => dark,
    };
    final radius = BorderRadius.circular(AppPalette.radius);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: selected ? accent : palette.border, width: selected ? 2 : 1),
            // Automatic takes the softer control shade, so it never looks like the dark box beside it.
            color: preference == ThemePreference.system ? palette.controlSurface : palette.canvas,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (preference == ThemePreference.system) ...[
                Icon(Icons.brightness_auto_outlined, size: 17, color: palette.title),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: palette.title,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two lines of tafsir in the chosen size, line spacing and diacritics, so the
/// sliders can be judged without opening a tafsir.
class _TafsirPreview extends StatelessWidget {
  const _TafsirPreview({required this.settings});

  final ReaderSettings settings;

  static const _quote = 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ';
  static const _bracket = TextStyle(
    fontFamily: QuranFontConfig.family,
    fontFamilyFallback: QuranFontConfig.fallback,
    fontWeight: FontWeight.w400,
  );
  static const _text =
      ' الثَّنَاءُ عَلَى اللَّهِ بِصِفَاتِهِ الَّتِي كُلُّهَا أَوْصَافُ كَمَالٍ، وَبِنِعَمِهِ الظَّاهِرَةِ وَالْبَاطِنَةِ.';

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    String show(String t) => settings.showTashkeel ? t : stripTashkeel(t);
    final base = TextStyle(
      fontFamily: UiFonts.reading,
      fontSize: settings.tafsirFontSize,
      height: settings.tafsirLineHeight,
      color: palette.body,
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: palette.controlSurface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(AppPalette.radius),
      ),
      child: Text.rich(
        TextSpan(
          style: base,
          children: [
            // Brackets in the Hafs font, as in the tafsir sheet (Noto Naskh draws them like "·{").
            TextSpan(
              style: TextStyle(color: palette.primary, fontWeight: FontWeight.w600),
              children: [
                const TextSpan(text: '﴿', style: _bracket),
                TextSpan(text: show(_quote)),
                const TextSpan(text: '﴾', style: _bracket),
              ],
            ),
            TextSpan(text: show(_text)),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
