import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/preferences_provider.dart';
import '../data/settings_repository_impl.dart';
import '../domain/entities/reader_settings.dart';
import '../domain/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.watch(preferencesProvider)),
);

final settingsProvider = NotifierProvider<SettingsController, ReaderSettings>(SettingsController.new);

class SettingsController extends Notifier<ReaderSettings> {
  Timer? _saveTimer;

  @override
  ReaderSettings build() {
    ref.onDispose(() => _saveTimer?.cancel());
    return ref.watch(settingsRepositoryProvider).load();
  }

  /// Applies [change] immediately; saves after a short pause, so dragging a
  /// slider writes once instead of sixty times a second.
  void update(ReaderSettings Function(ReaderSettings current) change) {
    final next = change(state);
    if (next == state) return;
    state = next;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), () {
      ref.read(settingsRepositoryProvider).save(state).ignore();
    });
  }
}
