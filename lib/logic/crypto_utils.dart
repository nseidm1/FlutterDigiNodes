import 'package:bignum/bignum.dart';
import 'package:bitcoin/wire.dart';
import 'package:diginodes/domain/node.dart';

class CryptoUtils {
  static Message getVersionMessage(Node node) {
    final services = BigInteger.ZERO;
    final time = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final peerAddress = PeerAddress.localhost(services: services, port: node.def.port);
    final subVersion = "/" + node.def.coinName + ":" + ".1-Crawler" + "/";
    return VersionMessage(
      clientVersion: node.def.protocolVersion,
      services: services,
      time: time,
      myAddress: peerAddress,
      theirAddress: peerAddress,
      nonce: 0,
      subVer: subVersion,
      lastHeight: 0,
      relayBeforeFilter: false,
      coinName: node.def.coinName,
    );
  }
}
