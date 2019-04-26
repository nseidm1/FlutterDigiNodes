import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bignum/bignum.dart';
import 'package:bitcoin/wire.dart';
import 'package:collection/collection.dart';
import 'package:diginodes/backend/backend.dart';
import 'package:diginodes/coin_definitions.dart';
import 'package:diginodes/domain/message_list.dart';
import 'package:diginodes/domain/node_list.dart';
import 'package:flutter/foundation.dart';
import 'package:hex/hex.dart';
import 'package:meta/meta.dart';

class NodeProcessor {
  NodeProcessor({
    @required NodeSet nodes,
    @required MessageList messages,
    @required ValueNotifier<Definition> coinDefinition,
  })  : _nodes = nodes,
        _messages = messages,
        _coinDefinition = coinDefinition;

  NodeSet _nodes;
  MessageList _messages;
  ValueNotifier<Definition> _coinDefinition;

  Timer _addrTimer;
  NodeConnection _nodeConnection;
  var _sendNonce = 0;
  var _sendAddressMessageCount = 0;
  var _crawlIndex = 0;
  bool _shutdownFlag = false;
  int _recentsCount = 0;
  int _addressBatchesReceived = 0;

  int get crawlIndex => _crawlIndex;
  int get recentsCount => _recentsCount;
  Completer _completer;

  List<Node> _getOpenNodesList() {
    return List.from(_nodes.where((node) => node.open));
  }

  Node _getNextOpenNode() {
    List<Node> openNodes = _getOpenNodesList();
    if (openNodes.length == 0) {
      return null;
    }
    _crawlIndex = (++_crawlIndex % openNodes.length);
    return openNodes[_crawlIndex];
  }

  Future<void> crawlOpenNodes() async {
    final nextOpenNode = _getNextOpenNode();
    if (nextOpenNode != null) {
      _nodeConnection = NodeConnection(
        close: close,
        node: nextOpenNode,
      );
      _completer = Completer<bool>();
      try {
        _nodeConnection.incomingMessages.listen((Message message) {
          if (message is PingMessage) {
            if (message.hasNonce) {
              _nodeConnection.sendMessage(PongMessage(_sendNonce));
            }
          } else if (message is VerackMessage) {
            _addrTimer = Timer.periodic(Duration(milliseconds: 3000), (t) => _sendAddressMessage());
          } else if (message is VersionMessage) {
            _nodeConnection.sendMessage(VerackMessage());
          } else if (message is AddressMessage) {
            _processAddresses(message);
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
      } catch (e) {
        print('$e');
      } finally {
        close();
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 250));
    }
    if (!_shutdownFlag) {
      crawlOpenNodes();
    }
  }

  void _processAddresses(AddressMessage message) {
    _addressBatchesReceived++;
    if (_addressBatchesReceived == 2) {
      _addressBatchesReceived = 0;
      close();
    }
    message.addresses.forEach((peer) => print(HEX.encode(peer.address)));
    List<Node> nodes = List();
    for (PeerAddress peerAddress in message.addresses) {
      nodes.add(
          Node(getInternetAddress(peerAddress.address), peerAddress.port, peerAddress.time, _coinDefinition.value));
    }
    DateTime recentTime = DateTime.now().toUtc().subtract(Duration(seconds: 28800));
    nodes.removeWhere((node) => _nodes.contains(node));
    for (Node node in nodes) {
      if (DateTime.fromMillisecondsSinceEpoch(node.time * 1000, isUtc: true).isAfter(recentTime)) {
        _recentsCount++;
      }
    }
    _nodes.addAll(nodes);
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
      close();
    } else {
      _messages.add("Sending getAddr Message: $_sendAddressMessageCount");
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

  void close() {
    _nodeConnection?.close();
    _addrTimer?.cancel();
    if (_completer != null && !_completer.isCompleted) {
      _completer.complete(true);
    }
    _sendAddressMessageCount = 0;
  }

  void reset() {
    _crawlIndex = 0;
    close();
  }

  void shutdown() {
    _shutdownFlag = true;
  }
}
