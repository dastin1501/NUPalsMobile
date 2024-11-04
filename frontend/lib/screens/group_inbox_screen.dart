import 'package:flutter/material.dart';
import 'package:frontend/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'group_message_screen.dart'; // Import your GroupMessageScreen
import '../utils/api_constant.dart'; // Import the ApiConstants

class GroupInboxScreen extends StatefulWidget {
  final String userId;

  GroupInboxScreen({required this.userId});

  @override
  _GroupInboxScreenState createState() => _GroupInboxScreenState();
}

class _GroupInboxScreenState extends State<GroupInboxScreen> {
  List<Map<String, dynamic>> _groupChats = [];
  List<String> _customInterests = [];
  String? _firstName; // To store user's first name
  String? _lastName; // To store user's last name

  @override
  void initState() {
    super.initState();
    _fetchGroupChats();
  }

  Future<void> _fetchGroupChats() async {
    try {
      // Fetch the user's profile data, including custom interests and name
      final userResponse = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/profile/${widget.userId}'), // Update to your user API endpoint
      );

      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        setState(() {
          _customInterests = List<String>.from(userData['customInterests']); // Use custom interests
          _firstName = userData['firstName']; // Store first name
          _lastName = userData['lastName'];   // Store last name
        });
      } else {
        _handleError('Failed to load user data: ${userResponse.body}');
        return; // Exit if user data fetch fails
      }

      // Fetch group chats that match custom interests
      if (_customInterests.isNotEmpty) {
        final groupResponse = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/api/group/chat/${widget.userId}'), // Your updated API endpoint to get group chats
        );

        if (groupResponse.statusCode == 200) {
          final List<dynamic> allGroupChats = jsonDecode(groupResponse.body);
          setState(() {
            // Filter group chats based on custom interests
            _groupChats = allGroupChats
                .where((chat) => _customInterests.contains(chat['title']))
                .cast<Map<String, dynamic>>()
                .toList();
          });
        } else {
          _handleError('Failed to load group chats: ${groupResponse.body}');
        }
      }
    } catch (error) {
      _handleError('Failed to load group chats: ${error.toString()}');
    }
  }

  Future<void> _navigateToGroupMessages(String groupChatId, String interest) async {
    try {
      // Fetch the count of users with the specified interest
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/group/countByInterest/$interest'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final int count = data['count'];

        if (count >= 3) {
          // Only navigate if there are 3 or more members with the same interest
          if (_firstName != null && _lastName != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupMessageScreen(
                  userId: widget.userId,
                  groupChatId: groupChatId,
                  firstName: _firstName!,
                  lastName: _lastName!,
                ),
              ),
            );
          } else {
            _handleError('User data not fully loaded');
          }
        } else {
          _handleError('Not enough members to join this group');
        }
      } else {
        _handleError('Error fetching member count');
      }
    } catch (error) {
      _handleError('Error fetching member count: ${error.toString()}');
    }
  }

  void _handleError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Inbox', style: TextStyle(color: Colors.white)),
        backgroundColor: nuBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _groupChats.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _groupChats.length,
                itemBuilder: (context, index) {
                  final groupChat = _groupChats[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16.0),
                      title: Text(
                        groupChat['title'],
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      onTap: () => _navigateToGroupMessages(groupChat['_id'], groupChat['title']), // Pass group ID and title as interest
                    ),
                  );
                },
              ),
      ),
    );
  }
}
