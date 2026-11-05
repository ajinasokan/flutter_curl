part of 'client.dart';

/// [_Engine] handles the request queue in a different isolate
/// handled by [_isolate] function
class _Engine {
  final libCurl = _LibCURL();
  late ffi.Pointer<_CURLMulti> multiHandle;

  static Map<String, StreamController<LogInfo>> logData = {};
  static Map<String, _ResponseBuffer> connData = {};
  static Map<String, IOSink> downloadFiles = {};
  static Map<String, RandomAccessFile> uploadFiles = {};
  static Map<String, ffi.Pointer<_CURLMime>> mimes = {};
  static Map<ffi.Pointer<_CURLEasy>, String> reqIDs = {};
  static Map<String, _WSConnection> sockets = {};
  static List<Object> wsEvents = [];

  void init({String? libPath}) {
    libCurl.init(libPath: libPath);
    multiHandle = libCurl.multi_init();
  }

  void send(Request req) {
    if (req._websocket && !libCurl.webSocket) {
      wsEvents.add(_WSClosed(
        req.id,
        error: "libcurl is built without WebSocket support",
      ));
      return;
    }

    final handle = libCurl.easy_init();
    reqIDs[handle] = req.id;
    connData[req.id] = _ResponseBuffer();
    connData[req.id]!.requestID = req.id;

    logData[req.id] = StreamController<LogInfo>();

    if (req.verbose!) {
      logData[req.id]!.add(LogInfo(
        requestID: req.id,
        content: libCurl.version().toDartString(),
      ));
    }

    if (req.body?._type == _BodyType.file) {
      uploadFiles[req.id] = File(req.body!._file).openSync();
    }

    if (req._downloadPath != null) {
      downloadFiles[req.id] = File(req._downloadPath!).openWrite();
    }

    if (req._websocket) {
      sockets[req.id] = _WSConnection(req.id, handle, this);
    }

    // set basic request params
    libCurl.easy_setopt_string(
      handle,
      consts.CURLOPT_CUSTOMREQUEST,
      req.method.toNativeUtf8(),
    );
    libCurl.easy_setopt_string(
      handle,
      consts.CURLOPT_URL,
      req.url.toNativeUtf8(),
    );
    if (req.userAgent != null) {
      libCurl.easy_setopt_string(
        handle,
        consts.CURLOPT_USERAGENT,
        req.userAgent!.toNativeUtf8(),
      );
    }
    if (req.proxy != null) {
      libCurl.easy_setopt_string(
        handle,
        consts.CURLOPT_PROXY,
        req.proxy!.toNativeUtf8(),
      );
    }
    // a total timeout would cut off a long lived WebSocket
    libCurl.easy_setopt_int(
      handle,
      consts.CURLOPT_TIMEOUT_MS,
      req._websocket ? 0 : req.timeout!.inMilliseconds,
    );
    libCurl.easy_setopt_int(
      handle,
      consts.CURLOPT_CONNECTTIMEOUT_MS,
      req.connectTimeout!.inMilliseconds,
    );
    libCurl.easy_setopt_int(
      handle,
      consts.CURLOPT_MAXAGE_CONN,
      req.connectionMaxAge!.inSeconds,
    );

    // set cookie path
    if (req._cookiePath != null) {
      // for reading
      libCurl.easy_setopt_string(
        handle,
        consts.CURLOPT_COOKIEFILE,
        req._cookiePath!.toNativeUtf8(),
      );
      // for storing
      libCurl.easy_setopt_string(
        handle,
        consts.CURLOPT_COOKIEJAR,
        req._cookiePath!.toNativeUtf8(),
      );
    }

    // set ip support.
    // TODO: add this to client config?
    const CURL_IPRESOLVE_WHATEVER = 0;
    // ignore: unused_local_variable
    const CURL_IPRESOLVE_V4 = 1;
    // ignore: unused_local_variable
    const CURL_IPRESOLVE_V6 = 2;
    libCurl.easy_setopt_int(
      handle,
      consts.CURLOPT_IPRESOLVE,
      CURL_IPRESOLVE_WHATEVER,
    );

    // set http version
    // READ: https://curl.se/libcurl/c/CURLOPT_HTTP_VERSION.html
    // WebSocket upgrade is done only over HTTP/1.1
    final httpVersionFlag = req._websocket
        ? consts.CURL_HTTP_VERSION_1_1
        : switch (req.httpVersion!) {
            HTTPVersion.none => consts.CURL_HTTP_VERSION_NONE,
            HTTPVersion.http1 => consts.CURL_HTTP_VERSION_1_0,
            HTTPVersion.http11 => consts.CURL_HTTP_VERSION_1_1,
            HTTPVersion.http2 => consts.CURL_HTTP_VERSION_2_0,
            HTTPVersion.http2tls => consts.CURL_HTTP_VERSION_2TLS,
            HTTPVersion.http2PriorKnowledge =>
              consts.CURL_HTTP_VERSION_2_PRIOR_KNOWLEDGE,
            HTTPVersion.http3 => consts.CURL_HTTP_VERSION_3,
            HTTPVersion.http3Only => consts.CURL_HTTP_VERSION_3ONLY,
          };
    libCurl.easy_setopt_int(
      handle,
      consts.CURLOPT_HTTP_VERSION,
      httpVersionFlag,
    );

    // in iOS BoringSSL doesn't use SecureTransport. so use the certs from
    // curl instead.
    // TODO: verify this is fine in appstore
    if (req._certPath != null) {
      libCurl.easy_setopt_string(
        handle,
        consts.CURLOPT_CAINFO,
        req._certPath!.toNativeUtf8(),
      );
    }

    // set alt-svc cache path
    if (req._altSvcCache != null) {
      libCurl.easy_setopt_string(
        handle,
        consts.CURLOPT_ALTSVC,
        req._altSvcCache!.toNativeUtf8(),
      );
      // enable alt-svc support for all http versions
      libCurl.easy_setopt_int(
        handle,
        consts.CURLOPT_ALTSVC_CTRL,
        consts.CURLALTSVC_H1 | consts.CURLALTSVC_H2 | consts.CURLALTSVC_H3,
      );
    }

    // enable verbose and set the callback
    // TODO: may be provide log to file support?
    if (req.verbose!) {
      libCurl.easy_setopt_int(
        handle,
        consts.CURLOPT_VERBOSE,
        1,
      );
      libCurl.easy_setopt_ptr(
        handle,
        consts.CURLOPT_DEBUGFUNCTION,
        ffi.Pointer.fromFunction<_DebugFunc>(_debugWriteFunc, 0),
      );
      libCurl.easy_setopt_string(
        handle,
        consts.CURLOPT_DEBUGDATA,
        req.id.toNativeUtf8(),
      );
    }

    if (!req.verifySSL!) {
      libCurl.easy_setopt_int(
        handle,
        consts.CURLOPT_SSL_VERIFYPEER,
        0,
      );
    }

    // add the headers
    connData[req.id]!.slist = ffi.nullptr;
    String? encodingHeader = "";
    for (var key in req.headers.keys) {
      if (key.toLowerCase() == "accept-encoding") {
        encodingHeader = req.headers[key];
        continue;
      }
      final temp = libCurl.slist_append(
        connData[req.id]!.slist!,
        "$key: ${req.headers[key]}".toNativeUtf8(),
      );
      if (temp != ffi.nullptr)
        connData[req.id]!.slist = temp;
      else
        print("error while adding $key");
    }

    // accept encoding header is set differently
    libCurl.easy_setopt_string(
      handle,
      consts.CURLOPT_ACCEPT_ENCODING,
      encodingHeader!.toNativeUtf8(),
    );

    if (connData[req.id]!.slist != ffi.nullptr) {
      libCurl.easy_setopt_ptr(
        handle,
        consts.CURLOPT_HTTPHEADER,
        connData[req.id]!.slist!,
      );
    }

    // add post body
    if ((req.method.toLowerCase() == "post" ||
            req.method.toLowerCase() == "put") &&
        req.body != null) {
      if (req.body!._type == _BodyType.string) {
        libCurl.easy_setopt_string(
          handle,
          consts.CURLOPT_POSTFIELDS,
          req.body!._string.toNativeUtf8(),
        );
      } else if (req.body!._type == _BodyType.raw) {
        libCurl.easy_setopt_string(
          handle,
          consts.CURLOPT_POSTFIELDS,
          utf8.decode(req.body!._raw, allowMalformed: true).toNativeUtf8(),
        );
      } else if (req.body!._type == _BodyType.form) {
        libCurl.easy_setopt_string(
          handle,
          consts.CURLOPT_POSTFIELDS,
          Uri(queryParameters: req.body!._form).query.toNativeUtf8(),
        );
      } else if (req.body!._type == _BodyType.file) {
        libCurl.easy_setopt_int(
          handle,
          consts.CURLOPT_UPLOAD,
          1,
        );
        libCurl.easy_setopt_off_t(
          handle,
          consts.CURLOPT_INFILESIZE_LARGE,
          uploadFiles[req.id]!.lengthSync(),
        );
        libCurl.easy_setopt_ptr(
          handle,
          consts.CURLOPT_READFUNCTION,
          ffi.Pointer.fromFunction<_ReadFunc>(_dataReadFunc, 0),
        );
        libCurl.easy_setopt_string(
          handle,
          consts.CURLOPT_READDATA,
          req.id.toNativeUtf8(),
        );
      } else if (req.body!._type == _BodyType.multipart) {
        final mime = libCurl.mime_init(handle);
        for (var p in req.body!._multipart) {
          final mimepart = libCurl.mime_addpart(mime);
          libCurl.mime_name(mimepart, p._name!.toNativeUtf8());
          if (p._type == MultipartType.raw) {
            libCurl.mime_data(
                mimepart, p._data!.toNativeUtf8(), p._data!.length);
          } else {
            libCurl.mime_filedata(mimepart, p._filepath!.toNativeUtf8());
            libCurl.mime_filename(mimepart, p._filename!.toNativeUtf8());
          }
        }
        libCurl.easy_setopt_ptr(handle, consts.CURLOPT_MIMEPOST, mime);
        mimes[req.id] = mime;
      }
    }

    // set callbacks
    libCurl.easy_setopt_ptr(
      handle,
      consts.CURLOPT_WRITEFUNCTION,
      req._websocket
          ? ffi.Pointer.fromFunction<_WriteFunc>(_wsWriteFunc, 0)
          : ffi.Pointer.fromFunction<_WriteFunc>(_dataWriteFunc, 0),
    );

    libCurl.easy_setopt_string(
      handle,
      consts.CURLOPT_WRITEDATA,
      req.id.toNativeUtf8(),
    );

    libCurl.easy_setopt_ptr(
      handle,
      consts.CURLOPT_HEADERFUNCTION,
      ffi.Pointer.fromFunction<_WriteFunc>(_headerWriteFunc, 0),
    );

    libCurl.easy_setopt_string(
      handle,
      consts.CURLOPT_HEADERDATA,
      req.id.toNativeUtf8(),
    );

    // add request to queue
    libCurl.multi_add_handle(multiHandle, handle);
  }

