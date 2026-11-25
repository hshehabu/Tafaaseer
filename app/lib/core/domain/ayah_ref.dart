import 'package:flutter/foundation.dart';

/// A surah:ayah reference. Shared by every feature, so it lives in core.
@immutable
class AyahRef {
  const AyahRef(this.surah, this.ayah);

  final int surah;
  final int ayah;

  /// Parses "2:255", "٢:٢٥٥" or "2 255". Returns null for anything else.
  static AyahRef? tryParse(String input) {
    final western = input.trim().replaceAllMapped(
      RegExp('[٠-٩]'),
      (m) => (m[0]!.codeUnitAt(0) - 0x0660).toString(),
    );
    final match = RegExp(r'^(\d{1,3})\s*[:\s/.-]\s*(\d{1,3})$').firstMatch(western);
    if (match == null) return null;
    return AyahRef(int.parse(match[1]!), int.parse(match[2]!));
  }

  /// Compact form used in storage: "2:255".
  String get key => '$surah:$ayah';

  @override
  bool operator ==(Object other) => other is AyahRef && other.surah == surah && other.ayah == ayah;

  @override
  int get hashCode => Object.hash(surah, ayah);

  @override
  String toString() => key;
}
