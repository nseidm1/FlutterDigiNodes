import 'dart:math';

import 'package:bignum/bignum.dart';
import 'package:bitcoin/wire.dart';
import 'package:diginodes/domain/node.dart';

class CryptoUtils {
  static Random random = Random();

  static Message getVersionMessage(Node node) {
    final services = BigInteger.ZERO;
    final time = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    VersionMessage ver = new VersionMessage(
      clientVersion: node.def.protocolVersion,
      services: services,
      time: time,
      myAddress: PeerAddress.localhost(services: services, port: node.def.port),
      theirAddress: PeerAddress.localhost(services: services, port: node.def.port),
      nonce: random.nextInt(999999),
      subVer: "/" + node.def.coinName + ":" + ".1-Crawler" + "/",
      lastHeight: 0,
      relayBeforeFilter: false,
      coinName: node.def.coinName,
    );
    return ver;
  }
}
