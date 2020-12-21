import 'dart:async';
import 'dart:ffi' as ffi;
import 'package:meta/meta.dart';
import 'package:ffi/ffi.dart';
import 'const.dart' as consts;
import 'dart:isolate';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show Platform, Directory, File;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as paths;
import 'package:flutter/services.dart' show rootBundle;

part 'ffi.dart';
part 'request.dart';
part 'response.dart';
part 'engine.dart';

class Client {
  static String libPath = 'libcurl.so';

  Isolate _engine;
  SendPort _sendPort;
  StreamSubscription _portSubscription;
  Map<String, Request> _queue;
  Map<String, Completer> _completers;

  final bool verbose;
  final String userAgent;
  final List<HTTPInterceptor> interceptors;
  final String altSvcCache;
  String certPath = "";

  Client({
    this.verbose,
    this.userAgent,
    this.altSvcCache,
    this.interceptors = const [],
  });

  Future<void> init() async {
    _queue = {};
    _completers = {};
    final receivePort = ReceivePort();
    _engine = await Isolate.spawn(_isolate, receivePort.sendPort);
    final completer = Completer<void>();

    if (Platform.isIOS) certPath = await getCertPath();

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

  Future<String> getCertPath() async {
    Directory directory = await paths.getTemporaryDirectory();
    var certPath = path.join(directory.path, "cert.pem");
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
    req.altSvcCache ??= altSvcCache;
    req.certPath ??= certPath;
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

  void dispose() {
    _portSubscription.cancel();
    _engine.kill();
  }
}

abstract class HTTPInterceptor {
  Future<void> beforeRequest(Request request);
  Future<void> afterResponse(Response response);
}
