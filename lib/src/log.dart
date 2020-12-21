class _Null {
  const _Null();
}

const _null = const _Null();

List<dynamic> _getNonNulls(tag, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10) {
  var params = [
    tag,
    if (p1 != _null) p1,
    if (p2 != _null) p2,
    if (p3 != _null) p3,
    if (p4 != _null) p4,
    if (p5 != _null) p5,
    if (p6 != _null) p6,
    if (p7 != _null) p7,
    if (p8 != _null) p8,
    if (p9 != _null) p9,
    if (p10 != _null) p10,
  ];
  return params;
}

enum LogLevel {
  verbose,
  info,
  debug,
  warn,
  error,
}

typedef void LogWriter(String content);
typedef String LogFormatter(LogLevel level, List<dynamic> params);

class Log {
  static bool colored = true;
  static bool timestamps = true;
  static bool levels = true;
  static bool enabled = true;

  static LogWriter writer = (content) {
    if (enabled) print(content);
  };

  static LogFormatter formatter = (level, params) {
    return params.map((p) => p.toString()).join(" ");
  };

  static log(LogLevel level, List<dynamic> params) {
    writer(formatter(level, params));
  }

  static v(
    tag, [
    p1 = _null,
    p2 = _null,
    p3 = _null,
    p4 = _null,
    p5 = _null,
    p6 = _null,
    p7 = _null,
    p8 = _null,
    p9 = _null,
    p10 = _null,
  ]) {
    var params = _getNonNulls(tag, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10);
    log(LogLevel.verbose, params);
  }

  static i(
    tag, [
    p1 = _null,
    p2 = _null,
    p3 = _null,
    p4 = _null,
    p5 = _null,
    p6 = _null,
    p7 = _null,
    p8 = _null,
    p9 = _null,
    p10 = _null,
  ]) {
    var params = _getNonNulls(tag, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10);
    log(LogLevel.info, params);
  }

  static d(
    tag, [
    p1 = _null,
    p2 = _null,
    p3 = _null,
    p4 = _null,
    p5 = _null,
    p6 = _null,
    p7 = _null,
    p8 = _null,
    p9 = _null,
    p10 = _null,
  ]) {
    var params = _getNonNulls(tag, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10);
    log(LogLevel.debug, params);
  }

  static w(
    tag, [
    p1 = _null,
    p2 = _null,
    p3 = _null,
    p4 = _null,
    p5 = _null,
    p6 = _null,
    p7 = _null,
    p8 = _null,
    p9 = _null,
    p10 = _null,
  ]) {
    var params = _getNonNulls(tag, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10);
    log(LogLevel.warn, params);
  }

  static e(
    tag, [
    p1 = _null,
    p2 = _null,
    p3 = _null,
    p4 = _null,
    p5 = _null,
    p6 = _null,
    p7 = _null,
    p8 = _null,
    p9 = _null,
    p10 = _null,
  ]) {
    var params = _getNonNulls(tag, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10);
    log(LogLevel.error, params);
  }
}
