import 'package:flutter/material.dart';
import 'package:frontend/utils/api_constant.dart';
import 'package:frontend/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  final String email;

  RegisterScreen({required this.email});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers for form fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _rePasswordController = TextEditingController();

  String? _selectedCollege;

  List<String> collegeDepartments = [
    'College of Allied Health',
    'College of Architecture',
    'College of Business and Accountancy',
    'College of Computing and Information Technologies',
    'College of Education, Arts and Sciences',
    'College of Engineering',
    'College of Hospitality & Tourism Management'
  ];

  Future<void> _pickDate() async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: nuBlue,
            hintColor: nuYellow,
            colorScheme: ColorScheme.light(primary: nuBlue),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        _birthdateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
        _ageController.text = _calculateAge(selectedDate).toString();
      });
    }
  }

  int _calculateAge(DateTime birthdate) {
    DateTime today = DateTime.now();
    int age = today.year - birthdate.year;
    if (today.month < birthdate.month || (today.month == birthdate.month && today.day < birthdate.day)) {
      age--;
    }
    return age;
  }

  bool _isStrongPassword(String password) {
    final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    return regex.hasMatch(password);
  }

  Future<void> _submitRegistration() async {
    // Check for empty fields
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _birthdateController.text.isEmpty ||
        _ageController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _rePasswordController.text.isEmpty ||
        _selectedCollege == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields!')),
      );
      return;
    }

    // Validate passwords
    if (_passwordController.text != _rePasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match!')),
      );
      return;
    }

    // Check password strength
    if (!_isStrongPassword(_passwordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password must be at least 8 characters long, contain upper/lowercase letters, numbers, and special characters.')),
      );
      return;
    }

    var uri = Uri.parse('${ApiConstants.baseUrl}/api/profile');
    var request = http.MultipartRequest('POST', uri);

    // Include all fields in the request
    request.fields['firstName'] = _firstNameController.text;
    request.fields['lastName'] = _lastNameController.text;
    request.fields['email'] = widget.email; // From email verification
    request.fields['username'] = _usernameController.text;
    request.fields['age'] = _ageController.text;
    request.fields['birthdate'] = _birthdateController.text;
    request.fields['college'] = _selectedCollege ?? '';
    request.fields['password'] = _passwordController.text;

    try {
      var response = await request.send();
      if (response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> responseData = json.decode(responseBody);
        String userId = responseData['_id'];

        // Save userId to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userId);

        // Navigate to SurveyScreen
        Navigator.pushReplacementNamed(
          context,
          '/survey',
          arguments: {'userId': userId, 'email': widget.email},
        );
      }
    } catch (e) {
      print('Error during registration: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: nuWhite,
      appBar: AppBar(
        title: Text('Complete Your Profile', style: TextStyle(color: nuWhite)),
        backgroundColor: nuBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),

              // First Name field
              TextField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  labelStyle: TextStyle(color: nuBlue),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: nuBlue),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: nuYellow),
                  ),
                ),
              ),
              SizedBox(height: 10),

              // Last Name field
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  labelStyle: TextStyle(color: nuBlue),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: nuBlue),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: nuYellow),
                  ),
                ),
              ),
              SizedBox(height: 10),

              // Username field
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: nuBlue),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: nuBlue),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: nuYellow),
                  ),
                ),
              ),
              SizedBox(height: 10),

              // Age field
              TextField(
                controller: _ageController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Age',
                  labelStyle: TextStyle(color: nuBlue),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: nuBlue),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: nuYellow),
                  ),
                ),
              ),
              SizedBox(height: 10),

              // Birthdate field
              TextField(
                controller: _birthdateController,
                readOnly: true,
                onTap: _pickDate,
                decoration: InputDecoration(
                  labelText: 'Birthdate',
                  labelStyle: TextStyle(color: nuBlue),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: nuBlue),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: nuYellow),
                  ),
                ),
              ),
              SizedBox(height: 10),
            // College dropdown
            Container(
              width: double.infinity, // Ensures it takes the full width of the parent
              child: DropdownButtonFormField<String>(
                isExpanded: true, // Ensures the dropdown uses available width
                value: _selectedCollege,
                hint: Text('Select College', style: TextStyle(color: nuBlue)),
                items: collegeDepartments.map((String college) {
                  return DropdownMenuItem(
                    value: college,
                    child: Text(college),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCollege = value;
                  });
                },
                decoration: InputDecoration(
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: nuBlue),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: nuYellow),
                  ),
                ),
              ),
            ),
              SizedBox(height: 10),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: nuBlue),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: nuBlue),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: nuYellow),
                  ),
                ),
              ),
              SizedBox(height: 10),

              // Re-enter Password field
              TextField(
                controller: _rePasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Re-enter Password',
                  labelStyle: TextStyle(color: nuBlue),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: nuBlue),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: nuYellow),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Submit button
              Center(
                child: ElevatedButton(
                  onPressed: _submitRegistration,
                  child: Text('Register', style: TextStyle(color: nuWhite)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: nuBlue,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
