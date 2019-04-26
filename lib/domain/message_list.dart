import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class MessageList extends DelegatingList<String> with ChangeNotifier {
  MessageList() : super(<String>[]);

  @override
  void add(String element) {
    super.add(element);
    notifyListeners();
  }
}
