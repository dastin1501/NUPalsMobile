import 'package:flutter/material.dart';
import 'package:frontend/screens/changepassword_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/utils/constants.dart'; // Ensure this file has your theme colors
import 'package:frontend/screens/survey_screen.dart'; // Import your survey screen
import '../utils/api_constant.dart'; // Import the ApiConstants
import 'package:image_picker/image_picker.dart'; // For image picking
import 'package:intl/intl.dart'; // Import intl package for date formatting

class EditProfileScreen extends StatefulWidget {
  final String userId;

  EditProfileScreen({required this.userId});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  String? _selectedCollege; // Variable for the selected college
  final _bioController = TextEditingController(); // Bio controller
  XFile? _selectedImage; // Variable for the selected image
  final ImagePicker _picker = ImagePicker(); // ImagePicker instance
  String _base64Image = '';
  DateTime? _lastSurveyDate; // Variable to store last survey submission date

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchLastSurveyDate(); // Fetch the last survey date
  }

  // Fetch the user profile from the server
  Future<void> _fetchUserProfile() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/api/profile/${widget.userId}'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _usernameController.text = data['username'] ?? '';
          _selectedCollege = data['college']; // Load selected college
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

  // Fetch the last survey date from the server
  Future<void> _fetchLastSurveyDate() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/api/profile/${widget.userId}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _lastSurveyDate = DateTime.tryParse(data['lastSurveyDate']); // Parse date string to DateTime
        });
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load last survey date', style: TextStyle(color: Colors.red))),
      );
    }
  }

  // Method to check if the user can take the survey
  bool _canTakeSurvey() {
    if (_lastSurveyDate == null) return true; // If no date is set, allow access
    final now = DateTime.now();
    final difference = now.difference(_lastSurveyDate!);
    return difference.inDays >= 7; // Check if 7 days have passed
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      print('Picked Image Path: ${image.path}');
      setState(() {
        _selectedImage = image;
      });

      // Convert the image to Base64
      final bytes = await image.readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes); // Directly set base64 image
      });
      print('Base64 Image: $_base64Image');
    } else {
      print('No image selected.');
    }
  }

  Future<void> _updateProfile() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    try {
      var requestBody = {
        'username': _usernameController.text,
        'college': _selectedCollege, // Use selected college
        'bio': _bioController.text, // Add bio
      };

      // Include Base64 image string if it's not null or empty
      if (_base64Image.isNotEmpty) {
        requestBody['profileImage'] = 'data:image/jpeg;base64,$_base64Image';
      }

      // Send the request
      var response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/profile/${widget.userId}/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        print('Profile updated: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context); // Return to the previous screen after successful update
      } else {
        // Extract the error message from the response
        final Map<String, dynamic> errorResponse = json.decode(response.body);
        String errorMessage = errorResponse['msg'] ?? 'Failed to update profile.';

        print('Failed to update profile: ${response.statusCode} - ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (error) {
      print('Error updating profile: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while updating the profile.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 246, 244, 244),
      appBar: AppBar(
        title: Text('Edit Profile', style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255))),
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
                    child: Text('Upload Profile Picture', style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: nuBlue,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ),
                SizedBox(height: 16), // Adjust height as needed
                // Display the selected image using Image.memory
                if (_base64Image.isNotEmpty)
                  Center( // Center the image preview
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Image.memory(
                        base64Decode(_base64Image), // Decode the base64 string to bytes
                        height: 150,
                        fit: BoxFit.cover, // Adjust as needed
                      ),
                    ),
                  ),
                buildTextField('Username', _usernameController, validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                }),

                // Dropdown for College selection
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    width: double.infinity, // Take full width
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'College',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      isExpanded: true, // Ensure it expands to fill the container
                      value: _selectedCollege,
                      items: collegeDepartments.map((String college) {
                        return DropdownMenuItem<String>(
                          value: college,
                          child: Text(
                            college,
                            style: TextStyle(color: Colors.black),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCollege = newValue; // Update selected college
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select your college';
                        }
                        return null;
                      },
                    ),
                  ),
                ),

                buildTextField('Bio', _bioController), // Bio field

                SizedBox(height: 24),

                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: nuBlue,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    onPressed: _updateProfile,
                    child: Text('Update Profile', style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255))),
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: nuBlue,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChangePasswordScreen(userId: widget.userId),
                        ),
                      );
                    },
                    child: Text('Change Password', style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255))),
                  ),
                ),
                // Survey button
                SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: nuBlue,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    onPressed: () {
                      if (_canTakeSurvey()) {
                        // Navigate to the survey screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SurveyScreen(
                              userId: widget.userId,
                              email: '',
                            ),
                          ),
                        );
                      } else {
                        // Show a warning message if the user cannot take the survey yet
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'You can take the survey again on ${DateFormat('yyyy-MM-dd').format(_lastSurveyDate!.add(Duration(days: 7)))}',
                              style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)),
                            ),
                          ),
                        );
                      }
                    },
                    child: Text('Take Survey', style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Function to build text fields with common styling
  Widget buildTextField(String labelText, TextEditingController controller, {FormFieldValidator<String>? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: validator,
      ),
    );
  }
}

List<String> collegeDepartments = [
  '',
    'College of Allied Health',
    'College of Architecture',
    'College of Business and Accountancy',
    'College of Computing and Information Technologies',
    'College of Education, Arts and Sciences',
    'College of Engineering',
    'College of Hospitality & Tourism Management'
];
