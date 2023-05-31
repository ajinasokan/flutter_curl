part of 'client.dart';

/// [_CURLEasy] holds handle for a single request
class _CURLEasy extends ffi.Opaque {}

/// [_CURLMulti] holds handle to the request queue
class _CURLMulti extends ffi.Opaque {}

/// [_CURLMsg] holds the status about a single request
class _CURLMsg extends ffi.Struct {
  @ffi.Int32()
  external int messageType;

  external ffi.Pointer<_CURLEasy> easyHandle;

  @ffi.Int32()
  external int result;

  factory _CURLMsg.allocate(
          int msg, ffi.Pointer<_CURLEasy> easyHandle, int result) =>
      malloc.allocate<_CURLMsg>(ffi.sizeOf<_CURLMsg>()).ref
        ..messageType = msg
        ..easyHandle = easyHandle
        ..result = result;
}

// C definitions

typedef _version_func = ffi.Pointer<Utf8> Function();
typedef _version = ffi.Pointer<Utf8> Function();

typedef _getdate_func = ffi.Int64 Function(
    ffi.Pointer<Utf8>, ffi.Pointer<ffi.Int64>);
typedef _getdate = int Function(ffi.Pointer<Utf8>, ffi.Pointer<ffi.Int64>);

typedef _multi_init_func = ffi.Pointer<_CURLMulti> Function();
typedef _multi_init = ffi.Pointer<_CURLMulti> Function();

typedef _multi_add_handle_func = ffi.Void Function(
    ffi.Pointer<_CURLMulti>, ffi.Pointer<_CURLEasy>);
typedef _multi_add_handle = void Function(
    ffi.Pointer<_CURLMulti>, ffi.Pointer<_CURLEasy>);

typedef _multi_remove_handle_func = ffi.Void Function(
    ffi.Pointer<_CURLMulti>, ffi.Pointer<_CURLEasy>);
typedef _multi_remove_handle = void Function(
    ffi.Pointer<_CURLMulti>, ffi.Pointer<_CURLEasy>);

typedef _multi_perform_func = ffi.Void Function(
    ffi.Pointer<_CURLMulti>, ffi.Pointer<ffi.Int32>);
typedef _multi_perform = void Function(
    ffi.Pointer<_CURLMulti>, ffi.Pointer<ffi.Int32>);

typedef _multi_poll_func = ffi.Void Function(
    ffi.Pointer<_CURLMulti>, ffi.Pointer, ffi.Int32, ffi.Int32, ffi.Pointer);
typedef _multi_poll = void Function(
    ffi.Pointer<_CURLMulti>, ffi.Pointer, int, int, ffi.Pointer);

typedef _multi_info_read_func = ffi.Pointer<_CURLMsg> Function(
    ffi.Pointer<_CURLMulti>, ffi.Pointer<ffi.Int32>);
typedef _multi_info_read = ffi.Pointer<_CURLMsg> Function(
    ffi.Pointer<_CURLMulti>, ffi.Pointer<ffi.Int32>);

typedef _easy_init_func = ffi.Pointer<_CURLEasy> Function();
typedef _easy_init = ffi.Pointer<_CURLEasy> Function();

typedef _easy_cleanup_func = ffi.Int32 Function(ffi.Pointer<_CURLEasy>);
typedef _easy_clenup = int Function(ffi.Pointer<_CURLEasy>);

typedef _easy_perform_func = ffi.Int32 Function(ffi.Pointer<_CURLEasy>);
typedef _easy_perform = int Function(ffi.Pointer<_CURLEasy>);

typedef _easy_setopt_string_func = ffi.Void Function(
    ffi.Pointer<_CURLEasy>, ffi.Int32, ffi.Pointer<Utf8>);
typedef _easy_setopt_string = void Function(
    ffi.Pointer<_CURLEasy>, int, ffi.Pointer<Utf8>);

typedef _easy_setopt_int_func = ffi.Void Function(
    ffi.Pointer<_CURLEasy>, ffi.Int32, ffi.Int32);
typedef _easy_setopt_int = void Function(ffi.Pointer<_CURLEasy>, int, int);

