import 'dart:core';

final coinDefinitions = const <Definition>[
  DigiByteCoinDefinition(),
  BitcoinCashCoinDefinition(),
];

/*
0 -> init(DigiByteCoinDefition.get())
1 -> init(BitcoinCoinDefition.get())
2 -> init(VertCoinDefinition.get())
3 -> init(RapidsCoinDefition.get())
4 -> init(DogeCoinDefition.get())
5 -> init(ZCashCoinDefition.get())
6 -> init(DashCoinDefinition.get())
7 -> init(BitcoinGoldCoinDefinition.get())
8 -> init(BitcoinCashCoinDefinition.get())
9 -> init(BitcoinDiamondCoinDefinition.get())
10 -> init(BitcoinSVCoinDefinition.get())
11 -> init(LitecoinDefinition.get())
12 -> init(BlocknetDefinition.get())
13 -> init(ZCoinDefinition.get())
14 -> init(KomodoDefinition.get())
15 -> init(StratisDefinition.get())
16 -> init(PivxCoinDefinition.get())
17 -> init(MueCoinDefinition.get())
18 -> init(PhoreCoinDefinition.get())
19 -> init(SyscoinDefinition.get())
*/

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
    "seed1.digibyte.co",
    "seed2.hashdragon.com",
    "dgb.cryptoservices.net",
    "digibytewiki.com",
    "digiexplorer.info",
    "seed1.digibyte.io",
    "seed2.digibyte.io",
    "seed3.digibyte.io",
    "digihash.co",
    "seed.digibyteprojects.com",
    "seed.digibyte.io",
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
