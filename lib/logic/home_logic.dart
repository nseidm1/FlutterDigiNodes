import 'dart:async';

import 'package:bitcoin/wire.dart';
import 'package:diginodes/backend/backend.dart';
import 'package:diginodes/coin_definitions.dart';
import 'package:diginodes/domain/node_list.dart';
import 'package:flutter/foundation.dart';
import 'package:diginodes/logic/open_scanner.dart';

class HomeLogic {
  final _coinDefinition = ValueNotifier<Definition>(null);
  final _loadingDNS = ValueNotifier<bool>(false);
  final _nodes = NodeSet();
  final _openNodes = NodeSet();

  OpenScanner _openScanner;

  HomeLogic() {
    _openScanner = OpenScanner(
      nodes: _nodes,
      added: _openNodeAdded,
    );
    _coinDefinition.addListener(_onCoinDefinitionChanged);
    _coinDefinition.value = coinDefinitions[0];
  }

  var _openNodeIndex = 0;
  bool shutdownFlag = false;

  ValueListenable<bool> get loadingDNS => _loadingDNS;
  ValueListenable<Definition> get coinDefinition => _coinDefinition;
  NodeSet get nodes => _nodes;

  int get nodesCount => _nodes.length;

  OpenScanner get openScanner => _openScanner;

  Future<void> _onCoinDefinitionChanged() async {
    _loadingDNS.value = true;
    _nodes.clear();
    _openScanner.reset();
    _nodes.addAll(await NodeService.instance.startDiscovery(_coinDefinition.value));
    _openScanner.start();
    _crawlOpenNodes();
    _loadingDNS.value = false;
  }

  void shutdown() {
    shutdownFlag = true;
    _openScanner.shutdown();
  }

  void _openNodeAdded(Node node) {
    _openNodes.add(node);
  }

  Node _getNextOpenNode() {
    if (_openNodes.length == 0) {
      return null;
    }
    _openNodeIndex = (++_openNodeIndex % _openNodes.length);
    return _openNodes[_openNodeIndex];
  }

  void _crawlOpenNodes() async {
    final nextOpenNode = _getNextOpenNode();
    if (nextOpenNode != null) {
      final connection = NodeConnection(nextOpenNode);
      final completer = Completer<bool>();
      try{
        connection.incomingMessages.listen((Message message) {
          if(message is VerackMessage) {
            connection.sendMessage(GetAddressMessage());
          }
          else if(message is AddressMessage) {
            print('Got addresses: ${message.addresses}');
            completer.complete(true);
          }
          else {
            print('Unknown: ${message}');
          }
        }, onError: (e, st) {
          completer.completeError(e, st);
        });
        await connection.connect(_coinDefinition.value);
        print('connected ${nextOpenNode}');
        /*Future.delayed(const Duration(seconds: 3), (){
          completer.completeError(new StateError('Timed-out ${nextOpenNode}'));
        });*/
        await completer.future;
        print('completed');
      }
      catch (e, st) {
        print('$e');//\n$st');
      }
      finally{
        connection.close();
      }
    }
    if (!shutdownFlag) {
      await Future.delayed(const Duration(milliseconds: 2500));
      _crawlOpenNodes();
    }
  }

  void onShareButtonPressed() {
    //
  }

  void onAddManualNodePressed() {

  }
}