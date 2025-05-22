import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String type;
  final String message;
  final String eventId;
  final String senderId;
  final DateTime timestamp;
  final bool read;

  AppNotification({
    required this.id,
    required this.type,
    required this.message,
    required this.eventId,
    required this.senderId,
    required this.timestamp,
    required this.read,
  });

  /// Factory to create a notification from Firestore document data
  factory AppNotification.fromDoc(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      type: data['type'] ?? 'unknown',
      message: data['message'] ?? '',
      eventId: data['eventId'] ?? '',
      senderId: data['senderId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      read: data['read'] ?? false,
    );
  }

  /// Convert this notification to a Firestore map
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'message': message,
      'eventId': eventId,
      'senderId': senderId,
      'timestamp': Timestamp.fromDate(timestamp),
      'read': read,
    };
  }


  String timeAgo() {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';

    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}