typedef _easy_setopt_ptr_func = ffi.Void Function(
    ffi.Pointer<_CURLEasy>, ffi.Int32, ffi.Pointer);
typedef _easy_setopt_ptr = void Function(
    ffi.Pointer<_CURLEasy>, int, ffi.Pointer);

typedef _easy_getinfo_func = ffi.Void Function(
    ffi.Pointer<_CURLEasy>, ffi.Int32, ffi.Pointer<ffi.Int64>);
typedef _easy_getinfo = void Function(
    ffi.Pointer<_CURLEasy>, int, ffi.Pointer<ffi.Int64>);

typedef _slist_append_func = ffi.Pointer Function(
    ffi.Pointer, ffi.Pointer<Utf8>);
typedef _slist_append = ffi.Pointer Function(ffi.Pointer, ffi.Pointer<Utf8>);

typedef _slist_free_all_func = ffi.Void Function(ffi.Pointer);
typedef _slist_free_all = void Function(ffi.Pointer);

typedef _curl_easy_strerror_func = ffi.Pointer<Utf8> Function(ffi.Int32);
typedef _curl_easy_strerror = ffi.Pointer<Utf8> Function(int);

/// [_CURLMime] holds handle for mime context
class _CURLMime extends ffi.Opaque {}

/// [_CURLMimePart] holds handle for mime part context
class _CURLMimePart extends ffi.Opaque {}

typedef _curl_mime_init_func = ffi.Pointer<_CURLMime> Function(
    ffi.Pointer<_CURLEasy>);
typedef _curl_mime_init = ffi.Pointer<_CURLMime> Function(
    ffi.Pointer<_CURLEasy>);

typedef _curl_mime_free_func = ffi.Void Function(ffi.Pointer<_CURLMime>);
typedef _curl_mime_free = void Function(ffi.Pointer<_CURLMime>);

typedef _curl_mime_addpart_func = ffi.Pointer<_CURLMimePart> Function(
    ffi.Pointer<_CURLMime>);
typedef _curl_mime_addpart = ffi.Pointer<_CURLMimePart> Function(
    ffi.Pointer<_CURLMime>);

typedef _curl_mime_name_func = ffi.Int32 Function(
    ffi.Pointer<_CURLMimePart>, ffi.Pointer<Utf8>);
typedef _curl_mime_name = int Function(
    ffi.Pointer<_CURLMimePart>, ffi.Pointer<Utf8>);

typedef _curl_mime_filename_func = ffi.Int32 Function(
    ffi.Pointer<_CURLMimePart>, ffi.Pointer<Utf8>);
typedef _curl_mime_filename = int Function(
    ffi.Pointer<_CURLMimePart>, ffi.Pointer<Utf8>);

typedef _curl_mime_type_func = ffi.Int32 Function(
    ffi.Pointer<_CURLMimePart>, ffi.Pointer<Utf8>);
typedef _curl_mime_type = int Function(
    ffi.Pointer<_CURLMimePart>, ffi.Pointer<Utf8>);

typedef _curl_mime_filedata_func = ffi.Int32 Function(
    ffi.Pointer<_CURLMimePart>, ffi.Pointer<Utf8>);
typedef _curl_mime_filedata = int Function(
    ffi.Pointer<_CURLMimePart>, ffi.Pointer<Utf8>);

typedef _curl_mime_data_func = ffi.Int32 Function(
    ffi.Pointer<_CURLMimePart>, ffi.Pointer<Utf8>, ffi.Int32);
typedef _curl_mime_data = int Function(
    ffi.Pointer<_CURLMimePart>, ffi.Pointer<Utf8>, int);

// Callback functions

typedef _ReadFunc = ffi.Int32 Function(
    ffi.Pointer<ffi.Uint8>, ffi.Int32, ffi.Int32, ffi.Pointer<Utf8>);

typedef _WriteFunc = ffi.Int32 Function(
    ffi.Pointer<ffi.Uint8>, ffi.Int32, ffi.Int32, ffi.Pointer<Utf8>);

typedef _DebugFunc = ffi.Int32 Function(ffi.Pointer<_CURLEasy>, ffi.Int32,
    ffi.Pointer<ffi.Uint8>, ffi.Int32, ffi.Pointer<Utf8>);

