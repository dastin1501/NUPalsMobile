import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/screens/search_screen.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/screens/splash_screen.dart';
import 'package:frontend/screens/signup_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/survey_screen.dart';
import 'package:frontend/screens/register_screen.dart';
import 'package:frontend/utils/shared_preferences.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
          initialRoute: userId != null ? '/main' : '/signup',
          routes: {
            '/signup': (context) => SignUpScreen(),
            '/login': (context) => LoginScreen(),
            '/': (context) => LoginScreen(),
            '/main': (context) => MainScreen(userId: userId!), // Pass the loaded user ID
            '/splash': (context) => SplashScreen(),
            '/register': (context) => RegisterScreen(email: ''),
            '/survey': (context) => SurveyScreen(email: '', userId: '',),
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
    ]);
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> logout() async {
    await SharedPreferencesService.removeUserId();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main Screen'),
        backgroundColor: Colors.blue,
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(userId: _userId),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Notifications'),
              onTap: () {
                // Navigate to Notifications screen
              },
            ),
            ListTile(
              leading: Icon(Icons.message),
              title: Text('Messages'),
              onTap: () {
                // Navigate to Messages screen
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
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
        ],
      ),
    );
  }
}

// Function to register user
Future<void> registerUser(BuildContext context, String email, String username, String password, String age, String college, String yearLevel, String bio) async {
  final response = await http.post(
    Uri.parse('http://yourserver.com/register'), // Replace with your server URL
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'email': email,
      'username': username,
      'password': password,
      'age': age,
      'college': college,
      'yearLevel': yearLevel,
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
