import 'package:flutter/material.dart';

class ScrollToBottomController extends ScrollController {
  ScrollToBottomController({
    @required Listenable listenable,
    double initialScrollOffset = 0.0,
    bool keepScrollOffset = false,
    String debugLabel,
    int duration,
  })  : _listenable = listenable,
        _duration = duration,
        super(
          initialScrollOffset: initialScrollOffset,
          keepScrollOffset: keepScrollOffset,
          debugLabel: debugLabel,
        );

  final Listenable _listenable;
  bool _attached = false;
  int _duration;

  @override
  void attach(ScrollPosition position) {
    super.attach(position);
    if (!_attached) {
      _listenable.addListener(_onListenerChanged);
      _attached = true;
    }
  }

  @override
  void detach(ScrollPosition position) {
    if (_attached) {
      _listenable.removeListener(_onListenerChanged);
      _attached = false;
    }
    super.detach(position);
  }

  @override
  void dispose() {
    _listenable.removeListener(_onListenerChanged);
    super.dispose();
  }

  void _onListenerChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (position != null && position.maxScrollExtent != null) {
          print('ScrollController - scrolling to bottom');
          animateTo(
            position.maxScrollExtent,
            curve: Curves.easeInOut,
            duration: Duration(milliseconds: _duration),
          );
        }
      } catch (e) {
        print('$e');
      }
    });
  }
}
