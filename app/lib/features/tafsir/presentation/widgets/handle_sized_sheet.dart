import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

/// The tafsir sheet's frame. It behaves like a standard draggable sheet:
/// scrolling the text up first lifts the sheet to full height, then scrolls
/// the text; pulling down at the top of the text lowers it, and from half
/// height closes it. The handle drags it too. When the keyboard opens (writing
/// a note) the sheet goes to full height with its content above the keyboard,
/// and returns to its previous height when the keyboard closes.
class HandleSizedSheet extends StatefulWidget {
  const HandleSizedSheet({super.key, required this.builder});

  /// Builds the content. Its scrollable must use the given controller, which
  /// is what lets scrolling move the sheet.
  final Widget Function(BuildContext context, ScrollController scrollController) builder;

  @override
  State<HandleSizedSheet> createState() => _HandleSizedSheetState();
}

class _HandleSizedSheetState extends State<HandleSizedSheet> {
  static const _half = 0.55;
  static const _full = 1.0;
  static const _min = 0.25;
  static const _motion = Duration(milliseconds: 220);

  final _sheet = DraggableScrollableController();
  bool _closing = false;
  bool _keyboardOpen = false;
  double _sizeBeforeKeyboard = _half;

  @override
  void initState() {
    super.initState();
    _sheet.addListener(_closeAtBottom);
  }

  @override
  void dispose() {
    _sheet
      ..removeListener(_closeAtBottom)
      ..dispose();
    super.dispose();
  }

  /// Pulled all the way down: close the sheet.
  void _closeAtBottom() {
    if (_closing || !_sheet.isAttached || _sheet.size > _min + 0.01) return;
    _closing = true;
    Navigator.of(context).maybePop();
  }

  void _animateTo(double size) {
    if (_sheet.isAttached) _sheet.animateTo(size, duration: _motion, curve: Curves.easeOut);
  }

  /// The keyboard opens to full height and closes back to where the sheet was.
  void _followKeyboard(bool open) {
    if (open == _keyboardOpen) return;
    _keyboardOpen = open;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sheet.isAttached) return;
      if (open) {
        _sizeBeforeKeyboard = _sheet.size;
        _animateTo(_full);
      } else {
        _animateTo(_sizeBeforeKeyboard);
      }
    });
  }

  /// Handle released: a flick goes where it points; otherwise the nearest stop.
  void _onHandleEnd(DragEndDetails details) {
    if (!_sheet.isAttached) return;
    final velocity = details.primaryVelocity ?? 0; // positive = downwards
    final size = _sheet.size;
    if (velocity < -300) return _animateTo(_full);
    if (velocity > 300) return size < _half + 0.02 ? _animateTo(_min) : _animateTo(_half);
    if (size < (_min + _half) / 2) return _animateTo(_min);
    _animateTo((size - _half).abs() < (size - _full).abs() ? _half : _full);
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    _followKeyboard(keyboard > 0);
    final palette = AppPalette.of(context);

    return LayoutBuilder(
      builder: (context, box) => DraggableScrollableSheet(
        controller: _sheet,
        expand: false,
        initialChildSize: _half,
        minChildSize: _min,
        maxChildSize: _full,
        snap: true,
        snapSizes: const [_half],
        builder: (context, scrollController) => Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (d) {
                if (_sheet.isAttached) {
                  _sheet.jumpTo((_sheet.size - d.delta.dy / box.maxHeight).clamp(_min, _full));
                }
              },
              onVerticalDragEnd: _onHandleEnd,
              onTap: () => _animateTo(_sheet.isAttached && _sheet.size < _full ? _full : _half),
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
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: keyboard),
                child: widget.builder(context, scrollController),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
