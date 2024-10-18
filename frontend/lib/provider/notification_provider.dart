import 'package:flutter/material.dart';
import 'package:frontend/models/notification.dart';
import 'package:http/http.dart' as http; // Add this for HTTP requests
import 'dart:convert'; // For JSON parsing

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> notifications = [];
  final String baseUrl; // Base URL for API requests

  // Constructor with base URL parameter
  NotificationProvider(this.baseUrl);

  Future<void> fetchNotifications(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/notifications/$userId'));
    
    if (response.statusCode == 200) {
      // Assuming the response body contains a JSON array of notifications
      final List<dynamic> jsonData = json.decode(response.body);
      notifications = jsonData.map((json) => NotificationModel(
        message: json['message'],
        type: json['type'],
        timestamp: DateTime.parse(json['timestamp']),
      )).toList();
      notifyListeners();
    } else {
      throw Exception('Failed to load notifications');
    }
  }
}
