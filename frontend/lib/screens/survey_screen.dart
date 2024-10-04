import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart'; // Import constants

class SurveyScreen extends StatefulWidget {
  final String userId;
  final String email; // New parameter for email

  SurveyScreen({required this.userId, required this.email});

  @override
  _SurveyScreenState createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final List<Map<String, String>> questions = [
    {
      'question': 'What do you enjoy doing on a weekend?',
      'type': 'text',
    },
    {
      'question': 'If you could be an expert in anything, what would it be?',
      'type': 'text',
    },
    {
      'question': 'What kind of activities make you lose track of time?',
      'type': 'text',
    },
    {
      'question': 'What’s your favorite movie genre?',
      'type': 'text',
    },
    {
      'question': 'Pick a superpower you’d want to have!',
      'type': 'text',
    },
  ];

  final List<TextEditingController> _controllers = [];
  String _errorMessage = '';
  bool _isLoading = false;
  List<String> topInterests = []; // To store user's top interests
  List<String> categorizedInterests = []; // To store categorized interests

  @override
  void initState() {
    super.initState();
    for (var question in questions) {
      _controllers.add(TextEditingController());
    }
  }

  void submitAnswers() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    List<String> answers = _controllers.map((controller) => controller.text).toList();

    // Use the email passed in instead of getting it from a TextField
    String email = widget.email;

    if (answers.any((answer) => answer.isEmpty)) {
      setState(() {
        _errorMessage = 'All fields are required!';
        _isLoading = false;
      });
      return;
    }

    try {
      var response = await http.post(
        Uri.parse('http://localhost:5000/api/survey/submit-survey'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'email': email, // Pass the email here
          'answers': answers,
        }),
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        topInterests = jsonResponse['customInterests'] ?? [];
        categorizedInterests = jsonResponse['categorizedInterests'] ?? []; // Get categorized interests

        // Show a dialog with top interests and categorized interests
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Your Interests'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Custom Interests: ${topInterests.isNotEmpty ? topInterests.join(', ') : 'None'}'),
                SizedBox(height: 8),
                Text('Categorized Interests: ${categorizedInterests.isNotEmpty ? categorizedInterests.join(', ') : 'None'}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/main');
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Error: ${response.statusCode}. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Interest Survey'),
        backgroundColor: nuBlue, // Use the defined color
      ),
      body: SingleChildScrollView( // Make the body scrollable
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...questions.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, String> question = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question['question']!,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: nuBlue),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _controllers[index],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Your answer...',
                          hintStyle: TextStyle(color: Theme.of(context).hintColor),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                );
              }).toList(),
              SizedBox(height: 20),
              if (_errorMessage.isNotEmpty)
                Text(_errorMessage, style: TextStyle(color: Colors.red)),
              SizedBox(height: 20),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: submitAnswers,
                      child: Text('Submit'),
                      style: ElevatedButton.styleFrom(backgroundColor: nuYellow), // Button color
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
