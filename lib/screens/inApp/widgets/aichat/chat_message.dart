import 'package:cloud_firestore/cloud_firestore.dart';

class AiChatMessage {
  final String id;
  final String role;
  final String content;
  final String? replyTo;
  final DateTime timestamp;
  bool isPinned;

  AiChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.replyTo,
    required this.timestamp,
    this.isPinned = false,
  });

  // Runtime-only
  bool get hasAnimated {
    final now = DateTime.now();
    return now.difference(timestamp).inSeconds >= 10;
  }

  factory AiChatMessage.fromFirestore(Map<String, dynamic> map, String id) {
    return AiChatMessage(
      id: id,
      role: map['role'] ?? 'user',
      content: map['content'] ?? '',
      replyTo: map['replyTo'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isPinned: map['isPinned'] ?? false,
    );
  }

  factory AiChatMessage.fromMap(Map<String, dynamic> map) {
    return AiChatMessage(
      id: map['id'] ?? '',
      role: map['role'] ?? 'user',
      content: map['content'] ?? '',
      replyTo: map['replyTo'],
      timestamp: DateTime.parse(map['timestamp']),
      isPinned: map['isPinned'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'replyTo': replyTo,
      'timestamp': timestamp.toIso8601String(),
      'isPinned': isPinned,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'role': role,
      'content': content,
      'replyTo': replyTo,
      'timestamp': Timestamp.fromDate(timestamp),
      'isPinned': isPinned,
    };
  }
}
