part of 'client.dart';

class Request {
  static int _id = 0;

  final String id;
  String url;
  String method;
  Map<String, String> headers;
  List<int> body;
  bool verbose;
  String altSvcCache;
  String certPath;

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
