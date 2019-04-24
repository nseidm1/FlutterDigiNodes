import 'package:collection/collection.dart';
import 'package:diginodes/backend/backend.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class NodeSet extends DelegatingSet<Node> with ChangeNotifier {
  NodeSet() : super({});

  ScrollController _nodesScrollController = ScrollController();

  ScrollController get nodesScrollController => _nodesScrollController;


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
    if (length > 5) {
      try {
        _nodesScrollController.animateTo(_nodesScrollController.position.maxScrollExtent,
            curve: Curves.easeOutBack, duration: Duration (milliseconds: 500));
      } catch(e) {
        print('${e}');
      }
    }
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
