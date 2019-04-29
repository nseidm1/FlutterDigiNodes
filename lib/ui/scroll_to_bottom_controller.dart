import 'package:flutter/material.dart';

class ScrollToBottomController extends ScrollController {
  ScrollToBottomController({
    double initialScrollOffset = 0.0,
    bool keepScrollOffset = false,
    String debugLabel,
    int duration,
  })  : _duration = duration,
        super(
          initialScrollOffset: initialScrollOffset,
          keepScrollOffset: keepScrollOffset,
          debugLabel: debugLabel,
        );

  int _duration = 0;
  bool _attached = false;

  @override
  void attach(ScrollPosition position) {
    _attached = true;
    super.attach(position);
  }

  @override
  void detach(ScrollPosition position) {
    _attached = false;
    super.detach(position);
  }

  @override
  void dispose() {
    _attached = false;
    super.dispose();
  }

  void scrollToBottom() {
    if (_attached && position != null && position.maxScrollExtent != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        animateTo(
          position.maxScrollExtent,
          curve: Curves.easeInOut,
          duration: Duration(milliseconds: _duration),
        );
      });
    }
  }
}
