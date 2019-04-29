import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:diginodes/backend/backend.dart';
import 'package:diginodes/coin_definitions.dart';
import 'package:diginodes/domain/node_list.dart';
import 'package:diginodes/domain/message_list.dart';
import 'package:diginodes/logic/node_processor.dart';
import 'package:diginodes/ui/scroll_to_bottom_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:diginodes/logic/open_scanner.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';

class HomeLogic {
  final _coinDefinition = ValueNotifier<Definition>(null);
  final _loadingDNS = ValueNotifier<bool>(false);
  final _nodes = NodeSet();
  final _messages = MessageList();

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
    _messagesScrollController = ScrollToBottomController(duration: 500);
    _nodesScrollController = ScrollToBottomController(duration: 4000);
    _openScanner = OpenScanner(
      nodes: _nodes,
    );
    _nodeProcessor = NodeProcessor(
      nodes: _nodes,
      messageAdded: _messageAdded,
      coinDefinition: _coinDefinition,
      addNewNodes: _addNewNodes,
    );
    _nodeProcessor.crawlOpenNodes();
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
    _messageAdded("Resolving DNS");
    List<Node> nodes = await NodeService.instance.startDiscovery(_coinDefinition.value);
    await Future.delayed(Duration(milliseconds: 1000));
    _addNewNodes(nodes);
    _openScanner.start();
    _messageAdded("DNS complete");
    _loadingDNS.value = false;
  }

  void _reset() {
    _nodeProcessor.clear();
    _nodes.clear();
    _openScanner.clear();
    _messages.clear();
  }

  void shutdown() {
    _nodeProcessor.shutdown();
    _openScanner.shutdown();
  }

  void _addNewNodes(List<Node> nodes) {
    _nodes.addAll(nodes);
    _nodesScrollController.scrollToBottom();
  }

  void _messageAdded(String message) {
    _messages.add(message);
    _messagesScrollController.scrollToBottom();
  }

  Future<void> onShareButtonPressed() async {
    File file = await updateShareFile();
    List<int> bytes = file.readAsBytesSync();
    await Share.file('nodes', 'nodes.zip', bytes, 'file/zip');
  }

  Future<File> updateShareFile() async {
    final file = await _localFile;

    StringBuffer buffer = StringBuffer();
    buffer.write('[');
    buffer.write(_nodes.map((node) => jsonEncode(node)).join(','));
    buffer.write(']');

    List<int> stringBytes = utf8.encode(buffer.toString());
    List<int> gzipBytes = new GZipEncoder().encode(stringBytes);
    return file.writeAsBytes(gzipBytes);
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/nodes.zip');
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  void onAddManualNodePressed() {}
}
