import 'dart:async';
import 'dart:io';

import 'package:diginodes/coin_definitions.dart';
import 'package:diginodes/messages/disconnect.dart';
import 'package:diginodes/messages/message.dart';
import 'package:diginodes/messages/none.dart';

final _dnsCache = Map<String, List<InternetAddress>>();

class Node {
  Node(this.address, this.port);

  final InternetAddress address;
  final int port;
  bool open = false;
}

class NodeService {
  static final instance = NodeService();

  final pingTimeout = Duration(milliseconds: 750);

  Future<void> init() async {
  }

  Future<void> close() async {
  }

  Future<List<Node>> startDiscovery(Definition definition) async {
    final results = await Future.wait(definition.dnsSeeds.map(
      (seed) async {
        var addresses = _dnsCache[seed];
        if (addresses == null) {
          try {
            addresses = await InternetAddress.lookup(seed);
          } catch (e) {
            print('DNS Failed: $e');
            addresses = [];
          }
          _dnsCache.putIfAbsent(seed, () => addresses);
        }
        return addresses;
      },
    ));
    final addresses = results.where((el) => el != null).reduce((a, b) => a + b).toList();
    print('onDnsDiscovery: ${definition.coinName}: addresses $addresses');
    return addresses.map((address) => Node(address, definition.port)).toList();
  }

  Future<bool> checkNode(Node node) async {
    try{
      final socket = await Socket.connect(node.address, node.port, timeout: Duration(milliseconds: 750));
      await socket.close();
      return Future<bool>.value(true);
    } catch (e) {
      return Future<bool>.value(false);
    }
  }

  Socket _currentSocket = null;

  void connectToNode(Node node) async {
    try{
      _currentSocket = await Socket.connect(node.address, node.port, timeout: Duration(milliseconds: 750));
      _currentSocket.listen(dataHandler, onError: errorHandler, onDone: doneHandler, cancelOnError: false);
      while(true) {

        if (MessageManager.instance.sendMessage is Disconnect) {
          doneHandler();
          return;
        }


        MessageManager.instance.sendMessage = None.instance;
      }
    } catch(e) {
      doneHandler();
    }
  }

  void dataHandler(data){
    print(new String.fromCharCodes(data).trim());
  }

  void errorHandler(error, StackTrace trace){
    print(error);
  }

  void doneHandler(){
    _currentSocket?.destroy();
  }

// 1. lookup dns
// 2. check nodes are open
// 3. connect to open nodes
// 4. send handshake and ack
// 5. send repeated getaddr until we get two responses
// 6. disconnect
}
