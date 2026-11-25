import 'package:flutter/foundation.dart';

import '../../../../core/domain/ayah_ref.dart';

@immutable
class Bookmark {
  const Bookmark({required this.ref, required this.createdAt});

  final AyahRef ref;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) => other is Bookmark && other.ref == ref && other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(ref, createdAt);
}
