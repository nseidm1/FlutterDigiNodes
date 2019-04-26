import 'dart:core';

final coinDefinitions = const <Definition>[
  DigiByteCoinDefinition(),
  BitcoinDiamondCoinDefinition(),
  BitcoinGoldCoinDefinition(),
];

abstract class Definition {
  const Definition();

  bool get allowEmptyPeers;

  List<String> get dnsSeeds;

  String get coinName;

  int get protocolVersion;

  int get port;

  int get packetMagic;
}

class DigiByteCoinDefinition implements Definition {
  const DigiByteCoinDefinition();

  @override
  final bool allowEmptyPeers = false;

  @override
  final List<String> dnsSeeds = const <String>[
    "seed.digibyteservers.io",
    "seed2.hashdragon.com",
    "dgb.cryptoservices.net",
    "digiexplorer.info",
    "seed1.digibyte.io",
    "seed2.digibyte.io",
    "seed3.digibyte.io",
    "digihash.co",
    "seed.digibyteprojects.com",
  ];

  @override
  final String coinName = "DigiByte";

  @override
  final int protocolVersion = 70016;

  @override
  final int port = 12024;

  @override
  final int packetMagic = 0xfac3b6da;
}

class BitcoinDiamondCoinDefinition implements Definition {
  const BitcoinDiamondCoinDefinition();

  @override
  final bool allowEmptyPeers = false;

  @override
  final List<String> dnsSeeds = const <String>[
    "seed1.dns.btcd.io",
    "seed2.dns.btcd.io",
    "seed3.dns.btcd.io",
    "seed4.dns.btcd.io",
    "seed5.dns.btcd.io",
    "seed6.dns.btcd.io"
  ];

  @override
  final String coinName = "Bitcoin Diamond";

  @override
  final int protocolVersion = 70015;

  @override
  final int port = 7117;

  @override
  final int packetMagic = 0xbddeb4d9;
}

class BitcoinGoldCoinDefinition implements Definition {
  const BitcoinGoldCoinDefinition();

  @override
  final bool allowEmptyPeers = false;

  @override
  final List<String> dnsSeeds = const <String>[
    "eu-dnsseed.bitcoingold-official.org",
    "dnsseed.bitcoingold.org",
    "dnsseed.bitcoingold.dev",
  ];

  @override
  final String coinName = "Bitcoin Gold";

  @override
  final int protocolVersion = 70016;

  @override
  final int port = 8338;

  @override
  final int packetMagic = 0xe1476d44;
}
