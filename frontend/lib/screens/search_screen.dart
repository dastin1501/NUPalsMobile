import 'package:flutter/material.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    _fetchAllUsers(); // Fetch all users from your backend
  }

  Future<void> _fetchAllUsers() async {
    try {
      final response = await http.get(Uri.parse('https://your-api-url.com/api/users'));

      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body);
        setState(() {
          _allUsers = users.cast<Map<String, dynamic>>();
          _matches = _allUsers;
        });
      } else {
        throw Exception('Failed to load users');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users')),
      );
    }
  }

  Future<void> followUser(String userIdToFollow) async {
    final response = await http.post(
      Uri.parse('https://your-api-url.com/api/profile/${widget.userId}/follow'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'followId': userIdToFollow}),
    );
    if (response.statusCode == 200) {
      print('User followed');
    } else {
      print('Failed to follow user');
    }
  }

  Future<void> unfollowUser(String userIdToUnfollow) async {
    final response = await http.post(
      Uri.parse('https://your-api-url.com/api/profile/${widget.userId}/unfollow'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'followId': userIdToUnfollow}),
    );
    if (response.statusCode == 200) {
      print('User unfollowed');
    } else {
      print('Failed to unfollow user');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        title: Text('Search', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Interest',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _matches = _allUsers
                      .where((user) =>
                          user['interests'].join(', ').toLowerCase().contains(value.toLowerCase()))
                      .toList();
                });
              },
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _matches.length,
                itemBuilder: (context, index) {
                  final user = _matches[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: Colors.yellow,
                        child: Icon(Icons.person, size: 32),
                      ),
                      title: Text(
                        '${user['username']} - ${user['interests'].join(', ')}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.person_add),
                        onPressed: () {
                          followUser(user['_id']); // Pass the actual userId here
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(userId: user['_id']),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
