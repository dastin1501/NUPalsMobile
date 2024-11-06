import 'package:flutter/material.dart';
import 'package:frontend/screens/edit_profile_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/utils/constants.dart';
import '../utils/api_constant.dart'; // Import the ApiConstants
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences for storing logged-in user ID
import 'report_screen.dart'; // Import the report screen

class ProfileScreen extends StatefulWidget {
  final String userId;

  ProfileScreen({required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _userProfile;
  bool _isOwnProfile = false;
  String? _loggedInUserId; // Add a variable to store the logged-in user's ID
  bool _isFollowing = false; // Track if the logged-in user is following the profile

  @override
  void initState() {
    super.initState();
    _loadLoggedInUserId(); // Load the logged-in user ID
  }

  // Load the logged-in user ID from shared preferences
  Future<void> _loadLoggedInUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _loggedInUserId = prefs.getString('userId'); // Fetch the logged-in user's ID from shared preferences
      // Refresh the user profile whenever logged-in user ID is loaded
      _userProfile = fetchUserProfile(widget.userId);
    });
  }

  Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/api/profile/$userId'));

      if (response.statusCode == 200) {
        final userProfile = jsonDecode(response.body);
        print(userProfile); // Debug print to check the response

        setState(() {
          // Check if this profile belongs to the logged-in user
          _isOwnProfile = userProfile['_id'] == _loggedInUserId; // Compare profile ID with logged-in user ID
          _isFollowing = userProfile['followers'].contains(_loggedInUserId); // Check if logged-in user is a follower
        });

        return userProfile;
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Failed to load profile: $error');
    }
  }

  Future<void> _toggleFollow() async {
    // Using the followUser function from your search screen
    final url = '${ApiConstants.baseUrl}/api/profile/${widget.userId}/follow'; // Updated URL for following
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'followId': _loggedInUserId}), // Send logged-in user ID
    );

    if (response.statusCode == 200) {
      setState(() {
        _isFollowing = !_isFollowing; // Toggle the following state
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isFollowing ? 'User followed' : 'User unfollowed')), // Update the message
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update follow status: ${response.body}')),
      );
    }
  }

  // Override didChangeDependencies to refresh profile when returning
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userProfile = fetchUserProfile(widget.userId); // Refresh the user profile
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
            return SingleChildScrollView(
              child: Column(
                children: [
                  _TopPortion(profilePicture: user['profilePicture']),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // Center items vertically
                      crossAxisAlignment: CrossAxisAlignment.center, // Center items horizontally
                      children: [
                        // Full Name
                        Text(
                          '${user['firstName']} ${user['lastName']}',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold, fontSize: 24),
                          textAlign: TextAlign.center, // Center align the text
                        ),
                        const SizedBox(height: 8),
                        // Bio
                        Text(
                          '${user['bio'] ?? "No bio available"}',
                          style: TextStyle(color: Colors.black, fontSize: 18),
                          textAlign: TextAlign.center, // Center align the text
                        ),
                        const SizedBox(height: 16),

                        // Follow/Unfollow button
                        if (!_isOwnProfile) // Show follow button only for other users
                          ElevatedButton(
                            onPressed: _toggleFollow, // Use the updated toggle follow function
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isFollowing ? Colors.red : nuBlue, // Change color based on follow status
                            ),
                            child: Text(_isFollowing ? "Unfollow" : "Follow"), // Change text based on follow status
                          ),

                        // Edit button for own profile
                        if (_isOwnProfile) // Show button only if this is the user's own profile
                          FloatingActionButton.extended(
                            onPressed: () async {
                              // Navigate to edit profile screen
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditProfileScreen(userId: user['_id']),
                                ),
                              );
                              // Optionally, you can also refresh the user profile here if using didChangeDependencies is not sufficient
                              _userProfile = fetchUserProfile(widget.userId); // Force refresh
                              setState(() {}); // Update the UI
                            },
                            heroTag: 'edit',
                            elevation: 0,
                            backgroundColor: nuBlue,
                            label: const Text(
                              "Edit Profile",
                              style: TextStyle(color: Colors.white),
                            ),
                            icon: const Icon(Icons.edit),
                          ),
                        
                        // Report button for other profiles
                        if (!_isOwnProfile) // Show report button for other users' profiles
                          FloatingActionButton.extended(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReportScreen(userId: user['_id']), // Navigate to report screen
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

                        const SizedBox(height: 16),

                        // User details in a professional layout
                        _ProfileInfoRow(label: 'Username:', value: user['username']),
                        _ProfileInfoRow(label: 'Email:', value: user['email']),
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
  final String? value; // Allow value to be nullable

  const _ProfileInfoRow({
    Key? key,
    required this.label,
    this.value, // Accept nullable value
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
            style: TextStyle(color: Colors.black, fontSize: 15), // Black color for the label
          ),
          Expanded(
            child: Text(
              value ?? "N/A", // Show "N/A" if value is null
              style: TextStyle(color: Colors.grey[800], fontSize: 15), // Grey color for the value
              textAlign: TextAlign.end, // Align text to the end
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
        // Remove prefix and decode Base64
        final base64String = profilePicture!.split(',').last; // Removes "data:image/jpeg;base64,"
        final bytes = base64Decode(base64String); // Decode the Base64 string
        return MemoryImage(bytes); // Use MemoryImage for Base64 data
      } catch (e) {
        print('Error decoding Base64 image: $e'); // Log the error for debugging
      }
    }
    return const AssetImage('assets/images/profile_pic.jpg') as ImageProvider; // Default image
  }
}