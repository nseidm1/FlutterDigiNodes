import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'node.dart';

class NodeSet extends DelegatingSet<Node> with ChangeNotifier {
  NodeSet() : super({});

  NodeSet.fromIterable(Iterable<Node> iterable) : super(Set<Node>.from(iterable));

  Node operator [](int index) => elementAt(index);

  @override
  bool add(Node value) {
    final result = super.add(value);
    notifyListeners();
    return result;
  }

  @override
  void addAll(Iterable<Node> elements) {
    super.addAll(elements);
    notifyListeners();
  }

  @override
  bool remove(Object value) {
    final result = super.remove(value);
    notifyListeners();
    return result;
  }

  @override
  void removeAll(Iterable<Object> elements) {
    super.removeAll(elements);
    notifyListeners();
  }

  List<Map<String, dynamic>> toJson() => map((el) => el.toJson()).toList(growable: false);
}
