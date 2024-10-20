import 'package:flutter/material.dart';
import 'package:frontend/services/notification_service.dart';
import 'package:frontend/models/user_notification.dart';

class NotificationsScreen extends StatefulWidget {
  final String userId;

  NotificationsScreen({required this.userId});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<UserNotification>> _notificationsFuture;
  final NotificationService notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notificationsFuture = notificationService.fetchNotifications(widget.userId);
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
                return ListTile(
                  title: Text('Notification'), // Static text as title (you can customize it)
                  subtitle: Text(notification.message), // Use the correct field
                  trailing: Text(notification.timestamp), // Add timestamp if desired
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
