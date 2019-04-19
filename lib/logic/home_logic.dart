import 'package:diginodes/backend/backend.dart';
import 'package:diginodes/coin_definitions.dart';
import 'package:diginodes/domain/node_list.dart';
import 'package:flutter/foundation.dart';
import 'package:isolate/runner.dart';

class HomeLogic {
  final coinDefinition = ValueNotifier<Definition>(null);
  final _loadingDNS = ValueNotifier<bool>(false);
  final _nodes = NodeSet();
  final _openCount = ValueNotifier<int>(0);
  var _recentsCount = 0;
  var _nodeCheckIndex = 0;
  var runners = List<Runner>();

  ValueListenable<bool> get loadingDNS => _loadingDNS;
  NodeSet get nodes => _nodes;

  ValueListenable<int> get openCount => _openCount;
  int get recentsCount => _recentsCount;
  int get nodesCount => _nodes.length;


  HomeLogic() {
    coinDefinition.addListener(_onCoinDefinitionChanged);
    coinDefinition.value = coinDefinitions[0];
  }

  Future<void> _onCoinDefinitionChanged() async {
    _loadingDNS.value = true;
    final nodes = await NodeService.instance.startDiscovery(coinDefinition.value);
    _nodes.addAll(nodes);
    await Future.wait(nodes.map((node) async {
      node.open = await NodeService.instance.checkNode(node, const Duration(milliseconds: 750));
      if(node.open){
        _openCount.value++;
      }
      await Future.delayed(Duration(milliseconds: 700));
    }));
    _loadingDNS.value = false;
  }

  Node getNextNode(int index) {
    return null;
  }

  checkOpenState(Node node) {

  }

  void onShareButtonPressed() {
    //
  }

  void onAddManualNodePressed() {

  }
}