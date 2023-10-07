import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:vit_helpcenter/dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final storedUsername = prefs.getString('username');

  await FlutterDownloader.initialize(
    debug: true,
  );
  runApp(MyApp(isLoggedIn: storedUsername != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  MyApp({required this.isLoggedIn});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: isLoggedIn ? Dashboard() : LoginScreen(),
      theme: ThemeData(
        primaryColor: Colors.blue,
        colorScheme:
            ColorScheme.fromSwatch().copyWith(secondary: Colors.blueAccent),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _handleSignIn() async {
    final username = usernameController.text;
    final password = passwordController.text;

    final url = Uri.parse(
        'https://vithelpcenter.vit.ac.in/vitcc-help-center/autoLogin');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': username,
          'password': password,
          'login': "LOGIN",
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.body;
        if (responseData.contains('Logged in User')) {
          final prefs = await SharedPreferences.getInstance();
          prefs.setString('username', username);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                return Dashboard();
              },
            ),
          );
        } else if (responseData.contains('Invalid User Id or Password')) {
          Fluttertoast.showToast(
            msg: 'Login failed: Invalid user ID or password.',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: 'Login failed with Status code : ${response.statusCode}',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('VIT Help Center'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            FlutterLogo(
              size: 100.0,
            ),
            SizedBox(height: 20.0),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: _handleSignIn,
              child: Text('Sign In'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
