import 'package:flutter/material.dart';
import 'package:frontend/screens/forgotpassword_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // For File usage
import 'package:frontend/utils/constants.dart'; // Ensure this file has your theme colors
import 'package:frontend/screens/survey_screen.dart'; // Import your survey screen
import '../utils/api_constant.dart'; // Import the ApiConstants
import 'package:image_picker/image_picker.dart'; // For image picking
// Import your forgot password screen

class EditProfileScreen extends StatefulWidget {
  final String userId;

  EditProfileScreen({required this.userId});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _collegeController = TextEditingController();
  final _bioController = TextEditingController(); // Bio controller
  XFile? _selectedImage; // Variable for the selected image
  final ImagePicker _picker = ImagePicker(); // ImagePicker instance

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/api/profile/${widget.userId}'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _usernameController.text = data['username'] ?? '';
          _collegeController.text = data['college'] ?? '';
          _bioController.text = data['bio'] ?? ''; // Load bio
        });
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile', style: TextStyle(color: Colors.red))),
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      print('Picked Image Path: ${image.path}');
      setState(() {
        _selectedImage = image;
      });
    } else {
      print('No image selected.');
    }
  }

  Future<void> _updateProfile() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/api/profile/${widget.userId}/update'),
      );

      // Add text fields to the request
      request.fields['username'] = _usernameController.text;
      request.fields['college'] = _collegeController.text;
      request.fields['bio'] = _bioController.text; // Add bio

      // Add the selected image if available
      if (_selectedImage != null) {
        var profileImage = await http.MultipartFile.fromPath(
          'profileImage',
          _selectedImage!.path,
        );
        request.files.add(profileImage);
      }

      // Send the request
      var response = await request.send();

      if (response.statusCode == 200) {
        print('Profile updated: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully', style: TextStyle(color: Colors.green))),
        );
        Navigator.pop(context); // Return to the previous screen after successful update
      } else {
        print('Failed to update profile: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile', style: TextStyle(color: Colors.red))),
        );
      }
    } catch (error) {
      print('Error updating profile: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile', style: TextStyle(color: Colors.red))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: nuBlue,
      appBar: AppBar(
        title: Text('Edit Profile', style: TextStyle(color: nuYellow)),
        backgroundColor: nuBlue,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image picker button
                Center(
                  child: ElevatedButton(
                    onPressed: _pickImage,
                    child: Text('Pick Profile Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: nuYellow,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ),

                // Display the selected image
                if (_selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Image.file(
                      File(_selectedImage!.path),
                      height: 150,
                    ),
                  ),

                buildTextField('Username', _usernameController, validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                }),
                buildTextField('College', _collegeController),
                buildTextField('Bio', _bioController), // Bio field

                SizedBox(height: 24),

                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: nuYellow,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    onPressed: _updateProfile,
                    child: Text('Update Profile', style: TextStyle(color: nuBlue, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(height: 24),
                
                // Button to change password
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
                          builder: (context) => ForgotPasswordScreen(), // Navigate to the forgot password screen
                        ),
                      );
                    },
                    child: Text('Change Password', style: TextStyle(color: nuBlue, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(height: 24),
                
                // Button to change interests
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
                          builder: (context) => SurveyScreen(
                            email: '', // Pass the actual email if necessary
                            userId: widget.userId, // Pass userId to survey screen
                          )),
                      );
                    },
                    child: Text('Change Interests', style: TextStyle(color: nuBlue, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: nuYellow),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.white),
        validator: validator,
      ),
    );
  }
}