  /// [perform] runs the libcurl processing to handle incoming
  /// data and collects these data to dart objects and frees the
  /// C resources once it is done
  ffi.Pointer<ffi.Int32> _tempCounter = malloc.allocate(ffi.sizeOf<ffi.Int32>())
    ..value = 0;
  Future<Response?> perform() async {
    libCurl.multi_perform(multiHandle, _tempCounter);
    final msgPtr = libCurl.multi_info_read(multiHandle, _tempCounter);
    if (msgPtr != ffi.nullptr) {
      final msg = msgPtr.ref;
      if (msg.messageType == consts.CURLMSG_DONE) {
        String? requestID = reqIDs[msg.easyHandle];
        final buffer = connData[requestID!]!;

        // get response code and http version used. this needs
        // an int reference. it is being reused for both calls
        ffi.Pointer<ffi.Int64> _tempLong =
            malloc.allocate(ffi.sizeOf<ffi.Int64>());
        _tempLong.value = 0;
        libCurl.easy_getinfo(
            msg.easyHandle, consts.CURLINFO_RESPONSE_CODE, _tempLong);
        buffer.statusCode = _tempLong.value;
        _tempLong.value = 0;
        libCurl.easy_getinfo(
            msg.easyHandle, consts.CURLINFO_HTTP_VERSION, _tempLong);
        buffer.httpVersion = _tempLong.value;
        malloc.free(_tempLong);

        if (msg.result != consts.CURLE_OK) {
          buffer.errorCode = msg.result;
          buffer.errorMessage =
              libCurl.easy_strerror(msg.result).toDartString();
        }

        _release(msg.easyHandle, requestID);

        final socket = sockets.remove(requestID);
        if (socket != null) {
          socket.freeOutbox();
          wsEvents.add(_WSClosed(
            requestID,
            code: socket.closeCode,
            reason: socket.closeReason,
            error: socket.closeReceived
                ? null
                : buffer.errorMessage ?? "connection closed",
            response: socket.open ? null : buffer.toResponse(this),
          ));
          return null;
        }

        return buffer.toResponse(this);
      }
    }
    return null;
  }

