import 'dart:async';
import 'dart:io';

import 'package:bignum/bignum.dart';
import 'package:bitcoin/wire.dart';
import 'package:diginodes/backend/backend.dart';
import 'package:diginodes/coin_definitions.dart';
import 'package:diginodes/domain/node_list.dart';
import 'package:diginodes/domain/string_list.dart';
import 'package:flutter/foundation.dart';
import 'package:diginodes/logic/open_scanner.dart';
import 'package:flutter/widgets.dart';

class HomeLogic {
  final _coinDefinition = ValueNotifier<Definition>(null);
  final _loadingDNS = ValueNotifier<bool>(false);
  final _nodes = NodeSet();
  final _messages = StringList(List());
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

  var _crawlIndex = 0;
  bool shutdownFlag = false;

  ValueListenable<bool> get loadingDNS => _loadingDNS;
  ValueListenable<Definition> get coinDefinition => _coinDefinition;
  NodeSet get nodes => _nodes;
  StringList get messages => _messages;

  int get nodesCount => _nodes.length;

  OpenScanner get openScanner => _openScanner;
  
  int get crawlIndex => _crawlIndex;

  Future<void> _onCoinDefinitionChanged() async {
    _loadingDNS.value = true;
    _nodes.clear();
    _openScanner.reset();
    _messages.add("Resolving DNS");
    _nodes.addAll(await NodeService.instance.startDiscovery(_coinDefinition.value));
    _openScanner.start();
    _messages.add("DNS complete");
    _crawlOpenNodes();
    _loadingDNS.value = false;
  }

  Future<void> shutdown() async {
    shutdownFlag = true;
    _openScanner.shutdown();
  }

  Future<void> _openNodeAdded(Node node) async {
    _openNodes.add(node);
  }

  Future<Node> _getNextOpenNode() async {
    if (_openNodes.length == 0) {
      return null;
    }
    _crawlIndex = (++_crawlIndex % _openNodes.length);
    return _openNodes[_crawlIndex];
  }

  Future<void> _crawlOpenNodes() async {
    final nextOpenNode = await _getNextOpenNode();
    if (nextOpenNode != null) {
      final connection = NodeConnection(nextOpenNode);
      final completer = Completer<bool>();
      try{
        connection.incomingMessages.listen((Message message) {
          if (message is PingMessage) {
            processPing(connection, message);
          } else if (message is VerackMessage) {
            processAck(connection, completer);
          } else if(message is VersionMessage) {
            processVersionMessage(connection);
          } else if(message is AddressMessage) {
            processAddresses(connection, completer, message);
          } else {
            print('Unknown: $message');
          }
        }, onError: (e) {
          completer.completeError(e);
        });
        await connection.connect(_coinDefinition.value);
        print('connected $nextOpenNode');
        _messages.add("New node connected: $_crawlIndex");
        await connection.sendMessage(await _getOutVMesg(nextOpenNode));
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

  Future<void> processAddresses(NodeConnection connection, Completer<bool> completer, AddressMessage message) async {
    print('Got addresses: ${message.addresses}');
    var nodes = List<Node>.from(message.addresses.map<Node>((peerAddress) =>
        Node(InternetAddress(Uri.dataFromBytes(peerAddress.address).toString()), peerAddress.port, _coinDefinition.value)));
    int previousNodeCount = _nodes.length;
    _nodes.addAll(nodes);
    var newNodeCount = _nodes.length - previousNodeCount;
    if (newNodeCount > 0) {
      _messages.add("New nodes received: ${newNodeCount}");
    } else {
      _messages.add("No new nodes received");
    }
    _addrTimer.cancel();
    completer.complete(true);
  }

  Future<void> processVersionMessage(NodeConnection connection) async {
    await connection.sendMessage(VerackMessage());
  }

  Future<void> processPing(NodeConnection connection, PingMessage message) async {
    if (message.hasNonce) {
      await connection.sendMessage(PongMessage(message.nonce));
    }
  }

  Future<void> processAck(NodeConnection connection, Completer<bool> completer) async {
    _addrTimer = Timer.periodic(Duration(milliseconds: 3000), (t) =>
        sendAddrMessage(connection, completer));
    await connection.sendMessage(GetAddressMessage());
  }

  Future<void> sendAddrMessage(NodeConnection connection, Completer<bool> completer) async {
    if (_addrCounter > 10) {
      connection.close();
      _addrTimer.cancel();
      completer.complete(true);
      _addrCounter = 0;
    } else {
      _messages.add("Sending getAddr Message");
      try {
        await connection.sendMessage(GetAddressMessage());
        _addrCounter++;
      } catch(e) {
        _addrTimer.cancel();
        completer.complete(true);
      }
    }
  }

  void onShareButtonPressed() {
    //
  }

  void onAddManualNodePressed() {

  }

  Future<Message> _getOutVMesg(Node node) async {
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