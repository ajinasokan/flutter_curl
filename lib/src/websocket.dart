part of 'client.dart';

/// [WebSocket] is an open connection made with [Client.connect]. Read
/// [messages] for incoming data and call [close] when done.
class WebSocket {
  final String _id;
  final Client _client;
  final _messages = StreamController<WebSocketMessage>();
  final _done = Completer<void>();

  /// handshake response from the server
  final Response response;

  /// close code and reason sent by the server, if any
  int? closeCode;
  String? closeReason;

  WebSocket._(this._id, this._client, this.response);

  /// [messages] ends when the connection closes, with an error if the
  /// server went away without a close frame
  Stream<WebSocketMessage> get messages => _messages.stream;

  /// [done] completes when the connection is closed
  Future<void> get done => _done.future;

  void sendText(String text) => _send(consts.CURLWS_TEXT, utf8.encode(text));

  void sendBinary(List<int> data) =>
      _send(consts.CURLWS_BINARY, Uint8List.fromList(data));

  Future<void> close([int code = 1000, String reason = ""]) {
    if (!_done.isCompleted) {
      _client._sendPort.send(_WSClose(_id, code, reason));
    }
    return _done.future;
  }

  void _send(int flags, Uint8List data) {
    if (_done.isCompleted) throw StateError("WebSocket is closed");
    _client._sendPort.send(_WSSend(_id, flags, data));
  }

  void _finish(_WSClosed closed) {
    closeCode = closed.code;
    closeReason = closed.reason;
    if (closed.error != null) {
      _messages.addError(WebSocketException(closed.error!));
    }
    _messages.close();
    _done.complete();
  }
}

class WebSocketMessage {
  final bool isText;
  final Uint8List data;

  WebSocketMessage._(this.isText, this.data);

  String get text => utf8.decode(data);
}

class WebSocketException implements Exception {
  final String message;

  /// handshake response when the server did not accept the upgrade
  final Response? response;

  WebSocketException(this.message, [this.response]);

  @override
  String toString() => "WebSocketException: $message";
}

// messages from the main isolate to the engine

class _WSSend {
  final String id;
  final int flags;
  final Uint8List data;

  _WSSend(this.id, this.flags, this.data);
}

class _WSClose {
  final String id;
  final int code;
  final String reason;

  _WSClose(this.id, this.code, this.reason);
}

// messages from the engine to the main isolate

class _WSOpen {
  final String id;
  final Response response;

  _WSOpen(this.id, this.response);
}

class _WSMessage {
  final String id;
  final bool isText;
  final Uint8List data;

  _WSMessage(this.id, this.isText, this.data);
}

class _WSClosed {
  final String id;
  final int? code;
  final String? reason;
  final String? error;
  final Response? response;

  _WSClosed(this.id, {this.code, this.reason, this.error, this.response});
}

/// [_WSFrame] is an outgoing frame copied to native memory
class _WSFrame {
  final ffi.Pointer<ffi.Uint8> data;
  final int length;
  final int flags;
  int sent = 0;

  _WSFrame(Uint8List bytes, this.flags)
      : data = malloc.allocate(bytes.isEmpty ? 1 : bytes.length),
        length = bytes.length {
    data.asTypedList(length).setAll(0, bytes);
  }
}

/// [_WSConnection] is the engine side state of a [WebSocket]
class _WSConnection {
  final String id;
  final ffi.Pointer<_CURLEasy> handle;
  final _Engine engine;
  final List<_WSFrame> outbox = [];
  final List<int> message = [];
  final List<int> control = [];
  bool open = false;
  bool closeQueued = false;
  bool closeReceived = false;
  DateTime? closeSentAt;
  int? closeCode;
  String? closeReason;

  _WSConnection(this.id, this.handle, this.engine);

  void queue(Uint8List data, int flags) {
    if (closeQueued) return;
    if (flags & consts.CURLWS_CLOSE != 0) closeQueued = true;
    outbox.add(_WSFrame(data, flags));
  }

  void queueClose(int code, String reason) {
    final r = utf8.encode(reason);
    queue(
      Uint8List(2 + r.length)
        ..[0] = code >> 8
        ..[1] = code & 0xff
        ..setAll(2, r),
      consts.CURLWS_CLOSE,
    );
  }

  /// [receive] collects a chunk of an incoming frame. Control frames can
  /// come between the fragments of a message, so they use their own buffer.
  void receive(Uint8List chunk, int flags, int bytesleft) {
    if (flags & consts.CURLWS_CLOSE != 0) {
      control.addAll(chunk);
      if (bytesleft > 0) return;
      closeReceived = true;
      if (control.length >= 2) {
        closeCode = control[0] << 8 | control[1];
        closeReason = utf8.decode(control.sublist(2), allowMalformed: true);
      }
      // curl does not answer a close frame, so echo the code back
      if (closeCode == null) {
        queue(Uint8List(0), consts.CURLWS_CLOSE);
      } else {
        queueClose(closeCode!, "");
      }
      control.clear();
    } else if (flags & (consts.CURLWS_TEXT | consts.CURLWS_BINARY) != 0) {
      message.addAll(chunk);
      if (bytesleft > 0 || flags & consts.CURLWS_CONT != 0) return;
      _Engine.wsEvents.add(_WSMessage(
        id,
        flags & consts.CURLWS_TEXT != 0,
        Uint8List.fromList(message),
      ));
      message.clear();
    }
    // curl answers pings by itself
  }

  void freeOutbox() {
    for (var f in outbox) {
      malloc.free(f.data);
    }
    outbox.clear();
  }
}
