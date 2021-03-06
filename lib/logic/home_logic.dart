import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:diginodes/backend/backend.dart';
import 'package:diginodes/coin_definitions.dart';
import 'package:diginodes/domain/node.dart';
import 'package:diginodes/domain/node_list.dart';
import 'package:diginodes/domain/message_list.dart';
import 'package:diginodes/logic/node_processor.dart';
import 'package:diginodes/ui/map.dart';
import 'package:diginodes/ui/scroll_to_bottom_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:diginodes/logic/open_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;

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

  AnimationController _controller;

  HomeLogic(this._controller) {
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
    _clear();
    _messageAdded("Resolving DNS");
    final nodes = await NodeService.instance.startDiscovery(_coinDefinition.value);
    await Future.delayed(Duration(milliseconds: 1000));
    _addNewNodes(nodes);
    _openScanner.start();
    _messageAdded("DNS complete");
    _loadingDNS.value = false;
  }

  void _clear() {
    _nodeProcessor.clear();
    _nodes.clear();
    _openScanner.clear();
    _messages.clear();
  }

  void shutdown() {
    _nodeProcessor.shutdown();
    _openScanner.shutdown();
  }

  Future<void> _addNewNodes(List<Node> nodes) async {
    final addresses = nodes.map((node) => node.address.address).join(",");
    Response response = await http.get('http://noahseidman.com/geoip.json?ips=$addresses');
    print('${response.statusCode}, ${response.reasonPhrase}');
    if (response != null) {
      Map responseJson = jsonDecode(response.body);
      print('${responseJson.length}');
      for (Node node in nodes) {
        final location = responseJson[node.address.address];
        if (location != null) {
          double longitude = location["longitude"].toDouble();
          double latitude = location["latitude"].toDouble();
          print('$longitude, $latitude');
          node.mapItem = MapItem(latitude, longitude, Colors.blue);
        }
      }
    }
    _nodes.addAll(nodes);
    _nodesScrollController.scrollToBottom();
  }

  Future<void> _messageAdded(String message) async {
    AnimationStatusListener listener;
    listener = (AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _controller.removeStatusListener(listener);
        _messages.add(message);
        listener = (AnimationStatus status) {
          _controller.removeStatusListener(listener);
          scrollToBottom();
        };
        _controller.addStatusListener(listener);
        _controller.reverse();
      }
    };
    _controller?.addStatusListener(listener);
    _controller?.forward();
  }

  Future<void> scrollToBottom() async {
    await Future.delayed(Duration(milliseconds: 750));
    _messagesScrollController.scrollToBottom();
  }

  Future<void> onShareButtonPressed() async {
    final file = await updateShareFile();
    final bytes = file.readAsBytesSync();
    await Share.file('nodes', 'nodes.json.gz', bytes, 'application/gzip');
  }

  Future<File> updateShareFile() async {
    final file = await _localFile;
    final stringBytes = utf8.encode(json.encode(_nodes.toJson()).toString());
    final gzipBytes = GZipEncoder().encode(stringBytes);
    return file.writeAsBytes(gzipBytes);
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/nodes.json.gz');
  }

  Future<String> get _localPath async {
    return (await getApplicationDocumentsDirectory()).path;
  }

  void onAddManualNodePressed() {}
}
