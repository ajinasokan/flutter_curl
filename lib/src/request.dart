part of 'client.dart';

/// [Request] holds request data for the HTTP call. Each request
/// has a unique id. It is used to track the request throughout the queue.
class Request {
  // counter to generate unique ids for each request
  static int _id = 0;

  final String id;
  final String url;
  final String method;
  final Map<String, String> headers;
  final List<int> body;
  String userAgent;
  bool verbose;

  String _cookiePath;
  String _altSvcCache;
  String _certPath;
  int _timeout;
  int _connectTimeout;
  String _downloadPath;

  Request({
    this.url,
    this.method,
    this.headers,
    this.body,
    this.verbose,
  })  : assert(url != null),
        assert(method != null),
        assert(headers != null),
        assert(body != null),
        id = "${++_id}";

  factory Request.get({
    String url,
    Map<String, String> headers,
  }) =>
      Request(
        method: "GET",
        url: url,
        headers: headers ?? {},
        body: [],
      );

  factory Request.delete({
    String url,
    Map<String, String> headers,
  }) =>
      Request(
        method: "DELETE",
        url: url,
        headers: headers ?? {},
        body: [],
      );

  factory Request.post({
    String url,
    Map<String, String> headers,
    String body,
  }) =>
      Request(
        method: "POST",
        url: url,
        headers: headers ?? {},
        body: utf8.encode(body),
      );

  factory Request.put({
    String url,
    Map<String, String> headers,
    String body,
  }) =>
      Request(
        method: "PUT",
        url: url,
        headers: headers ?? {},
        body: utf8.encode(body),
      );
}
