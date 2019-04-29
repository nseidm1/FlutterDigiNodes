import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bitcoin/wire.dart';
import 'package:diginodes/coin_definitions.dart';
import 'package:diginodes/domain/node.dart';
import 'package:meta/meta.dart';

final _dnsCache = Map<String, List<InternetAddress>>();

class NodeService {
  static final instance = NodeService();

  static const PING_TIMEOUT = 1000;

  final pingTimeout = Duration(milliseconds: PING_TIMEOUT);

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
    return addresses.map((address) => Node(address, definition.port, 0, definition, open: false)).toList();
  }

  Future<bool> checkNode(Node node) async {
    try {
      final socket = await Socket.connect(node.address, node.port, timeout: Duration(milliseconds: 1500));
      await socket.close();
      return Future<bool>.value(true);
    } catch (e) {
      return Future<bool>.value(false);
    }
  }
}

typedef Close = void Function();

class NodeConnection {
  NodeConnection({
    @required Close close,
    @required Node node,
  })  : _homeLogicClose = close,
        _node = node;

  final Node _node;
  final Close _homeLogicClose;
  final _builder = BytesBuilder();
  final _incomingMessages = StreamController<Message>.broadcast();
  Socket _socket;
  bool _connected = false;

  bool get isConnected => _connected;

  Stream<Message> get incomingMessages => _incomingMessages.stream;
  Socket get socket => _socket;

  Future<void> connect(Definition definition) async {
    _socket = await Socket.connect(
      _node.address,
      _node.port,
      timeout: const Duration(milliseconds: 1500),
    );
    _socket.setOption(SocketOption.tcpNoDelay, true);
    _socket.listen(_dataHandler, onError: _errorHandler, onDone: _doneHandler);
    _connected = true;
  }

  Future<void> sendMessage(Message message) async {
    try {
      var bytes = Message.encode(message, _node.def.packetMagic, _node.def.protocolVersion);
      //print('message bytes: ${HEX.encode(bytes)}');
      _socket.add(bytes);
      print('Message sent $message');
    } catch (e) {
      _homeLogicClose();
    }
  }

  ///This is not called directly from this class,
  ///instead _homeLogicClose() is called in HomeLogic, which calls here.
  close() {
    _connected = false;
    _socket?.destroy();
  }

  Future<void> _dataHandler(List<int> data) async {
    _builder.add(data);
    attemptToFindMessage();
  }

  void attemptToFindMessage() {
    try {
      attemptToDeserializeMessage();
    } catch (e) {
      if (e is ArgumentError) {
        pruneUnsupportedMessage();
        attemptToFindMessage();
      }
    }
  }

  void attemptToDeserializeMessage() {
    final allBytes = _builder.toBytes();
    final message = Message.decode(allBytes, _node.def.protocolVersion);
    print('_dataHandler decoded: $message');
    _incomingMessages.add(message);
    _builder.clear();
    _builder.add(allBytes.sublist(message.byteSize));
  }

  void pruneUnsupportedMessage() {
    final bytes = _builder.toBytes();
    int offset = findSecondMagicPacketOffset(_builder.toBytes());
    if (offset != -1) {
      _builder.clear();
      _builder.add(bytes.sublist(offset));
    } else {
      _builder.clear();
    }
  }

  int findSecondMagicPacketOffset(List<int> bytes) {
    final packetMagic = _node.def.packetMagic;
    final allBytes = Uint8List.fromList(bytes).buffer.asByteData();
    var magicOccurrence = 0;
    for (int i = 0; i < allBytes.lengthInBytes - 4; i++) {
      if (allBytes.getUint32(i, Endian.big) == packetMagic) {
        if (magicOccurrence == 1) {
          return i;
        } else {
          magicOccurrence++;
        }
      }
    }
    return -1;
  }

  void _errorHandler(error, StackTrace trace) {
    print('socket error: $error');
    _homeLogicClose();
  }

  void _doneHandler() {
    _homeLogicClose();
  }
}