  /// [_release] removes the handle from the queue and frees the C
  /// resources of the request
  void _release(ffi.Pointer<_CURLEasy> handle, String requestID) {
    libCurl.slist_free_all(connData[requestID]!.slist!);
    libCurl.multi_remove_handle(multiHandle, handle);
    libCurl.easy_cleanup(handle);
    reqIDs.remove(handle);
    connData.remove(requestID);
    logData[requestID]!.close();

    if (uploadFiles.containsKey(requestID)) {
      uploadFiles[requestID]!.closeSync();
      uploadFiles.remove(requestID);
    }

    if (mimes.containsKey(requestID)) {
      libCurl.mime_free(mimes[requestID]!);
      mimes.remove(requestID);
    }

    if (downloadFiles.containsKey(requestID)) {
      downloadFiles[requestID]!.close();
      downloadFiles.remove(requestID);
    }
  }

  void wsSend(_WSSend item) {
    sockets[item.id]?.queue(item.data, item.flags);
  }

  void wsClose(_WSClose item) {
    sockets[item.id]?.queueClose(item.code, item.reason);
  }

  /// [flush] sends the queued WebSocket frames and ends the connections
  /// that finished the close handshake
  ffi.Pointer<ffi.Size> _sent = malloc.allocate(ffi.sizeOf<ffi.Size>());
  void flush() {
    for (var socket in sockets.values.toList()) {
      String? error;
      while (socket.outbox.isNotEmpty) {
        final frame = socket.outbox.first;
        final result = _sendFrame(socket, frame);
        if (result == consts.CURLE_AGAIN) break;
        if (result != consts.CURLE_OK) {
          error = libCurl.easy_strerror(result).toDartString();
          break;
        }
        if (frame.flags & consts.CURLWS_CLOSE != 0) {
          socket.closeSentAt = DateTime.now();
        }
        malloc.free(frame.data);
        socket.outbox.removeAt(0);
      }

      if (error != null) {
        _finish(socket, error);
      } else if (socket.closeSentAt != null && socket.closeReceived) {
        _finish(socket, null);
      } else if (socket.closeSentAt != null &&
          DateTime.now().difference(socket.closeSentAt!) > _closeTimeout) {
        _finish(socket, "timed out waiting for close frame");
      }
    }
  }

