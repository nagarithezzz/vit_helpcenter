import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:html/dom.dart' as dom;
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

class EditPage extends StatefulWidget {
  final String incNumber;

  EditPage({required this.incNumber});

  @override
  _EditPageState createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  List<Widget> inputFields = [];
  List<String> labelTexts = [];
  List<dom.Element?> inputs = [];

  @override
  void initState() {
    super.initState();
    fetchHtmlResponse();
  }

  Future<void> fetchHtmlResponse() async {
    final baseUrl =
        'https://vithelpcenter.vit.ac.in/vitcc-help-center/showFormForUpdate';
    final url = Uri.parse('$baseUrl/${widget.incNumber}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final htmlResponse = response.body;
        buildInputFields(htmlResponse);
      } else {
        print(
            'Failed to fetch HTML response with status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching HTML response: $error');
    }
  }

  void buildInputFields(String html) {
    final document = htmlParser.parse(html);
    final labels = document.querySelectorAll('label');
    final inputs = document.querySelectorAll('input, textarea');

    labelTexts = labels.map((label) => label.text.trim()).toList();
    this.inputs = inputs;

    for (var i = 0; i < labelTexts.length; i++) {
      final label = labelTexts[i];
      final input = inputs[i]?.attributes['value'] ?? inputs[i]?.text.trim();

      final isDescription = label.toLowerCase().contains('description');

      inputFields.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextFormField(
            initialValue: input ?? '',
            readOnly: !isDescription, // Set readOnly based on label
            decoration: InputDecoration(
              labelText: label,
              filled: true,
              fillColor: isDescription
                  ? Colors.white
                  : Colors.grey[200], // Set background color
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              contentPadding: EdgeInsets.all(16.0),
            ),
          ),
        ),
      );
    }

    setState(() {});
  }

  Future<void> updateData() async {
    final updateUrl =
        'https://vithelpcenter.vit.ac.in/vitcc-help-center/updateAComplaint';
    final Map<String, String> payloads = {};

    for (var i = 0; i < labelTexts.length; i++) {
      final labelText = labelTexts[i];
      final inputValue =
          inputs[i]?.attributes['value'] ?? inputs[i]?.text.trim();

      if (inputValue != null && inputValue.isNotEmpty) {
        payloads[labelText] = inputValue;
      }
      print(payloads);
    }

    try {
      final response = await http.post(Uri.parse(updateUrl), body: payloads);

      if (response.statusCode == 200) {
        print('Update successful');
      } else {
        print('Update failed with status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error updating data: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.incNumber}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Column(
              children: inputFields,
            ),
            SizedBox(
              height: 16.0,
            ),
            ElevatedButton(
              onPressed: () {
                updateData();
              },
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
