part of 'client.dart';

class Engine {
  final LibCURL _libCurl = LibCURL();
  ffi.Pointer<CURLMulti> _multiHandle;

  Isolate poller;
  static Map<String, _ResponseBuffer> _connData = {};
  static Map<ffi.Pointer<CURLEasy>, String> _reqIDs = {};

  void init() {
    _libCurl.init();
    _multiHandle = _libCurl.multi_init();
  }

  void send(Request req) {
    ffi.Pointer<CURLEasy> _handle = _libCurl.easy_init();
    _reqIDs[_handle] = req.id;

    _connData[req.id] = _ResponseBuffer();
    _connData[req.id]._requestID = req.id;

    _libCurl.easy_setopt_string(
      _handle,
      consts.CURLOPT_CUSTOMREQUEST,
      Utf8.toUtf8(req.method),
    );

    _libCurl.easy_setopt_string(
      _handle,
      consts.CURLOPT_URL,
      Utf8.toUtf8(req.url),
    );

    _libCurl.easy_setopt_string(
      _handle,
      consts.CURLOPT_USERAGENT,
      Utf8.toUtf8("curl/7.42.0"),
    );

    final CURL_IPRESOLVE_V4 = 1;
    final CURL_IPRESOLVE_V6 = 2;
    _libCurl.easy_setopt_int(
      _handle,
      consts.CURLOPT_IPRESOLVE,
      CURL_IPRESOLVE_V4,
    );

    _libCurl.easy_setopt_int(
      _handle,
      consts.CURLOPT_HTTP_VERSION,
      consts.CURL_HTTP_VERSION_1_1 |
          consts.CURL_HTTP_VERSION_2_0 |
          consts.CURL_HTTP_VERSION_3,
    );

    if (req.altSvcCache != null) {
      _libCurl.easy_setopt_string(
        _handle,
        consts.CURLOPT_ALTSVC,
        Utf8.toUtf8(req.altSvcCache),
      );
    }

    if (Platform.isIOS) {
      _libCurl.easy_setopt_string(
        _handle,
        consts.CURLOPT_CAINFO,
        Utf8.toUtf8(req.certPath),
      );
    }

    _libCurl.easy_setopt_int(
      _handle,
      consts.CURLOPT_ALTSVC_CTRL,
      consts.CURLALTSVC_H1 | consts.CURLALTSVC_H2 | consts.CURLALTSVC_H3,
    );

    if (req.verbose) {
      _libCurl.easy_setopt_int(
        _handle,
        consts.CURLOPT_VERBOSE,
        1,
      );
      _libCurl.easy_setopt_ptr(
        _handle,
        consts.CURLOPT_DEBUGFUNCTION,
        ffi.Pointer.fromFunction<_DebugFunc>(debugWriteFunc, 0),
      );
    }

    _connData[req.id]._slist = ffi.nullptr;
    String encodingHeader = "";
    for (var key in req.headers.keys) {
      if (key.toLowerCase() == "accept-encoding") {
        encodingHeader = req.headers[key];
        continue;
      }
      final temp = _libCurl.slist_append(
        _connData[req.id]._slist,
        Utf8.toUtf8("$key: ${req.headers[key]}"),
      );
      if (temp != ffi.nullptr)
        _connData[req.id]._slist = temp;
      else
        print("error while adding $key");
    }

    _libCurl.easy_setopt_string(
      _handle,
      consts.CURLOPT_ACCEPT_ENCODING,
      Utf8.toUtf8(encodingHeader),
    );

    if (_connData[req.id]._slist != ffi.nullptr) {
      _libCurl.easy_setopt_ptr(
        _handle,
        consts.CURLOPT_HTTPHEADER,
        _connData[req.id]._slist,
      );
    }

    if (req.method.toLowerCase() == "post") {
      _libCurl.easy_setopt_string(
        _handle,
        consts.CURLOPT_POSTFIELDS,
        Utf8.toUtf8(utf8.decode(req.body)),
      );
    }

    _libCurl.easy_setopt_ptr(
      _handle,
      consts.CURLOPT_WRITEFUNCTION,
      ffi.Pointer.fromFunction<_WriteFunc>(dataWriteFunc, 0),
    );

    _libCurl.easy_setopt_string(
      _handle,
      consts.CURLOPT_WRITEDATA,
      Utf8.toUtf8(req.id),
    );

    _libCurl.easy_setopt_ptr(
      _handle,
      consts.CURLOPT_HEADERFUNCTION,
      ffi.Pointer.fromFunction<_WriteFunc>(headerWriteFunc, 0),
    );

    _libCurl.easy_setopt_string(
      _handle,
      consts.CURLOPT_HEADERDATA,
      Utf8.toUtf8(req.id),
    );

    _libCurl.multi_add_handle(_multiHandle, _handle);
  }

