part of 'client.dart';

enum _BodyType {
  raw,
  file,
  string,
  form,
  multipart,
}

class RequestBody {
  _BodyType _type;
  List<int> _raw;
  String _string;
  String _file;
  Map<String, dynamic> _form;
  String _multipart;

  RequestBody._();

  factory RequestBody.raw({List<int> data}) {
    return RequestBody._()
      .._type = _BodyType.raw
      .._raw = data;
  }

  factory RequestBody.file({String path}) {
    return RequestBody._()
      .._type = _BodyType.raw
      .._file = path;
  }

  factory RequestBody.string({String content}) {
    return RequestBody._()
      .._type = _BodyType.string
      .._string = content;
  }

  factory RequestBody.form({Map<String, dynamic> params}) {
    return RequestBody._()
      .._type = _BodyType.form
      .._form = params;
  }

  factory RequestBody.multipart({String data}) {
    return RequestBody._()
      .._type = _BodyType.multipart
      .._multipart = data;
  }
}
