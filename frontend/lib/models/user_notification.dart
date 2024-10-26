// models/user_notification.dart

class UserNotification {
  final String id;
  final String message;
  final String timestamp;
  final String senderId; // Add this line

  UserNotification({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.senderId, // Add this line
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['_id'],
      message: json['message'],
      timestamp: json['timestamp'],
      senderId: json['senderId']['_id'], // Assuming senderId is populated with an object
    );
  }
}
