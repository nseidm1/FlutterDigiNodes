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

  static const _PING_TIMEOUT = 2500;
  static final _pingTimeout = Duration(milliseconds: _PING_TIMEOUT);

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
      final socket = await Socket.connect(node.address, node.port, timeout: _pingTimeout);
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

  static const _SOCKET_CONNECT_TIMEOUT = 2500;
  static final _socketConnectTimeout = Duration(milliseconds: _SOCKET_CONNECT_TIMEOUT);

  final _node;
  final _homeLogicClose;
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
      timeout: _socketConnectTimeout,
    );
    _socket.setOption(SocketOption.tcpNoDelay, true);
    _socket.listen(_dataHandler, onError: _errorHandler, onDone: _doneHandler);
    _connected = true;
  }

  Future<void> sendMessage(Message message) async {
    try {
      _socket.add(Message.encode(message, _node.def.packetMagic, _node.def.protocolVersion));
      print('Message sent $message');
    } catch (e) {
      _homeLogicClose();
    }
  }

  ///This is not called directly from this class,
  ///instead _homeLogicClose() is called in HomeLogic, which calls here.
  void close() {
    _connected = false;
    _socket?.destroy();
  }

  void _dataHandler(List<int> data) {
    _builder.add(data);
    _pruneJunk();
    _attemptToFindMessage();
  }

  void _attemptToFindMessage() {
    try {
      //This recursively calls this function until a SerializationException is thrown by Message.decode
      _attemptToDeserializeMessage();
      _attemptToFindMessage();
    } catch (e) {
      if (e is ArgumentError) {
        print('Pruning unsupported message: $e');
        _pruneUnsupportedMessage();
        _attemptToFindMessage();
      } else if (e is SerializationException) {
        if (e.toString().contains("Too few bytes to be a Message")) {
          // Do nothing, a full message has yet to be retrieved
          // print('Waiting for the rest of the message');
        }
        if (e.toString().contains("Incorrect checksum provided in serialized message")) {}
      } else {
        print('$e');
      }
    }
  }

  void _attemptToDeserializeMessage() {
    final allBytes = _builder.toBytes();
    final message = Message.decode(allBytes, _node.def.protocolVersion);
    _builder.clear();
    _builder.add(allBytes.sublist(message.byteSize));
    _incomingMessages.add(message);
    print('_dataHandler decoded: $message');
  }

  void _pruneUnsupportedMessage() {
    List<int> packetMagics = _findPacketMagic(_builder.toBytes());
    if (packetMagics.length > 1) {
      _builder.add(_builder.takeBytes().sublist(packetMagics[1]));
    } else {
      _builder.clear();
    }
  }

  List<int> _findPacketMagic(List<int> bytes) {
    final indexes = List<int>();
    final packetMagic = _node.def.packetMagic;
    final allBytes = Uint8List.fromList(bytes).buffer.asByteData();
    for (int i = 0; i < allBytes.lengthInBytes - 4; i++) {
      if (allBytes.getUint32(i, Endian.big) == packetMagic) {
        indexes.add(i);
      }
    }
    return indexes;
  }

  bool _pruneJunk() {
    final packetMagic = _node.def.packetMagic;
    final allBytes = Uint8List.fromList(_builder.toBytes()).buffer.asByteData();
    if (allBytes.lengthInBytes >= 4 && allBytes.getUint32(0, Endian.big) != packetMagic) {
      for (int i = 0; i < allBytes.lengthInBytes - 4; i++) {
        if (allBytes.getUint32(i, Endian.big) == packetMagic) {
          _builder.add(_builder.takeBytes().sublist(i));
          print('Junk pruned');
          return true;
        }
      }
    }
    return false;
  }

  void _errorHandler(error, StackTrace trace) {
    print('socket error: $error');
    _homeLogicClose();
  }

  void _doneHandler() {
    print('socket done');
    _homeLogicClose();
  }
}
