import 'package:flutter/foundation.dart';

import '../../../../core/domain/ayah_ref.dart';

/// Where one of the 60 hizbs begins. Two hizbs make a juz.
@immutable
class HizbStart {
  const HizbStart({required this.hizb, required this.juz, required this.ref, required this.surahName});

  final int hizb;
  final int juz;
  final AyahRef ref;
  final String surahName;
}
