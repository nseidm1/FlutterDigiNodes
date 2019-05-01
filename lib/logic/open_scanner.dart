import 'package:diginodes/backend/backend.dart';
import 'package:diginodes/domain/node_list.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

class OpenScanner {
  OpenScanner({
    @required NodeSet nodes,
  }) : _nodes = nodes;

  static const SUPER_DELAY = 5000;
  static const LONGEST_DELAY = 2500;
  static const LONG_DELAY = 1500;
  static const MEDIUM_DELAY = 1000;
  static const SHORT_DELAY = 750;

  final NodeSet _nodes;
  final _indexes = [
    ValueNotifier<int>(0),
    ValueNotifier<int>(0),
    ValueNotifier<int>(0),
    ValueNotifier<int>(0),
    ValueNotifier<int>(0),
    ValueNotifier<int>(0)
  ];
  final _openCount = new ValueNotifier<int>(0);

  ValueListenable<int> get one => _indexes[0];
  ValueListenable<int> get two => _indexes[1];
  ValueListenable<int> get three => _indexes[2];
  ValueListenable<int> get four => _indexes[3];
  ValueListenable<int> get five => _indexes[4];
  ValueListenable<int> get six => _indexes[5];

  bool _shutdown = false;
  bool _running = false;

  ValueListenable<int> get openCount => _openCount;

  int get _nodeCount => _nodes.length;

  int _currentMaxIndex(int index) {
    final currentMaxIndex = _indexes.fold<int>(0, (prev, el) => math.max(prev, el.value));
    if (currentMaxIndex < _nodeCount - 1) {
      return currentMaxIndex;
    } else {
      return (index).clamp(0, _nodeCount - 1) - 1;
    }
  }

  Future<void> start() async {
    if (_running) {
      return;
    }
    _running = true;
    _startScanner(0);
    _startScanner(1);
    _startScanner(2);
    _startScanner(3);
    _startScanner(4);
    _startScanner(5);
  }

  void shutdown() {
    _shutdown = true;
  }

  void clear() {
    _indexes.forEach((i) => i.value = 0);
    _openCount.value = 0;
  }

  Future<void> _startScanner(int index) async {
    if (_nodeCount != 0) {
      _indexes[index].value = _currentMaxIndex(index) + 1;
      await Future.delayed(Duration(milliseconds: 10 * (index + 1)));
      final nextNode = _nodes[_indexes[index].value];
      if (!nextNode.open) {
        if (await NodeService.instance.checkNode(nextNode)) {
          if (!nextNode.open) {
            nextNode.open = true;
            _openCount.value++;
          }
        }
      }
    }
    if (!_shutdown) {
      int milliseconds;
      if (_nodeCount < 25) {
        milliseconds = SUPER_DELAY;
      } else if (_nodeCount < 100) {
        milliseconds = LONGEST_DELAY;
      } else if (_nodeCount < 1000) {
        milliseconds = LONG_DELAY;
      } else if (_nodeCount < 5000) {
        milliseconds = MEDIUM_DELAY;
      } else {
        milliseconds = SHORT_DELAY;
      }
      await Future.delayed(Duration(milliseconds: milliseconds));
      _startScanner(index);
    }
  }
}
