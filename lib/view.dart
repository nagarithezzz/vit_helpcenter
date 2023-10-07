import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:html/dom.dart' as dom;
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

class ViewPage extends StatefulWidget {
  final String incNumber;

  ViewPage({required this.incNumber});

  @override
  _ViewPageState createState() => _ViewPageState();
}

class _ViewPageState extends State<ViewPage> {
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
        'https://vithelpcenter.vit.ac.in/vitcc-help-center/showFormForView';
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

    bool hasSupportingFile = false;
    labelTexts = labels.map((label) => label.text.trim()).toList();
    this.inputs = inputs;

    if (labelTexts.contains('Supporting file Attached')) {
      labelTexts.remove('Supporting file Attached');
      hasSupportingFile = true;
      print(labelTexts.length);
    }

    for (var i = 0; i < labelTexts.length; i++) {
      final label = labelTexts[i];
      final input = inputs[i]?.attributes['value'] ?? inputs[i]?.text.trim();

      inputFields.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextFormField(
            initialValue: input ?? '',
            readOnly: true,
            decoration: InputDecoration(
              labelText: label,
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              contentPadding: EdgeInsets.all(16.0),
            ),
          ),
        ),
      );
    }

    print(hasSupportingFile);
    if (hasSupportingFile) {
      inputFields.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              SizedBox(
                height: 16,
              ), // Add space between the buttons and the text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Supporting File Attached',
                    style: TextStyle(
                      fontSize: 16, // Increase font size
                      fontWeight: FontWeight.bold, // Make it bold
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: onPreviewClicked,
                    child: Text('Preview'),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: onDownloadClicked,
                    child: Text('Download'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    setState(() {});
  }

  void onDownloadClicked() async {
    final Map<String, String> queryParams = {
      'id': '${widget.incNumber}',
      'category': '',
      'status': '',
      'hostelBlockName': '',
      'hostelRoomNumber': '',
      'reporterId': '',
      'reporterName': '',
      'reporterEmailId': '',
      'reporterRole': '',
      'description': '',
      'resolverComments': '',
    };

    for (var i = 0; i < labelTexts.length; i++) {
      final label = labelTexts[i];
      final input = inputs[i]?.attributes['value'] ?? inputs[i]?.text.trim();

      queryParams[label] = input ?? '';
    }

    final baseUrlForDownload =
        'https://vithelpcenter.vit.ac.in/vitcc-help-center/downloadFile';
    final downloadUrl = Uri.https(
      'vithelpcenter.vit.ac.in',
      '/vitcc-help-center/downloadFile',
      queryParams,
    );
    try {
      final taskId = await FlutterDownloader.enqueue(
        url: downloadUrl.toString(),
        savedDir: '/storage/emulated/0/Download/',
        fileName: '${widget.incNumber}.jpg',
        showNotification: true,
        openFileFromNotification: true,
      );

      if (taskId != null) {
        print('Download task ID: $taskId');
      } else {
        print('Failed to enqueue download task.');
      }
    } catch (error) {
      print('Error downloading image: $error');
    }
  }

  void onPreviewClicked() {
    final Map<String, String> queryParams = {
      'id': '${widget.incNumber}',
      'category': '',
      'status': '',
      'hostelBlockName': '',
      'hostelRoomNumber': '',
      'reporterId': '',
      'reporterName': '',
      'reporterEmailId': '',
      'reporterRole': '',
      'description': '',
      'resolverComments': '',
    };

    for (var i = 0; i < labelTexts.length; i++) {
      final label = labelTexts[i];
      final input = inputs[i]?.attributes['value'] ?? inputs[i]?.text.trim();

      queryParams[label] = input ?? '';
    }

    final baseUrlForPreview =
        'https://vithelpcenter.vit.ac.in/vitcc-help-center/preview';
    final previewUrl = Uri.https(
      'vithelpcenter.vit.ac.in',
      '/vitcc-help-center/preview',
      queryParams,
    );
    showDialog(
      context: context,
      builder: (_) {
        return GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(previewUrl.toString()),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.incNumber}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: inputFields,
          ),
        ),
      ),
    );
  }
}
