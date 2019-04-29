import 'dart:io';
import '../coin_definitions.dart';

class Node {
  Node(this.address, this.port, this.time, this.def, {bool open = false}) : _open = open;

  final InternetAddress address;
  final int port;
  final Definition def;
  final int time;
  bool _open;

  bool get open => _open;
  set open(open) => _open = open;

  @override
  String toString() {
    return 'Node{address: $address, port: $port, open: $open}';
  }

  @override
  bool operator ==(Object other) => other is Node && address == other.address;

  @override
  int get hashCode => address.hashCode;

  Map<String, dynamic> toJson() => {
        'address': address.address,
        'port': port,
        'time': time,
        'open': open,
      };
}
