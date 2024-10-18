import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification.dart'; // Import your NotificationModel

class NotificationService {
  final String baseUrl;

  NotificationService(this.baseUrl);

  // Fetch notifications for a specific user
  Future<List> fetchNotifications(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/notifications/$userId'));

      // Check if the response is successful (status code 200)
      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => NotificationModel.fromJson(data)).toList();
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (error) {
      // Handle any errors that occur during the fetch
      print('Error fetching notifications: $error');
      throw Exception('Failed to load notifications');
    }
  }

  // Send a follow request
  Future<void> sendFollowRequest(String followerId, String followeeId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/follow'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'followerId': followerId,
          'followeeId': followeeId,
        }),
      );

      // Check for successful response
      if (response.statusCode != 200) {
        throw Exception('Failed to send follow request: ${response.statusCode}');
      }
    } catch (error) {
      // Handle any errors that occur during the request
      print('Error sending follow request: $error');
      throw Exception('Failed to send follow request');
    }
  }

  // Notify users of a new post
  Future<void> notifyPost(String postId, String adminId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/notify-post'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'postId': postId,
          'adminId': adminId,
        }),
      );

      // Check for successful response
      if (response.statusCode != 200) {
        throw Exception('Failed to notify users of post: ${response.statusCode}');
      }
    } catch (error) {
      // Handle any errors that occur during the request
      print('Error notifying users of post: $error');
      throw Exception('Failed to notify users of post');
    }
  }
}
