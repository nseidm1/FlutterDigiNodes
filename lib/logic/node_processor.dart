import 'dart:async';
import 'package:bitcoin/wire.dart';
import 'package:diginodes/backend/backend.dart';
import 'package:diginodes/coin_definitions.dart';
import 'package:diginodes/domain/node.dart';
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

  final NodeSet _nodes;
  final _messageAdded;
  final _addNewNodes;
  final _coinDefinition;

  static const SEND_ADDRESS_LIMIT = 15;
  static const SEND_ADDRESS_PERIOD_MILLIS = 3000;
  static const NO_NODES_DELAY = 1000;
  static const GENERAL_NODES_DELAY = 2500;
  static const HARD_TIMEOUT = 10000;

  Timer _addrTimer;
  Timer _hardTimeout;
  NodeConnection _nodeConnection;
  Completer _completer;

  bool _shutdownFlag = false;
  int _sendNonce = 0;
  int _crawlIndex = 0;
  int _sendAddressMessageCount = 0;
  int _addressBatchesReceived = 0;
  int _recentsCount = 0;

  int get recentsCount => _recentsCount;
  int get crawlIndex => _crawlIndex;

  List<Node> _getOpenNodesList() {
    return List.from(_nodes.where((node) => node.open));
  }

  Node _getNextOpenNode() {
    List<Node> openNodes = _getOpenNodesList();
    if (openNodes.length == 0) {
      return null;
    }
    _crawlIndex = crawlIndex % openNodes.length;
    return openNodes[_crawlIndex++];
  }

  Future<void> crawlOpenNodes() async {
    final nextOpenNode = _getNextOpenNode();
    if (nextOpenNode != null) {
      _hardTimeout = Timer(Duration(milliseconds: HARD_TIMEOUT), () => close());
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
        _nodeConnection.sendMessage(CryptoUtils.getVersionMessage(nextOpenNode));
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
      await Future.delayed(const Duration(milliseconds: GENERAL_NODES_DELAY));
      crawlOpenNodes();
    }
  }

  void incomingMessageHandler(Message message) {
    if (message is PingMessage) {
      if (message.hasNonce) {
        _nodeConnection.sendMessage(PongMessage(message.nonce > 0 ? message.nonce : _sendNonce));
      }
    } else if (message is VerackMessage) {
      _hardTimeout.cancel();
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
    } else if (message is RejectMessage) {
      print('Reject: ${message.message}, ${message.reason}');
    }
  }

  void sendAddressMessage() {
    if (_sendAddressMessageCount > SEND_ADDRESS_LIMIT) {
      close();
    } else {
      _messageAdded("Sending getAddr Message: $_sendAddressMessageCount");
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
      _messageAdded("Found ${nodes.length} new ${nodes.length == 1 ? 'node' : 'nodes'}");
      _addNewNodes(nodes);
    } else {
      _messageAdded("No new nodes found");
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
    _sendAddressMessageCount = 1;
  }

  void clear() {
    _crawlIndex = 0;
    close();
  }

  void shutdown() {
    _shutdownFlag = true;
  }
}