/// [_LibCURL] defines and initializes the functions in libcurl
/// used by the plugin
class _LibCURL {
  // handle to the lib
  late ffi.DynamicLibrary _dylib;

  // C handles
  late _version version;
  late _getdate getdate;
  late _multi_init multi_init;
  late _multi_add_handle multi_add_handle;
  late _multi_remove_handle multi_remove_handle;
  late _multi_perform multi_perform;
  late _multi_poll multi_poll;
  late _multi_info_read multi_info_read;

  late _easy_init easy_init;
  late _easy_clenup easy_cleanup;
  late _easy_perform easy_perform;
  late _easy_setopt_string easy_setopt_string;
  late _easy_setopt_int easy_setopt_int;
  late _easy_setopt_ptr easy_setopt_ptr;
  late _easy_getinfo easy_getinfo;

  late _slist_append slist_append;
  late _slist_free_all slist_free_all;

  late _curl_easy_strerror easy_strerror;

  late _curl_mime_init mime_init;
  late _curl_mime_addpart mime_addpart;
  late _curl_mime_filename mime_filename;
  late _curl_mime_filedata mime_filedata;
  late _curl_mime_data mime_data;
  late _curl_mime_name mime_name;
  late _curl_mime_free mime_free;

  void init({String? libPath}) {
    // Load the library depending on the platform. If libPath is
    // provided it takes the precendence over all.
    if (libPath != null) {
      _dylib = ffi.DynamicLibrary.open(libPath);
    } else if (Platform.isIOS) {
      _dylib = ffi.DynamicLibrary.process();
    } else if (Platform.isMacOS) {
      _dylib = ffi.DynamicLibrary.process();
    } else if (Platform.isLinux) {
      _dylib = ffi.DynamicLibrary.open(path.join(
          path.dirname(Platform.resolvedExecutable), "lib", "libcurl.so"));
    } else if (Platform.isAndroid) {
      _dylib = ffi.DynamicLibrary.open("libcurl.so");
    } else {
      // TODO: add windows, macos and linux
      throw Exception("Unsupported platform");
    }

    // Initialize all functions defined for the plugin
    version = _dylib
        .lookup<ffi.NativeFunction<_version_func>>('curl_version')
        .asFunction();

    getdate = _dylib
        .lookup<ffi.NativeFunction<_getdate_func>>('curl_getdate')
        .asFunction();

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
            'curl_easy_setopt_string')
        .asFunction();

    easy_setopt_int = _dylib
        .lookup<ffi.NativeFunction<_easy_setopt_int_func>>(
            'curl_easy_setopt_int')
        .asFunction();

    easy_setopt_ptr = _dylib
        .lookup<ffi.NativeFunction<_easy_setopt_ptr_func>>(
            'curl_easy_setopt_ptr')
        .asFunction();

    easy_getinfo = _dylib
        .lookup<ffi.NativeFunction<_easy_getinfo_func>>(
            'curl_easy_getinfo_long')
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

    mime_init = _dylib
        .lookup<ffi.NativeFunction<_curl_mime_init_func>>('curl_mime_init')
        .asFunction();
    mime_addpart = _dylib
        .lookup<ffi.NativeFunction<_curl_mime_addpart_func>>(
            'curl_mime_addpart')
        .asFunction();
    mime_filename = _dylib
        .lookup<ffi.NativeFunction<_curl_mime_filename_func>>(
            'curl_mime_filename')
        .asFunction();
    mime_filedata = _dylib
        .lookup<ffi.NativeFunction<_curl_mime_filedata_func>>(
            'curl_mime_filedata')
        .asFunction();
    mime_data = _dylib
        .lookup<ffi.NativeFunction<_curl_mime_data_func>>('curl_mime_data')
        .asFunction();
    mime_name = _dylib
        .lookup<ffi.NativeFunction<_curl_mime_name_func>>('curl_mime_name')
        .asFunction();
    mime_free = _dylib
        .lookup<ffi.NativeFunction<_curl_mime_free_func>>('curl_mime_free')
        .asFunction();
  }
}
