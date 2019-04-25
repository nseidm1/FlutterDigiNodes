import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bignum/bignum.dart';
import 'package:bitcoin/wire.dart';
import 'package:collection/collection.dart';
import 'package:diginodes/backend/backend.dart';
import 'package:diginodes/coin_definitions.dart';
import 'package:diginodes/domain/node_list.dart';
import 'package:diginodes/domain/message_list.dart';
import 'package:flutter/foundation.dart';
import 'package:diginodes/logic/open_scanner.dart';
import 'package:flutter/widgets.dart';
import 'package:hex/hex.dart';

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
  var _sendAddressMessageCount = 0;
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
    _reset();
    _messages.add("Resolving DNS");
    _nodes.addAll(await NodeService.instance.startDiscovery(_coinDefinition.value));
    _openScanner.start();
    _messages.add("DNS complete");
    _crawlOpenNodes();
    _loadingDNS.value = false;
  }

  void _reset() {
    _sendAddressMessageCount = 0;
    _crawlIndex = 0;
    _addrTimer?.cancel();
    _nodes.clear();
    _openNodes.clear();
    _openScanner.reset();
    _messages.clear();
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
      Timer timeout;
      try{
        _nodeConnection.incomingMessages.listen((Message message) {
          if (message is PingMessage) {
            if (message.hasNonce && message.nonce > 0) {
              _nodeConnection.sendMessage(PongMessage(message.nonce));
            }
          } else if (message is VerackMessage) {
            timeout.cancel();
            _addrTimer = Timer.periodic(Duration(milliseconds: 6000), (t) =>
                _sendAddressMessage());
          } else if(message is VersionMessage) {
            _nodeConnection.sendMessage(VerackMessage());
          } else if(message is AddressMessage) {
            _processAddresses(message);
          }
        }, onError: (e) {
          _completer.completeError(e);
        });
        await _nodeConnection.connect(_coinDefinition.value);
        print('connected $nextOpenNode');
        _messages.add("New node connected: $_crawlIndex");
        await _nodeConnection.sendMessage(_getMyVersionMessage(nextOpenNode));
        timeout = Timer(Duration(milliseconds: 15000), () => _completer.complete(true));
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

  Future<void> _processAddresses(AddressMessage message) async {
    message.addresses.forEach((peer) => print(HEX.encode(peer.address)));
    var nodes = List<Node>();
    for (PeerAddress peerAddress in message.addresses) {
      try {
        InternetAddress internetAddress = getInternetAddress(peerAddress.address);
        print('Internet Address: $internetAddress');
        nodes.add(Node(internetAddress, peerAddress.port, _coinDefinition.value));
      } catch(e){

      }
    }
    int previousNodeCount = _nodes.length;
    _nodes.addAll(nodes);
    var newNodeCount = _nodes.length - previousNodeCount;
    if (newNodeCount > 0) {
      _messages.add("New nodes received: $newNodeCount");
    } else {
      _messages.add("No new nodes received");
    }
    _close();
  }

  InternetAddress getInternetAddress(List<int> address) {
    const equality = ListEquality<int>();
    if (equality.equals(address.sublist(0, 12), const <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xFF, 0xFF])) {
      return InternetAddress(address.sublist(12).map((el) => el.toRadixString(10)).join('.'));
    } else {
      final view = Uint8List.fromList(address).buffer.asUint16List();
      return InternetAddress(view.map((el) => el.toRadixString(16)).join(':'));
    }
  }

  void _sendAddressMessage() {
    if (_sendAddressMessageCount > 10) {
      _close();
    } else {
      _messages.add("Sending getAddr Message");
      _nodeConnection.sendMessage(PingMessage.empty());
      _nodeConnection.sendMessage(GetAddressMessage.empty());
      _sendAddressMessageCount++;
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
      subVer: "/" + node.def.coinName + ":" + ".1-Crawler" + "/",
      lastHeight: 0,
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
    _sendAddressMessageCount = 0;
  }

  void onShareButtonPressed() {
    //
  }

  void onAddManualNodePressed() {

  }
}