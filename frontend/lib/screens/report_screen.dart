import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/api_constant.dart'; // Import your API constants

class ReportScreen extends StatefulWidget {
  final String userId;

  ReportScreen({required this.userId});

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> submitReport() async {
    setState(() {
      _isSubmitting = true;
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? loggedInUserId = prefs.getString('userId'); // Fetch logged-in user ID

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/report/${widget.userId}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'reportedBy': loggedInUserId,
        'reason': _reasonController.text,
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report submitted successfully')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit report')));
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report User'),
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Why are you reporting this user?',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _reasonController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Describe the issue...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            _isSubmitting
                ? CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: submitReport,
                    child: Text('Submit Report'),
                  ),
          ],
        ),
      ),
    );
  }
}
