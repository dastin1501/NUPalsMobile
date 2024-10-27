import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/utils/constants.dart';
import 'package:http/http.dart' as http;
import '../models/feedback.dart'; 
import '../utils/api_constant.dart'; // Import the API constants

// Change FeedbackScreen to StatefulWidget
class FeedbackScreen extends StatefulWidget {
  final String userId;

  FeedbackScreen({required this.userId});

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _controller = TextEditingController();

  void _submitFeedback() async {
    // Capture feedback and send to your backend
    final feedback = UserFeedback(
      userId: widget.userId, // Use the actual user ID passed from FeedbackScreen
      message: _controller.text,
      timestamp: DateTime.now(),
    );

    // Call your backend API to submit the feedback
    await submitFeedbackToBackend(feedback.toMap());

    // Clear the text field
    _controller.clear();
    // Optionally show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Feedback submitted!')));
  }

  Future<void> submitFeedbackToBackend(Map<String, dynamic> feedbackData) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/feedback'), // Use your API base URL
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(feedbackData),
    );

    if (response.statusCode == 201) {
      // Feedback submitted successfully
    } else {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit feedback')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Feedback', style: TextStyle(color: Colors.white)),
      backgroundColor: nuBlue,),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: 'Your Feedback'),
              maxLines: 5,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitFeedback,
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