  ffi.Pointer<ffi.Int32> _tempCounter = allocate();
  Future<Response> perform() async {
    _libCurl.multi_perform(_multiHandle, _tempCounter);
    final msgPtr = _libCurl.multi_info_read(_multiHandle, _tempCounter);
    if (msgPtr != ffi.nullptr) {
      final msg = msgPtr.ref;
      if (msg.messageType == consts.CURLMSG_DONE) {
        String requestID = _reqIDs[msg.easyHandle];
        final buffer = _connData[requestID];

        ffi.Pointer<ffi.Int64> _tempLong = allocate();
        _libCurl.easy_getinfo(
            msg.easyHandle, consts.CURLINFO_RESPONSE_CODE, _tempLong);
        buffer._statusCode = _tempLong.value;
        _libCurl.easy_getinfo(
            msg.easyHandle, consts.CURLINFO_HTTP_VERSION, _tempLong);
        buffer._httpVersion = _tempLong.value;
        free(_tempLong);

        _libCurl.slist_free_all(_connData[requestID]._slist);
        _libCurl.multi_remove_handle(_multiHandle, msg.easyHandle);
        _libCurl.easy_cleanup(msg.easyHandle);
        _reqIDs.remove(msg.easyHandle);
        _connData.remove(requestID);
        return buffer.toResponse();
      }
    }
    return null;
  }

  // void poll() {
  //   _libCurl.multi_poll(_multiHandle, ffi.nullptr, 0, 50, ffi.nullptr);
  // }

  void dispose() {}
}

void _isolate(SendPort sendPort) async {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  final c = Engine();

  receivePort.listen((req) {
    c.send(req);
  });

  c.init();

  while (true) {
    final res = await c.perform();
    if (res != null) {
      sendPort.send(res);
    }
    await Future.delayed(Duration(milliseconds: 10));
  }
}

int dataWriteFunc(
  ffi.Pointer<ffi.Uint8> data,
  int size,
  int nmemb,
  ffi.Pointer<Utf8> requestID,
) {
  int realsize = size * nmemb;

  Engine._connData[Utf8.fromUtf8(requestID)]._bodyBuffer
      .addAll(data.asTypedList(realsize));

  return realsize;
}

int headerWriteFunc(
  ffi.Pointer<ffi.Uint8> data,
  int size,
  int nmemb,
  ffi.Pointer<Utf8> requestID,
) {
  int realsize = size * nmemb;

  Engine._connData[Utf8.fromUtf8(requestID)]._headerBuffer
      .addAll(data.asTypedList(realsize));

  return realsize;
}

int debugWriteFunc(
  ffi.Pointer<CURLEasy> handle,
  int type,
  ffi.Pointer<ffi.Uint8> data,
  int size,
  ffi.Pointer<Utf8> requestID,
) {
  final CURLINFO_TEXT = 0;
  final CURLINFO_HEADER_IN = 1;
  final CURLINFO_HEADER_OUT = 2;
  if (type == CURLINFO_TEXT ||
      type == CURLINFO_HEADER_IN ||
      type == CURLINFO_HEADER_OUT) {
    print(utf8.decode(data.asTypedList(size)));
  }
  return 0;
}
