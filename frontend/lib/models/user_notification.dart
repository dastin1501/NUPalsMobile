// lib/models/user_notification.dart
class UserNotification {
  final String id;
  final String message;
  final String timestamp;

  UserNotification({
    required this.id,
    required this.message,
    required this.timestamp,
  });

  // Factory constructor to parse JSON
  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['_id'],
      message: json['message'], // Adjust this field name to match your API response
      timestamp: json['timestamp'], // Adjust as needed
    );
  }
}
