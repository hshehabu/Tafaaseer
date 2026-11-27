import 'package:flutter/scheduler.dart';

/// Frame-time recorder for measuring smoothness on a real phone.
///
/// Off unless the app is built with `--dart-define=TAFASEER_PERF=true`, so
/// normal builds pay nothing. When on, it prints a summary to the Android log
/// (`adb logcat -s flutter`) every [_window] frames: UI-thread (build/layout)
/// and raster (drawing) times, and how many frames missed the 60 fps budget.
abstract final class FrameStats {
  static const enabled = bool.fromEnvironment('TAFASEER_PERF');
  static const _window = 120;
  static const _budgetUs = 16667; // 60 fps

  static final _ui = <int>[];
  static final _raster = <int>[];

  static void start() {
    if (!enabled) return;
    SchedulerBinding.instance.addTimingsCallback((timings) {
      for (final t in timings) {
        _ui.add(t.buildDuration.inMicroseconds);
        _raster.add(t.rasterDuration.inMicroseconds);
      }
      if (_ui.length >= _window) _report();
    });
  }

  static void _report() {
    String line(String name, List<int> us) {
      final sorted = [...us]..sort();
      double pct(double p) => sorted[((sorted.length - 1) * p).round()] / 1000;
      final over = us.where((v) => v > _budgetUs).length;
      return '$name p50 ${pct(0.5).toStringAsFixed(1)} p90 ${pct(0.9).toStringAsFixed(1)} '
          'p99 ${pct(0.99).toStringAsFixed(1)} max ${pct(1).toStringAsFixed(1)} ms, over 16.7 ms: $over';
    }

    // ignore: avoid_print
    print('[tafaseer.perf] ${_ui.length} frames | ${line('ui', _ui)} | ${line('raster', _raster)}');
    _ui.clear();
    _raster.clear();
  }
}
