import 'dart:io';
import 'dart:async';
import 'package:flutter_curl/flutter_curl.dart' as curl;
import 'package:path_provider/path_provider.dart' as paths;
import 'echo_server.dart' as echo;
import 'dart:convert';

List<Test> tests = [
  Test(
    title: "create curl client",
    exec: (ctx) async {
      final c = curl.Client(verbose: true);
      ctx["ref"] = c;
      await c.init();
      return c.runtimeType;
    },
    expect: (ctx) => curl.Client,
    afterTest: (ctx) {
      (ctx["ref"] as curl.Client).dispose();
    },
  ),
  Test(
    title: "http 1.1",
    exec: (ctx) async {
      final c = curl.Client(
        verbose: true,
        verifySSL: false,
        httpVersions: [curl.HTTPVersion.http11],
      );
      await c.init();
      final res = await c.send(curl.Request(
        method: "get",
        url: echo.url!,
        headers: {},
      ));
      c.dispose();
      return res.httpVersion;
    },
    expect: (ctx) => curl.HTTPVersion.http11,
  ),
  Test(
    title: "http 2",
    exec: (ctx) async {
      final c = curl.Client(verifySSL: false);
      await c.init();
      final res = await c.send(curl.Request(
        method: "get",
        url: echo.url!,
        headers: {},
      ));
      c.dispose();
      return res.httpVersion;
    },
    expect: (ctx) => curl.HTTPVersion.http2,
  ),
  Test(
    title: "ssl verification",
    exec: (ctx) async {
      final c = curl.Client(); // verifySSL: true
      await c.init();
      final res = await c.send(curl.Request(
        method: "get",
        url: echo.url!,
        headers: {},
      ));
      c.dispose();
      return res.errorMessage;
    },
    expect: (ctx) => "SSL peer certificate or SSH remote key was not OK",
  ),
  Test(
    title: "ssl verification disabled",
    exec: (ctx) async {
      final c = curl.Client(verifySSL: false);
      await c.init();
      final res = await c.send(curl.Request(
        method: "get",
        url: echo.url!,
        headers: {},
      ));
      c.dispose();
      return res.statusCode;
    },
    expect: (ctx) => 200,
  ),
  Test(
    title: "status 200",
    exec: (ctx) async {
      final c = curl.Client(verifySSL: false);
      await c.init();
      final res = await c.send(curl.Request(
        method: "get",
        url: echo.url!,
        headers: {},
      ));
      c.dispose();
      return res.statusCode;
    },
    expect: (ctx) => 200,
  ),
  Test(
    title: "status 400",
    exec: (ctx) async {
      final c = curl.Client(verifySSL: false);
      await c.init();
      final res = await c.send(curl.Request(
        method: "get",
        url: echo.url!,
        headers: {
          "X-StatusCode": "400",
        },
      ));
      c.dispose();
      return res.statusCode;
    },
    expect: (ctx) => 400,
  ),
  Test(
    title: "custom request method",
    exec: (ctx) async {
      final c = curl.Client(verifySSL: false);
      await c.init();
      final res = await c.send(curl.Request(
        method: "xyz",
        url: echo.url!,
        headers: {
          "X-StatusCode": "400",
        },
      ));
      c.dispose();
      return json.decode(res.text())["method"];
    },
    expect: (ctx) => "xyz",
  ),
  Test(
    title: "default user agent",
    exec: (ctx) async {
      final c = curl.Client(verifySSL: false);
      await c.init();
      final res = await c.send(curl.Request(
        method: "get",
        url: echo.url!,
        headers: {},
      ));
      c.dispose();
      return json.decode(res.text())["headers"]["user-agent"];
    },
    expect: (ctx) => null,
  ),
  Test(
    title: "custom user agent",
    exec: (ctx) async {
      final c = curl.Client(verifySSL: false, userAgent: "custom agent");
      await c.init();
      final res = await c.send(curl.Request(
        method: "get",
        url: echo.url!,
        headers: {},
      ));
      c.dispose();
      return json.decode(res.text())["headers"]["user-agent"];
    },
    expect: (ctx) => "custom agent",
  ),
  Test(
    title: "custom user agent header",
    exec: (ctx) async {
      final c = curl.Client(verifySSL: false);
      await c.init();
      final res = await c.send(curl.Request(
        method: "get",
        url: echo.url!,
        headers: {
          "user-agent": "dart_curl",
        },
      ));
      c.dispose();
      return json.decode(res.text())["headers"]["user-agent"];
    },
    expect: (ctx) => "dart_curl",
  ),
  // user agent in header overrides client setting
  Test(
    title: "custom user agent header override",
    exec: (ctx) async {
      final c = curl.Client(verifySSL: false, userAgent: "custom agent");
      await c.init();
      final res = await c.send(curl.Request(
        method: "get",
        url: echo.url!,
        headers: {
          "user-agent": "dart_curl",
        },
      ));
      c.dispose();
      return json.decode(res.text())["headers"]["user-agent"];
    },
    expect: (ctx) => "dart_curl",
  ),
  Test(
    title: "post raw",
    exec: (ctx) async {
      final c = curl.Client(verifySSL: false);
      await c.init();
      final res = await c.send(curl.Request.post(
        url: echo.url!,
        body: curl.RequestBody.raw("hello world".codeUnits),
      ));
      c.dispose();
      return json.decode(res.text())["body"];
    },
    expect: (ctx) => "hello world",
  ),
  Test(
    title: "post string",
    exec: (ctx) async {
      final c = curl.Client(verifySSL: false);
      await c.init();
      final res = await c.send(curl.Request.post(
        url: echo.url!,
        body: curl.RequestBody.string("hello world"),
      ));
      c.dispose();
      return json.decode(res.text())["body"];
    },
    expect: (ctx) => "hello world",
  ),
  Test(
    title: "post form",
    exec: (ctx) async {
      final c = curl.Client(verifySSL: false);
      await c.init();
      final res = await c.send(curl.Request.post(
        url: echo.url!,
        body: curl.RequestBody.form({
          "age": "10",
          "hello": "world",
        }),
      ));
      c.dispose();
      final map = json.decode(res.text());
      return map["body"] == "age=10&hello=world" &&
          map["headers"]["content-type"] == "application/x-www-form-urlencoded";
    },
    expect: (ctx) => true,
  ),
  Test(
    title: "post multipart",
    exec: (ctx) async {
      final f = (await paths.getTemporaryDirectory()).path + "/multipart.txt";
      File(f).writeAsStringSync("text content");
      final c = curl.Client(verifySSL: false);
      await c.init();
      final res = await c.send(curl.Request.post(
        url: echo.url!,
        body: curl.RequestBody.multipart([
          curl.Multipart(name: "age", data: "1024"),
          curl.Multipart(name: "hello", data: "world"),
          curl.Multipart.file(
            name: "fieldname",
            path: f,
            filename: "filename.txt",
          ),
        ]),
      ));
      c.dispose();

      File(f).deleteSync();
      final map = json.decode(res.text());
      String body = map["body"];
      return map["headers"]["content-type"]
              .contains("multipart/form-data; boundary=") &&
          body.contains(
              'Content-Disposition: form-data; name="fieldname"; filename="filename.txt"') &&
          body.contains('text content') &&
          body.contains('form-data; name="age"') &&
          body.contains('1024') &&
          body.contains('name="hello"') &&
          body.contains('world');
    },
    expect: (ctx) => true,
  ),
  Test(
    title: "brotli compression",
    exec: (ctx) async {
      final c = curl.Client(verifySSL: false);
      await c.init();
      final res = await c.send(curl.Request.get(
        url: echo.url!,
        headers: {
          "X-Encoding": "br",
        },
      ));
      c.dispose();
      return res.headers["content-encoding"] == "br" &&
          res.text().contains("<html>");
    },
    expect: (ctx) => true,
  ),
  Test(
    title: "gzip compression",
    exec: (ctx) async {
      final c = curl.Client(verifySSL: false);
      await c.init();
      final res = await c.send(curl.Request.get(
        url: echo.url!,
        headers: {
          "X-Encoding": "gzip",
        },
      ));
      c.dispose();
      return res.headers["content-encoding"] == "gzip" &&
          res.text().contains("<html>");
    },
    expect: (ctx) => true,
  ),
  Test(
    title: "multiple request",
    exec: (ctx) async {
      final c = curl.Client(verifySSL: false);
      await c.init();
      final res1Fut = c.send(curl.Request(
        method: "get",
        url: echo.url! + "/hello",
        headers: {},
      ));
      final res2Fut = c.send(curl.Request(
        method: "get",
        url: echo.url! + "/world",
        headers: {},
      ));
      final res = await Future.wait([res1Fut, res2Fut]);
      c.dispose();
      return res[0].statusCode == 200 && res[1].statusCode == 200;
    },
    expect: (ctx) => true,
  ),
  Test(
    title: "etag cache hit",
    exec: (ctx) async {
      final memCache = <String, String>{};
      final caching = curl.HTTPCaching(
        getter: (key) async => memCache[key],
        setter: (key, val) async => memCache[key] = val,
      );
      final c = curl.Client(
        verifySSL: false,
        interceptors: [
          caching,
        ],
      );
      await c.init();
      var res = await c.send(curl.Request(
        method: "get",
        url: echo.url!,
        headers: {
          "X-Etag": "abcd",
        },
      ));
      final firstStatus = res.statusCode;
      res = await c.send(curl.Request(
        method: "get",
        url: echo.url!,
        headers: {
          "X-Etag": "abcd",
        },
      ));
      c.dispose();
      return firstStatus == 200 && res.headers[":from_cache"] == "true";
    },
    expect: (ctx) => true,
  ),
  Test(
    title: "etag cache miss",
    exec: (ctx) async {
      final memCache = <String, String>{};
      final caching = curl.HTTPCaching(
        getter: (key) async => memCache[key],
        setter: (key, val) async => memCache[key] = val,
      );
      final c = curl.Client(
        verifySSL: false,
        interceptors: [
          caching,
        ],
      );
      await c.init();
      var res = await c.send(curl.Request(
        method: "get",
        url: echo.url!,
        headers: {
          "X-Etag": "abcd",
        },
      ));
      final firstStatus = res.statusCode;
      res = await c.send(curl.Request(
        method: "get",
        url: echo.url!,
        headers: {
          "X-Etag": "xyz",
        },
      ));
      c.dispose();
      return firstStatus == 200 && res.headers[":from_cache"] == null;
    },
    expect: (ctx) => true,
  ),
  Test(
    title: "last modified cache hit",
    exec: (ctx) async {
      final memCache = <String, String>{};
      final caching = curl.HTTPCaching(
        getter: (key) async => memCache[key],
        setter: (key, val) async => memCache[key] = val,
      );
      final c = curl.Client(
        verifySSL: false,
        interceptors: [
          caching,
        ],
      );
      await c.init();
      var res = await c.send(curl.Request(
        method: "get",
        url: echo.url!,
        headers: {
          "X-LastModified": "Wed, 21 Oct 2015 07:28:00 GMT",
        },
      ));
      final firstStatus = res.statusCode;
      res = await c.send(curl.Request(
        method: "get",
        url: echo.url!,
        headers: {
          "X-LastModified": "Wed, 21 Oct 2015 07:28:00 GMT",
        },
      ));
      c.dispose();
      return firstStatus == 200 && res.headers[":from_cache"] == "true";
    },
    expect: (ctx) => true,
  ),
  Test(
    title: "last modified cache miss",
    exec: (ctx) async {
      final memCache = <String, String>{};
      final caching = curl.HTTPCaching(
        getter: (key) async => memCache[key],
        setter: (key, val) async => memCache[key] = val,
      );
      final c = curl.Client(
        verifySSL: false,
        interceptors: [
          caching,
        ],
      );
      await c.init();
      var res = await c.send(curl.Request(
        method: "get",
        url: echo.url!,
        headers: {
          "X-LastModified": "Wed, 21 Oct 2015 07:28:00 GMT",
        },
      ));
      final firstStatus = res.statusCode;
      res = await c.send(curl.Request(
        method: "get",
        url: echo.url!,
        headers: {
          "X-LastModified": "Wed, 21 Oct 2015 07:28:01 GMT",
        },
      ));
      c.dispose();
      return firstStatus == 200 && res.headers[":from_cache"] == null;
    },
    expect: (ctx) => true,
  ),
  // TODO: a simple http echo proxy to mock this
  // Test(
  //   title: "http proxy",
  //   exec: (ctx) async {
  //     final c = curl.Client(
  //       verifySSL: false,
  //     );
  //     await c.init();
  //     var res = await c.send(curl.Request(
  //       method: "GET",
  //       url: "http://canhazip.com",
  //       proxy: "<proxy http://ip:port>",
  //     ));
  //     final ip = res.text().trim();
  //     c.dispose();
  //     return ip == "<proxy ip>";
  //   },
  //   expect: (ctx) => true,
  // ),
];

// TODO: http3, altsvc

class Test {
  final String title;
  final dynamic Function(Map<String, dynamic>) exec;
  final dynamic Function(Map<String, dynamic>) expect;
  final dynamic Function(Map<String, dynamic>)? beforeTest;
  final dynamic Function(Map<String, dynamic>)? afterTest;
  final Map<String, dynamic> context = {};
  bool? passed;

  Test({
    required this.title,
    required this.exec,
    required this.expect,
    this.beforeTest,
    this.afterTest,
  });

  Future<void> run() async {
    if (beforeTest != null) {
      var beforeTestRes = beforeTest!(context);
      if (beforeTestRes is Future) beforeTestRes = await beforeTestRes;
    }

    var execRes = exec(context);
    if (execRes is Future) execRes = await execRes;

    var expectRes = expect(context);
    if (expectRes is Future) expectRes = await expectRes;

    passed = execRes == expectRes;

    if (!passed!) {
      print("expected: $expectRes\ngot: $execRes");
    }

    if (afterTest != null) {
      var afterTestRes = afterTest!(context);
      if (afterTestRes is Future) afterTestRes = await afterTestRes;
    }
  }
}
