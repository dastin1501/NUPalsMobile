// lib/services/notification_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/models/user_notification.dart'; // Adjust the path as necessary

class NotificationService {
  // Fetch notifications for a user
  Future<List<UserNotification>> fetchNotifications(String userId) async {
    final response = await http.get(Uri.parse('http://localhost:5000/api/notifications/$userId'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => UserNotification.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load notifications');
    }
  }
}
