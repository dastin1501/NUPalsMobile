import 'package:flutter/material.dart';
import 'package:frontend/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Import intl package for date formatting
import '../utils/api_constant.dart'; // Import the ApiConstants
import 'package:socket_io_client/socket_io_client.dart' as IO;

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
  late IO.Socket socket;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(); 
    _fetchMessages();
    _initSocket();
  }

  void _initSocket() {
    socket = IO.io('${ApiConstants.baseUrl}', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('Connected to socket');
      // Join the chat or listen for messages
      socket.emit('join', {'userId': widget.userId, 'otherUserId': widget.otherUserId});
    });

    socket.on('new_message', (data) {
      // Handle incoming messages
      setState(() {
        _messages.add(data); // Adjust according to the message structure
      });
      _scrollToBottom(); // Scroll to bottom when a new message is received
    });

    socket.onDisconnect((_) => print('Disconnected from socket'));
  }

  @override
  void dispose() {
    socket.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/messages/${widget.userId}/${widget.otherUserId}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> messages = jsonDecode(response.body);
        setState(() {
          _messages = messages.cast<Map<String, dynamic>>();
        });
        _scrollToBottom(); // Scroll to bottom after fetching messages
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

    final message = {
      'senderId': widget.userId,
      'receiverId': widget.otherUserId,
      'content': _messageController.text,
      'createdAt': DateTime.now().toIso8601String(), // Add the timestamp
    };

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': widget.userId,
          'receiverId': widget.otherUserId,
          'content': _messageController.text,
        }),
      );

      if (response.statusCode == 201) {
        socket.emit('new_message', message);
        setState(() {
          _messages.add(message); // Add message to the list immediately for a responsive UI
        });
        _scrollToBottom(); // Scroll to bottom after sending the message
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

void _scrollToBottom() {
  // Check if the user is near the bottom of the scroll view
  if (_scrollController.hasClients) {
    final position = _scrollController.position;
    if (position.pixels == position.maxScrollExtent) {
      // Only scroll to bottom if the user is already at the bottom
      _scrollController.animateTo(
        position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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
        title: Text(
          'Messaging',
          style: TextStyle(color: Colors.white), // Set the text color to white
        ),
        backgroundColor: nuBlue, // Set AppBar color to nuBlue
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: true, // Reverse the list to show the latest messages at the bottom
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[_messages.length - 1 - index]; // Reverse the index
                  final isMe = message['senderId'] == widget.userId;

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.only(top: 8.0, bottom: 8.0),
                      padding: EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: isMe ? nuBlue : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            message['content'],
                            style: TextStyle(color: isMe ? Colors.white : Colors.black),
                          ),
                          SizedBox(height: 4.0), // Space between message and timestamp
                          Text(
                            _formatTimestamp(message['createdAt']),
                            style: TextStyle(
                              color: isMe ? Colors.white70 : Colors.black54,
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ),
                    ),
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
