part of 'client.dart';

class _ResponseBuffer {
  String _requestID;
  ffi.Pointer _slist;
  List<int> _bodyBuffer;
  List<int> _headerBuffer;
  int _statusCode;
  int _httpVersion;

  _ResponseBuffer() {
    _statusCode = 0;
    _bodyBuffer = [];
    _headerBuffer = [];
  }

  Response toResponse() {
    var rawHeaders = utf8.decode(_headerBuffer);
    rawHeaders = rawHeaders.trim();
    var items = rawHeaders.split("\r\n");
    items.removeAt(0); // proto

    Map<String, String> headers = {};
    for (var item in items) {
      int pos = item.indexOf(": ");
      String key = item.substring(0, pos).toLowerCase();
      String value = item.substring(pos + 2);
      if (headers[key] == null) {
        headers[key] = value;
      } else {
        headers[key] += "; " + value;
      }
    }

    final res = Response(
      statusCode: _statusCode,
      body: _bodyBuffer,
      headers: headers,
      httpVersion: _httpVersion,
    );
    res._requestID = _requestID;
    return res;
  }
}

class Response {
  String _requestID;
  Request _request;

  int statusCode;
  Map<String, String> headers;
  List<int> body;
  int httpVersion;

  Response({
    this.statusCode,
    this.headers,
    this.body,
    this.httpVersion,
  });

  Request get request => _request;

  int get length => body.length;

  String text() => utf8.decode(body);
}
