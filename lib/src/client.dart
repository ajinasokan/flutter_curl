import 'dart:async';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'dart:isolate';
import 'dart:convert';
import 'dart:io' show Platform, File, Directory, IOSink, RandomAccessFile;
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
part 'websocket.dart';

/// [Client] handles all the HTTP calls. Add [Request] to [Client] and await for [Response]. Call [init] before use and [dispose] after use.
class Client {
  late Isolate _engine;
  late SendPort _sendPort;
  late StreamSubscription _portSubscription;
  late Map<String, Request> _queue;
  late Map<String, Completer> _completers;
  late Map<String, Completer<WebSocket>> _connects;
  late Map<String, WebSocket> _sockets;

  final bool verbose;
  final void Function(String)? logWriter;
  final String? userAgent;
  final String? proxy;
  final Duration timeout;
  final Duration connectTimeout;
  final Duration connectionMaxAge;
  final List<HTTPInterceptor> interceptors;
  final String? cookiePath;
  final bool verifySSL;
  final String? altSvcCache;
  final HTTPVersion httpVersion;
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
    this.logWriter,
    this.verifySSL = true,
    this.userAgent,
    this.proxy,
    this.cookiePath,
    this.httpVersion = HTTPVersion.none,
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
    _connects = {};
    _sockets = {};
    final receivePort = ReceivePort();
    _engine = await Isolate.spawn(_isolate, (receivePort.sendPort, libPath));
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
        if (verbose) (logWriter ?? print)(item.content?.trim() ?? '');
      } else if (item is _WSOpen) {
        item.response._request = _queue.remove(item.id);
        final socket = WebSocket._(item.id, this, item.response);
        _sockets[item.id] = socket;
        _connects.remove(item.id)!.complete(socket);
      } else if (item is _WSMessage) {
        _sockets[item.id]
            ?._messages
            .add(WebSocketMessage._(item.isText, item.data));
      } else if (item is _WSClosed) {
        final request = _queue.remove(item.id);
        item.response?._request = request;
        _connects.remove(item.id)?.completeError(WebSocketException(
            item.error ?? "connection closed", item.response));
        _sockets.remove(item.id)?._finish(item);
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
    ByteData data =
        await rootBundle.load("packages/flutter_curl/certs/cacert.pem");
    List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await Directory(path.dirname(certPath)).create(recursive: true);
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
      _prepare(req);

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

  /// [connect] opens a WebSocket to a ws:// or wss:// URL. It throws
  /// [WebSocketException] when the server does not accept the upgrade.
  /// Interceptors do not apply.
  Future<WebSocket> connect(Request req) {
    req._websocket = true;
    _prepare(req);
    final completer = Completer<WebSocket>();
    _connects[req.id] = completer;
    _sendPort.send(req);
    return completer.future;
  }

  /// [_prepare] fills the request with the client defaults and queues it
  void _prepare(Request req) {
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
    req.httpVersion = req.httpVersion ?? httpVersion;
    _queue[req.id] = req;
  }

  Future<Response> download({
    required Request request,
    required String path,
  }) async {
    request._downloadPath = path;
    return send(request);
  }

  void dispose() {
    for (var c in _connects.values) {
      c.completeError(WebSocketException("client disposed"));
    }
    for (var s in _sockets.values) {
      s._finish(_WSClosed(s._id, error: "client disposed"));
    }
    _portSubscription.cancel();
    _engine.kill();
    _logs.close();
  }
}

abstract class HTTPInterceptor {
  Future<void> beforeRequest(Request request, void Function(Response) cancel);
  Future<void> afterResponse(Response response);
}
