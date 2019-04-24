import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class StringList extends DelegatingList<String> with ChangeNotifier {

  ScrollController _messagesScrollController = ScrollController();

  ScrollController get messagesScrollController => _messagesScrollController;

  StringList(List<String> base) : super(base);

  @override
  void add(String element) {
    super.add(element);
    notifyListeners();
    if (length > 5) {
      _messagesScrollController.animateTo(_messagesScrollController.position.maxScrollExtent + 50,
          curve: Curves.easeOutBack, duration: Duration (milliseconds: 500));
    }
  }
}