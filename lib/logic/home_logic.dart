import 'dart:async';

import 'package:bignum/bignum.dart';
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
  var _sendNonce = 0;
  Timer _addrTimer;
  var _addrCounter = 0;

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
          
          if (message is VerackMessage) {
            _addrTimer = Timer.periodic(Duration(milliseconds: 2500), (t) => sendAddrMessage(connection, completer));
            connection.sendMessage(GetAddressMessage());
          } else if(message is VersionMessage) {
            connection.sendMessage(VerackMessage());
          } else if(message is AddressMessage) {
            print('Got addresses: ${message.addresses}');
            _addrTimer.cancel();
            completer.complete(true);
          } else {
            print('Unknown: ${message}');
          }
        }, onError: (e, st) {
          completer.completeError(e, st);
        });
        await connection.connect(_coinDefinition.value);
        print('connected ${nextOpenNode}');
        await connection.sendMessage(_getOutVMesg(nextOpenNode));
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

  void sendAddrMessage(NodeConnection connection, Completer<bool> completer) {
    connection.sendMessage(GetAddressMessage());
    _addrCounter++;
    if (_addrCounter > 20) {
      connection.close();
      _addrTimer.cancel();
      completer.complete(true);
      _addrCounter = 0;
    }
  }

  void onShareButtonPressed() {
    //
  }

  void onAddManualNodePressed() {

  }

  Message _getOutVMesg(Node node) {
    final services = BigInteger.ZERO;
    final time = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    VersionMessage ver = new VersionMessage(
      clientVersion: node.def.protocolVersion,
      services: services,
      time: time,
      myAddress: PeerAddress.localhost(services: services, port: node.def.port),
      theirAddress: PeerAddress.localhost(services: services, port: node.def.port),
      nonce: ++_sendNonce,
      subVer: VersionMessage.LIBRARY_SUBVER,
      lastHeight: 10000,
      relayBeforeFilter: false,
      coinName: node.def.coinName,
    );
    return ver;
  }
}