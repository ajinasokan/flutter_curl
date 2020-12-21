import 'dart:io';
import 'dart:convert' as convert;
import 'package:path/path.dart' as path;
import 'client.dart';
import 'log.dart';

class HTTPCaching extends HTTPInterceptor {
  String _cacheDir = path.join(".", "http_cache");

  HTTPCaching({String cacheDir}) {
    if (cacheDir != null) _cacheDir = cacheDir;
  }

  Future<List<int>> _get(String key) async {
    var file = File(path.join(_cacheDir, key));
    if (await file.exists()) return file.readAsBytes();
    return null;
  }

  Future<void> _set(String key, List<int> value) async {
    var file = File(path.join(_cacheDir, key));
    await file.create(recursive: true);
    await file.writeAsBytes(value);
  }

  Future<void> beforeRequest(Request request) async {
    var slug = request.url.replaceAll(RegExp("[^A-Za-z0-9-]+"), "-");
    var etagKey = "etag_" + slug;
    var dataKey = "data_" + slug;
    var etag = await _get(etagKey);
    var data = await _get(dataKey);
    if (etag != null && data != null) {
      request.headers["if-none-match"] = convert.utf8.decode(etag);
    }
    Log.d(request.method, request.url, request.headers, request.body.length);
  }

  Future<void> afterResponse(Response response) async {
    var slug = response.request.url.replaceAll(RegExp("[^A-Za-z0-9-]+"), "-");
    var etagKey = "etag_" + slug;
    var dataKey = "data_" + slug;

    Log.d(response.statusCode, response.request.url, response.body.length);

    if (response.statusCode == 304) {
      var data = await _get(dataKey);
      response.body = data;
    } else if (response.headers.containsKey("etag")) {
      _set(etagKey, convert.utf8.encode(response.headers["etag"]));
      _set(dataKey, response.body);
    }
  }
}
