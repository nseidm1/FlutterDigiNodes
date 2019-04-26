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
import 'package:diginodes/logic/node_processor.dart';
import 'package:diginodes/ui/scroll_to_bottom_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:diginodes/logic/open_scanner.dart';
import 'package:flutter/widgets.dart';
import 'package:hex/hex.dart';

class HomeLogic {
  final _coinDefinition = ValueNotifier<Definition>(null);
  final _loadingDNS = ValueNotifier<bool>(false);
  final _nodes = NodeSet();
  final _messages = MessageList();
  final _openNodes = NodeSet();
  int _recentCount = 0;

  OpenScanner _openScanner;
  NodeProcessor _nodeProcessor;

  ScrollToBottomController _messagesScrollController;
  ScrollController get messagesScrollController => _messagesScrollController;

  ScrollToBottomController _nodesScrollController;
  ScrollController get nodesScrollController => _nodesScrollController;

  ValueListenable<bool> get loadingDNS => _loadingDNS;
  ValueListenable<Definition> get coinDefinition => _coinDefinition;
  NodeSet get nodes => _nodes;
  MessageList get messages => _messages;
  int get nodesCount => _nodes.length;
  OpenScanner get openScanner => _openScanner;
  NodeProcessor get nodeProcessor => _nodeProcessor;
  int get recentCount => _recentCount;

  HomeLogic() {
    _messagesScrollController = ScrollToBottomController(listenable: _messages);
    _nodesScrollController = ScrollToBottomController(listenable: _nodes);
    _openScanner = OpenScanner(
      nodes: _nodes,
      added: _openNodeAdded,
    );
    _nodeProcessor = NodeProcessor(
      nodes: _nodes,
      messages: _messages,
      processAddresses: _processAddresses,
      coinDefinition: _coinDefinition,
    );
    _coinDefinition.addListener(_onCoinDefinitionChanged);
    _coinDefinition.value = coinDefinitions[0];
  }

  void dispose() {
    _messagesScrollController.dispose();
    _nodesScrollController.dispose();
  }

  Future<void> _onCoinDefinitionChanged() async {
    _loadingDNS.value = true;
    _reset();
    _messages.add("Resolving DNS");
    _nodes.addAll(await NodeService.instance.startDiscovery(_coinDefinition.value));
    _openScanner.start();
    _messages.add("DNS complete");
    _nodeProcessor.crawlOpenNodes();
    _loadingDNS.value = false;
  }

  void _reset() {
    _nodeProcessor.reset();
    _nodes.clear();
    _openNodes.clear();
    _openScanner.reset();
    _messages.clear();
  }

  void shutdown() {
    _nodeProcessor.shutdown();
    _openScanner.shutdown();
  }

  void _openNodeAdded(Node node) {
    _openNodes.add(node);
  }

  void _processAddresses(AddressMessage message) async {
    message.addresses.forEach((peer) => print(HEX.encode(peer.address)));
    var nodes = List<Node>();
    DateTime recentTime = DateTime.now().toUtc().subtract(Duration(seconds: 28800));
    for (PeerAddress peerAddress in message.addresses) {
      try {
        InternetAddress internetAddress = getInternetAddress(peerAddress.address);
        print('Internet Address: $internetAddress');
        bool recent = DateTime.fromMillisecondsSinceEpoch(peerAddress.time * 1000, isUtc: true).isAfter(recentTime);
        if (recent) {
          _recentCount++;
        }
        nodes.add(Node(internetAddress, peerAddress.port, _coinDefinition.value));
      } catch(e){
        print('$e');
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
    _nodeProcessor.close();
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

  void onShareButtonPressed() {
    //
  }

  void onAddManualNodePressed() {

  }
}