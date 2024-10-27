import 'package:flutter/material.dart';
import 'package:frontend/utils/constants.dart';
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

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}'); // Log the response body

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

  void _navigateToMessaging(String? otherUserId, String? otherUserName) {
    print('Navigating to messaging with:');
    print('UserId: $otherUserId');
    print('UserName: $otherUserName');

    if (otherUserId != null && otherUserName != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagingScreen(
            userId: widget.userId,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User information is missing.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom title replacing AppBar
            Text(
              'Your Connections',
              style: TextStyle(
                color: nuBlue, // Replace with nuBlue if defined elsewhere
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16), // Space between title and list
            _mutualFollowers.isEmpty
                ? Center(
                    child: CircularProgressIndicator() // Loading indicator
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: _mutualFollowers.length,
                      itemBuilder: (context, index) {
                        final user = _mutualFollowers[index];
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16.0),
                          leading: CircleAvatar(
                              backgroundImage: user['profilePicture'] != null
                                  ? NetworkImage(user['profilePicture'])
                                  : AssetImage('assets/images/profile_pic.jpg') as ImageProvider,
                            ),
                            title: Text(
                              user['username'] ?? 'Unknown User', // Default name if username is null
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
                            onTap: () => _navigateToMessaging(user['userId'], user['username']), // Ensure 'username' matches the key in your API response
                          ),
                        );
                      },
                    ),
                  ),
            // Show 'No Connections' text if no mutual followers
            if (_mutualFollowers.isEmpty) 
              Center(child: Text('No Connections', style: TextStyle(fontSize: 20, color: Color.fromARGB(255, 19, 0, 0)))),
          ],
        ),
      ),
    );
  }
}
