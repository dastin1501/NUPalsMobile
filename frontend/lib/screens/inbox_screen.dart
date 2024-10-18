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
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _mutualFollowers.length,
          itemBuilder: (context, index) {
            final user = _mutualFollowers[index];
            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16.0),
                title: Text(
                  user['username'],
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['lastMessage'] ?? 'No messages yet'),
                    SizedBox(height: 4),
                    Text(
                      user['timestamp'] != null
                          ? DateTime.parse(user['timestamp']).toLocal().toString().split(' ')[0] // Display date only
                          : '',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                onTap: () => _navigateToMessaging(user['userId']),
              ),
            );
          },
        ),
      ),
    );
  }
}
