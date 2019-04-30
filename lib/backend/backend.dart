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
      var bytes = Message.encode(message, _node.def.packetMagic, _node.def.protocolVersion);
      _socket.add(bytes);
      print('Message sent $message');
    } catch (e) {
      _homeLogicClose();
    }
  }

  ///This is not called directly from this class,
  ///instead _homeLogicClose() is called in HomeLogic, which calls here.
  Future<void> close() async {
    _connected = false;
    _socket?.destroy();
  }

  Future<void> _dataHandler(List<int> data) async {
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
        _pruneUnsupportedMessage();
        _attemptToFindMessage();
        print('Pruning unsupported message: $e');
      } else if (e is SerializationException) {
        if (e.toString().contains("Too few bytes to be a Message")) {
          // Do nothing, a full message has yet to be retrieved
          print('Waiting for the rest of the message');
        }
      } else {
        print('$e');
      }
    }
  }

  void _attemptToDeserializeMessage() {
    final allBytes = _builder.toBytes();
    final message = Message.decode(allBytes, _node.def.protocolVersion);
    print('_dataHandler decoded: $message');
    _incomingMessages.add(message);
    _builder.clear();
    _builder.add(allBytes.sublist(message.byteSize));
  }

  void _pruneUnsupportedMessage() {
    final bytes = _builder.toBytes();
    int offset = _findSecondMagicOffset(_builder.toBytes());
    _builder.clear();
    if (offset > 0) {
      _builder.add(bytes.sublist(offset));
    }
  }

  bool _pruneJunk() {
    final packetMagic = _node.def.packetMagic;
    final allBytes = Uint8List.fromList(_builder.toBytes()).buffer.asByteData();
    if (allBytes.lengthInBytes >= 4 && allBytes.getUint32(0, Endian.big) != packetMagic) {
      for (int i = 0; i < allBytes.lengthInBytes - 4; i++) {
        if (allBytes.getUint32(i, Endian.big) == packetMagic) {
          final holder = _builder.toBytes();
          _builder.clear();
          _builder.add(holder.sublist(i));
          print('Junk pruned');
          return true;
        }
      }
    }
    return false;
  }

  int _findSecondMagicOffset(List<int> bytes) {
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
    print('socket done');
    _homeLogicClose();
  }
}
