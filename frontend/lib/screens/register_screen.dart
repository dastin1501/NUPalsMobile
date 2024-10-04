import 'package:flutter/material.dart';
import 'package:frontend/utils/api_constant.dart';
import 'package:frontend/utils/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class RegisterScreen extends StatefulWidget {
  final String email;

  RegisterScreen({required this.email});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  Uint8List? _image;
  final ImagePicker _picker = ImagePicker();

  // Controllers for form fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _rePasswordController = TextEditingController();

  String? _selectedCollege;
  String? _selectedYearLevel;

  List<String> collegeDepartments = [
    'College of Allied Health',
    'College of Architecture',
    'College of Business and Accountancy',
    'College of Computing and Information Technologies',
    'College of Education, Arts and Sciences',
    'College of Engineering',
    'College of Hospitality & Tourism Management'
  ];

  List<String> yearLevels = ['1st Year', '2nd Year', '3rd Year', '4th Year', 'Irregular', 'Transferee'];

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

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _image = bytes;
      });
    }
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
        _selectedCollege == null ||
        _selectedYearLevel == null) {
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

    var uri = Uri.parse('${ApiConstants.profileEndpoint}');
    var request = http.MultipartRequest('POST', uri);

    // Add profile image if selected
    if (_image != null) {
      var stream = http.ByteStream.fromBytes(_image!);
      var length = _image!.length;
      var mimeType = lookupMimeType('path/to/your/image/file.jpg') ?? 'application/octet-stream'; // Update with the actual path or extension
      var multipartFile = http.MultipartFile(
        'profileImage',
        stream,
        length,
        filename: 'profileImage.jpg',
        contentType: MediaType.parse(mimeType),
      );
      request.files.add(multipartFile);
    }

    // Include all fields in the request
    request.fields['firstName'] = _firstNameController.text;
    request.fields['lastName'] = _lastNameController.text;
    request.fields['email'] = widget.email; // From email verification
    request.fields['username'] = _usernameController.text;
    request.fields['age'] = _ageController.text;
    request.fields['birthdate'] = _birthdateController.text;
    request.fields['college'] = _selectedCollege ?? '';
    request.fields['yearLevel'] = _selectedYearLevel ?? '';
    request.fields['password'] = _passwordController.text;

    try {
      var response = await request.send();
      if (response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> responseData = json.decode(responseBody);
        String userId = responseData['_id']; // Assuming your API responds with the user's ObjectID

        Navigator.pushReplacementNamed(context,'/survey',arguments: {'userId': userId, 'email': widget.email},); // Navigate using the MongoDB ObjectID
      } else {
        final responseBody = await response.stream.bytesToString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register: ${response.statusCode} - $responseBody')),
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
              Center(
                child: Column(
                  children: [
                    Text(
                      'Profile Image (Optional)',
                      style: TextStyle(color: nuBlue, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _image != null ? MemoryImage(_image!) : null,
                        child: _image == null
                            ? Icon(Icons.camera_alt, size: 50, color: nuWhite)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
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

              // College selection
              DropdownButtonFormField<String>(
                value: _selectedCollege,
                hint: Text('Select College', style: TextStyle(color: nuBlue)),
                items: collegeDepartments.map((String college) {
                  return DropdownMenuItem<String>(
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
              SizedBox(height: 10),

              // Year Level selection
              DropdownButtonFormField<String>(
                value: _selectedYearLevel,
                hint: Text('Select Year Level', style: TextStyle(color: nuBlue)),
                items: yearLevels.map((String yearLevel) {
                  return DropdownMenuItem<String>(
                    value: yearLevel,
                    child: Text(yearLevel),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedYearLevel = value;
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

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: nuBlue,
                  ),
                  child: Text('Register'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
