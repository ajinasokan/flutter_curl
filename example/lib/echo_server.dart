import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

HttpServer server;
String url;

Future<void> startTestServer() async {
  server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    0,
  );
  url = 'http://${server.address.host}:${server.port}';
  _serve();
}

void _serve() async {
  await for (HttpRequest request in server) {
    Map<String, String> headers = {};
    request.headers.forEach((name, values) {
      headers[name] = values.join("; ");
    });

    String customStatusCode = request.headers.value("X-StatusCode");
    if (customStatusCode != null)
      request.response.statusCode = int.parse(customStatusCode);

    String customEtag = request.headers.value("X-Etag");
    if (customEtag != null) {
      request.response.headers.set("etag", customEtag);
      if (customEtag == request.headers.value("If-None-Match")) {
        request.response.statusCode = 304;
      }
    }

    String customLastModified = request.headers.value("X-LastModified");
    if (customLastModified != null) {
      request.response.headers.set("last-modified", customLastModified);
      if (request.headers.ifModifiedSince != null &&
          HttpDate.parse(customLastModified).millisecondsSinceEpoch <=
              request.headers.ifModifiedSince.millisecondsSinceEpoch) {
        request.response.statusCode = 304;
      }
    }

    String encoding = request.headers.value("X-Encoding");
    if (encoding != null) {
      if (encoding == "gzip") {
        request.response.headers.set("content-encoding", "gzip");
        request.response.add(
            (await rootBundle.load("assets/gzip.bin")).buffer.asUint8List());
      }
      if (encoding == "br") {
        request.response.headers.set("content-encoding", "br");
        request.response.add(
            (await rootBundle.load("assets/brotli.bin")).buffer.asUint8List());
      }
    } else {
      request.response.write(json.encode({
        "url": request.requestedUri.toString(),
        "method": request.method,
        "headers": headers,
        "body": await systemEncoding.decodeStream(request),
      }));
    }
    await request.response.close();
  }
}

Future<void> stopTestServer() async {
  await server.close(force: true);
  server = null;
  url = null;
}
