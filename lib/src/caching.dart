import 'package:flutter/foundation.dart';
import 'package:flutter_curl/flutter_curl.dart';
import 'dart:convert' as convert;

class HTTPCaching extends HTTPInterceptor {
  final Future<String> Function(String key) getter;
  final Future<String> Function(String key, String? value) setter;

  HTTPCaching({
    required this.getter,
    required this.setter,
  });

  @override
  beforeRequest(Request request, void Function(Response) cancel) async {
    var slug = request.url.replaceAll(RegExp("[^A-Za-z0-9-]+"), "-");
    var etagKey = "etag_" + slug;
    var dataKey = "data_" + slug;
    var dateKey = "etag_" + slug;

    var etag = await getter(etagKey);
    var date = await getter(dateKey);
    var data = await getter(dataKey);
    if (etag != null && data != null) {
      request.headers["If-None-Match"] = etag;
    }
    if (date != null && data != null) {
      request.headers["If-Modified-Since"] = date;
    }
  }

  afterResponse(Response response) async {
    var slug = response.request!.url.replaceAll(RegExp("[^A-Za-z0-9-]+"), "-");
    var etagKey = "etag_" + slug;
    var dateKey = "etag_" + slug;
    var dataKey = "data_" + slug;

    if (response.statusCode == 304) {
      var data = await getter(dataKey);
      response.statusCode = 200;
      response.body = convert.utf8.encode(data);
      response.headers[":from_cache"] = "true";
    } else if (response.headers.containsKey("etag")) {
      setter(etagKey, response.headers["etag"]);
      setter(dataKey, response.text());
    } else if (response.lastModified != null) {
      setter(dateKey, response.headers["last-modified"]);
      setter(dataKey, response.text());
    }
  }
}
