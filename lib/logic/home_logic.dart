import 'dart:async';

import 'package:diginodes/backend/backend.dart';
import 'package:diginodes/coin_definitions.dart';
import 'package:diginodes/domain/node_list.dart';
import 'package:flutter/foundation.dart';
import 'package:diginodes/logic/open_scanner.dart';

class HomeLogic {

  static HomeLogic instance = HomeLogic();

  final _coinDefinition = ValueNotifier<Definition>(null);
  final _loadingDNS = ValueNotifier<bool>(false);
  final _nodes = NodeSet();

  ValueListenable<bool> get loadingDNS => _loadingDNS;
  ValueListenable<Definition> get coinDefinition => _coinDefinition;
  NodeSet get nodes => _nodes;

  int get nodesCount => _nodes.length;

  OpenScanner _openScanner = OpenScanner.instance;
  OpenScanner get openScanner => _openScanner;

  HomeLogic() {
    _coinDefinition.addListener(_onCoinDefinitionChanged);
    _coinDefinition.value = coinDefinitions[0];
  }

  Future<void> _onCoinDefinitionChanged() async {
    _loadingDNS.value = true;
    _nodes.clear();
    _openScanner.reset();
    _nodes.addAll(await NodeService.instance.startDiscovery(_coinDefinition.value));
    _openScanner.start();
    _loadingDNS.value = false;
  }

  checkOpenState(Node node) {

  }

  void onShareButtonPressed() {
    //
  }

  void onAddManualNodePressed() {

  }
}