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
  final RequestBody? body;
  String? userAgent;
  bool? verbose;
  bool? verifySSL;
  List<HTTPVersion>? httpVersions;

  String? _cookiePath;
  String? _altSvcCache;
  Duration? timeout;
  Duration? connectTimeout;
  String? _downloadPath;

  Request({
    required this.url,
    this.method = "GET",
    this.headers = const {},
    this.body,
    this.verbose,
    this.verifySSL,
    this.httpVersions,
    this.timeout,
    this.connectTimeout,
  }) : id = "${++_id}";

  factory Request.get({
    required String url,
    Map<String, String>? headers,
  }) =>
      Request(
        method: "GET",
        url: url,
        headers: headers ?? {},
      );

  factory Request.delete({
    required String url,
    Map<String, String>? headers,
  }) =>
      Request(
        method: "DELETE",
        url: url,
        headers: headers ?? {},
      );

  factory Request.post({
    required String url,
    Map<String, String>? headers,
    RequestBody? body,
  }) =>
      Request(
        method: "POST",
        url: url,
        headers: headers ?? {},
        body: body,
      );

  factory Request.put({
    required String url,
    Map<String, String>? headers,
    RequestBody? body,
  }) =>
      Request(
        method: "PUT",
        url: url,
        headers: headers ?? {},
        body: body,
      );
}
