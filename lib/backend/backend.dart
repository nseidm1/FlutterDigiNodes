import 'dart:io';

import 'package:diginodes/coin_definitions.dart';

final _dnsCache = Map<String, List<InternetAddress>>();

class Node {
  Node(this.address, this.port);

  final InternetAddress address;
  final int port;
  bool open;
}

class NodeService {
  static final instance = NodeService();

  Future<void> init() async {
    // final runners = List.generate(6, (int index) => IsolateRunner.spawn());
    // loadBalancer = LoadBalancer(await Future.wait(runners));
  }

  Future<void> close() async {
    // return loadBalancer.close();
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

  Future<bool> checkNode(Node node, Duration timeout) async {
    try{
      final socket = await Socket.connect(node.address, node.port, timeout: timeout);
      await socket.close();
      return true;
    }
    catch (e) {
      return false;
    }
  }

// 1. lookup dns
// 2. check nodes are open
// 3. connect to open nodes
// 4. send handshake and ack
// 5. send repeated getaddr until we get two responses
// 6. disconnect
}
