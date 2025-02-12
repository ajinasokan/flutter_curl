import 'dart:async';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'dart:isolate';
import 'dart:convert';
import 'dart:io' show Platform, File, IOSink, RandomAccessFile;
import 'package:path/path.dart' as path;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart' as paths;
import 'const.dart' as consts;

part 'ffi.dart';
part 'request.dart';
part 'request_body.dart';
part 'response.dart';
part 'engine.dart';
part 'log_info.dart';

/// [Client] handles all the HTTP calls. Add [Request] to [Client] and await for [Response]. Call [init] before use and [dispose] after use.
class Client {
  late Isolate _engine;
  late SendPort _sendPort;
  late StreamSubscription _portSubscription;
  late Map<String, Request> _queue;
  late Map<String, Completer> _completers;

  final bool verbose;
  final String? userAgent;
  final String? proxy;
  final Duration timeout;
  final Duration connectTimeout;
  final Duration connectionMaxAge;
  final List<HTTPInterceptor> interceptors;
  final String? cookiePath;
  final bool verifySSL;
  final String? altSvcCache;
  final List<HTTPVersion> httpVersions;
  String? libPath;
  String? certPath;

  final _logs = StreamController<LogInfo>();
  Stream<LogInfo>? _broadcast;
  Stream<LogInfo>? get _logStream {
    if (_broadcast == null) _broadcast = _logs.stream.asBroadcastStream();
    return _broadcast;
  }

  Stream<LogInfo> logsFor(Request request) =>
      _logStream!.where((event) => event.requestID == request.id);

  Client({
    this.verbose = false,
    this.verifySSL = true,
    this.userAgent,
    this.proxy,
    this.cookiePath,
    this.httpVersions = const [
      HTTPVersion.http1,
      HTTPVersion.http11,
      HTTPVersion.http2,
    ],
    this.libPath,
    this.interceptors = const [],
    this.timeout = Duration.zero,
    this.connectTimeout = const Duration(seconds: 300),
    this.connectionMaxAge = const Duration(seconds: 118), // curl default
    this.altSvcCache,
  });

  Future<void> init() async {
    _queue = {};
    _completers = {};
    final receivePort = ReceivePort();
    _engine = await Isolate.spawn(_isolate, receivePort.sendPort);
    final completer = Completer<void>();

    certPath ??= await _getCertPath();

    _portSubscription = receivePort.listen((item) {
      if (item is SendPort) {
        _sendPort = item;
        completer.complete();
      } else if (item is Response) {
        item._request = _queue[item._requestID!];
        _completers[item._requestID!]!.complete(item);
        _queue.remove(item._requestID);
        _completers.remove(item._requestID);
      } else if (item is LogInfo) {
        _logs.add(item);
        if (verbose) print(item.content);
      }
    });
    return completer.future;
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
    Response? res;

    for (var i in interceptors) {
      await i.beforeRequest(req, (Response _res) {
        res = _res;
      });
      if (res != null) break;
    }

    if (res == null) {
      req._cookiePath ??= cookiePath;
      req._altSvcCache ??= altSvcCache;
      req._certPath ??= certPath;
      req.timeout ??= timeout;
      req.connectTimeout ??= connectTimeout;
      req.connectionMaxAge ??= connectionMaxAge;
      req.userAgent ??= userAgent;
      req.proxy ??= proxy;
      req.verbose = req.verbose ?? verbose;
      req.verifySSL = req.verifySSL ?? verifySSL;
      req.httpVersions = req.httpVersions ?? httpVersions;
      _queue[req.id] = req;

      final completer = Completer<Response>();
      _completers[req.id] = completer;
      _sendPort.send(req);

      res = await completer.future;
    }

    for (var i in interceptors.reversed) {
      await i.afterResponse(res!);
    }
    return res!;
  }

  Future<Response> download({
    required Request request,
    required String path,
  }) async {
    request._downloadPath = path;
    return send(request);
  }

  void dispose() {
    _portSubscription.cancel();
    _engine.kill();
    _logs.close();
  }
}

abstract class HTTPInterceptor {
  Future<void> beforeRequest(Request request, void Function(Response) cancel);
  Future<void> afterResponse(Response response);
}
