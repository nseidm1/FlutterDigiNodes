import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class MessageList extends DelegatingList<String> with ChangeNotifier {

  ScrollController _messagesScrollController = ScrollController();

  ScrollController get messagesScrollController => _messagesScrollController;

  MessageList(List<String> base) : super(base);

  @override
  void add(String element) {
    super.add(element);
    notifyListeners();
    int totalPosition = _messagesScrollController.positions.length;
    if (totalPosition > 0 && _messagesScrollController.positions.elementAt(totalPosition - 1).maxScrollExtent != null) {
      _messagesScrollController.animateTo(_messagesScrollController.position.maxScrollExtent,
          curve: Curves.easeOutBack, duration: Duration (milliseconds: 500));
    }
  }
}