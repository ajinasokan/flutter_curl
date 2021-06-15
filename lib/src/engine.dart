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

  void init({String? libPath}) {
    libCurl.init(libPath: libPath);
    multiHandle = libCurl.multi_init();
  }

  void send(Request req) {
    if (req.verbose!) {
      print(libCurl.version().toDartString());
    }

    final handle = libCurl.easy_init();
    reqIDs[handle] = req.id;
    connData[req.id] = _ResponseBuffer();
    connData[req.id]!.requestID = req.id;

    logData[req.id] = StreamController<LogInfo>();

    if (req.body?._type == _BodyType.file) {
      uploadFiles[req.id] = File(req.body!._file).openSync();
    }

    if (req._downloadPath != null) {
      downloadFiles[req.id] = File(req._downloadPath!).openWrite();
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
    libCurl.easy_setopt_int(
      handle,
      consts.CURLOPT_TIMEOUT_MS,
      req.timeout!.inMilliseconds,
    );
    libCurl.easy_setopt_int(
      handle,
      consts.CURLOPT_CONNECTTIMEOUT_MS,
      req.connectTimeout!.inMilliseconds,
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
    const CURL_IPRESOLVE_V4 = 1;
    const CURL_IPRESOLVE_V6 = 2;
    libCurl.easy_setopt_int(
      handle,
      consts.CURLOPT_IPRESOLVE,
      CURL_IPRESOLVE_WHATEVER,
    );

    // enable support for all http versions
    // READ: https://curl.se/libcurl/c/CURLOPT_HTTP_VERSION.html
    if (req.httpVersions!.isNotEmpty) {
      int flag = 0;
      if (req.httpVersions!.contains(HTTPVersion.http1)) {
        flag |= consts.CURL_HTTP_VERSION_1_0;
      }
      if (req.httpVersions!.contains(HTTPVersion.http11)) {
        flag |= consts.CURL_HTTP_VERSION_1_1;
      }
      if (req.httpVersions!.contains(HTTPVersion.http2)) {
        flag |= consts.CURL_HTTP_VERSION_2_0;
      }
      if (req.httpVersions!.contains(HTTPVersion.http3)) {
        flag |= consts.CURL_HTTP_VERSION_3;
      }
      libCurl.easy_setopt_int(
        handle,
        consts.CURLOPT_HTTP_VERSION,
        flag,
      );
    } else {
      libCurl.easy_setopt_int(
        handle,
        consts.CURLOPT_HTTP_VERSION,
        consts.CURL_HTTP_VERSION_NONE, // let curl figure it out
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
    if (req.method.toLowerCase() == "post" ||
        req.method.toLowerCase() == "put") {
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
        libCurl.easy_setopt_int(
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
      ffi.Pointer.fromFunction<_WriteFunc>(_dataWriteFunc, 0),
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
            msg.easyHandle!, consts.CURLINFO_RESPONSE_CODE, _tempLong);
        buffer.statusCode = _tempLong.value;
        _tempLong.value = 0;
        libCurl.easy_getinfo(
            msg.easyHandle!, consts.CURLINFO_HTTP_VERSION, _tempLong);
        buffer.httpVersion = _tempLong.value;
        malloc.free(_tempLong);

        if (msg.result != consts.CURLE_OK) {
          buffer.errorMessage =
              libCurl.easy_strerror(msg.result!).toDartString();
        }

        // cleanup everything
        libCurl.slist_free_all(connData[requestID]!.slist!);
        libCurl.multi_remove_handle(multiHandle, msg.easyHandle!);
        libCurl.easy_cleanup(msg.easyHandle!);
        reqIDs.remove(msg.easyHandle);
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

        return buffer.toResponse(this);
      }
    }
    return null;
  }

  void dispose() {}
}

/// [_isolate] function runs in a different isolate and sends
/// requests and responses to and from libcurl to the main
/// Flutter isolate
void _isolate(SendPort sendPort) async {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  final engine = _Engine();
  receivePort.listen((req) async {
    engine.send(req);
    await for (var data in _Engine.logData[req.id]!.stream) {
      sendPort.send(data);
    }
  });
  engine.init();

  while (true) {
    final res = await engine.perform();
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

  _Engine.connData[requestID.toDartString()]!.headerBuffer
      .addAll(data.asTypedList(realsize));

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
