import 'package:flutter/material.dart';
import 'package:frontend/screens/edit_profile_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/utils/constants.dart';
import '../utils/api_constant.dart'; // Import the ApiConstants

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
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/api/profile/$userId'));

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
        Uri.parse('${ApiConstants.baseUrl}/api/profile/$followId/follow'),
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
        Uri.parse('${ApiConstants.baseUrl}/api/profile/$followId/unfollow'),
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
    backgroundColor: const Color.fromARGB(255, 246, 244, 244),
    appBar: AppBar(
      title: Text(
        'Profile',
        style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255), fontSize: 24),
      ),
      backgroundColor: nuBlue,
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
          return SingleChildScrollView( // Add SingleChildScrollView here
            child: Column(
              children: [
                _TopPortion(profilePicture: user['profilePicture']), // Directly use _TopPortion here
                // Use a fixed height for the user information section below
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        '${user['firstName']} ${user['lastName']}',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FloatingActionButton.extended(
                            onPressed: () {
                              if (!_isOwnProfile) {
                                _isFollowing
                                    ? _unfollowUser(user['_id'])
                                    : _followUser(user['_id']);
                              }
                            },
                            heroTag: 'follow',
                            elevation: 0,
                            label: Text(_isFollowing ? 'Unfollow' : 'Follow'),
                            icon: const Icon(Icons.person_add_alt_1),
                          ),
                          const SizedBox(width: 16.0),
                          if (_isOwnProfile)
                            FloatingActionButton.extended(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfileScreen(userId: user['_id']),
                                  ),
                                );
                              },
                              heroTag: 'edit',
                              elevation: 0,
                              backgroundColor: Colors.red,
                              label: const Text("Edit Profile"),
                              icon: const Icon(Icons.edit),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ProfileInfoRow(
                        followers: user['followers']?.length ?? 0,
                        following: user['follows']?.length ?? 0,
                        posts: user['posts']?.length ?? 0,
                      ),
                      const SizedBox(height: 16),
                      // Additional user info
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
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    ),
  );
}


}

class _ProfileInfoRow extends StatelessWidget {
  final int followers;
  final int following;
  final int posts;

  const _ProfileInfoRow({
    Key? key,
    required this.followers,
    required this.following,
    required this.posts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      constraints: const BoxConstraints(maxWidth: 400),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _singleItem(context, 'Posts', posts),
          const VerticalDivider(),
          _singleItem(context, 'Followers', followers),
          const VerticalDivider(),
          _singleItem(context, 'Following', following),
        ],
      ),
    );
  }

  Widget _singleItem(BuildContext context, String title, int value) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall, // Use bodySmall instead of caption
          ),
        ],
      );
}

class _TopPortion extends StatelessWidget {
  final String? profilePicture;

  const _TopPortion({Key? key, this.profilePicture}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container( // Ensure the Stack has a defined size
      height: 200, // Set a fixed height
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 50),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [nuBlue, Colors.blueAccent],
              ),
            ),
          ),
          Center(
            child: CircleAvatar(
              radius: 60, // Size of the profile image
              backgroundImage: profilePicture != null && profilePicture!.isNotEmpty
                  ? NetworkImage(profilePicture!) // Load the image from the URL
                  : const AssetImage('assets/images/profile_pic.jpg') as ImageProvider, // Placeholder image
            ),
          ),
        ],
      ),
    );
  }
}
