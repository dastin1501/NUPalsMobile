// lib/models/notification.dart

class NotificationModel {
  final String message; // Notification message
  final String type;    // Type of notification (e.g., alert, info)
  final DateTime timestamp; // When the notification was created

  NotificationModel({
    required this.message,
    required this.type,
    required this.timestamp,
  });
}
