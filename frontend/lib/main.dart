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

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(360, 690),
      builder: (context, child) {
        return MaterialApp(
          title: 'Social Media App',
          theme: ThemeData(primarySwatch: Colors.blue),
          initialRoute: '/splash',
          routes: {
            '/signup': (context) => SignUpScreen(),
            '/login': (context) => LoginScreen(),
            '/': (context) => LoginScreen(),
            '/main': (context) {
              final userId = ModalRoute.of(context)!.settings.arguments as String;
              return MainScreen(userId: userId);
            },
            '/splash': (context) => SplashScreen(),
            '/register': (context) {
              final userId = ModalRoute.of(context)!.settings.arguments as String;
              return RegisterScreen(email: ''); // Ensure you pass the correct email
            },
            '/survey': (context) {
              final args = ModalRoute.of(context)!.settings.arguments;
              if (args is Map<String, dynamic>) {
                final userId = args['userId'] as String;
                final email = args['email'] as String; // Ensure email is passed correctly
                return SurveyScreen(userId: userId, email: email); // Pass user ID and email
              } else {
                // Handle the case where the arguments are not as expected
                return SurveyScreen(userId: '', email: ''); // or handle appropriately
              }
            },
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
