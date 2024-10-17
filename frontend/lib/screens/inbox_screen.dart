import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'messaging_screen.dart'; // Import your MessagingScreen

class InboxScreen extends StatefulWidget {
  final String userId;

  InboxScreen({required this.userId});

  @override
  _InboxScreenState createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<Map<String, dynamic>> _mutualFollowers = [];

  @override
  void initState() {
    super.initState();
    _fetchMutualFollowers();
  }

  Future<void> _fetchMutualFollowers() async {
    // Fetch mutual followers for the user
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/users/mutual-followers/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> followers = jsonDecode(response.body);
        setState(() {
          _mutualFollowers = followers.cast<Map<String, dynamic>>();
        });
      } else {
        throw Exception('Failed to load mutual followers');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load mutual followers: ${error.toString()}')),
      );
    }
  }

  void _navigateToMessaging(String otherUserId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagingScreen(
          userId: widget.userId,
          otherUserId: otherUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inbox'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _mutualFollowers.length,
          itemBuilder: (context, index) {
            final user = _mutualFollowers[index];
            return ListTile(
              title: Text(user['username']), // Display the username of the mutual follower
              subtitle: Text(user['lastMessage'] ?? 'No messages yet'), // Display last message if available
              onTap: () => _navigateToMessaging(user['userId']), // Navigate to MessagingScreen
            );
          },
        ),
      ),
    );
  }
}
