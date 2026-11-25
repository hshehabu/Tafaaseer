import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/ayah_ref.dart';
import '../../../../core/l10n/app_strings.dart';
import '../providers/quran_providers.dart';

/// Asks for "surah:ayah" and returns a reference that exists, or null (D4).
Future<AyahRef?> showJumpToAyahDialog(BuildContext context) =>
    showDialog<AyahRef>(context: context, builder: (_) => const _JumpToAyahDialog());

class _JumpToAyahDialog extends ConsumerStatefulWidget {
  const _JumpToAyahDialog();

  @override
  ConsumerState<_JumpToAyahDialog> createState() => _JumpToAyahDialogState();
}

class _JumpToAyahDialogState extends ConsumerState<_JumpToAyahDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final surahs = ref.read(surahsProvider).value ?? const [];
    final target = ref.read(resolveAyahRefProvider)(_controller.text, surahs);
    if (target == null) {
      setState(() => _error = AppStrings.jumpInvalid);
      return;
    }
    Navigator.of(context).pop(target);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.jumpToAyah),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.datetime, // digits plus ":" on most keyboards
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        decoration: InputDecoration(hintText: AppStrings.jumpHint, errorText: _error, errorMaxLines: 2),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text(AppStrings.cancel)),
        FilledButton(onPressed: _submit, child: const Text(AppStrings.go)),
      ],
    );
  }
}
