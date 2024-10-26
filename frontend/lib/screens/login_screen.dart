import 'package:flutter/material.dart';
import 'package:frontend/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/utils/shared_preferences.dart';
import '../utils/api_constant.dart'; // Import the ApiConstants

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    // Append the fixed domain to the email
    final email = "${_emailController.text}@test.com";

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email, // Use the modified email here
          'password': _passwordController.text,
        }),
      );

      final responseData = jsonDecode(response.body);
      print('Response Data: $responseData'); // Debugging line

      if (response.statusCode == 200 && responseData['userId'] != null) {
        final userId = responseData['userId'];

        // Save userId to SharedPreferences
        await SharedPreferencesService.saveUserId(userId);

        // Navigate to main screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(
            context,
            '/main',
            arguments: userId, // Passing userId as an argument
          );
        });
      } else {
        // Show an error message if login fails
        final errorMessage = responseData['message'] ?? 'Login Failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (error) {
      print('Login error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login error occurred')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg.png'), // Path to your background image
            fit: BoxFit.cover, // Ensures the image covers the whole container
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Main Card containing the login form
                SizedBox(
                  width: 400, // Ensuring fixed width for both Card and Container
                  child: Card(
                    color: Colors.white, // Set the card color to white
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
                            'Login',
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
                              labelText: 'Enter University Email', // Update label text
                              prefixIcon: Icon(Icons.email, color: nuBlue),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              suffixText: '@test.com', // Show the fixed domain
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock, color: nuBlue),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            obscureText: true,
                          ),
                          SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                              backgroundColor: nuBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text('Login'),
                          ),
                          SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/forgotpassword');
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(color: const Color.fromARGB(255, 65, 65, 65)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Separate container for "Don't have an account?" button
                SizedBox(height: 24),
                SizedBox(
                  width: 400, // Matching width with the login card
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9), // Background for the container
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
                          Navigator.pushNamed(context, '/signup');
                        },
                        child: Text(
                          'Don\'t have an account? Sign Up',
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
