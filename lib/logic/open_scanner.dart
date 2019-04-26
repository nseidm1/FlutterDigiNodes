import 'package:diginodes/backend/backend.dart';
import 'package:diginodes/domain/node_list.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

typedef OpenNodeAdded = void Function(Node bode);

class OpenScanner {
  OpenScanner({
    @required NodeSet nodes,
    OpenNodeAdded added,
  })  : _nodes = nodes,
        _added = added;

  final NodeSet _nodes;
  final OpenNodeAdded _added;

  final _indexes = [
    ValueNotifier<int>(0),
    ValueNotifier<int>(0),
    ValueNotifier<int>(0),
    ValueNotifier<int>(0),
    ValueNotifier<int>(0),
    ValueNotifier<int>(0)
  ];

  ValueListenable<int> get one => _indexes[0];
  ValueListenable<int> get two => _indexes[1];
  ValueListenable<int> get three => _indexes[2];
  ValueListenable<int> get four => _indexes[3];
  ValueListenable<int> get five => _indexes[4];
  ValueListenable<int> get six => _indexes[5];

  bool _shutdown = false;
  bool _running = false;

  ValueNotifier<int> _openCount = new ValueNotifier<int>(0);
  ValueListenable<int> get openCount => _openCount;

  int get _nodeCount => _nodes.length;

  void setDnsOpen(int count) {
    _openCount.value = count;
  }

  int _currentMaxIndex() {
    final currentMaxIndex = _indexes.fold<int>(0, (prev, el) => math.max(prev, el.value));
    if (currentMaxIndex < _nodeCount - 1) {
      return currentMaxIndex;
    } else {
      return -1;
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

  void reset() {
    _indexes.forEach((i) => i.value = 0);
  }

  Future<void> _startScanner(int index) async {
    if (_nodeCount != 0) {
      _indexes[index].value = _currentMaxIndex() + 1;
      Node nextNode = _nodes[_indexes[index].value];
      if (!nextNode.open) {
        bool open = await NodeService.instance.checkNode(nextNode);
        nextNode.open = open;
        if (open) {
          _added(nextNode);
          _openCount.value++;
        }
      }
    }
    if (!_shutdown) {
      int milliseconds;
      if (_nodeCount < 100) {
        milliseconds = 2500;
      } else if (_nodeCount < 1000) {
        milliseconds = 1500;
      } else if (_nodeCount < 5000) {
        milliseconds = 1000;
      } else {
        milliseconds = 750;
      }
      await Future.delayed(Duration(milliseconds: milliseconds));
      _startScanner(index);
    }
  }
}
