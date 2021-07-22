part of "client.dart";

/// [_CURLMsg] holds the status about a single request
class _CURLMsg extends ffi.Struct {
  @ffi.Int32()
  int? messageType;

  ffi.Pointer<ffi.Void>? easyHandle;

  @ffi.Int32()
  int? result;

  factory _CURLMsg.allocate(
          int msg, ffi.Pointer<ffi.Void> easyHandle, int result) =>
      malloc.allocate<_CURLMsg>(ffi.sizeOf<_CURLMsg>()).ref
        ..messageType = msg
        ..easyHandle = easyHandle
        ..result = result;
}

typedef _ReadFunc = ffi.Int32 Function(
    ffi.Pointer<ffi.Uint8>, ffi.Int32, ffi.Int32, ffi.Pointer<ffi.Int8>);

typedef _WriteFunc = ffi.Int32 Function(
    ffi.Pointer<ffi.Uint8>, ffi.Int32, ffi.Int32, ffi.Pointer<ffi.Int8>);

typedef _DebugFunc = ffi.Int32 Function(ffi.Pointer<ffi.Void>, ffi.Int32,
    ffi.Pointer<ffi.Uint8>, ffi.Int32, ffi.Pointer<ffi.Int8>);

typedef _c_curl_easy_setopt_string = ffi.Int32 Function(
  ffi.Pointer<ffi.Void> curl,
  ffi.Int32 option,
  ffi.Pointer<ffi.Int8> content,
);

typedef _dart_curl_easy_setopt_string = int Function(
  ffi.Pointer<ffi.Void> curl,
  int option,
  ffi.Pointer<ffi.Int8> content,
);

typedef _c_curl_easy_setopt_int = ffi.Int32 Function(
  ffi.Pointer<ffi.Void> curl,
  ffi.Int32 option,
  ffi.Int32 content,
);

typedef _dart_curl_easy_setopt_int = int Function(
  ffi.Pointer<ffi.Void> curl,
  int option,
  int content,
);

typedef _c_curl_easy_setopt_ptr = ffi.Int32 Function(
  ffi.Pointer<ffi.Void> curl,
  ffi.Int32 option,
  ffi.Pointer<ffi.Void> content,
);

typedef _dart_curl_easy_setopt_ptr = int Function(
  ffi.Pointer<ffi.Void> curl,
  int option,
  ffi.Pointer<ffi.Void> content,
);

typedef _c_curl_easy_getinfo_long = ffi.Int32 Function(
  ffi.Pointer<ffi.Void> handle,
  ffi.Int32 info,
  ffi.Pointer<ffi.Int64> codep,
);

typedef _dart_curl_easy_getinfo_long = int Function(
  ffi.Pointer<ffi.Void> handle,
  int info,
  ffi.Pointer<ffi.Int64> codep,
);

class LibCURLExtended extends LibCURL {
  final ffi.DynamicLibrary dynamicLibrary;
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  LibCURLExtended(this.dynamicLibrary)
      : _lookup = dynamicLibrary.lookup,
        super(dynamicLibrary);

  int curl_easy_setopt_string(
    ffi.Pointer<ffi.Void> curl,
    int option,
    ffi.Pointer<ffi.Int8> content,
  ) {
    return _curl_easy_setopt_string(
      curl,
      option,
      content,
    );
  }

  late final _curl_easy_setopt_string_ptr =
      _lookup<ffi.NativeFunction<_c_curl_easy_setopt_string>>(
          'curl_easy_setopt');
  late final _dart_curl_easy_setopt_string _curl_easy_setopt_string =
      _curl_easy_setopt_string_ptr.asFunction<_dart_curl_easy_setopt_string>();

  int curl_easy_setopt_int(
    ffi.Pointer<ffi.Void> curl,
    int option,
    int content,
  ) {
    return _curl_easy_setopt_int(
      curl,
      option,
      content,
    );
  }

  late final _curl_easy_setopt_int_ptr =
      _lookup<ffi.NativeFunction<_c_curl_easy_setopt_int>>('curl_easy_setopt');
  late final _dart_curl_easy_setopt_int _curl_easy_setopt_int =
      _curl_easy_setopt_int_ptr.asFunction<_dart_curl_easy_setopt_int>();

  int curl_easy_setopt_ptr(
    ffi.Pointer<ffi.Void> curl,
    int option,
    ffi.Pointer<ffi.Void> content,
  ) {
    return _curl_easy_setopt_ptr_1(
      curl,
      option,
      content,
    );
  }

  late final _curl_easy_setopt_ptr_ptr =
      _lookup<ffi.NativeFunction<_c_curl_easy_setopt_ptr>>('curl_easy_setopt');
  late final _dart_curl_easy_setopt_ptr _curl_easy_setopt_ptr_1 =
      _curl_easy_setopt_ptr_ptr.asFunction<_dart_curl_easy_setopt_ptr>();

  int curl_easy_getinfo_long(
    ffi.Pointer<ffi.Void> handle,
    int info,
    ffi.Pointer<ffi.Int64> codep,
  ) {
    return _curl_easy_getinfo_long(
      handle,
      info,
      codep,
    );
  }

  late final _curl_easy_getinfo_long_ptr =
      _lookup<ffi.NativeFunction<_c_curl_easy_getinfo_long>>(
          'curl_easy_getinfo');
  late final _dart_curl_easy_getinfo_long _curl_easy_getinfo_long =
      _curl_easy_getinfo_long_ptr.asFunction<_dart_curl_easy_getinfo_long>();
}
