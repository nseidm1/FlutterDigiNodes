import 'dart:async';
import 'package:bitcoin/wire.dart';
import 'package:diginodes/backend/backend.dart';
import 'package:diginodes/coin_definitions.dart';
import 'package:diginodes/domain/node_list.dart';
import 'package:diginodes/logic/crypto_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

import 'address_handler.dart';

typedef AddNewNodes = void Function(List<Node> nodes);
typedef MessageAdded = void Function(String message);
typedef NodeComplete = void Function();

class NodeProcessor {
  NodeProcessor({
    @required NodeSet nodes,
    @required MessageAdded messageAdded,
    @required ValueNotifier<Definition> coinDefinition,
    @required AddNewNodes addNewNodes,
  })  : _nodes = nodes,
        _messageAdded = messageAdded,
        _coinDefinition = coinDefinition,
        _addNewNodes = addNewNodes;

  NodeSet _nodes;
  MessageAdded _messageAdded;
  ValueNotifier<Definition> _coinDefinition;

  static const SEND_ADDRESS_LIMIT = 10;
  static const SEND_ADDRESS_PERIOD_MILLIS = 3000;
  static const NO_NODES_DELAY = 1000;

  Timer _addrTimer;
  NodeConnection _nodeConnection;
  var _sendNonce = 0;
  var _crawlIndex = 0;
  bool _shutdownFlag = false;
  int _recentsCount = 0;

  AddNewNodes _addNewNodes;
  var _sendAddressMessageCount = 0;
  int get crawlIndex => _crawlIndex;
  int _addressBatchesReceived = 0;

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
    _crawlIndex = crawlIndex % openNodes.length;
    try {
      return openNodes[_crawlIndex];
    } finally {
      _crawlIndex++;
    }
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
        _nodeConnection.incomingMessages
            .listen((Message message) => incomingMessageHandler(message), onError: (e) => _completer.completeError(e));
        await _nodeConnection.connect(_coinDefinition.value);
        _messageAdded("New node connected: $_crawlIndex");
        await _nodeConnection.sendMessage(CryptoUtils.getVersionMessage(nextOpenNode));
        await _completer.future;
      } catch (e) {
        print('$e');
      } finally {
        close();
      }
    } else {
      await Future.delayed(const Duration(milliseconds: NO_NODES_DELAY));
    }
    if (!_shutdownFlag) {
      crawlOpenNodes();
    }
  }

  void incomingMessageHandler(Message message) {
    if (message is PingMessage) {
      if (message.hasNonce) {
        _nodeConnection.sendMessage(PongMessage(_sendNonce));
      }
    } else if (message is VerackMessage) {
      _addrTimer = Timer.periodic(Duration(milliseconds: SEND_ADDRESS_PERIOD_MILLIS), (t) => sendAddressMessage());
    } else if (message is VersionMessage) {
      _nodeConnection.sendMessage(VerackMessage());
    } else if (message is AddressMessage) {
      AddressHandler.processAddresses(
          existingNodeSet: _nodes,
          incomingMessage: message,
          coinDefinition: _coinDefinition.value,
          processStart: () => processAddressBatchCounter(),
          processComplete: (nodes) => newAddresses(nodes));
    }
  }

  void sendAddressMessage() {
    if (_sendAddressMessageCount > SEND_ADDRESS_LIMIT) {
      close();
    } else {
      _messageAdded("Sending getAddr Message: $_sendAddressMessageCount");
      _nodeConnection.sendMessage(PingMessage.empty());
      _nodeConnection.sendMessage(GetAddressMessage.empty());
      _sendAddressMessageCount++;
    }
  }

  void newAddresses(List<Node> nodes) {
    DateTime recentTime = DateTime.now().toUtc().subtract(Duration(seconds: 28800));
    for (Node node in nodes) {
      if (DateTime.fromMillisecondsSinceEpoch(node.time * 1000, isUtc: true).isAfter(recentTime)) {
        _recentsCount++;
      }
    }
    if (nodes.length > 0) {
      _addNewNodes(nodes);
    }
  }

  ///
  /// Return true of we've processed the second address batch from any given node
  ///
  bool processAddressBatchCounter() {
    _addressBatchesReceived++;
    if (_addressBatchesReceived == 2) {
      _addressBatchesReceived = 0;
      close();
      return true;
    }
    return false;
  }

  void close() {
    _nodeConnection?.close();
    _addrTimer?.cancel();
    if (_completer != null && !_completer.isCompleted) {
      _completer.complete(true);
    }
    _sendAddressMessageCount = 0;
  }

  void processCoinChange() {
    _crawlIndex = 0;
    close();
  }

  void shutdown() {
    _shutdownFlag = true;
  }
}
