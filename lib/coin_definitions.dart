import 'dart:core';

final coinDefinitions = const <Definition>[
  DigiByteCoinDefinition(),
  BitcoinCoinDefition(),
  BitcoinDiamondCoinDefinition(),
  BitcoinGoldCoinDefinition(),
  BlocknetDefinition(),
  DashCoinDefinition(),
  DogeCoinDefition(),
  KomodoDefinition(),
  LitecoinDefinition(),
  MueCoinDefinition(),
  PhoreCoinDefinition(),
  PivxCoinDefinition(),
  RapidsCoinDefition(),
  StratisDefinition(),
  VertCoinDefinition(),
  ZCashCoinDefition(),
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
  final int protocolVersion = 70017;

  @override
  final int port = 12024;

  @override
  final int packetMagic = 0xfac3b6da;
}

class BitcoinCoinDefition implements Definition {
  const BitcoinCoinDefition();

  @override
  final bool allowEmptyPeers = false;

  @override
  final List<String> dnsSeeds = const <String>[
    "seed.bitcoin.sipa.be", // Pieter Wuille
    "dnsseed.bluematt.me", // Matt Corallo
    "dnsseed.bitcoin.dashjr.org", // Luke Dashjr
    "seed.bitcoinstats.com", // Chris Decker
    "seed.bitcoin.jonasschnelli.ch", // Jonas Schnelli
    "seed.btc.petertodd.org", // Peter Todd
    "seed.bitcoin.sprovoost.nl", // Sjors Provoost
    "seed.bitnodes.io", // Addy Yeow
    "dnsseed.emzy.de", // Stephan Oeste
  ];

  @override
  final String coinName = "Bitcoin";

  @override
  final int protocolVersion = 70015;

  @override
  final int port = 8333;

  @override
  final int packetMagic = 0xf9beb4d9;
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

class BlocknetDefinition implements Definition {
  const BlocknetDefinition();

  @override
  final bool allowEmptyPeers = false;

  @override
  final List<String> dnsSeeds = const <String>[
    "178.62.90.213",
    "138.197.73.214",
    "34.235.49.248",
    "35.157.52.158",
    "18.196.208.65",
    "13.251.15.150",
    "13.229.39.34",
    "52.56.35.74",
    "35.177.173.53",
    "35.176.65.103",
    "35.178.142.231"
  ];

  @override
  final String coinName = "Blocknet";

  @override
  final int protocolVersion = 70712;

  @override
  final int port = 41412;

  @override
  final int packetMagic = 0xa1a0a2a3;
}

class DashCoinDefinition implements Definition {
  const DashCoinDefinition();

  @override
  final bool allowEmptyPeers = false;

  @override
  final List<String> dnsSeeds = const <String>["dnsseed.dash.org", "dnsseed.dashdot.io", "dnsseed.masternode.io"];

  @override
  final String coinName = "Dash";

  @override
  final int protocolVersion = 70213;

  @override
  final int port = 9999;

  @override
  final int packetMagic = 0xbf0c6bbd;
}

class DogeCoinDefition implements Definition {
  const DogeCoinDefition();

  @override
  final bool allowEmptyPeers = false;

  @override
  final List<String> dnsSeeds = const <String>[
    "seed.dogecoin.com",
    "seed.multidoge.org",
    "seed2.multidoge.org",
    "seed.doger.dogecoin.com"
  ];

  @override
  final String coinName = "Dogecoin";

  @override
  final int protocolVersion = 70004;

  @override
  final int port = 22556;

  @override
  final int packetMagic = 0xc0c0c0c0;
}

class KomodoDefinition implements Definition {
  const KomodoDefinition();

  @override
  final bool allowEmptyPeers = false;

  @override
  final List<String> dnsSeeds = const <String>[
    "seeds.veruscoin.io",
    "seeds.komodoplatform.com",
    "static.kolo.supernet.org",
    "dynamic.kolo.supernet.org"
  ];

  @override
  final String coinName = "Komodo";

  @override
  final int protocolVersion = 170007;

  @override
  final int port = 7770;

  @override
  final int packetMagic = 0xf9eee48d;
}

class LitecoinDefinition implements Definition {
  const LitecoinDefinition();

  @override
  final bool allowEmptyPeers = false;

  @override
  final List<String> dnsSeeds = const <String>[
    "seed-a.litecoin.loshan.co.uk",
    "dnsseed.thrasher.io",
    "dnsseed.litecointools.com",
    "dnsseed.litecoinpool.org",
    "dnsseed.koin-project.com"
  ];

  @override
  final String coinName = "Litecoin";

  @override
  final int protocolVersion = 70015;

  @override
  final int port = 9333;

  @override
  final int packetMagic = 0xfbc0b6db;
}

class MueCoinDefinition implements Definition {
  const MueCoinDefinition();

  @override
  final bool allowEmptyPeers = false;

