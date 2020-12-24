import 'package:flutter/material.dart';
import 'package:flutter_curl/flutter_curl.dart';

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
    curl = Client(verbose: true);
    await curl.init();
  }

  void _incrementCounter() async {
    state = "Sending request";
    setState(() {});
    final res = await curl.send(Request(
      method: "GET",
      url: "https://ajinasokan.com/",
      headers: {},
      body: [],
      verbose: true,
    ));

    print("Status: ${res.statusCode}");
    print("HTTP: ${res.httpVersion}");
    res.headers.forEach((key, value) {
      print("$key: $value");
      if (key == "content-encoding") {
        encoding = value;
      }
    });
    // print(res.text());

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
