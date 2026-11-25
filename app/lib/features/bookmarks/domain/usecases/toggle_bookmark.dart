import '../../../../core/domain/ayah_ref.dart';
import '../entities/bookmark.dart';

/// Adds the ayah to the top of the list, or removes it if it is already there.
class ToggleBookmark {
  const ToggleBookmark({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  List<Bookmark> call(List<Bookmark> current, AyahRef ref) {
    final without = current.where((b) => b.ref != ref).toList();
    if (without.length != current.length) return without;
    return [Bookmark(ref: ref, createdAt: _clock()), ...current];
  }
}
