part of 'client.dart';

enum _BodyType {
  raw,
  file,
  string,
  form,
  multipart,
}

class RequestBody {
  _BodyType? _type;
  late List<int> _raw;
  late String _string;
  late String _file;
  Map<String, dynamic>? _form;
  late List<Multipart> _multipart;

  RequestBody._();

  factory RequestBody.raw(List<int> data) {
    return RequestBody._()
      .._type = _BodyType.raw
      .._raw = data;
  }

  factory RequestBody.file(String path) {
    return RequestBody._()
      .._type = _BodyType.raw
      .._file = path;
  }

  factory RequestBody.string(String content) {
    return RequestBody._()
      .._type = _BodyType.string
      .._string = content;
  }

  factory RequestBody.form(Map<String, String> params) {
    return RequestBody._()
      .._type = _BodyType.form
      .._form = params;
  }

  factory RequestBody.multipart(List<Multipart> data) {
    return RequestBody._()
      .._type = _BodyType.multipart
      .._multipart = data;
  }
}

enum MultipartType {
  raw,
  file,
}

class Multipart {
  String? _name;
  String? _data;
  String? _filename;
  String? _filepath;
  MultipartType? _type;

  Multipart({String? name, String? data}) {
    _name = name;
    _data = data;
    _type = MultipartType.raw;
  }

  factory Multipart.file({String? name, String? path, String? filename}) {
    return Multipart(name: name)
      .._filename = filename
      .._filepath = path
      .._type = MultipartType.file;
  }
}
