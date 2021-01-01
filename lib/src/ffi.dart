part of 'client.dart';

/// [CURLEasy] holds handle for a single request
class CURLEasy extends ffi.Struct {}

/// [CURLMulti] holds handle to the request queue
class CURLMulti extends ffi.Struct {}

/// [CURLMsg] holds the status about a single request
class CURLMsg extends ffi.Struct {
  @ffi.Int32()
  int messageType;

  ffi.Pointer<CURLEasy> easyHandle;

  @ffi.Int32()
  int result;

  factory CURLMsg.allocate(
          int msg, ffi.Pointer<CURLEasy> easyHandle, int result) =>
      allocate<CURLMsg>().ref
        ..messageType = msg
        ..easyHandle = easyHandle
        ..result = result;
}

// C definitions

typedef _multi_init_func = ffi.Pointer<CURLMulti> Function();
typedef _multi_init = ffi.Pointer<CURLMulti> Function();

typedef _multi_add_handle_func = ffi.Void Function(
    ffi.Pointer<CURLMulti>, ffi.Pointer<CURLEasy>);
typedef _multi_add_handle = void Function(
    ffi.Pointer<CURLMulti>, ffi.Pointer<CURLEasy>);

typedef _multi_remove_handle_func = ffi.Void Function(
    ffi.Pointer<CURLMulti>, ffi.Pointer<CURLEasy>);
typedef _multi_remove_handle = void Function(
    ffi.Pointer<CURLMulti>, ffi.Pointer<CURLEasy>);

typedef _multi_perform_func = ffi.Void Function(
    ffi.Pointer<CURLMulti>, ffi.Pointer<ffi.Int32>);
typedef _multi_perform = void Function(
    ffi.Pointer<CURLMulti>, ffi.Pointer<ffi.Int32>);

typedef _multi_poll_func = ffi.Void Function(
    ffi.Pointer<CURLMulti>, ffi.Pointer, ffi.Int32, ffi.Int32, ffi.Pointer);
typedef _multi_poll = void Function(
    ffi.Pointer<CURLMulti>, ffi.Pointer, int, int, ffi.Pointer);

typedef _multi_info_read_func = ffi.Pointer<CURLMsg> Function(
    ffi.Pointer<CURLMulti>, ffi.Pointer<ffi.Int32>);
typedef _multi_info_read = ffi.Pointer<CURLMsg> Function(
    ffi.Pointer<CURLMulti>, ffi.Pointer<ffi.Int32>);

typedef _easy_init_func = ffi.Pointer<CURLEasy> Function();
typedef _easy_init = ffi.Pointer<CURLEasy> Function();

typedef _easy_cleanup_func = ffi.Int32 Function(ffi.Pointer<CURLEasy>);
typedef _easy_clenup = int Function(ffi.Pointer<CURLEasy>);

typedef _easy_perform_func = ffi.Int32 Function(ffi.Pointer<CURLEasy>);
typedef _easy_perform = int Function(ffi.Pointer<CURLEasy>);

typedef _easy_setopt_string_func = ffi.Void Function(
    ffi.Pointer<CURLEasy>, ffi.Int32, ffi.Pointer<Utf8>);
typedef _easy_setopt_string = void Function(
    ffi.Pointer<CURLEasy>, int, ffi.Pointer<Utf8>);

typedef _easy_setopt_int_func = ffi.Void Function(
    ffi.Pointer<CURLEasy>, ffi.Int32, ffi.Int32);
typedef _easy_setopt_int = void Function(ffi.Pointer<CURLEasy>, int, int);

typedef _easy_setopt_ptr_func = ffi.Void Function(
    ffi.Pointer<CURLEasy>, ffi.Int32, ffi.Pointer);
typedef _easy_setopt_ptr = void Function(
    ffi.Pointer<CURLEasy>, int, ffi.Pointer);

typedef _easy_getinfo_func = ffi.Void Function(
    ffi.Pointer<CURLEasy>, ffi.Int32, ffi.Pointer<ffi.Int64>);
typedef _easy_getinfo = void Function(
    ffi.Pointer<CURLEasy>, int, ffi.Pointer<ffi.Int64>);

typedef _slist_append_func = ffi.Pointer Function(
    ffi.Pointer, ffi.Pointer<Utf8>);
typedef _slist_append = ffi.Pointer Function(ffi.Pointer, ffi.Pointer<Utf8>);

typedef _slist_free_all_func = ffi.Void Function(ffi.Pointer);
typedef _slist_free_all = void Function(ffi.Pointer);

typedef _curl_easy_strerror_func = ffi.Pointer<Utf8> Function(ffi.Int32);
typedef _curl_easy_strerror = ffi.Pointer<Utf8> Function(int);

