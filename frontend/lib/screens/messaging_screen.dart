import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Import intl package for date formatting

class MessagingScreen extends StatefulWidget {
  final String userId;
  final String otherUserId; // The user you want to message

  MessagingScreen({required this.userId, required this.otherUserId});

  @override
  _MessagingScreenState createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/messages/${widget.userId}/${widget.otherUserId}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> messages = jsonDecode(response.body);
        setState(() {
          _messages = messages.cast<Map<String, dynamic>>();
        });
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load messages: ${error.toString()}')),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': widget.userId,
          'receiverId': widget.otherUserId,
          'content': _messageController.text,
        }),
      );

      if (response.statusCode == 201) {
        _fetchMessages(); // Refresh messages after sending
        _messageController.clear(); // Clear the input field
      } else {
        throw Exception('Failed to send message');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: ${error.toString()}')),
      );
    }
  }

  String _formatTimestamp(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp).toLocal(); // Convert to local time
    return DateFormat('yyyy-MM-dd – hh:mm a').format(dateTime); // Format the date and time as needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messaging'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return ListTile(
                    title: Text(message['content']),
                    subtitle: Text(
                      '${message['senderId'] == widget.userId ? 'You' : 'Them'} • ${_formatTimestamp(message['createdAt'])}', // Add timestamp formatting
                    ),
                    tileColor: message['senderId'] == widget.userId ? Colors.lightBlueAccent : Colors.grey[200],
                    contentPadding: EdgeInsets.all(10),
                  );
                },
              ),
            ),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Type your message...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
