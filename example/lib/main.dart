import 'package:flutter/material.dart';
import 'package:flutter_curl/flutter_curl.dart';
import 'package:path_provider/path_provider.dart' as paths;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Client curl;
  String state = "Idle";
  String statusCode = "NA";
  String httpVersion = "NA";
  String encoding = "NA";

  void init() async {
    curl = Client(
      verbose: true,
      timeout: Duration(seconds: 10),
      connectTimeout: Duration(seconds: 4),
    );
    await curl.init();
  }

  void _incrementCounter() async {
    state = "Sending request";
    setState(() {});
    final downloadPath =
        (await paths.getApplicationDocumentsDirectory()).path + "/index.html";

    print("Downloading to $downloadPath");
    final res = await curl.download(
      path: downloadPath,
      request: Request(
        method: "GET",
        url: "https://ajinasokan.com/",
        headers: {},
        verbose: true,
      ),
    );

    print("Status: ${res.statusCode}");
    print("HTTP: ${res.httpVersion}");
    res.headers.forEach((key, value) {
      print("$key: $value");
      if (key == "content-encoding") {
        encoding = value;
      }
    });
    print("Text: " + res.text());
    print("Error: ${res.errorMessage}");

    statusCode = "${res.statusCode}";
    httpVersion = "${res.httpVersion}";
    state = "Idle";
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    curl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(title: Text("CURL Test")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('State: $state'),
              Text('Status code: $statusCode'),
              Text('HTTP Version: $httpVersion'),
              Text('Encoding: $encoding'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _incrementCounter,
          tooltip: 'Increment',
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
