import 'dart:core';

final coinDefinitions = const <Definition>[
  DigiByteCoinDefinition(),
  BitcoinCashCoinDefinition(),
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

class BitcoinCashCoinDefinition implements Definition {
  const BitcoinCashCoinDefinition();

  @override
  final bool allowEmptyPeers = false;

  @override
  final List<String> dnsSeeds = const <String>[
    "seed.bitcoinabc.org",
    "seed-abc.bitcoinforks.org",
    "btccash-seeder.bitcoinunlimited.info",
    "seed.bitprim.org",
    "seed.deadalnix.me",
    "seeder.criptolayer.net",
  ];

  @override
  final String coinName = "Bitcoin Cash";

  @override
  final int protocolVersion = 70015;

  @override
  final int port = 8333;

  @override
  final int packetMagic = 0xe3e1f3e8;
}
