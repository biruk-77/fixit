// lib/models/chat_message.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String messageType;

  // --- FIELDS FOR ADVANCED FEATURES ---
  final Map<String, dynamic>?
  data; // For extra data like jobId or file metadata
  final Map<String, String>? reactions; // Map of userId -> emoji character

  // Structured reply information
  final String? replyToMessageId;
  final String? replyToMessageText;
  final String? replyToSenderName;
  final String? replyToMessageType;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.messageType = 'text',
    this.data,
    this.reactions,
    this.replyToMessageId,
    this.replyToMessageText,
    this.replyToSenderName,
    this.replyToMessageType,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      messageType: json['messageType'] ?? 'text',
      // --- DESERIALIZE NEW FIELDS ---
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : null,
      reactions: json['reactions'] != null
          ? Map<String, String>.from(json['reactions'])
          : null,
      replyToMessageId: json['replyToMessageId'],
      replyToMessageText: json['replyToMessageText'],
      replyToSenderName: json['replyToSenderName'],
      replyToMessageType: json['replyToMessageType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'messageType': messageType,
      // --- SERIALIZE NEW FIELDS ---
      'data': data,
      'reactions': reactions,
      'replyToMessageId': replyToMessageId,
      'replyToMessageText': replyToMessageText,
      'replyToSenderName': replyToSenderName,
      'replyToMessageType': replyToMessageType,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? messageType,
    Map<String, dynamic>? data,
    Map<String, String>? reactions,
    String? replyToMessageId,
    String? replyToMessageText,
    String? replyToSenderName,
    String? replyToMessageType,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      messageType: messageType ?? this.messageType,
      data: data ?? this.data,
      reactions: reactions ?? this.reactions,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToMessageText: replyToMessageText ?? this.replyToMessageText,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      replyToMessageType: replyToMessageType ?? this.replyToMessageType,
    );
  }
}
