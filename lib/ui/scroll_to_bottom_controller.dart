import 'package:flutter/material.dart';

class ScrollToBottomController extends ScrollController {
  ScrollToBottomController({
    @required Listenable listenable,
    double initialScrollOffset = 0.0,
    bool keepScrollOffset = true,
    String debugLabel,
  })  : _listenable = listenable,
        super(
          initialScrollOffset: initialScrollOffset,
          keepScrollOffset: keepScrollOffset,
          debugLabel: debugLabel,
        );

  final Listenable _listenable;
  bool _attached = false;

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
      if (position.maxScrollExtent != null && position.extentAfter < 64.0) {
        animateTo(
          position.maxScrollExtent,
          curve: Curves.easeOutBack,
          duration: Duration(milliseconds: 500),
        );
      }
    });
  }
}
