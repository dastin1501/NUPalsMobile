import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/utils/constants.dart';
import 'package:http/http.dart' as http;
import '../utils/api_constant.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final String content;
  final String media;
  final String userId;

  PostDetailScreen({
    required this.postId,
    required this.content,
    required this.media,
    required this.userId,
  });

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool isLiked = false;
  int likesCount = 0;
  List comments = [];

  @override
  void initState() {
    super.initState();
    _fetchPostDetails();
  }

  Future<void> _fetchPostDetails() async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/api/posts/${widget.postId}'));
    if (response.statusCode == 200) {
      final post = json.decode(response.body);
      setState(() {
        likesCount = post['likes'].length;
        comments = post['comments'];
        isLiked = post['likes'].contains(widget.userId);
      });
    } else {
      print('Failed to fetch post details: ${response.statusCode}');
    }
  }

  Future<void> _toggleLike() async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/posts/${widget.postId}/like'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'userId': widget.userId}),
    );

    if (response.statusCode == 200) {
      setState(() {
        isLiked = !isLiked;
        likesCount += isLiked ? 1 : -1;
      });
    } else {
      print('Failed to like the post: ${response.body}');
    }
  }

  Future<void> _addComment(String comment) async {
    if (comment.isEmpty) return;

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/posts/${widget.postId}/comment'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': widget.userId,
        'text': comment,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        comments.add({'text': comment, 'userId': {'email': 'You'}}); // Adjust as per your data structure
      });
    } else {
      print('Failed to add comment: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController commentController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 246, 244, 244), // Match HomeScreen background
      appBar: AppBar(
        title: Text('Post Details'),
        backgroundColor: nuYellow,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.content,
                        style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0), fontSize: 16),
                      ),
                      SizedBox(height: 16),
                      if (widget.media.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            // Show full image in a dialog
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return Dialog(
                                  backgroundColor: nuBlue,
                                  child: Container(
                                    width: double.infinity,
                                    child: Image.memory(
                                      base64Decode(widget.media.split(',')[1]),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Image.memory(
                              base64Decode(widget.media.split(',')[1]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
                            color: isLiked ? Colors.red : Colors.grey,
                            onPressed: _toggleLike,
                          ),
                          Text(
                            '$likesCount likes',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Comments',
                        style: TextStyle(
                          color: nuBlue,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                            leading: CircleAvatar(
                              backgroundColor: nuYellow,
                              child: Icon(Icons.person, color: nuBlue),
                            ),
                            title: Text(
                              '${comment['userId']['firstName']} ${comment['userId']['lastName']}',
                              style: TextStyle(color: nuBlue, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              comment['text'],
                              style: TextStyle(color: nuWhite),
                            ),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: TextField(
                          controller: commentController,
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white24,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: TextStyle(color: nuWhite),
                          onSubmitted: (value) {
                            _addComment(value);
                            commentController.clear();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
