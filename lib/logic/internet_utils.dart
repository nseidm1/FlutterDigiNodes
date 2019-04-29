import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';

class InternetUtils {
  static InternetAddress getInternetAddress(List<int> address) {
    const equality = ListEquality<int>();
    if (equality.equals(address.sublist(0, 12), const <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xFF, 0xFF])) {
      return InternetAddress(address.sublist(12).map((el) => el.toRadixString(10)).join('.'));
    } else {
      final view = Uint8List.fromList(address).buffer.asUint16List();
      return InternetAddress(view.map((el) => el.toRadixString(16)).join(':'));
    }
  }
}
