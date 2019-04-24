import 'dart:async';
import 'dart:io';

import 'package:bignum/bignum.dart';
import 'package:bitcoin/wire.dart';
import 'package:diginodes/backend/backend.dart';
import 'package:diginodes/coin_definitions.dart';
import 'package:diginodes/domain/node_list.dart';
import 'package:diginodes/domain/message_list.dart';
import 'package:flutter/foundation.dart';
import 'package:diginodes/logic/open_scanner.dart';
import 'package:flutter/widgets.dart';

class HomeLogic {
  final _coinDefinition = ValueNotifier<Definition>(null);
  final _loadingDNS = ValueNotifier<bool>(false);
  final _nodes = NodeSet();
  final _messages = StringList(List());
  final _openNodes = NodeSet();

  Timer _addrTimer;
  NodeConnection _nodeConnection;
  OpenScanner _openScanner;
  Completer _completer;

  var _sendNonce = 0;
  var _crawlingIndex = 0;
  var _crawlIndex = 0;
  bool shutdownFlag = false;

  ValueListenable<bool> get loadingDNS => _loadingDNS;
  ValueListenable<Definition> get coinDefinition => _coinDefinition;
  NodeSet get nodes => _nodes;
  StringList get messages => _messages;
  int get nodesCount => _nodes.length;
  OpenScanner get openScanner => _openScanner;
  int get crawlIndex => _crawlIndex;

  HomeLogic() {
    _openScanner = OpenScanner(
      nodes: _nodes,
      added: _openNodeAdded,
    );
    _coinDefinition.addListener(_onCoinDefinitionChanged);
    _coinDefinition.value = coinDefinitions[0];
  }

  Future<void> _onCoinDefinitionChanged() async {
    _loadingDNS.value = true;
    _nodes.clear();
    _openScanner.reset();
    _messages.clear();
    _addrTimer?.cancel();
    _crawlingIndex = 0;
    _messages.add("Resolving DNS");
    _nodes.addAll(await NodeService.instance.startDiscovery(_coinDefinition.value));
    _openScanner.start();
    _messages.add("DNS complete");
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
    _crawlIndex = (++_crawlIndex % _openNodes.length);
    return _openNodes[_crawlIndex];
  }

  Future<void> _crawlOpenNodes() async {
    final nextOpenNode = _getNextOpenNode();
    if (nextOpenNode != null) {
      _nodeConnection = NodeConnection(
          close: _close, 
          node: nextOpenNode,
      );
      _completer = Completer<bool>();
      try{
        _nodeConnection.incomingMessages.listen((Message message) {
          if (message is PingMessage) {
            processPing(message);
          } else if (message is VerackMessage) {
            processAck();
          } else if(message is VersionMessage) {
            processVersionMessage();
          } else if(message is AddressMessage) {
            processAddresses(message);
          } else {
            print('Unknown: $message');
          }
        }, onError: (e) {
          _completer.completeError(e);
        });
        await _nodeConnection.connect(_coinDefinition.value);
        print('connected $nextOpenNode');
        _messages.add("New node connected: $_crawlIndex");
        await _nodeConnection.sendMessage(_getMyVersionMessage(nextOpenNode));
        await _completer.future;
        print('next node');
      }
      catch (e, st) {
        print('$e');//\n$st');
      }
      finally{
        _close();
      }
    }
    if (!shutdownFlag) {
      await Future.delayed(const Duration(milliseconds: 2500));
      _crawlOpenNodes();
    }
  }

  Future<void> processAddresses(AddressMessage message) async {
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
    _completer.complete(true);
  }

  Future<void> processVersionMessage() async {
    await _nodeConnection.sendMessage(VerackMessage());
  }

  Future<void> processPing(PingMessage message) async {
    if (message.hasNonce) {
      await _nodeConnection.sendMessage(PongMessage(message.nonce));
    }
  }

  Future<void> processAck() async {
    await sendAddressMessage();
    _addrTimer = Timer.periodic(Duration(milliseconds: 6000), (t) =>
        sendAddressMessage());
  }

  Future<void> sendAddressMessage() async {
    if (_crawlingIndex > 10) {
      _close();
    } else {
      _messages.add("Sending getAddr Message");
      await _nodeConnection.sendMessage(GetAddressMessage());
      _crawlingIndex++;
    }
  }

  Message _getMyVersionMessage(Node node) {
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

  void _close() {
    _nodeConnection?.close();
    _addrTimer?.cancel();
    if (!_completer.isCompleted) {
      _completer.complete(true);
    }
    _crawlingIndex = 0;
  }

  void onShareButtonPressed() {
    //
  }

  void onAddManualNodePressed() {

  }
}