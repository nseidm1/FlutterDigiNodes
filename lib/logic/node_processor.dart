import 'dart:async';

import 'package:bignum/bignum.dart';
import 'package:bitcoin/wire.dart';
import 'package:diginodes/backend/backend.dart';
import 'package:diginodes/coin_definitions.dart';
import 'package:diginodes/domain/message_list.dart';
import 'package:diginodes/domain/node_list.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

typedef ProcessAddresses = void Function(AddressMessage message);

class NodeProcessor {
  NodeProcessor({
    @required NodeSet nodes,
    @required MessageList messages,
    @required ProcessAddresses processAddresses,
    @required ValueNotifier<Definition> coinDefinition,
  }): _nodes = nodes, _messages = messages, _processAddresses = processAddresses, _coinDefinition = coinDefinition;

  NodeSet _nodes;
  MessageList _messages;
  ProcessAddresses _processAddresses;
  ValueNotifier<Definition> _coinDefinition;

  Timer _addrTimer;
  NodeConnection _nodeConnection;
  var _sendNonce = 0;
  var _sendAddressMessageCount = 0;
  var _crawlIndex = 0;
  bool _shutdownFlag = false;

  int get crawlIndex => _crawlIndex;
  Completer _completer;

  Node _getNextOpenNode() {
    if (_nodes.length == 0) {
      return null;
    }
    _crawlIndex = (++_crawlIndex % _nodes.length);
    return _nodes[_crawlIndex];
  }

  Future<void> crawlOpenNodes() async {
    final nextOpenNode = _getNextOpenNode();
    if (nextOpenNode != null) {
      _nodeConnection = NodeConnection(
        close: close,
        node: nextOpenNode,
      );
      _completer = Completer<bool>();
      Timer timeout;
      try{
        _nodeConnection.incomingMessages.listen((Message message) {
          if (message is PingMessage) {
            if (message.hasNonce) {
              _nodeConnection.sendMessage(PongMessage(_sendNonce));
            }
          } else if (message is VerackMessage) {
            timeout.cancel();
            _addrTimer = Timer.periodic(Duration(milliseconds: 3000), (t) =>
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
      catch (e) {
        print('$e');
      }
      finally{
        close();
      }
    }
    if (!_shutdownFlag) {
      await Future.delayed(const Duration(milliseconds: 2500));
      crawlOpenNodes();
    }
  }

  void _sendAddressMessage() {
    if (_sendAddressMessageCount > 10) {
      close();
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

  void close() {
    _nodeConnection?.close();
    _addrTimer?.cancel();
    if (!_completer.isCompleted) {
      _completer.complete(true);
    }
    _sendAddressMessageCount = 0;
  }

  void reset() {
    _sendAddressMessageCount = 0;
    _crawlIndex = 0;
    _addrTimer?.cancel();
  }

  void shutdown() {
    _shutdownFlag = true;
  }
}