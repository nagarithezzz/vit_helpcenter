import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:html/dom.dart' as htmlDom;

void main() {
  runApp(Dashboard());
}

class Dashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: UserProfilePage(),
      theme: ThemeData(
        primaryColor: Colors.blue,
      ),
    );
  }
}

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String username = '';
  String baseUrl =
      'https://vithelpcenter.vit.ac.in/vitcc-help-center/getUserComplaint';

  @override
  void initState() {
    super.initState();
    loadUsername();
  }

  Future<void> loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('username');
    if (savedUsername != null) {
      setState(() {
        username = savedUsername;
        fetchHtmlResponse();
      });
    }
  }

  Future<void> fetchHtmlResponse() async {
    final url = Uri.parse('$baseUrl/$username');
    print(url);
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final htmlResponse = response.body;
        printHtmlDetails(htmlResponse);
      } else {
        print(
            'Failed to fetch HTML response with status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching HTML response: $error');
    }
  }

  void printHtmlDetails(String html) {
    final document = htmlParser.parse(html);

    final rows = document.querySelectorAll('table tr');

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final cells = row.children;
      final incNumber = cells[0].text;
      final category = cells[1].text;
      final subCategory = cells[2].text;
      final description = cells[3].text;
      final status = cells[4].text;
      final createdOn = cells[5].text;
      final buttons = cells[6].querySelectorAll('a');
      final buttonClasses = buttons
          ?.map((button) => button.attributes['class'] ?? '')
          ?.join(', ');

      print('INC Number: $incNumber');
      print('Category: $category');
      print('Sub Category: $subCategory');
      print('Description: $description');
      print('Status: $status');
      print('Created On: $createdOn');
      if (buttonClasses != null) {
        print('Button Classes: $buttonClasses');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${username.isNotEmpty ? username : "Guest"}'),
      ),
      body: Stack(
        children: <Widget>[
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[],
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Tooltip(
                message: 'Create an Incident',
                child: FloatingActionButton(
                  onPressed: () {},
                  child: Icon(Icons.add),
                  backgroundColor: Colors.blue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
