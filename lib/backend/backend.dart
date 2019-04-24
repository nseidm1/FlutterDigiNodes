import 'dart:async';
import 'dart:io';

import 'package:bignum/bignum.dart';
import 'package:bitcoin/wire.dart';
import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:diginodes/coin_definitions.dart';

final _dnsCache = Map<String, List<InternetAddress>>();

class Node {
  Node(this.address, this.port, this.def);

  final InternetAddress address;
  final int port;
  final Definition def;

  bool open = false;

  @override
  String toString() {
    return 'Node{address: $address, port: $port, open: $open}';
  }
}

class NodeService {
  static final instance = NodeService();

  final pingTimeout = Duration(milliseconds: 750);

  Future<void> init() async {}

  Future<void> close() async {}

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
    return addresses.map((address) => Node(address, definition.port, definition)).toList();
  }

  Future<bool> checkNode(Node node) async {
    try {
      final socket = await Socket.connect(node.address, node.port, timeout: Duration(milliseconds: 750));
      await socket.close();
      return Future<bool>.value(true);
    } catch (e) {
      return Future<bool>.value(false);
    }
  }

// 1. lookup dns
// 2. check nodes are open
// 3. connect to open nodes
// 4. send handshake and ack
// 5. send repeated getaddr until we get two responses
// 6. disconnect
}

class NodeConnection {
  NodeConnection(this._node);

  final Node _node;
  final _builder = BytesBuilder();
  final _incomingMessages = StreamController<Message>.broadcast();
  Socket _socket;
  bool _connected = false;

  bool get isConnected => _connected;

  Stream<Message> get incomingMessages => _incomingMessages.stream;

  Future<void> connect(Definition definition) async {
    _socket = await Socket.connect(
      _node.address,
      _node.port,
      timeout: const Duration(milliseconds: 750),
    );
    _socket.setOption(SocketOption.tcpNoDelay, true);
    _socket.listen(_dataHandler, onError: _errorHandler, onDone: _doneHandler);
    _connected = true;
  }

  Future<void> sendMessage(Message message) async {
    final bytes = Message.encode(message, _node.def.packetMagic, _node.def.protocolVersion);
    print('sending message $message');
    _socket.add(bytes);
  }

  Future<void> close() async {
    _connected = false;
    await _socket.close();
    _socket?.destroy();
  }

  void _dataHandler(List<int> data) {
    _builder.add(data);
    final allBytes = _builder.toBytes();
    try {
      final message = Message.decode(allBytes, _node.def.protocolVersion);
      print('_dataHandler decoded: ${message}');
      _incomingMessages.add(message);
      _builder.clear();
      _builder.add(allBytes.sublist(message.byteSize));
    } catch (e) {
      print('_dataHandler unsupported message: ${e}');
    }
  }

  void _errorHandler(error, StackTrace trace) {
    print('socket error: $error');
  }

  void _doneHandler() {
    close();
  }
}
