import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http2/transport.dart' as transport;
import 'package:http2/multiprotocol_server.dart' as http2;

http2.MultiProtocolHttpServer server;
String url;

Future<void> startTestServer() async {
  var context = SecurityContext()
    ..useCertificateChainBytes(
        (await rootBundle.load('assets/cert.pem')).buffer.asUint8List())
    ..usePrivateKeyBytes(
        (await rootBundle.load('assets/key.pem')).buffer.asUint8List(),
        password: 'test');
  server = await http2.MultiProtocolHttpServer.bind(
    "localhost",
    0,
    context,
  );
  url = 'https://localhost:${server.port}';
  _serve();
}

void _serve() async {
  server.startServing(handleRequest, handleStream, onError: (_, __) {});
}

void handleRequest(req) async {
  final r = TestRequest();
  r.url = req.uri.toString();
  r.method = req.method;
  r.headers = {};
  req.headers.forEach((name, values) {
    r.headers[name] = values.join("; ");
  });
  final s = await processRequest(r);
  req.response.statusCode = s.statusCode;
  s.headers.forEach((name, values) {
    req.response.headers.add(name, values);
  });
  req.response.write(s.body);
  req.response.close();
}

void handleStream(transport.ServerTransportStream stream) async {
  final req = TestRequest();
  await for (var message in stream.incomingMessages) {
    if (message is transport.HeadersStreamMessage) {
      for (var header in message.headers) {
        var name = utf8.decode(header.name);
        var value = utf8.decode(header.value);
        req.headers[name] = value;
      }
    } else if (message is transport.DataStreamMessage) {
      req.body.addAll(message.bytes);
    }
    if (message.endStream) break;
  }
  req.method = req.headers[":method"];
  req.url = Uri(
    scheme: req.headers[":scheme"],
    host: req.headers[":authority"].split(":")[0],
    port: int.parse(req.headers[":authority"].split(":")[1]),
    path: req.headers[":path"],
  ).toString();
  final s = await processRequest(req);
  stream.sendHeaders([
    transport.Header.ascii(":status", s.statusCode.toString())
  ]..addAll(s.headers.entries
      .map((e) => transport.Header(
            systemEncoding.encode(e.key),
            systemEncoding.encode(e.value),
          ))
      .toList()));
  stream.sendData(s.body, endStream: true);
}

class TestRequest {
  String url;
  String method;
  Map<String, String> headers = {};
  List<int> body = [];
}

class TestResponse {
  int statusCode = 200;
  Map<String, String> headers = {};
  List<int> body = [];
}

Future<TestResponse> processRequest(TestRequest request) async {
  final response = TestResponse();
  String customStatusCode = request.headers["X-StatusCode".toLowerCase()];
  if (customStatusCode != null)
    response.statusCode = int.parse(customStatusCode);

  String customEtag = request.headers["X-Etag".toLowerCase()];
  if (customEtag != null) {
    response.headers["etag"] = customEtag;
    if (customEtag == request.headers["If-None-Match".toLowerCase()]) {
      response.statusCode = 304;
    }
  }

  String customLastModified = request.headers["X-LastModified".toLowerCase()];
  if (customLastModified != null) {
    response.headers["last-modified"] = customLastModified;
    if (request.headers["if-modified-since"] != null &&
        HttpDate.parse(customLastModified).millisecondsSinceEpoch <=
            HttpDate.parse(request.headers["if-modified-since"])
                .millisecondsSinceEpoch) {
      response.statusCode = 304;
    }
  }

  String encoding = request.headers["X-Encoding".toLowerCase()];
  if (encoding != null) {
    if (encoding == "gzip") {
      response.headers["content-encoding"] = "gzip";
      response.body =
          (await rootBundle.load("assets/gzip.bin")).buffer.asUint8List();
    }
    if (encoding == "br") {
      response.headers["content-encoding"] = "br";
      response.body =
          (await rootBundle.load("assets/brotli.bin")).buffer.asUint8List();
    }
  } else {
    response.body = systemEncoding.encode(json.encode({
      "url": url,
      "method": request.method,
      "headers": request.headers,
      "body": utf8.decode(request.body),
    }));
  }
  return response;
}

Future<void> stopTestServer() async {
  await server.close(force: true);
  server = null;
  url = null;
}
