import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import '../utils/shared_preferences.dart';
import '../utils/api_constant.dart';
 
class SurveyScreen extends StatefulWidget {
  final String email;
  final String userId;
 
  SurveyScreen({required this.email, required this.userId});
 
  @override
  _SurveyScreenState createState() => _SurveyScreenState();
}
 
class _SurveyScreenState extends State<SurveyScreen> {
  final List<String> _questions = [
    'Tell us a little about your hobbies or things you enjoy doing!',
    'What subjects or fields absolutely spark your curiosity?',
    'Are there any skills you’re currently learning or hoping to develop?',
    'Any big dreams or career goals you’re reaching for?'
  ];
 
  final List<String> _responses = List.filled(4, '');
  int _currentQuestionIndex = 0;
  String _result = '';
  String _userId = '';
  bool _isLoading = false; // Loading state
 
  final TextEditingController _textController = TextEditingController();
 
  // Images related to each question
  final List<String> _questionImages = [
    'https://www.shutterstock.com/image-vector/people-different-hobbies-talented-characters-260nw-2258924833.jpg', // Hobbies
    'https://media.licdn.com/dms/image/D4D12AQEc-3-mGtTeZA/article-cover_image-shrink_720_1280/0/1682322533021?e=2147483647&v=beta&t=kj6vcoq5J6YmP5kniFfY3O3WR45nPBs7yGIy-nLg2jY', // Curiosity
    'https://www.ciphr.com/hs-fs/hubfs/Imported_Blog_Media/iStock-1440756999.jpg?width=2121&height=1414&name=iStock-1440756999.jpg', // Skills
    'https://media.istockphoto.com/id/1221452135/vector/businesspeople-driving-arrow-to-goal.jpg?s=612x612&w=0&k=20&c=VkLmbbIESHKsVLygd_054c4m-bT7Z2Te14foSIXTvYI=' // Goals
  ];
 
  @override
  void initState() {
    super.initState();
    _loadUserId();
  }
 
  Future<void> _loadUserId() async {
    String? userId = await SharedPreferencesService.getUserId();
    setState(() {
      _userId = userId ?? '';
    });
  }
 
  void _nextQuestion() {
    if (_responses[_currentQuestionIndex].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Oops! Please answer the current question.')),
      );
      return;
    }
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _textController.clear();
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
 
    setState(() {
      _isLoading = true; // Show loading indicator
    });
 
    final responseText = _responses
        .asMap()
        .entries
        .map((entry) => {'question': _questions[entry.key], 'answer': entry.value})
        .toList();
 
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/survey/analyze'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'surveyResponse': {'questions': responseText}, 'userId': _userId}),
    );
 
    setState(() {
      _isLoading = false; // Hide loading indicator
    });
 
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      setState(() {
        _result = 'Your Interests: ${responseData['interests']}\nTop Categories: ${responseData['topCategories']}';
      });
      _showResultModal();
    } else {
      setState(() {
        _result = 'Uh-oh! Something went wrong. Please try again.';
      });
    }
  }
 
  void _showResultModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Survey Results 🎉',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: nuBlue),
              ),
              SizedBox(height: 16),
              Text(
                _result,
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final userId = await SharedPreferencesService.getUserId();
                  Navigator.of(context).pushReplacementNamed(
                    '/main',
                    arguments: userId,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: nuBlue,
                  foregroundColor: Colors.white, // Change text color to white
                ),
                child: Text('Go to Homepage'),
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: nuWhite,
      appBar: AppBar(
        title: Text('Survey Time!', style: TextStyle(color: nuWhite)),
        backgroundColor: nuBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Display a related image based on the current question
            Image.network(
              _questionImages[_currentQuestionIndex],
              height: 180,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 16),
            Text(
              _questions[_currentQuestionIndex],
              style: TextStyle(fontSize: 18, color: nuBlue),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Your answer here!',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onChanged: (value) => _responses[_currentQuestionIndex] = value,
              enabled: !_isLoading, // Disable input when loading
            ),
            SizedBox(height: 20),
            if (_isLoading)
              CircularProgressIndicator(color: nuBlue) // Show loading indicator
            else
              ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: nuBlue,
                foregroundColor: Colors.white, // Change text color to white
              ),
              child: Text(_currentQuestionIndex < _questions.length - 1 ? 'Next Question ➡️' : 'Submit 🎉'),
            ),
          ],
        ),
      ),
    );
  }
}