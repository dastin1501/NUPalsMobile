import 'package:flutter/material.dart';
import 'package:frontend/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../utils/api_constant.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class MessagingScreen extends StatefulWidget {
  final String userId;
  final String otherUserId; // The user you want to message
  final String otherUserName; // Add this line for the username

  MessagingScreen({required this.userId, required this.otherUserId, required this.otherUserName});

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
      socket.emit('join', {'userId': widget.userId, 'otherUserId': widget.otherUserId});
    });

    socket.on('new_message', (data) {
      setState(() {
        _messages.add(data); 
      });
      _scrollToBottom();
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
          _messages = messages.cast<Map<String, dynamic>>(); // Ensure casting to the correct type
        });
        _scrollToBottom();
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
      'createdAt': DateTime.now().toIso8601String(),
    };

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(message), // Send the entire message object
      );

      if (response.statusCode == 201) {
        socket.emit('new_message', message); // Emit the new message to socket
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
        _messageController.clear();
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
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      if (position.pixels == position.maxScrollExtent) {
        _scrollController.animateTo(
          position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  String _formatTimestamp(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp).toLocal();
    return DateFormat('yyyy-MM-dd – hh:mm a').format(dateTime);
  }

  void _reportUser() {
    // Navigate to the ReportScreen (you can customize this function)
    Navigator.pushNamed(context, '/report', arguments: {
      'userId': widget.otherUserId,
      'reportedBy': widget.userId,
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              // Navigate to the other user's profile screen
              Navigator.pushNamed(context, '/viewprofile', arguments: widget.otherUserId);
            },
            child: Text(
              widget.otherUserName, // Display the username here
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
         IconButton(
            icon: Icon(
              Icons.report, // Use the report icon
              color: Colors.red, // Set the icon color to red
            ),
            onPressed: _reportUser, // Call report function
          ),
        ],
      ),
      backgroundColor: nuBlue,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
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
                        SizedBox(height: 4.0),
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
