import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'messaging_screen.dart'; // Import your MessagingScreen
import '../utils/api_constant.dart'; // Import the ApiConstants

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
        Uri.parse('${ApiConstants.baseUrl}/api/users/mutual-followers/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> followers = jsonDecode(response.body);

        // Use a Map to track unique followers by userId
        final Map<String, Map<String, dynamic>> uniqueFollowers = {};
        for (var follower in followers) {
          // Ensure the dynamic is cast to Map<String, dynamic>
          final Map<String, dynamic> followerMap = follower as Map<String, dynamic>;

          // Add unique entries based on userId
          uniqueFollowers[followerMap['userId']] = followerMap;
        }

        // Convert the unique Map back to a List<Map<String, dynamic>>
        setState(() {
          _mutualFollowers = uniqueFollowers.values.toList().cast<Map<String, dynamic>>();
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
