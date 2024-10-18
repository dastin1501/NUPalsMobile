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
  List<String> _userInterests = [];
  bool _isSpecificInterest = true;
  bool _isLoading = true; // Loading indicator

  @override
  void initState() {
    super.initState();
    _fetchUserInterests(); // Fetch the user's interests first
    _fetchAllUsers();
  }

  Future<void> _fetchUserInterests() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5000/api/users/profile/${widget.userId}'));

      if (response.statusCode == 200) {
        final user = jsonDecode(response.body);
        setState(() {
          _userInterests = List<String>.from(user['customInterests']); // Store user's interests
        });
      } else {
        throw Exception('Failed to load user interests');
      }
    } catch (error) {
      setState(() {
        _isLoading = false; // Stop loading
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user interests: ${error.toString()}')),
      );
    }
  }

  Future<void> _fetchAllUsers() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5000/api/users'));

      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body);
        setState(() {
          // Filter out the current user
          _allUsers = users.cast<Map<String, dynamic>>()
              .where((user) => user['_id'] != widget.userId)
              .toList();
          _matches = _filterUsersByCommonInterests(); // Initialize matches based on common interests
          _isLoading = false; // Stop loading
        });
      } else {
        throw Exception('Failed to load users');
      }
    } catch (error) {
      setState(() {
        _isLoading = false; // Stop loading
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: ${error.toString()}')),
      );
    }
  }

  List<Map<String, dynamic>> _filterUsersByCommonInterests() {
    return _allUsers.where((user) {
      // Check if there is at least one matching interest
      return user['customInterests'].any((interest) => 
          _userInterests.contains(interest));
    }).toList();
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
                labelText: _isSpecificInterest ? 'Search by Specific Interest' : 'Search by Category',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  // For specific interest, filter based on user input
                  if (_isSpecificInterest) {
                    _matches = _allUsers.where((user) {
                      return user['customInterests']
                          .any((interest) => interest.toLowerCase().contains(value.toLowerCase()));
                    }).toList();
                  } // For categorized interests, implement your existing logic if needed
                });
              },
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isSpecificInterest = true;
                    });
                  },
                  child: Text('Specific Interest'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isSpecificInterest = false;
                    });
                  },
                  child: Text('Categorized Interest'),
                ),
              ],
            ),
            SizedBox(height: 20),
            if (_isLoading)
              Center(child: CircularProgressIndicator()) // Show loading indicator
            else
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
                          '${user['username']} - ${user['customInterests'].join(', ')}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.person_add),
                          onPressed: () {
                            followUser(user['_id']);
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

  Future<void> followUser(String userIdToFollow) async {
    final response = await http.post(
      Uri.parse('http://localhost:5000/api/profile/${widget.userId}/follow'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'followId': userIdToFollow}),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User followed')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to follow user')),
      );
    }
  }
}
