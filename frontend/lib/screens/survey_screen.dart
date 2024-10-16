import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import '../utils/shared_preferences.dart';

class SurveyScreen extends StatefulWidget {
  final String email;
  final String userId;

  SurveyScreen({required this.email, required this.userId});

  @override
  _SurveyScreenState createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final List<String> _questions = [
    "What outdoor activities do you enjoy?",
    "What technologies are you interested in?",
    "What hobbies do you have?"
  ];

  final List<String> _responses = List.filled(3, '');
  int _currentQuestionIndex = 0;
  String _result = '';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadUserId(); // Load user ID when the screen initializes
  }

  Future<void> _loadUserId() async {
    String? userId = await SharedPreferencesService.getUserId();
    setState(() {
      _userId = userId ?? '';
    });
  }

  void _nextQuestion() {
    if (_responses[_currentQuestionIndex].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please answer the current question.')));
      return;
    }
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _submitResponses();
    }
  }

  void _submitResponses() async {
    if (_userId.isEmpty) {
      setState(() {
        _result = 'Error: User ID is empty. Please log in again.';
      });
      return;
    }

    final responseText = _responses
        .asMap()
        .entries
        .map((entry) => {'question': _questions[entry.key], 'answer': entry.value})
        .toList();

    final response = await http.post(
      Uri.parse('http://localhost:5000/api/survey/analyze'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'surveyResponse': {'questions': responseText}, 'userId': _userId}),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      setState(() {
        _result = 'Interests: ${responseData['interests']}\nTop Categories: ${responseData['topCategories']}\nMatched Categories: ${responseData['matchedCategories']}';
      });
    } else {
      setState(() {
        _result = 'Error: Unable to submit responses';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: nuWhite,
      appBar: AppBar(title: Text('Survey', style: TextStyle(color: nuWhite)), backgroundColor: nuBlue),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(_questions[_currentQuestionIndex], style: TextStyle(fontSize: 18, color: nuBlue)),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(hintText: 'Your answer', hintStyle: TextStyle(color: Colors.grey)),
              onChanged: (value) => _responses[_currentQuestionIndex] = value,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(backgroundColor: nuBlue),
              child: Text(_currentQuestionIndex < _questions.length - 1 ? 'Next' : 'Submit'),
            ),
            SizedBox(height: 20),
            Text(_result, style: TextStyle(fontSize: 16, color: Colors.black)),
          ],
        ),
      ),
    );
  }
}
