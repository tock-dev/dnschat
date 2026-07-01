import 'dart:convert';

import 'package:dnschat/pages/home.dart';

class ChatMessage {
  final String text;
  final String sender;
  final DateTime timestamp;

  bool get isMine => sender == username;

  ChatMessage(this.text, this.sender, this.timestamp);

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      map['text'],
      map['sender'],
      DateTime.parse(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'sender': sender,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  String toJson() => json.encode(toMap());

  factory ChatMessage.fromJson(String source) =>
      ChatMessage.fromMap(json.decode(source));
}
