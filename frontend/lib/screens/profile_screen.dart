import 'package:flutter/material.dart';
import 'package:frontend/screens/edit_profile_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/utils/constants.dart'; // Ensure this file has your theme colors

class ProfileScreen extends StatefulWidget {
  final String userId;

  ProfileScreen({required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _userProfile;

  @override
  void initState() {
    super.initState();
    _userProfile = fetchUserProfile(widget.userId);
  }

  Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5000/api/profile/$userId'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
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
      backgroundColor: nuBlue,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(color: nuYellow),
        ),
        backgroundColor: nuBlue,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: nuYellow));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: nuYellow)));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('No user data available', style: TextStyle(color: nuYellow)));
          } else {
            final user = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: user['profileImage'] != ''
                        ? CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(user['profileImage']),
                          )
                        : Icon(Icons.account_circle, size: 100, color: nuYellow),
                  ),
                  SizedBox(height: 16),
                  buildUserInfo('Username:', user['username']),
                  buildUserInfo('Age:', user['age']),
                  buildUserInfo('Department:', user['department']),
                  buildUserInfo('Year Level:', user['yearLevel']),
                  buildUserInfo('Bio:', user['bio']),
                  buildUserInfo('Interests:', user['interests'] != null ? (user['interests'] as List<dynamic>).join(', ') : 'N/A'),
                  SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: nuYellow,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(userId: widget.userId),
                          ),
                        );
                      },
                      child: Text('Edit Profile', style: TextStyle(color: nuBlue, fontWeight: FontWeight.bold)),
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

  Widget buildUserInfo(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: RichText(
        text: TextSpan(
          text: '$label ',
          style: TextStyle(color: nuYellow, fontSize: 18, fontWeight: FontWeight.bold),
          children: [
            TextSpan(
              text: value != null ? value.toString() : 'N/A',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
