import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

/// A bottom sheet whose height changes only when the reader drags its handle,
/// never because the text inside scrolls: long tafsirs scroll within the sheet.
///
/// The one exception is the keyboard (writing a note): the sheet then opens
/// to full height and keeps its content above the keyboard.
class HandleSizedSheet extends StatefulWidget {
  const HandleSizedSheet({super.key, required this.builder});

  /// Builds the content; it scrolls with the given controller.
  final Widget Function(BuildContext context, ScrollController scrollController) builder;

  @override
  State<HandleSizedSheet> createState() => _HandleSizedSheetState();
}

class _HandleSizedSheetState extends State<HandleSizedSheet> {
  static const _half = 0.55;
  static const _full = 1.0;
  static const _min = 0.25;

  /// A drag that moves the sheet less than this (as a share of the screen) is ignored.
  static const _nudge = 0.02;

  /// Pulling down this far from half height closes the sheet.
  static const _closePull = 0.1;

  final _scroll = ScrollController();
  double _size = _half;
  bool _dragging = false;

  /// The text is being pulled past its top or end, which resizes the sheet.
  bool _pulling = false;

  /// The height when the current drag or pull began.
  double _startSize = _half;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Pulling the text past its top shrinks the sheet (and can close it); pushing
  /// it past its end grows the sheet. In between, the text just scrolls.
  bool _onScroll(ScrollNotification n, double maxHeight) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    if (n is OverscrollNotification && n.dragDetails != null && MediaQuery.viewInsetsOf(context).bottom == 0) {
      setState(() {
        if (!_pulling) _startSize = _size;
        _pulling = true;
        _dragging = true;
        _size = (_size + n.overscroll / maxHeight).clamp(_min, _full);
      });
    } else if (n is ScrollEndNotification && _pulling) {
      _pulling = false;
      _onDragEnd(DragEndDetails(primaryVelocity: n.dragDetails?.primaryVelocity ?? 0));
    }
    return false;
  }

  /// Snaps by direction, so one pull is enough: any pull up opens the sheet
  /// fully; a pull down returns it to half height, or closes it when pulled
  /// far enough down from half (or flicked down hard).
  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0; // positive = downwards
    final moved = _size - _startSize;
    setState(() {
      _dragging = false;
      final up = moved > _nudge || velocity < -700;
      final down = moved < -_nudge || velocity > 700;
      if (up) {
        _size = _full;
      } else if (down) {
        final fromHalfOrLower = _startSize <= _half + 0.01;
        if (fromHalfOrLower && (moved < -_closePull || velocity > 1500)) {
          Navigator.of(context).maybePop();
          return;
        }
        _size = _half;
      } else {
        _size = _startSize; // a small nudge: stay where it was
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final palette = AppPalette.of(context);

    return LayoutBuilder(
      builder: (context, box) {
        final size = keyboard > 0 ? _full : _size;
        return AnimatedContainer(
          duration: _dragging ? Duration.zero : const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: box.maxHeight * size,
          child: Column(
            children: [
              // The handle. Pulling the text past its top or end resizes the sheet too (_onScroll).
              Semantics(
                label: MaterialLocalizations.of(context).modalBarrierDismissLabel,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragStart: (_) => setState(() {
                    _dragging = true;
                    _startSize = _size;
                  }),
                  onVerticalDragUpdate: (d) =>
                      setState(() => _size = (_size - d.delta.dy / box.maxHeight).clamp(_min, _full)),
                  onVerticalDragEnd: _onDragEnd,
                  onTap: () => setState(() => _size = _size < _full ? _full : _half),
                  child: SizedBox(
                    height: 28,
                    width: double.infinity,
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: palette.secondaryBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: keyboard),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (n) => _onScroll(n, box.maxHeight),
                    // Clamping physics on every platform, so pulling past an end
                    // reports an overscroll (which resizes the sheet) instead of bouncing.
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        // Always scrollable, so a short tafsir that fits can still be pulled.
                        physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      ),
                      child: widget.builder(context, _scroll),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