  static const _closeTimeout = Duration(seconds: 5);

  /// [_sendFrame] sends the rest of the frame. curl may take only a part
  /// of it per call.
  int _sendFrame(_WSConnection socket, _WSFrame frame) {
    do {
      _sent.value = 0;
      final result = libCurl.ws_send(
        socket.handle,
        frame.data + frame.sent,
        frame.length - frame.sent,
        _sent,
        0,
        frame.flags,
      );
      frame.sent += _sent.value;
      if (result != consts.CURLE_OK) return result;
    } while (frame.sent < frame.length);
    return consts.CURLE_OK;
  }

  void _finish(_WSConnection socket, String? error) {
    sockets.remove(socket.id);
    _release(socket.handle, socket.id);
    socket.freeOutbox();
    wsEvents.add(_WSClosed(
      socket.id,
      code: socket.closeCode,
      reason: socket.closeReason,
      error: socket.closeReceived ? null : error,
    ));
  }

  void dispose() {}
}

/// [_isolate] function runs in a different isolate and sends
/// requests and responses to and from libcurl to the main
/// Flutter isolate
void _isolate((SendPort, String?) args) async {
  final (sendPort, libPath) = args;
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  final engine = _Engine();
  receivePort.listen((item) async {
    if (item is _WSSend) {
      engine.wsSend(item);
    } else if (item is _WSClose) {
      engine.wsClose(item);
    } else if (item is Request) {
      engine.send(item);
      final logs = _Engine.logData[item.id];
      if (logs == null) return;
      await for (var data in logs.stream) {
        sendPort.send(data);
      }
    }
  });
  engine.init(libPath: libPath);

  while (true) {
    engine.flush();
    final res = await engine.perform();
    for (var event in _Engine.wsEvents) {
      sendPort.send(event);
    }
    _Engine.wsEvents.clear();
    if (res != null) sendPort.send(res);
    await Future.delayed(Duration(milliseconds: 10));
  }
}

