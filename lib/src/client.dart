import 'dart:async';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'dart:isolate';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show Platform, File, IOSink;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as paths;
import 'package:flutter/services.dart' show rootBundle;

import 'const.dart' as consts;

part 'ffi.dart';
part 'request.dart';
part 'response.dart';
part 'engine.dart';

/// [Client] handles all the HTTP calls. Add [Request] to [Client] and await for [Response]. Call [init] before use and [dispose] after use.
class Client {
  Isolate _engine;
  SendPort _sendPort;
  StreamSubscription _portSubscription;
  Map<String, Request> _queue;
  Map<String, Completer> _completers;
  String _altSvcCache;

  final bool verbose;
  final String userAgent;
  final Duration timeout;
  final Duration connectTimeout;
  final List<HTTPInterceptor> interceptors;
  final String cookiePath;
  String libPath;
  String certPath = "";

  Client({
    this.verbose,
    this.userAgent,
    this.cookiePath,
    this.libPath,
    this.interceptors = const [],
    this.timeout = Duration.zero,
    this.connectTimeout = const Duration(seconds: 300),
  });

  Future<void> init() async {
    _queue = {};
    _completers = {};
    final receivePort = ReceivePort();
    _engine = await Isolate.spawn(_isolate, receivePort.sendPort);
    final completer = Completer<void>();

    _altSvcCache = await _getAltSvcPath();
    if (Platform.isIOS) certPath = await _getCertPath();

    _portSubscription = receivePort.listen((item) {
      if (item is SendPort) {
        _sendPort = item;
        completer.complete();
      } else if (item is Response) {
        item._request = _queue[item._requestID];
        _completers[item._requestID].complete(item);
        _queue.remove(item._requestID);
        _completers.remove(item._requestID);
      }
    });
    return completer.future;
  }

  /// [_getAltSvcPath] provides path to the file where
  /// alt-svc header specifications are kept. This will be used
  /// for protocol upgrades if possible
  Future<String> _getAltSvcPath() async {
    final tempDir = await paths.getTemporaryDirectory();
    return path.join(tempDir.path, "altsvc.txt");
  }

  /// [_getCertPath] copies the certificate from bundle to a file
  /// in the temporary directory and then returns its path. Used for
  /// iOS since BoringSSL doesn't use the SecureTransport
  Future<String> _getCertPath() async {
    final tempDir = await paths.getTemporaryDirectory();
    var certPath = path.join(tempDir.path, "cert.pem");
    if (File(certPath).existsSync()) return certPath;
    ByteData data =
        await rootBundle.load("packages/flutter_curl/certs/cacert.pem");
    List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(certPath).writeAsBytes(bytes);
    return certPath;
  }

  Future<Response> send(Request req) async {
    for (var i in interceptors) {
      await i.beforeRequest(req);
    }
    req._cookiePath ??= cookiePath;
    req._altSvcCache ??= _altSvcCache;
    req._certPath ??= certPath;
    req._timeout ??= timeout.inMilliseconds;
    req._connectTimeout ??= connectTimeout.inMilliseconds;
    req.userAgent ??= userAgent;
    req.verbose = req.verbose ?? verbose ?? false;
    _queue[req.id] = req;

    final completer = Completer<Response>();
    _completers[req.id] = completer;
    _sendPort.send(req);

    final res = await completer.future;
    for (var i in interceptors) {
      await i.afterResponse(res);
    }
    return res;
  }

  Future<Response> download({Request request, String path}) async {
    request._downloadPath = path;
    return send(request);
  }

  void dispose() {
    _portSubscription.cancel();
    _engine.kill();
  }
}

abstract class HTTPInterceptor {
  Future<void> beforeRequest(Request request);
  Future<void> afterResponse(Response response);
}
