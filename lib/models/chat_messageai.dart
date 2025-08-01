// In lib/models/chat_messageai.dart

import 'dart:typed_data';
import 'package:uuid/uuid.dart'; 

enum MessageType { user, bot, error }

class ChatMessage {
  final String id; // This is the required 'id' field
  String text;
  final MessageType messageType;
  final Uint8List? imageBytes;

  ChatMessage({required this.text, required this.messageType, this.imageBytes})
    : id = const Uuid().v4();
}