/// [_dataReadFunc] sends data from file for upload
int _dataReadFunc(
  ffi.Pointer<ffi.Uint8> data,
  int size,
  int nmemb,
  ffi.Pointer<Utf8> requestID,
) {
  int realsize = size * nmemb;

  final _requestID = requestID.toDartString();
  return _Engine.uploadFiles[_requestID]!
      .readIntoSync(data.asTypedList(realsize), 0, realsize);
}

/// [_dataWriteFunc] collects response body to body buffer
int _dataWriteFunc(
  ffi.Pointer<ffi.Uint8> data,
  int size,
  int nmemb,
  ffi.Pointer<Utf8> requestID,
) {
  int realsize = size * nmemb;

  final _requestID = requestID.toDartString();
  final _byteData = data.asTypedList(realsize);
  // if this is suppose to be a download then add the data
  // to IOSink of file. otherwise add it to the response buffer
  if (_Engine.downloadFiles.containsKey(_requestID)) {
    _Engine.downloadFiles[_requestID]!.add(_byteData);
  } else {
    _Engine.connData[_requestID]!.bodyBuffer.addAll(_byteData);
  }

  return realsize;
}

/// [_headerWriteFunc] collects header data to the header buffer
int _headerWriteFunc(
  ffi.Pointer<ffi.Uint8> data,
  int size,
  int nmemb,
  ffi.Pointer<Utf8> requestID,
) {
  int realsize = size * nmemb;

  final _requestID = requestID.toDartString();
  _Engine.connData[_requestID]!.headerBuffer.addAll(data.asTypedList(realsize));

  // a blank line ends the headers. for a WebSocket that is when the
  // upgrade is done
  final socket = _Engine.sockets[_requestID];
  if (socket != null &&
      !socket.open &&
      realsize == 2 &&
      data[0] == 13 &&
      data[1] == 10) {
    final buffer = _Engine.connData[_requestID]!;
    final libCurl = socket.engine.libCurl;
    ffi.Pointer<ffi.Int64> _tempLong = malloc.allocate(ffi.sizeOf<ffi.Int64>());
    _tempLong.value = 0;
    libCurl.easy_getinfo(
        socket.handle, consts.CURLINFO_RESPONSE_CODE, _tempLong);
    buffer.statusCode = _tempLong.value;
    _tempLong.value = 0;
    libCurl.easy_getinfo(
        socket.handle, consts.CURLINFO_HTTP_VERSION, _tempLong);
    buffer.httpVersion = _tempLong.value;
    malloc.free(_tempLong);

    if (buffer.statusCode == 101) {
      socket.open = true;
      _Engine.wsEvents.add(
        _WSOpen(_requestID, buffer.toResponse(socket.engine)),
      );
    }
  }

  return realsize;
}

/// [_wsWriteFunc] collects incoming WebSocket frames
int _wsWriteFunc(
  ffi.Pointer<ffi.Uint8> data,
  int size,
  int nmemb,
  ffi.Pointer<Utf8> requestID,
) {
  int realsize = size * nmemb;

  final _requestID = requestID.toDartString();
  final socket = _Engine.sockets[_requestID]!;
  // body of a refused upgrade is not WebSocket data
  if (!socket.open) {
    _Engine.connData[_requestID]!.bodyBuffer.addAll(data.asTypedList(realsize));
    return realsize;
  }

  final meta = socket.engine.libCurl.ws_meta(socket.handle).ref;
  socket.receive(data.asTypedList(realsize), meta.flags, meta.bytesleft);

  return realsize;
}

/// [_debugWriteFunc] prints the logs to Flutter logs
int _debugWriteFunc(
  ffi.Pointer<_CURLEasy> handle,
  int type,
  ffi.Pointer<ffi.Uint8> data,
  int size,
  ffi.Pointer<Utf8> requestID,
) {
  const CURLINFO_TEXT = 0;
  const CURLINFO_HEADER_IN = 1;
  const CURLINFO_HEADER_OUT = 2;
  if (type == CURLINFO_TEXT ||
      type == CURLINFO_HEADER_IN ||
      type == CURLINFO_HEADER_OUT) {
    final requestIDStr = requestID.toDartString();
    final content = utf8.decode(data.asTypedList(size));

    _Engine.logData[requestIDStr]!.add(LogInfo(
      requestID: requestIDStr,
      content: content,
    ));
  }
  return 0;
}