  @override
  final List<String> dnsSeeds = const <String>[
    "dns1.monetaryunit.org",
    "dns2.monetaryunit.org",
    "dns3.monetaryunit.org"
  ];

  @override
  final String coinName = "MUE";

  @override
  final int protocolVersion = 70703;

  @override
  final int port = 19687;

  @override
  final int packetMagic = 0x91c4fdea;
}

class PhoreCoinDefinition implements Definition {
  const PhoreCoinDefinition();

  @override
  final bool allowEmptyPeers = false;

  @override
  final List<String> dnsSeeds = const <String>["dns0.phore.io", "phore.seed.rho.industries"];

  @override
  final String coinName = "Phore";

  @override
  final int protocolVersion = 70007;

  @override
  final int port = 11771;

  @override
  final int packetMagic = 0x91c4fde9;
}

class PivxCoinDefinition implements Definition {
  const PivxCoinDefinition();

  @override
  final bool allowEmptyPeers = false;

  @override
  final List<String> dnsSeeds = const <String>[
    "pivx.seed.fuzzbawls.pw",
    "pivx.seed2.fuzzbawls.pw",
    "coin-server.com",
    "s3v3nh4cks.ddns.net",
    "178.254.23.111"
  ];

  @override
  final String coinName = "Pivx";

  @override
  final int protocolVersion = 70915;

  @override
  final int port = 51472;

  @override
  final int packetMagic = 0x90c4fde9;
}

class RapidsCoinDefition implements Definition {
  const RapidsCoinDefition();

  @override
  final bool allowEmptyPeers = false;

  @override
  final List<String> dnsSeeds = const <String>["68.183.236.217", "159.65.189.155", "209.97.188.183", "104.248.169.67"];

  @override
  final String coinName = "Rapids";

  @override
  final int protocolVersion = 70914;

  @override
  final int port = 28732;

  @override
  final int packetMagic = 0x61a2f5cb;
}

class StratisDefinition implements Definition {
  const StratisDefinition();

  @override
  final bool allowEmptyPeers = false;

  @override
  final List<String> dnsSeeds = const <String>[
    "seednode1.stratisplatform.com",
    "seednode2.stratis.cloud",
    "seednode3.stratisplatform.com",
    "seednode4.stratis.cloud"
  ];

  @override
  final String coinName = "Stratis";

  @override
  final int protocolVersion = 70000;

  @override
  final int port = 16178;

  @override
  final int packetMagic = 0x70352205;
}

class SyscoinDefinition implements Definition {
  const SyscoinDefinition();

  @override
  final bool allowEmptyPeers = false;

  @override
  final List<String> dnsSeeds = const <String>[
    "seed1.syscoin.org",
    "seed2.syscoin.org",
    "seed3.syscoin.org",
    "seed4.syscoin.org"
  ];

  @override
  final String coinName = "Syscoin";

  @override
  final int protocolVersion = 70224;

  @override
  final int port = 8369;

  @override
  final int packetMagic = 0xf9beb4d9;
}

class VertCoinDefinition implements Definition {
  const VertCoinDefinition();

  @override
  final bool allowEmptyPeers = false;

  @override
  final List<String> dnsSeeds = const <String>["useast1.vtconline.org", "vtc.gertjaap.org"];

  @override
  final String coinName = "VertCoin";

  @override
  final int protocolVersion = 70015;

  @override
  final int port = 5889;

  @override
  final int packetMagic = 0xfabfb5da;
}

class ZCashCoinDefition implements Definition {
  const ZCashCoinDefition();

  @override
  final bool allowEmptyPeers = false;

  @override
  final List<String> dnsSeeds = const <String>["dnsseed.z.cash", "dnsseed.str4d.xyz", "dnsseed.znodes.org"];

  @override
  final String coinName = "ZCash";

  @override
  final int protocolVersion = 170007;

  @override
  final int port = 8233;

  @override
  final int packetMagic = 0x24e92764;
}

class ZCoinDefinition implements Definition {
  const ZCoinDefinition();

  @override
  final bool allowEmptyPeers = false;

  @override
  final List<String> dnsSeeds = const <String>[
    "amsterdam.zcoin.io",
    "australia.zcoin.io",
    "chicago.zcoin.io",
    "london.zcoin.io",
    "frankfurt.zcoin.io",
    "newjersey.zcoin.io",
    "sanfrancisco.zcoin.io",
    "tokyo.zcoin.io",
    "singapore.zcoin.io",
    "172.93.199.83",
    "209.97.133.14",
    "45.77.215.231",
    "54.202.208.55",
    "85.214.40.125",
    "104.207.146.219",
    "159.203.122.183",
  ];

  @override
  final String coinName = "Zcoin";

  @override
  final int protocolVersion = 90026;

  @override
  final int port = 8168;

  @override
  final int packetMagic = 0xe3d9fef1;
}
