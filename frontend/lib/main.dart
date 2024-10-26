  import 'package:flutter/material.dart';
  import 'package:flutter_screenutil/flutter_screenutil.dart';
  import 'package:frontend/screens/changepassword_screen.dart';
  import 'package:frontend/screens/feedback_screen.dart';
  import 'package:frontend/screens/forgotpassword_screen.dart';
  import 'package:frontend/screens/profile_screen.dart';
  import 'package:frontend/screens/report_screen.dart';
  import 'package:frontend/screens/search_screen.dart';
  import 'package:frontend/screens/home_screen.dart';
  import 'package:frontend/screens/splash_screen.dart';
  import 'package:frontend/screens/signup_screen.dart';
  import 'package:frontend/screens/login_screen.dart';
  import 'package:frontend/screens/survey_screen.dart';
  import 'package:frontend/screens/register_screen.dart';
  import 'package:frontend/screens/messaging_screen.dart'; // Adjust the path as necessary
  import 'package:frontend/screens/inbox_screen.dart'; // Import the Inbox Screen
  import 'package:frontend/screens/notifications_screen.dart'; // Import Notifications Screen
  import 'package:frontend/screens/group_inbox_screen.dart'; //
  import 'package:frontend/utils/constants.dart';
  import 'package:frontend/utils/shared_preferences.dart';
  import 'dart:async';
  import 'package:http/http.dart' as http;
  import 'dart:convert';
  import '../utils/api_constant.dart'; // Import the ApiConstants

  void main() async {
    WidgetsFlutterBinding.ensureInitialized(); // Ensure binding is initialized
    final userId = await SharedPreferencesService.getUserId(); // Load user ID

    runApp(MyApp(userId: userId));
  }

  class MyApp extends StatelessWidget {
    final String? userId;

    MyApp({this.userId});

    @override
    Widget build(BuildContext context) {
      return ScreenUtilInit(
        designSize: Size(360, 690),
        builder: (context, child) {
          return MaterialApp(
            title: 'Social Media App',
            theme: ThemeData(primarySwatch: Colors.blue),
            initialRoute: userId != null && userId!.isNotEmpty ? '/main' : '/login',
            routes: {
              '/signup': (context) => SignUpScreen(),
              '/login': (context) => LoginScreen(),
              '/': (context) => LoginScreen(),
              '/forgotpassword': (context) => ForgotPasswordScreen(),
              '/main': (context) {
                final userId = ModalRoute.of(context)!.settings.arguments as String?;
                if (userId == null || userId.isEmpty) {
                  // If userId is null or empty, redirect to login
                  WidgetsBinding.instance!.addPostFrameCallback((_) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  });
                  return Container(); // Return an empty container or a loading indicator
                }
                return MainScreen(userId: userId); // Safe to pass userId now
              },
              '/splash': (context) => SplashScreen(),
              '/register': (context) => RegisterScreen(email: ''),
              '/survey': (context) => SurveyScreen(email: '', userId: ''),
              '/profile': (context) {final String userId = ModalRoute.of(context)!.settings.arguments as String; // Get userId from arguments
                return ProfileScreen(userId: userId); },
              '/messages': (context) {String otherUserId = 'someOtherUserId'; // Replace this with the actual value
                                      String otherUserName = 'someOtherUserName'; // Replace this with the actual value
                return MessagingScreen(userId: userId!, otherUserId: otherUserId, otherUserName: otherUserName);},
              '/inbox': (context) => InboxScreen(userId: userId!),
              '/groupinbox': (context) => GroupInboxScreen(userId: userId!),
              '/notifications': (context) => NotificationsScreen(userId: userId!),
              '/feedback': (context) => FeedbackScreen(userId: userId!),
              '/report': (context) => ReportScreen(userId: userId!),
              '/changepass': (context) => ChangePasswordScreen(userId: userId!),
            },
          );
        },
      );
    }
  }


  class MainScreen extends StatefulWidget {
    final String userId;

    MainScreen({required this.userId});

    @override
    _MainScreenState createState() => _MainScreenState();
  }

  class _MainScreenState extends State<MainScreen> {
    int _currentIndex = 0;
    late String _userId;

    final List<Widget> _children = [];

    @override
    void initState() {
      super.initState();
      _userId = widget.userId;
      print('User ID: $_userId'); // Debugging print
      _children.addAll([
        HomeScreen(userId: _userId),
        SearchScreen(userId: _userId),
        InboxScreen(userId: _userId), // Add InboxScreen as a child
        GroupInboxScreen(userId: _userId), // Use the new GroupInboxScreen
      ]);
    }

    void onTabTapped(int index) {
      setState(() {
        _currentIndex = index;
      });
    }

  Future<void> logout() async {
    final userId = await SharedPreferencesService.getUserId(); // Retrieve the user ID

    if (userId == null) {
      // User is already logged out
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/logout'), // Replace with your actual logout URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}), // Send userId in the body
      );

      if (response.statusCode == 200) {
        // Handle successful logout
        await SharedPreferencesService.removeUserId(); // Remove user ID from SharedPreferences
        print('User ID after logout: ${await SharedPreferencesService.getUserId()}'); // Should print null

        // Navigate to the login screen
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      } else {
        // Handle unsuccessful logout
        final responseData = jsonDecode(response.body);
        final errorMessage = responseData['message'] ?? 'Logout Failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (error) {
      print('Logout error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout error occurred')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: nuBlue,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png', // Replace with the path to your logo
              height: 40, // Adjust the height as needed
            ),
            SizedBox(width: 10), // Add some space between the logo and the title
          Text(
              'NUPals',
              style: TextStyle(color: Colors.white), // Set text color to white
            ),
          ],
        ),
      ),

        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text('Profile'),
                onTap: () {
                  Navigator.pushNamed(context, '/profile', arguments: _userId); // Use named route
                },
              ),
              ListTile(
                leading: Icon(Icons.notifications),
                title: Text('Notifications'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsScreen(userId: _userId), // Navigate to Notifications Screen
                    ),
                  );
                },
              ),
                ListTile(
          leading: Icon(Icons.group), // Use a group icon
          title: Text('Group Inbox'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupInboxScreen(userId: _userId),
              ),
            );
          },
        ),
        ListTile(
                leading: Icon(Icons.feedback),
                title: Text('Feedback'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FeedbackScreen(userId: _userId),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                onTap: () async {
                  await logout();
                },
              ),
            ],
          ),
        ),
      body: _children[_currentIndex],
  bottomNavigationBar: BottomNavigationBar(
    currentIndex: _currentIndex,
    onTap: onTabTapped,
    backgroundColor: nuBlue, // Set the background color to blue
    selectedItemColor: Colors.yellow, // Set the color for the selected icon
    unselectedItemColor: Colors.white, // Set the color for unselected icons
    showSelectedLabels: false, // Hide the label of the selected tab
    showUnselectedLabels: false, // Hide the labels of unselected tabs
    items: [
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home', // Label will be hidden
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.search),
        label: 'Search', // Label will be hidden
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.inbox),
        label: 'Inbox', // Label will be hidden
      ),
    ],
  ),

      );
    }
  }

  // Function to register user
  Future<void> registerUser(BuildContext context, String email, String username, String password, String age, String college, String bio) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/auth/register'), // Replace with your server URL
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'username': username,
        'password': password,
        'age': age,
        'college': college,
        'bio': bio,
      }),
    );

    if (response.statusCode == 201) {
      // Registration successful, save user ID
      final data = json.decode(response.body);
      final userId = data['userId'];
      await SharedPreferencesService.saveUserId(userId);
      // Navigate to survey or main screen
      Navigator.pushNamed(context, '/survey', arguments: {'email': email});
    } else {
      // Handle error
      print('Registration failed: ${response.body}');
    }
  }
