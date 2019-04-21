import 'dart:io';

import 'package:diginodes/backend/backend.dart';
import 'package:diginodes/domain/node_list.dart';
import 'package:diginodes/logic/home_logic.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

class OpenScanner {

  static final instance = OpenScanner();

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

  int _currentMaxIndex() {
    int currentMaxIndex = _indexes.fold(0, (prev, element) => math.max(prev, element.value));
    if (currentMaxIndex < HomeLogic.instance.nodes.length - 1) {
      return currentMaxIndex;
    } else {
      return -1;
    }
  }

  void start() {
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

  void _startScanner(int index) async {
    if (HomeLogic.instance.nodes.length == 0) {
      if (!_shutdown) {
        await new Future.delayed(const Duration(seconds: 1));
        _startScanner(index);
      }
      return;
    }
    _indexes[index].value = _currentMaxIndex() + 1;
    Node nextNode = HomeLogic.instance.nodes[_indexes[index].value];
    if (!nextNode.open) {
      bool open = await NodeService.instance.checkNode(nextNode);
      nextNode.open = open;
      if (open) {
        _openCount.value++;
      }
    }
    if (!_shutdown) {
      await new Future.delayed(const Duration(seconds: 1));
      _startScanner(index);
    }
  }
}