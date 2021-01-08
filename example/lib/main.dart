import 'package:flutter/material.dart';
import 'tests.dart';
import 'echo_server.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  void runTests() async {
    await startTestServer();
    tests.forEach((t) {
      t.passed = null;
    });
    setState(() {});
    for (var t in tests) {
      await t.run();
      setState(() {});
    }
    await stopTestServer();
  }

  void runTest(Test t) async {
    await startTestServer();
    t.passed = null;
    setState(() {});
    await t.run();
    setState(() {});
    await stopTestServer();
  }

  String get title {
    int success = 0;
    int fail = 0;
    int stopped = 0;
    tests.forEach((e) {
      if (e.passed == true) success++;
      if (e.passed == false) fail++;
      if (e.passed == null) stopped++;
    });
    return "Success: $success, Fail: $fail, Stopped: $stopped";
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView.builder(
          itemCount: tests.length,
          itemBuilder: (_, i) {
            return ListTile(
              onTap: () async {
                runTest(tests[i]);
              },
              leading: {
                null: Icon(Icons.more_horiz),
                true: Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                ),
                false: Icon(
                  Icons.remove_circle,
                  color: Colors.red,
                )
              }[tests[i].passed],
              title: Text(tests[i].title),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => runTests(),
          tooltip: 'Increment',
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
