import 'dart:async';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'dart:isolate';
import 'dart:convert';
import 'dart:io' show Platform, File, IOSink, RandomAccessFile;

import 'const.dart' as consts;

part 'ffi.dart';
part 'request.dart';
part 'request_body.dart';
part 'response.dart';
part 'engine.dart';

/// [Client] handles all the HTTP calls. Add [Request] to [Client] and await for [Response]. Call [init] before use and [dispose] after use.
class Client {
  Isolate _engine;
  SendPort _sendPort;
  StreamSubscription _portSubscription;
  Map<String, Request> _queue;
  Map<String, Completer> _completers;

  final bool verbose;
  final String userAgent;
  final Duration timeout;
  final Duration connectTimeout;
  final List<HTTPInterceptor> interceptors;
  final String cookiePath;
  final bool verifySSL;
  final String altSvcCache;
  final List<HTTPVersion> httpVersions;
  String libPath;

  Client({
    this.verbose,
    this.verifySSL,
    this.userAgent,
    this.cookiePath,
    this.httpVersions,
    this.libPath,
    this.interceptors = const [],
    this.timeout = Duration.zero,
    this.connectTimeout = const Duration(seconds: 300),
    this.altSvcCache,
  });

  Future<void> init() async {
    _queue = {};
    _completers = {};
    final receivePort = ReceivePort();
    _engine = await Isolate.spawn(_isolate, receivePort.sendPort);
    final completer = Completer<void>();

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

  Future<Response> send(Request req) async {
    Response res;

    for (var i in interceptors) {
      await i.beforeRequest(req, (Response _res) {
        res = _res;
      });
      if (res != null) break;
    }

    if (res == null) {
      req._cookiePath ??= cookiePath;
      req._altSvcCache ??= altSvcCache;
      req.timeout ??= timeout;
      req.connectTimeout ??= connectTimeout;
      req.userAgent ??= userAgent;
      req.verbose = req.verbose ?? verbose ?? false;
      req.verifySSL = req.verifySSL ?? verifySSL ?? true;
      req.httpVersions = req.httpVersions ?? httpVersions ?? [];
      _queue[req.id] = req;

      final completer = Completer<Response>();
      _completers[req.id] = completer;
      _sendPort.send(req);

      res = await completer.future;
    }

    for (var i in interceptors.reversed) {
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
  Future<void> beforeRequest(Request request, void Function(Response) cancel);
  Future<void> afterResponse(Response response);
}
