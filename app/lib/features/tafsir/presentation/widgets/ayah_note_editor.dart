import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/domain/ayah_ref.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../notes/presentation/providers/notes_providers.dart';

/// The reader's own note on one ayah. Saves as they type (after a short
/// pause) and when the sheet closes. Clearing the text removes the note.
class AyahNoteEditor extends ConsumerStatefulWidget {
  const AyahNoteEditor({super.key, required this.ayah});

  final AyahRef ayah;

  @override
  ConsumerState<AyahNoteEditor> createState() => _AyahNoteEditorState();
}

class _AyahNoteEditorState extends ConsumerState<AyahNoteEditor> {
  late final TextEditingController _text;

  // Read once up front: the final save happens in dispose(), where reading providers isn't allowed.
  late final NotesController _notes;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: ref.read(noteProvider(widget.ayah)));
    _notes = ref.read(notesProvider.notifier);
  }

  void _save() => _notes.write(widget.ayah, _text.text);

  @override
  void dispose() {
    _saveTimer?.cancel();
    _save();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: TextField(
        controller: _text,
        autofocus: _text.text.isEmpty,
        minLines: 6,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(fontFamily: UiFonts.reading, fontSize: 17, height: 1.8, color: palette.body),
        decoration: const InputDecoration(hintText: AppStrings.noteHint),
        onChanged: (_) {
          _saveTimer?.cancel();
          _saveTimer = Timer(const Duration(milliseconds: 400), _save);
        },
      ),
    );
  }
}
