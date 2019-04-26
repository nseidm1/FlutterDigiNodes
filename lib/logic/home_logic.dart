import 'dart:async';

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

  HomeLogic() {
    _messagesScrollController = ScrollToBottomController(listenable: _messages, duration: 500);
    _nodesScrollController = ScrollToBottomController(listenable: _nodes, duration: 10000);
    _openScanner = OpenScanner(
      nodes: _nodes,
      added: _openNodeAdded,
    );
    _nodeProcessor = NodeProcessor(
      nodes: _nodes,
      messages: _messages,
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
    _openScanner.setDnsOpen(_nodes.length);
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

  void onShareButtonPressed() {
    //
  }

  void onAddManualNodePressed() {}
}
