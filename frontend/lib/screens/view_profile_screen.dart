import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/utils/constants.dart';
import '../utils/api_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'report_screen.dart';

class ViewProfileScreen extends StatefulWidget {
  final String userId;

  ViewProfileScreen({required this.userId});

  @override
  _ViewProfileScreenState createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  Future<Map<String, dynamic>>? _userProfile; // Make it nullable
  String? _loggedInUserId;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _loadLoggedInUserId();
  }

  Future<void> _loadLoggedInUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _loggedInUserId = prefs.getString('userId');
    await _fetchUserProfile(); // Fetch profile after loading user ID
  }

Future<void> _fetchUserProfile() async {
  _userProfile = fetchUserProfile(widget.userId);
  if (_userProfile != null) {
    final userProfile = await _userProfile!;
    print("Fetched user profile: $userProfile"); // Log the entire profile
    print("Fetched followers: ${userProfile['followers']}"); // Debugging line
    
    setState(() {
      _isFollowing = userProfile['followers']
          .any((follower) => follower['_id'] == _loggedInUserId);
      print("Is following: $_isFollowing"); // Debugging line
    });
  }
}

  Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/api/profile/$userId'));

      if (response.statusCode == 200) {
        final userProfile = jsonDecode(response.body);
        return userProfile; // Return the user profile directly
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Failed to load profile: $error');
    }
  }

Future<void> _toggleFollow() async {
  final url = _isFollowing
      ? '${ApiConstants.baseUrl}/api/profile/${widget.userId}/unfollow'
      : '${ApiConstants.baseUrl}/api/profile/${widget.userId}/followuser';

  // Use 'unfollowId' for unfollowing and 'followId' for following
  final body = _isFollowing
      ? jsonEncode({'unfollowId': _loggedInUserId}) // When unfollowing
      : jsonEncode({'followId': _loggedInUserId}); // When following

  final response = await http.post(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
    },
    body: body,
  );
  if (response.statusCode == 200) {
    setState(() {
      _isFollowing = !_isFollowing; // Toggle the following state
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isFollowing ? 'User followed' : 'User unfollowed')),
    );
    await _fetchUserProfile(); // Refetch the user profile to ensure the latest state
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to update follow status: ${response.body}')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 246, 244, 244),
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
         backgroundColor: nuBlue,
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context, true); // Pass true to indicate refresh
        },
      ),
    ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) { // Handle null case
            return Center(child: Text('No profile data available.'));
          } else {
            final user = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                children: [
                  _TopPortion(profilePicture: user['profilePicture']),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${user['firstName']} ${user['lastName']}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 24),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user['bio'] ?? "No bio available",
                          style: TextStyle(color: Colors.black, fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
             ElevatedButton(
  onPressed: _toggleFollow, // Call toggleFollow directly
  style: ElevatedButton.styleFrom(
    backgroundColor: _isFollowing ? Colors.red : nuBlue, // Red if unfollowing, NUBlue if following
    foregroundColor: Colors.white, // Set the text color to white
  minimumSize: Size(180, 60), // Set a minimum size for the button (width, height)
  ),
  child: Text(_isFollowing ? "Unfollow" : "Follow"), // Change text based on follow status
),

                        const SizedBox(height: 16),
 SizedBox(
                        height: 30, // Adjust width as needed
                        child: FloatingActionButton.extended(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReportScreen(userId: user['_id']),
                              ),
                            );
                          },
                          heroTag: 'report',
                          elevation: 0,
                          backgroundColor: Colors.redAccent,
                          label: const Text(
                            "Report User",
                            style: TextStyle(color: Colors.white),
                          ),
                          icon: const Icon(Icons.report),
                        ),
                      ),
                        const SizedBox(height: 16),
                        _ProfileInfoRow(label: 'Username:', value: user['username']),
                        _ProfileInfoRow(label: 'Age:', value: user['age']?.toString() ?? "N/A"),
                        _ProfileInfoRow(label: 'College:', value: user['college']),
                        _ProfileInfoRow(label: 'Interests:', value: user['customInterests']?.join(", ") ?? "None"),
                        //_ProfileInfoRow(label: 'Categorized Interests:', value: user['categorizedInterests']?.join(", ") ?? "None"),
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
  final String label;
  final String? value;

  const _ProfileInfoRow({
    Key? key,
    required this.label,
    this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.black, fontSize: 15),
          ),
          Expanded(
            child: Text(
              value ?? "N/A",
              style: TextStyle(color: Colors.grey[800], fontSize: 15),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopPortion extends StatelessWidget {
  final String? profilePicture;

  const _TopPortion({Key? key, this.profilePicture}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 50),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [nuBlue, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: MediaQuery.of(context).size.width / 2 - 50,
            child: CircleAvatar(
              radius: 50,
              backgroundImage: _getProfileImage(),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider _getProfileImage() {
    if (profilePicture != null && profilePicture!.isNotEmpty) {
      try {
        final base64String = profilePicture!.split(',').last;
        final bytes = base64Decode(base64String);
        return MemoryImage(bytes);
      } catch (e) {
        print('Error decoding Base64 image: $e');
      }
    }
    return const AssetImage('assets/images/profile_pic.jpg') as ImageProvider;
  }
}
