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

                        // Edit button for own profile
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
                            backgroundColor: nuBlue,
                            label: const Text(
                              "Edit Profile",
                              style: TextStyle(color: Colors.white),
                            ),
                            icon: const Icon(Icons.edit),
                          ),
                        const SizedBox(height: 16),

                        // User details in a professional layout
                        _ProfileInfoRow(label: 'Username:', value: user['username']),
                        _ProfileInfoRow(label: 'Email:', value: user['email']),
                        _ProfileInfoRow(label: 'Age:', value: user['age']?.toString() ?? "N/A"),
                        _ProfileInfoRow(label: 'College:', value: user['college']),
                        _ProfileInfoRow(label: 'Year Level:', value: user['yearLevel']),
                        _ProfileInfoRow(label: 'Custom Interests:', value: user['customInterests']?.join(", ") ?? "None"),
                        _ProfileInfoRow(label: 'Categorized Interests:', value: user['categorizedInterests']?.join(", ") ?? "None"),
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
              textAlign: TextAlign.end,
              style: TextStyle(color: Colors.black, fontSize: 15), // Black color for the value
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
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [nuBlue, Colors.blueAccent],
              ),
            ),
          ),
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundImage: profilePicture != null && profilePicture!.isNotEmpty
                  ? NetworkImage(profilePicture!)
                  : const AssetImage('assets/images/profile_pic.jpg') as ImageProvider,
            ),
          ),
        ],
      ),
    );
  }
}
