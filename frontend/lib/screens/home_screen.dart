import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting the post date
import 'package:frontend/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'post_detail_screen.dart'; // Import the PostDetailScreen

class HomeScreen extends StatefulWidget {
  final String userId;

  HomeScreen({required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List posts = [];

  // Function to fetch posts from the backend
  Future<void> fetchPosts() async {
    final response = await http.get(Uri.parse('http://localhost:5000/api/posts'));

    if (response.statusCode == 200) {
      setState(() {
        posts = json.decode(response.body); // Parse the JSON data
      });
    } else {
      print('Failed to load posts: ${response.statusCode}'); // Log error
      throw Exception('Failed to load posts');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPosts(); // Fetch posts when screen loads
  }

  // Function to format the timestamp to a readable date and time
  String formatTime(String timestamp) {
    final DateTime postDate = DateTime.parse(timestamp);
    return DateFormat('yyyy-MM-dd hh:mm a').format(postDate); // Example format: 2023-09-23 02:45 PM
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: nuBlue, // Apply nuBlue as the background color
      appBar: AppBar(
        title: Text('Home'),
        backgroundColor: nuYellow, // Apply nuYellow as the AppBar background
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Explore Your Feed',
              style: TextStyle(
                color: nuWhite, // Apply nuWhite for text
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  final media = post['media'];
                  final likes = post['likes']?.length ?? 0; // Get the number of likes
                  final comments = post['comments']?.length ?? 0; // Get the number of comments
                  final timestamp = post['createdAt']; // Post creation time

                  return GestureDetector(
                    onTap: () {
                      // Navigate to PostDetailScreen on post click
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PostDetailScreen(
                            content: post['content'], // Pass post content
                            media: media,
                            postId: post['_id'], // Pass the correct post ID
                            userId: widget.userId, // Pass the userId from HomeScreen
                          ),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: nuYellow, // Apply nuYellow for CircleAvatar
                              child: Icon(Icons.account_circle, color: nuBlue, size: 32),
                            ),
                            title: Text(
                              post['userId']['email'], // Display user email
                              style: TextStyle(
                                color: nuBlue, // Apply nuBlue for text
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              post['content'], // Display post content
                              style: TextStyle(color: Colors.grey[700], fontSize: 14),
                            ),
                          ),
                          if (media != null && media.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Image.memory(
                                base64Decode(media.split(',')[1]), // Decode base64 string and display image
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 200,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.thumb_up, color: nuYellow, size: 20),
                                    SizedBox(width: 6),
                                    Text(
                                      '$likes Likes', // Display the number of likes
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.comment, color: nuYellow, size: 20),
                                    SizedBox(width: 6),
                                    Text(
                                      '$comments Comments', // Display the number of comments
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                                Text(
                                  formatTime(timestamp), // Display the time the post was created
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10), // Space between posts
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
