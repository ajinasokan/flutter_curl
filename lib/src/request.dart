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
  final RequestBody body;
  String userAgent;
  bool verbose;
  bool verifySSL;
  List<HTTPVersion> httpVersions;

  String _cookiePath;
  String _altSvcCache;
  Duration timeout;
  Duration connectTimeout;
  String _downloadPath;

  Request({
    @required this.url,
    this.method = "GET",
    this.headers = const {},
    this.body,
    this.verbose = false,
    this.verifySSL = true,
    this.httpVersions = const [
      HTTPVersion.http1,
      HTTPVersion.http11,
      HTTPVersion.http2,
    ],
    this.timeout = Duration.zero,
    this.connectTimeout = const Duration(seconds: 300),
  })  : assert(url != null),
        assert(method != null),
        assert(headers != null),
        id = "${++_id}";

  factory Request.get({
    String url,
    Map<String, String> headers,
  }) =>
      Request(
        method: "GET",
        url: url,
        headers: headers ?? {},
      );

  factory Request.delete({
    String url,
    Map<String, String> headers,
  }) =>
      Request(
        method: "DELETE",
        url: url,
        headers: headers ?? {},
      );

  factory Request.post({
    String url,
    Map<String, String> headers,
    RequestBody body,
  }) =>
      Request(
        method: "POST",
        url: url,
        headers: headers ?? {},
        body: body,
      );

  factory Request.put({
    String url,
    Map<String, String> headers,
    RequestBody body,
  }) =>
      Request(
        method: "PUT",
        url: url,
        headers: headers ?? {},
        body: body,
      );
}
