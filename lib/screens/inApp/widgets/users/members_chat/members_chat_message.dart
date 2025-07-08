class MembersChatMessage {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final String? replyTo;
  final List<String>? seenBy;
  Map<String, List<String>>? reactions;

  MembersChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.seenBy,
    this.reactions,
    this.replyTo,
  });

  factory MembersChatMessage.fromFirestore(Map<String, dynamic> map, String id) {
    return MembersChatMessage(
      id: id,
      senderId: map['userId'],
      content: map['content'],
      replyTo: map['replyTo'],
      timestamp: map['timestamp'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.parse(map['timestamp']),
      seenBy: List<String>.from(map['seenBy'] ?? []),
      reactions: (map['reactions'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, List<String>.from(value)),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'content': content,
      'replyTo': replyTo,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'seenBy': seenBy,
      'reactions': reactions,
    };
  }

  MembersChatMessage copyWith({
    String? id,
    String? senderId,
    String? content,
    DateTime? timestamp,
    String? replyTo,
    List<String>? seenBy,
    Map<String, List<String>>? reactions,
  }) {
    return MembersChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      replyTo: replyTo ?? this.replyTo,
      seenBy: seenBy ?? this.seenBy,
      reactions: reactions ?? this.reactions,
    );
  }
}
