import 'package:bitcoin/wire.dart';
import 'package:diginodes/backend/backend.dart';
import 'package:diginodes/domain/node_list.dart';
import 'package:hex/hex.dart';
import 'package:meta/meta.dart';

import '../coin_definitions.dart';
import 'internet_utils.dart';

typedef ProcessComplete = void Function(List<Node> nodes);
typedef ProcessStart = bool Function();

class AddressHandler {
  ///
  /// Return a list of new nodes received after de duping process being considered
  ///
  static void processAddresses(
      {@required NodeSet existingNodeSet,
      @required AddressMessage incomingMessage,
      @required Definition coinDefinition,
      @required ProcessStart processStart,
      @required ProcessComplete processComplete}) {
    if (processStart()) {
      return null;
    }
    incomingMessage.addresses.forEach((peer) => print(HEX.encode(peer.address)));
    List<Node> nodes = List();
    for (PeerAddress peerAddress in incomingMessage.addresses) {
      nodes.add(Node(
          InternetUtils.getInternetAddress(peerAddress.address), peerAddress.port, peerAddress.time, coinDefinition));
    }
    nodes.removeWhere((node) => existingNodeSet.contains(node));
    processComplete(nodes);
  }
}
