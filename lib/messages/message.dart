import 'package:diginodes/messages/disconnect.dart';
import 'package:diginodes/messages/none.dart';

class Message {

  static var _messages = List<Message>.unmodifiable([new Disconnect()]);
  static List<Message> get messages => _messages;
}

class MessageManager {

  static MessageManager instance = MessageManager();
  Message sendMessage = None.instance;
}