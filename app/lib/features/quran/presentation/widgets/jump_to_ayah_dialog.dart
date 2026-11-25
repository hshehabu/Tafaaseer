import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/ayah_ref.dart';
import '../../../../core/l10n/app_strings.dart';
import '../providers/quran_providers.dart';

/// Asks for a surah number and an ayah number and returns a reference that
/// exists, or null (D4). Two number fields, because many phone number pads
/// have no ":" key.
Future<AyahRef?> showJumpToAyahDialog(BuildContext context) =>
    showDialog<AyahRef>(context: context, builder: (_) => const _JumpToAyahDialog());

class _JumpToAyahDialog extends ConsumerStatefulWidget {
  const _JumpToAyahDialog();

  @override
  ConsumerState<_JumpToAyahDialog> createState() => _JumpToAyahDialogState();
}

class _JumpToAyahDialogState extends ConsumerState<_JumpToAyahDialog> {
  final _surah = TextEditingController();
  final _ayah = TextEditingController(text: '1');
  final _ayahFocus = FocusNode();
  String? _error;

  @override
  void dispose() {
    _surah.dispose();
    _ayah.dispose();
    _ayahFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final surahs = ref.read(surahsProvider).value ?? const [];
    final target = ref.read(resolveAyahRefProvider)('${_surah.text.trim()}:${_ayah.text.trim()}', surahs);
    if (target == null) {
      setState(() => _error = AppStrings.jumpInvalid);
      return;
    }
    Navigator.of(context).pop(target);
  }

  @override
  Widget build(BuildContext context) {
    final surahs = ref.watch(surahsProvider).value ?? const [];
    final surahNumber = int.tryParse(_surah.text.trim());
    final surahName = surahNumber != null && surahNumber >= 1 && surahNumber <= surahs.length
        ? surahs[surahNumber - 1].nameAr
        : null;

    InputDecoration decoration(String label) => InputDecoration(labelText: label, counterText: '');

    return AlertDialog(
      title: const Text(AppStrings.jumpToAyah),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _surah,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 3,
                  textAlign: TextAlign.center,
                  textInputAction: TextInputAction.next,
                  decoration: decoration(AppStrings.jumpSurah),
                  onChanged: (_) => setState(() => _error = null),
                  onSubmitted: (_) => _ayahFocus.requestFocus(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _ayah,
                  focusNode: _ayahFocus,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 3,
                  textAlign: TextAlign.center,
                  decoration: decoration(AppStrings.jumpAyah),
                  onChanged: (_) => setState(() => _error = null),
                  onSubmitted: (_) => _submit(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Confirms the surah as the reader types its number.
          Text(
            _error ?? (surahName == null ? AppStrings.jumpHint : AppStrings.surahPrefix(surahName)),
            style: TextStyle(
              color: _error == null ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text(AppStrings.cancel)),
        FilledButton(onPressed: _submit, child: const Text(AppStrings.go)),
      ],
    );
  }
}
