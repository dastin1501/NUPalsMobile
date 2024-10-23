import 'dart:math';
import 'package:flutter/material.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/api_constant.dart'; // Import the ApiConstants

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
  List<String> _searchedInterests = []; // To store the searched interests

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
          _following = List<String>.from(user['follows'] ?? []);
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
          _matches = _getTopMatches(); // Initial matches
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

  List<Map<String, dynamic>> _filterUsersByCommonInterests() {
    return _allUsers.where((user) {
      return user['customInterests'].any((interest) =>
          _userInterests.contains(interest));
    }).toList();
  }

  List<Map<String, dynamic>> _getTopMatches() {
    List<Map<String, dynamic>> filteredUsers = _filterUsersByCommonInterests();
    
    // Sort the filtered users based on the number of interest matches
    filteredUsers.sort((a, b) {
      int aMatches = a['customInterests']
          .where((interest) => _userInterests.contains(interest))
          .length;
      int bMatches = b['customInterests']
          .where((interest) => _userInterests.contains(interest))
          .length;
      return bMatches.compareTo(aMatches);
    });

    return filteredUsers.take(3).toList(); // Limit to 3 matches
  }

  void _shuffleAndRefresh() {
  setState(() {
    String searchText = _searchController.text.toLowerCase();
    List<Map<String, dynamic>> filteredMatches;

    // First, filter users by common interests (users with at least one matching interest)
    filteredMatches = _filterUsersByCommonInterests();

    // If there's search text, filter further by the specific interest entered
    if (searchText.isNotEmpty) {
      filteredMatches = filteredMatches.where((user) {
        final List<dynamic> interests = user['customInterests'] ?? [];
        return interests.any((interest) =>
            interest.toString().toLowerCase().contains(searchText));
      }).toList();
    }

    // Shuffle the filtered matches
    filteredMatches.shuffle(Random());
    _matches = filteredMatches.take(3).toList(); // Limit to 3 matches
  });
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
                labelText: 'Search by Specific Interest',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  // Split input into a list, limit to the first 3 interests
                  _searchedInterests = _searchController.text.split(',')
                      .map((interest) => interest.trim())
                      .toList()
                      .take(3)
                      .toList();

                  // Update matches based on the searched interests
                  _matches = _filterUsersByCommonInterests().where((user) {
                    final List<dynamic> interests = user['customInterests'] ?? [];
                    return interests.any((interest) =>
                        _searchedInterests.contains(interest));
                  }).toList().take(3).toList(); // Limit to 3 matches
                });
              },
            ),
            SizedBox(height: 10),
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
                          backgroundColor: Colors.yellow,
                          child: Icon(Icons.person, size: 32),
                        ),
                        title: Text(
                          '${user['username']} - ${user['customInterests'].join(', ')}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        trailing: IconButton(
                          icon: Icon(isFollowing ? Icons.check : Icons.person_add),
                          onPressed: isFollowing
                              ? null
                              : () {
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
            ElevatedButton(
              onPressed: _shuffleAndRefresh,
              child: Text('Refresh Users'),
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
        _fetchAllUsers();
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
