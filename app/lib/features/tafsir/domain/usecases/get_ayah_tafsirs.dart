import 'package:flutter/foundation.dart';

import '../entities/tafsir_entry.dart';
import '../repositories/tafsir_repository.dart';

@immutable
class AyahTafsirs {
  const AyahTafsirs({required this.entries, required this.initialIndex});

  final List<TafsirEntry> entries;

  /// The pill selected when the sheet opens.
  final int initialIndex;

  bool get isEmpty => entries.isEmpty;
}

/// Loads the pills for an ayah and picks the one to open first:
/// always the default tafsir (al-Muyassar, decision E4), else the first.
class GetAyahTafsirs {
  const GetAyahTafsirs(this._repository);

  final TafsirRepository _repository;

  Future<AyahTafsirs> call(int ayahId) async {
    final entries = await _repository.getEntriesForAyah(ayahId);
    final defaultIndex = entries.indexWhere((e) => e.source.isDefault);
    return AyahTafsirs(entries: entries, initialIndex: defaultIndex < 0 ? 0 : defaultIndex);
  }
}
