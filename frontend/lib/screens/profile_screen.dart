import 'package:flutter/material.dart';
import 'package:frontend/screens/edit_profile_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  ProfileScreen({required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _userProfile;
  bool _isFollowing = false;
  bool _isOwnProfile = false;

  @override
  void initState() {
    super.initState();
    _userProfile = fetchUserProfile(widget.userId);
  }

  Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5000/api/profile/$userId'));

      if (response.statusCode == 200) {
        final userProfile = jsonDecode(response.body);
        print(userProfile); // Debug print to check the response

        setState(() {
          _isFollowing = userProfile['followers'] != null &&
              userProfile['followers'].any((follower) => follower['_id'] == widget.userId);

          // Check if this profile belongs to the current user
          _isOwnProfile = userProfile['_id'] == widget.userId;
        });

        return userProfile;
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Failed to load profile: $error');
    }
  }

  Future<void> _followUser(String followId) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/profile/$followId/follow'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'followId': followId}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isFollowing = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Followed successfully!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Already following!')));
      }
    } catch (error) {
      print('Error following user: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to follow user!')));
    }
  }

  Future<void> _unfollowUser(String followId) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/profile/$followId/unfollow'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'followId': followId}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isFollowing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unfollowed successfully!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Not following this user!')));
      }
    } catch (error) {
      print('Error unfollowing user: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to unfollow user!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: nuBlue,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(color: nuYellow, fontSize: 24),
        ),
        backgroundColor: nuWhite,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final user = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: user['profileImage'] != null && user['profileImage'].isNotEmpty
                            ? NetworkImage(user['profileImage'])
                            : AssetImage('assets/default_avatar.png') as ImageProvider,
                      ),
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          Text('Followers: ${user['followers']?.length ?? 0}', style: TextStyle(color: nuYellow, fontSize: 18)),
                          Text('Follows: ${user['follows']?.length ?? 0}', style: TextStyle(color: nuYellow, fontSize: 18)),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Text('Name: ${user['firstName']} ${user['lastName']}', style: TextStyle(color: nuYellow, fontSize: 20)),
                    Text('Username: ${user['username']}', style: TextStyle(color: nuYellow, fontSize: 20)),
                    Text('Email: ${user['email']}', style: TextStyle(color: nuYellow, fontSize: 20)),
                    Text('Age: ${user['age']}', style: TextStyle(color: nuYellow, fontSize: 20)),
                    Text('College: ${user['college']}', style: TextStyle(color: nuYellow, fontSize: 20)),
                    Text('Year Level: ${user['yearLevel']}', style: TextStyle(color: nuYellow, fontSize: 20)),
                    SizedBox(height: 16),
                    Text('Bio: ${user['bio'] ?? "No bio available"}', style: TextStyle(color: nuYellow, fontSize: 20)),
                    SizedBox(height: 16),
                    Text('Custom Interests: ${user['customInterests']?.join(", ") ?? "None"}', style: TextStyle(color: nuYellow, fontSize: 20)),
                    SizedBox(height: 16),
                    Text('Categorized Interests: ${user['categorizedInterests']?.join(", ") ?? "None"}', style: TextStyle(color: nuYellow, fontSize: 20)),
                    SizedBox(height: 16),
                    if (!_isOwnProfile) // Only show follow/unfollow if not own profile
                      ElevatedButton(
                        onPressed: () {
                          if (_isFollowing) {
                            _unfollowUser(user['_id']);
                          } else {
                            _followUser(user['_id']);
                          }
                        },
                        child: Text(_isFollowing ? 'Unfollow' : 'Follow'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: nuWhite,
                          foregroundColor: nuBlue,
                        ),
                      ),
                    SizedBox(height: 16),
                    if (_isOwnProfile)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(userId: user['_id']),
                            ),
                          );
                        },
                        child: Text('Edit Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: nuWhite,
                          foregroundColor: nuBlue,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
