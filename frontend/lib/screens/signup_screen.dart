import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:frontend/screens/termsandcondition_screen.dart';
import 'package:frontend/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'register_screen.dart';
import '../utils/api_constant.dart'; // Import the ApiConstants
 
class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}
 
class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _isCodeSent = false;
  bool _isTermsAccepted = false; // Track if terms are accepted
  bool _showTerms = true; // Track if terms are shown
  bool _isLoading = false; // Track loading state
 
  Future<void> _sendVerificationCode() async {
    setState(() {
      _isLoading = true; // Set loading to true
    });
    final email = "${_emailController.text}@students.national-u.edu.ph";
 
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/send-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
 
      if (response.statusCode == 200) {
        setState(() {
          _isCodeSent = true;
          _showTerms = false; // Hide the terms after sending the verification code
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification code sent to $email')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send code: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Set loading to false after processing
      });
    }
  }
 
  Future<void> _verifyCodeAndProceed() async {
    setState(() {
      _isLoading = true; // Set loading to true
    });
    final email = "${_emailController.text}@students.national-u.edu.ph";
    final code = _codeController.text;
 
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );
 
      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RegisterScreen(email: email),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Set loading to false after processing
      });
    }
  }
 
  void _acceptTerms() {
    setState(() {
      _isTermsAccepted = true; // Mark terms as accepted
      _showTerms = false; // Hide the terms section
    });
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg.png'), // Path to background image
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 400,
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
                          Image.asset(
                            'assets/logo.png', // Path to logo image
                            height: 100,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: nuBlue,
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
                              suffixText: '@students.national-u.edu.ph',
                            ),
                          ),
                          SizedBox(height: 24),
 
                          // Only show terms if _showTerms is true
                          if (_showTerms) ...[
                            Row(
                              children: [
                                Checkbox(
                                  value: _isTermsAccepted,
                                  onChanged: (value) {
                                    setState(() {
                                      _isTermsAccepted = value ?? false;
                                    });
                                  },
                                ),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'I accept the ',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        TextSpan(
                                          text: 'Terms and Conditions',
                                          style: TextStyle(
                                            color: nuBlue,
                                            decoration: TextDecoration.underline,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => TermsConditionsScreen(),
                                                ),
                                              );
                                            },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          SizedBox(height: 16),
 
                          // Show loading indicator or button
                          if (_isLoading)
                            CircularProgressIndicator() // Show loading indicator
                          else if (!_isCodeSent)
                            ElevatedButton(
                              onPressed: _isTermsAccepted ? _sendVerificationCode : null,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: nuBlue,
                                backgroundColor: nuYellow,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text('Send Verification Code'),
                            )
                          else
                            Column(
                              children: [
                                TextField(
                                  controller: _codeController,
                                  decoration: InputDecoration(
                                    labelText: 'Enter Verification Code',
                                    prefixIcon: Icon(Icons.verified, color: nuBlue),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _isTermsAccepted ? _verifyCodeAndProceed : null,
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: nuBlue,
                                    backgroundColor: nuYellow,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: Text('Verify and Proceed'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: 400,
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        child: Text(
                          'Already have an account? Login',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 65, 65, 65),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}