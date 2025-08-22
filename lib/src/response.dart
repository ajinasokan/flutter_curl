part of 'client.dart';

enum HTTPVersion {
  unknown,
  http1,
  http11,
  http2,
  http3,
}

class _ResponseBuffer {
  String? requestID;
  ffi.Pointer? slist;
  final List<int> bodyBuffer = [];
  final List<int> headerBuffer = [];
  int statusCode = 0;
  int httpVersion = 0;
  int? errorCode;
  String? errorMessage;

  Response toResponse(_Engine engine) {
    // Parse headers
    // TODO: figure out if there is a better way to do this
    var rawHeaders = utf8.decode(headerBuffer);
    rawHeaders = rawHeaders.trim();
    var items = rawHeaders.split("\r\n");
    items.removeAt(0); // proto

    Map<String, String> headers = {};
    DateTime? lastModified;
    for (var item in items) {
      int pos = item.indexOf(": ");
      // when requesting https over http proxy there are two proto responses
      // `HTTP/1.1 200 OK` and `HTTP/2 200`
      // this skips non header lines from the buffer
      if (pos == -1) continue;
      String key = item.substring(0, pos).toLowerCase();
      String value = item.substring(pos + 2);
      if (headers[key] == null) {
        headers[key] = value;
      } else {
        headers[key] = headers[key]! + "; " + value;
      }
      if (key == "last-modified") {
        lastModified = DateTime.fromMillisecondsSinceEpoch(
            engine.libCurl.getdate(value.toNativeUtf8(), ffi.nullptr) * 1000);
      }
    }

    // Pick HTTP version
    HTTPVersion httpVer = <int, HTTPVersion>{
          consts.CURL_HTTP_VERSION_1_0: HTTPVersion.http1,
          consts.CURL_HTTP_VERSION_1_1: HTTPVersion.http11,
          consts.CURL_HTTP_VERSION_2TLS: HTTPVersion.http2,
          consts.CURL_HTTP_VERSION_2_0: HTTPVersion.http2,
          consts.CURL_HTTP_VERSION_2_PRIOR_KNOWLEDGE: HTTPVersion.http2,
          consts.CURL_HTTP_VERSION_3: HTTPVersion.http3,
        }[httpVersion] ??
        HTTPVersion.unknown;

    return Response(
      statusCode: statusCode,
      body: bodyBuffer,
      headers: headers,
      httpVersion: httpVer,
      errorCode: errorCode,
      errorMessage: errorMessage,
      lastModified: lastModified,
    ).._requestID = requestID;
  }
}

class Response {
  String? _requestID;
  Request? _request;

  int statusCode;
  List<int> body;
  final Map<String, String> headers;
  final HTTPVersion httpVersion;
  final String? errorMessage;
  final int? errorCode;
  final DateTime? lastModified;

  Response({
    required this.statusCode,
    required this.headers,
    required this.body,
    required this.httpVersion,
    required this.errorCode,
    required this.errorMessage,
    required this.lastModified,
  });

  Request? get request => _request;

  int get length => body.length;

  String text() => utf8.decode(body);
}
