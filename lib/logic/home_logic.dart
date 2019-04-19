import 'dart:isolate';

import 'package:diginodes/backend/backend.dart';
import 'package:diginodes/coin_definitions.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/foundation.dart';

class HomeLogic {
  final coinDefinition = ValueNotifier<Definition>(null);
  final _loading = ValueNotifier<bool>(false);
  final _nodes = ValueNotifier<List<Node>>(<Node>[]);

  ValueListenable<bool> get loading => _loading;

  ValueListenable<List<Node>> get nodes => _nodes;

  HomeLogic() {
    coinDefinition.addListener(_onCoinDefinitionChanged);
    coinDefinition.value = coinDefinitions[0];
  }

  Future<void> _onCoinDefinitionChanged() async {
    _loading.value = true;
    final nodes = await NodeService.instance.startDiscovery(coinDefinition.value);
    _loading.value = false;
    await Future.wait(nodes.map((node) async {
      node.open = await NodeService.instance.checkNode(node, const Duration(milliseconds: 750));
    }));
    _nodes.value = nodes;
  }

  void onShareButtonPressed() {
    //
  }

  void onAddManualNodePressed() {

  }
}