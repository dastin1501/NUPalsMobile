import 'package:flutter/material.dart';
import 'package:frontend/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../utils/api_constant.dart'; // Import the ApiConstants
import 'package:socket_io_client/socket_io_client.dart' as IO; // Import socket_io_client

class GroupMessageScreen extends StatefulWidget {
  final String userId;
  final String groupChatId;
  final String firstName; // Add this
  final String lastName; // Add this

  GroupMessageScreen({
    required this.userId,
    required this.groupChatId,
    required this.firstName, // Add this
    required this.lastName,  // Add this
  });

  @override
  _GroupMessageScreenState createState() => _GroupMessageScreenState();
}

class _GroupMessageScreenState extends State<GroupMessageScreen> {
  List<Map<String, dynamic>> _messages = [];
  TextEditingController _messageController = TextEditingController();
  late IO.Socket _socket; // Define a socket variable
  late ScrollController _scrollController; // Add a ScrollController

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(); // Initialize the ScrollController
    _fetchMessages(); // Fetch messages on initialization
    _initSocket(); // Initialize socket connection
  }

  void _initSocket() {
    _socket = IO.io('${ApiConstants.baseUrl}', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket.connect();

    _socket.onConnect((_) {
      print('Connected to socket server');
      _socket.emit('joinGroup', widget.groupChatId); // Join the group chat
    });

_socket.on('newMessage', (data) {
  setState(() {
    // Check if the message is already present
    if (!_messages.any((msg) => msg['_id'] == data['_id'])) {
      _messages.add(data); // Add new message to the list only if it's not already there
      _scrollToBottom(); // Scroll to bottom when a new message is received
    }
  });
});


    _socket.onDisconnect((_) => print('Disconnected from socket server'));
  }

 Future<void> _fetchMessages() async {
  try {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/group/message/${widget.groupChatId}'), // Your API endpoint
    );

    if (response.statusCode == 200) {
      final List<dynamic> messages = jsonDecode(response.body);
      setState(() {
        _messages = messages.cast<Map<String, dynamic>>(); // Cast messages to List<Map<String, dynamic>>
      });
      // Jump to the bottom after loading messages
      _scrollToBottom(); // Call this directly after setState
    } else {
      _handleError('Failed to load messages: ${response.body}');
    }
  } catch (error) {
    _handleError('Failed to load messages: ${error.toString()}');
  }
}

  void _handleError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
void _sendMessage() async {
  if (_messageController.text.isNotEmpty) {
    final message = {
      'groupId': widget.groupChatId,
      'senderId': widget.userId,
      'content': _messageController.text,
      'createdAt': DateTime.now().toIso8601String(),
      'firstName': widget.firstName,
      'lastName': widget.lastName,
      '_id': DateTime.now().millisecondsSinceEpoch.toString(), // Generate a unique ID
    };

    // Emit the message via socket
    _socket.emit('sendMessage', message);

    // Clear input after sending
    _messageController.clear(); 

   // Instead of adding immediately, rely on the server response via socket
    // setState(() {
    //   _messages.add(message); // Remove this line to prevent immediate local addition
    // });
    // _scrollToBottom(); // Scroll to the bottom after sending
  }
}

void _scrollToBottom() {
  // Jump to the bottom of the ListView
  if (_scrollController.hasClients) {
    // Ensure the scroll position is calculated after the frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }
}

  String _formatTimestamp(String timestamp) {
    DateTime dateTime = DateTime.parse(timestamp).toLocal(); // Convert to local time
    return DateFormat('yyyy-MM-dd – hh:mm a').format(dateTime); // Format the date and time as needed
  }

  @override
  void dispose() {
    _socket.dispose(); // Dispose of the socket when the widget is removed
    _scrollController.dispose(); // Dispose of the ScrollController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Messages', style: TextStyle(color: Colors.white)),
        backgroundColor: nuBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController, // Set the ScrollController
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];

                  // Handle senderId being either a string or an object
                  final isMe = message['senderId'] is String
                      ? message['senderId'] == widget.userId
                      : message['senderId']['_id'] == widget.userId; // Handle object or string comparison

                  String senderName = '${message['firstName']} ${message['lastName']}';

                  // If senderId is an object, try to extract the first and last name
                  if (message['senderId'] is Map && message['senderId'].containsKey('firstName')) {
                    senderName = '${message['senderId']['firstName']} ${message['senderId']['lastName']}';
                  }

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (!isMe && senderName.isNotEmpty) ...[
                            Text(
                              senderName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.0,
                              ),
                            ),
                            SizedBox(height: 4.0),
                          ],
                          Container(
                            padding: EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: isMe ? const Color.fromARGB(255, 53, 64, 143): Colors.grey[200],
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message['content'] ?? 'No content',
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
                labelText: 'Type a message',
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
