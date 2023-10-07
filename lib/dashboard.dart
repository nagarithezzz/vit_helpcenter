import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:html/dom.dart' as htmlDom;
import 'package:vit_helpcenter/edit.dart';
import 'package:vit_helpcenter/main.dart';
import 'package:vit_helpcenter/view.dart';

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

class Report {
  String incNumber = '';
  String createdOn = '';
  String category = '';
  String subCategory = '';
  String description = '';
  String status = '';
  List<String> buttonClasses = [];
}

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String username = '';
  List<Report> reports = [];
  String baseUrl =
      'https://vithelpcenter.vit.ac.in/vitcc-help-center/getUserComplaint';

  @override
  void initState() {
    super.initState();
    loadUsername();
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('username');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          return MyApp(isLoggedIn: false);
        },
      ),
    );
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
      final report = Report();
      report.incNumber = cells[0].text;
      report.category = cells[1].text;
      report.subCategory = cells[2].text;
      report.description = cells[3].text;
      report.status = cells[4].text;
      report.createdOn = cells[5].text;

      final buttons = cells[6].querySelectorAll('a');
      final buttonClasses = buttons
              ?.map((button) => button.attributes['class'] ?? '')
              ?.toList() ??
          [];

      report.buttonClasses = buttonClasses;

      setState(() {
        reports.add(report);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${username.isNotEmpty ? username : "Guest"}'),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (choice) {
              if (choice == 'logout') {
                logout();
              }
            },
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Logout'),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            if (reports.isEmpty)
              Center(
                child: Text(
                  'No incidents found!',
                  style: TextStyle(fontSize: 30, color: Colors.blue),
                ),
              ),
            for (var report in reports)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 2,
                  child: ExpansionTile(
                    title: Text(
                      '${report.incNumber}',
                      style: TextStyle(fontSize: 18),
                    ),
                    subtitle: Text(
                      'Created On: ${report.createdOn}',
                      style: TextStyle(fontSize: 14),
                    ),
                    trailing: Icon(Icons.keyboard_arrow_down),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category: ${report.category}',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Sub Category: ${report.subCategory}',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Description: ${report.description}',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Status: ${report.status}',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: buildButtons(
                                  report.buttonClasses, report.incNumber),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
        tooltip: 'Create an Incident',
      ),
    );
  }

  List<Widget> buildButtons(List<String> buttonClasses, String incNumber) {
    List<Widget> buttons = [];
    for (var buttonClass in buttonClasses) {
      if (buttonClass.contains('btn btn-success btn-sm')) {
        buttons.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewPage(incNumber: incNumber),
                  ),
                );
              },
              icon: Icon(Icons.visibility),
              label: Text('View'),
              style: ElevatedButton.styleFrom(
                primary: Colors.green,
              ),
            ),
          ),
        );
      } else if (buttonClass.contains('btn btn-danger btn-sm')) {
        buttons.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditPage(incNumber: incNumber),
                  ),
                );
              },
              icon: Icon(Icons.edit),
              label: Text('Edit'),
              style: ElevatedButton.styleFrom(
                primary: Colors.red,
              ),
            ),
          ),
        );
      }
    }

    return buttons;
  }
}
