import 'package:flutter/material.dart';
import 'package:frontend/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/api_constant.dart'; // Import the ApiConstants

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  bool codeSent = false;
  bool _isLoadingRequestCode = false; // Loading state for request code
  bool _isLoadingResetPassword = false; // Loading state for password reset

  Future<void> _requestVerificationCode() async {
    final email = "${_emailController.text}@students.national-u.edu.ph";
    
    setState(() {
      _isLoadingRequestCode = true; // Start loading
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      setState(() {
        _isLoadingRequestCode = false; // Stop loading
      });

      if (response.statusCode == 200) {
        setState(() {
          codeSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification code sent to email')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send verification code')),
        );
      }
    } catch (error) {
      setState(() {
        _isLoadingRequestCode = false; // Stop loading on error
      });
      print('Error requesting verification code: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred')),
      );
    }
  }

  Future<void> _resetPassword() async {
    final email = "${_emailController.text}@students.national-u.edu.ph";

    setState(() {
      _isLoadingResetPassword = true; // Start loading
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': _codeController.text,
          'newPassword': _newPasswordController.text,
        }),
      );

      setState(() {
        _isLoadingResetPassword = false; // Stop loading
      });

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reset password')),
        );
      }
    } catch (error) {
      setState(() {
        _isLoadingResetPassword = false; // Stop loading on error
      });
      print('Error resetting password: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg.png'), // Background image
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: 400, // Fixed width for consistency
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo widget
                      Image.asset(
                        'assets/logo.png',
                        height: 100, // Adjust height as needed
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Forgot Password',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 53, 64, 143),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Enter University ID',
                          prefixIcon: Icon(Icons.email, color: nuBlue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixText: '@students.national-u.edu.ph', // Fixed domain
                        ),
                      ),
                      SizedBox(height: 16),
                      if (codeSent) ...[
                        TextField(
                          controller: _codeController,
                          decoration: InputDecoration(
                            labelText: 'Verification Code',
                            prefixIcon: Icon(Icons.code, color: nuBlue),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _newPasswordController,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            prefixIcon: Icon(Icons.lock, color: nuBlue),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          obscureText: true,
                        ),
                      ],
                      SizedBox(height: 24),
                      // Show loading indicator or button based on request state
                      if (_isLoadingRequestCode || _isLoadingResetPassword)
                        CircularProgressIndicator()
                      else
                        ElevatedButton(
                          onPressed: codeSent ? _resetPassword : _requestVerificationCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: nuYellow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(codeSent ? 'Reset Password' : 'Request Code'),
                        ),
                      SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Navigate back to the login screen
                        },
                        child: Text(
                          'Back to Login',
                          style: TextStyle(color: const Color.fromARGB(255, 65, 65, 65)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