// struct curl_mime
// struct curl_mimepart
// curl_mime_init
// curl_mime_addpart
// curl_mime_filename
// curl_mime_filedata
// curl_mime_data
// curl_mime_name

// Callback functions

typedef _ReadFunc = ffi.Int32 Function(
    ffi.Pointer<ffi.Uint8>, ffi.Int32, ffi.Int32, ffi.Pointer<Utf8>);

typedef _WriteFunc = ffi.Int32 Function(
    ffi.Pointer<ffi.Uint8>, ffi.Int32, ffi.Int32, ffi.Pointer<Utf8>);

typedef _DebugFunc = ffi.Int32 Function(ffi.Pointer<CURLEasy>, ffi.Int32,
    ffi.Pointer<ffi.Uint8>, ffi.Int32, ffi.Pointer<Utf8>);

/// [_LibCURL] defines and initializes the functions in libcurl
/// used by the plugin
class _LibCURL {
  // handle to the lib
  ffi.DynamicLibrary _dylib;

  // C handles
  _multi_init multi_init;
  _multi_add_handle multi_add_handle;
  _multi_remove_handle multi_remove_handle;
  _multi_perform multi_perform;
  _multi_poll multi_poll;
  _multi_info_read multi_info_read;

  _easy_init easy_init;
  _easy_clenup easy_cleanup;
  _easy_perform easy_perform;
  _easy_setopt_string easy_setopt_string;
  _easy_setopt_int easy_setopt_int;
  _easy_setopt_ptr easy_setopt_ptr;
  _easy_getinfo easy_getinfo;

  _slist_append slist_append;
  _slist_free_all slist_free_all;

  _curl_easy_strerror easy_strerror;

  void init({String libPath}) {
    // Load the library depending on the platform. If libPath is
    // provided it takes the precendence over all.
    if (libPath != null) {
      _dylib = ffi.DynamicLibrary.open(libPath);
    } else if (Platform.isIOS) {
      _dylib = ffi.DynamicLibrary.process();
    } else if (Platform.isAndroid) {
      _dylib = ffi.DynamicLibrary.open("libcurl.so");
    } else {
      // TODO: add windows, macos and linux
      throw Exception("Unsupported platform");
    }

    // Initialize all functions defined for the plugin
    multi_init = _dylib
        .lookup<ffi.NativeFunction<_multi_init_func>>('curl_multi_init')
        .asFunction();

    multi_add_handle = _dylib
        .lookup<ffi.NativeFunction<_multi_add_handle_func>>(
            'curl_multi_add_handle')
        .asFunction();

    multi_remove_handle = _dylib
        .lookup<ffi.NativeFunction<_multi_remove_handle_func>>(
            'curl_multi_remove_handle')
        .asFunction();

    multi_perform = _dylib
        .lookup<ffi.NativeFunction<_multi_perform_func>>('curl_multi_perform')
        .asFunction();

    multi_poll = _dylib
        .lookup<ffi.NativeFunction<_multi_poll_func>>('curl_multi_poll')
        .asFunction();

    multi_info_read = _dylib
        .lookup<ffi.NativeFunction<_multi_info_read_func>>(
            'curl_multi_info_read')
        .asFunction();

    easy_init = _dylib
        .lookup<ffi.NativeFunction<_easy_init_func>>('curl_easy_init')
        .asFunction();

    easy_cleanup = _dylib
        .lookup<ffi.NativeFunction<_easy_cleanup_func>>('curl_easy_cleanup')
        .asFunction();

    easy_perform = _dylib
        .lookup<ffi.NativeFunction<_easy_perform_func>>('curl_easy_perform')
        .asFunction();

    easy_setopt_string = _dylib
        .lookup<ffi.NativeFunction<_easy_setopt_string_func>>(
            'curl_easy_setopt')
        .asFunction();

    easy_setopt_int = _dylib
        .lookup<ffi.NativeFunction<_easy_setopt_int_func>>('curl_easy_setopt')
        .asFunction();

    easy_setopt_ptr = _dylib
        .lookup<ffi.NativeFunction<_easy_setopt_ptr_func>>('curl_easy_setopt')
        .asFunction();

    easy_getinfo = _dylib
        .lookup<ffi.NativeFunction<_easy_getinfo_func>>('curl_easy_getinfo')
        .asFunction();

    slist_append = _dylib
        .lookup<ffi.NativeFunction<_slist_append_func>>('curl_slist_append')
        .asFunction();

    slist_free_all = _dylib
        .lookup<ffi.NativeFunction<_slist_free_all_func>>('curl_slist_free_all')
        .asFunction();

    easy_strerror = _dylib
        .lookup<ffi.NativeFunction<_curl_easy_strerror_func>>(
            'curl_easy_strerror')
        .asFunction();
  }
}
