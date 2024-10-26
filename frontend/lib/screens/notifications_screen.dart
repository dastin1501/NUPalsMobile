// frontend/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_notification.dart';
import '../utils/api_constant.dart';
import 'profile_screen.dart'; // Import your existing ProfileScreen

class NotificationsScreen extends StatefulWidget {
  final String userId;

  NotificationsScreen({required this.userId});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<UserNotification>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _fetchNotifications(widget.userId);
  }

  Future<List<UserNotification>> _fetchNotifications(String userId) async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/api/notifications/$userId/notifications'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => UserNotification.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: FutureBuilder<List<UserNotification>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final notifications = snapshot.data!;
            if (notifications.isEmpty) {
              return Center(child: Text('No notifications available.'));
            }
            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return GestureDetector(
                  onTap: () {
                    // Navigate to existing ProfileScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(userId: notification.senderId), // Use senderId
                      ),
                    );
                  },
                  child: ListTile(
                    title: Text(notification.message),
                    subtitle: Text('Received on ${notification.timestamp}'),
                    trailing: Icon(Icons.notifications),
                  ),
                );
              },
            );
          } else {
            return Center(child: Text('No notifications available.'));
          }
        },
      ),
    );
  }
}
