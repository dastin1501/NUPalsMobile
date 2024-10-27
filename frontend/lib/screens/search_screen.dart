import 'dart:math';
import 'package:flutter/material.dart';
import 'package:frontend/screens/view_profile_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/api_constant.dart'; // Import the ApiConstants
import '../utils/constants.dart'; // Import your constants for colors
 
class SearchScreen extends StatefulWidget {
  final String userId;
 
  SearchScreen({required this.userId});
 
  @override
  _SearchScreenState createState() => _SearchScreenState();
}
 
class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _matches = [];
  List<Map<String, dynamic>> _allUsers = [];
  List<String> _userInterests = [];
  List<String> _following = [];
  bool _isLoading = true;
 
  @override
  void initState() {
    super.initState();
    _fetchUserInterests();
    _fetchAllUsers();
  }
 
  Future<void> _fetchUserInterests() async {
  try {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/api/users/profile/${widget.userId}'));
    if (response.statusCode == 200) {
      final user = jsonDecode(response.body);
 
      setState(() {
        _userInterests = List<String>.from(user['customInterests']);
        // Map `following` IDs to strings explicitly
        _following = List<String>.from(user['following'].map((f) => f.toString()));
      });
    } else {
      throw Exception('Failed to load user interests');
    }
  } catch (error) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load user interests: ${error.toString()}')),
    );
  }
}
 
 
  Future<void> _fetchAllUsers() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/api/users'));
      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body);
        setState(() {
          _allUsers = users.cast<Map<String, dynamic>>()
              .where((user) => user['_id'] != widget.userId)
              .toList();
          _matches = _getTopMatches().take(3).toList(); // Initial matches
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load users');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: ${error.toString()}')),
      );
    }
  }
 
  List<Map<String, dynamic>> _getTopMatches() {
    return _allUsers.where((user) {
      return user['customInterests'].any((interest) => _userInterests.contains(interest));
    }).toList()
      ..sort((a, b) {
        int aMatches = a['customInterests'].where((interest) => _userInterests.contains(interest)).length;
        int bMatches = b['customInterests'].where((interest) => _userInterests.contains(interest)).length;
        return bMatches.compareTo(aMatches);
      });
  }
 
  void _shuffleAndRefresh() {
    setState(() {
      _matches.shuffle(Random());
      _matches = _matches.take(3).toList(); // Limit to 3 matches
    });
  }
 
 
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 246, 244, 244), // Consistent background color
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Make Connections',
              style: TextStyle(
                color: nuBlue, // Apply nuBlue for text
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Specific Interest',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: nuBlue), // Consistent focus border color
                ),
              ),
              onChanged: (value) {
                setState(() {
                  String searchText = _searchController.text.toLowerCase();
                  _matches = _getTopMatches().where((user) {
                    final List<dynamic> interests = user['customInterests'] ?? [];
                    return interests.any((interest) => interest.toString().toLowerCase().contains(searchText));
                  }).toList().take(3).toList(); // Limit to 3 matches
                });
              },
            ),
            SizedBox(height: 20),
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _matches.length,
                  itemBuilder: (context, index) {
                    final user = _matches[index];
                    final isFollowing = _following.contains(user['_id']);
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
leading: CircleAvatar(
  backgroundColor: nuBlue,
  backgroundImage: user['profilePicture'] != null && user['profilePicture'].isNotEmpty
      ? MemoryImage(base64Decode(user['profilePicture']!.split(',').last)) // Remove the prefix and decode
      : AssetImage('assets/images/profile_pic.jpg') as ImageProvider,
),
 
                        title: Text(
                          user['username'],
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(user['customInterests'].join(', ')),
 trailing: IconButton(
  icon: Icon(
    _following.contains(user['_id']) ? Icons.check_circle : Icons.person_add,
    color: _following.contains(user['_id']) ? Colors.green : null, // Green for followed
  ),
  onPressed: _following.contains(user['_id'])
      ? null // Disable button if already following
      : () => followUser(user['_id']), // Enable follow action if not followed
),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewProfileScreen(userId: user['_id']),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _shuffleAndRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: nuBlue, // Match your theme color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
  'Refresh Users',
  style: TextStyle(color: Colors.white),
),
            ),
          ],
        ),
      ),
    );
  }
 
  Future<void> followUser(String userIdToFollow) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/profile/${widget.userId}/follow'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'followId': userIdToFollow}),
    );
 
   if (response.statusCode == 200) {
    setState(() {
      // Update the following list immediately
      _following.add(userIdToFollow); // Add the new followed user
      // Optional: Refresh the user list if necessary
      // _fetchAllUsers(); // Comment this out if you want to avoid resetting
    });
 
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User followed')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to follow user: ${response.body}')),
    );
  }
 
  }
}
 