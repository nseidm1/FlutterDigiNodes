import 'dart:async';

import 'package:diginodes/backend/backend.dart';
import 'package:diginodes/coin_definitions.dart';
import 'package:diginodes/domain/node_list.dart';
import 'package:flutter/foundation.dart';
import 'package:isolate/runner.dart';
import 'package:diginodes/logic/open_scanner.dart';

class HomeLogic {

  static HomeLogic instance = HomeLogic();

  final coinDefinition = ValueNotifier<Definition>(null);
  final _loadingDNS = ValueNotifier<bool>(false);
  final _nodes = NodeSet();
  var _recentsCount = 0;
  var _nodeCheckIndex = ValueNotifier<int>(0);
  var runners = List<Runner>();

  ValueListenable<bool> get loadingDNS => _loadingDNS;
  ValueListenable<int> get nodeCheckIndex => _nodeCheckIndex;
  NodeSet get nodes => _nodes;

  int get recentsCount => _recentsCount;
  int get nodesCount => _nodes.length;

  OpenScanner _openScanner = OpenScanner.instance;
  OpenScanner get openScanner => _openScanner;

  HomeLogic() {
    coinDefinition.addListener(_onCoinDefinitionChanged);
    coinDefinition.value = coinDefinitions[0];
  }

  Future<void> _onCoinDefinitionChanged() async {
    _loadingDNS.value = true;
    final nodes = await NodeService.instance.startDiscovery(coinDefinition.value);
    _nodes.addAll(nodes);
    _openScanner.start();
    _loadingDNS.value = false;
  }

  Node getNextNode() {
    if (_nodeCheckIndex == nodes.length - 1) {
      _nodeCheckIndex.value = 0;
    } else {
      _nodeCheckIndex.value++;
    }
    return nodes[_nodeCheckIndex.value];
  }

  checkOpenState(Node node) {

  }

  void onShareButtonPressed() {
    //
  }

  void onAddManualNodePressed() {

  }
}