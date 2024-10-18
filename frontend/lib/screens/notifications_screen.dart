import 'package:flutter/material.dart';
import 'package:frontend/provider/notification_provider.dart';
import 'package:frontend/models/notification.dart' as models; // Import your custom model with an alias
import 'package:provider/provider.dart';

class NotificationScreen extends StatelessWidget {
  // Accept userId as a constructor parameter
  final String userId;

  NotificationScreen({required this.userId}); // Constructor

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: FutureBuilder(
        future: provider.fetchNotifications(userId), // Use the passed userId
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          return ListView.builder(
            itemCount: provider.notifications.length,
            itemBuilder: (context, index) {
              final notification = provider.notifications[index] as models.NotificationModel; // Cast to your model

              return ListTile(
                title: Text(notification.message), // Use your model's properties
                subtitle: Text(notification.timestamp.toString()), // Assuming timestamp is a DateTime
              );
            },
          );
        },
      ),
    );
  }
}
