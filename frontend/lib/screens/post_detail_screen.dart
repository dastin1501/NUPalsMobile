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
 String? firstName;
  String? lastName;
String? profilePicture;

  @override
  void initState() {
    super.initState();
    _fetchPostDetails();
       _fetchUserDetails(); // Fetch the user's details
  }

Future<void> _fetchUserDetails() async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/api/profile/${widget.userId}'));
    if (response.statusCode == 200) {
      final user = json.decode(response.body);
      setState(() {
        firstName = user['firstName'];
        lastName = user['lastName'];
        profilePicture = user['profilePicture'];
      });
    } else {
      print('Failed to fetch user details: ${response.statusCode}');
    }
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
    // Fetch user details again after adding a comment
    await _fetchUserDetails(); 

    setState(() {
      comments.add({'text': comment, 'userId': {'firstName': firstName, 'lastName': lastName, 'profilePicture': profilePicture}});
    });
  } else {
    print('Failed to add comment: ${response.body}');
  }
}
  @override
Widget build(BuildContext context) {
  TextEditingController commentController = TextEditingController();

  return Scaffold(
    backgroundColor: const Color.fromARGB(255, 246, 244, 244),
    appBar: AppBar(
      title: Text(
        'Post Details',
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: nuBlue,
    ),
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post content
                Text(
                  widget.content,
                  style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0), fontSize: 16),
                ),
                SizedBox(height: 16),
                if (widget.media.isNotEmpty)
                  GestureDetector(
                    onTap: () {
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
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(widget.media.split(',')[1]),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
                      color: isLiked ? Colors.red : Colors.grey,
                      onPressed: _toggleLike,
                    ),
                    SizedBox(width: 8),
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

                // Moved the comment input to the top of the container
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: TextStyle(color: const Color.fromARGB(179, 0, 0, 0)),
                            filled: true,
                            fillColor: Colors.grey[200], // Light gray color for the input field
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: TextStyle(color: const Color.fromARGB(255, 1, 0, 0)),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send, color: nuBlue), // Send button
                        onPressed: () {
                          _addComment(commentController.text);
                          commentController.clear();
                        },
                      ),
                    ],
                  ),
                ),
                
                // Container to hold the comments
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Comments List
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          final user = comment['userId'];

                          String defaultAssetImage = 'assets/images/profile_pic.jpg';

                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                            leading: CircleAvatar(
                              backgroundImage: user['profilePicture'] != null && user['profilePicture'].isNotEmpty
                                  ? MemoryImage(base64Decode(user['profilePicture'].split(',').last))
                                  : AssetImage(defaultAssetImage) as ImageProvider,
                            ),
                            title: Text(
                              '${user['firstName']} ${user['lastName']}',
                              style: TextStyle(color: nuBlue, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              comment['text'],
                              style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

}
