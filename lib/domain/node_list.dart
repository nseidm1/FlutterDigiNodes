import 'package:collection/collection.dart';
import 'package:diginodes/backend/backend.dart';
import 'package:flutter/foundation.dart';

class NodeSet extends DelegatingSet<Node> with ChangeNotifier {
  NodeSet() : super({});

  NodeSet.fromIterable(Iterable<Node> iterable)
      : super(Set<Node>.from(iterable));

  @override
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

  @override
  void clear() {
    super.clear();
    notifyListeners();
  }
}
