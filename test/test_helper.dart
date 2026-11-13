import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

// 1x1 transparent PNG bytes
final Uint8List kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockImageHttpClient();
  }
}

class _MockImageHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  void addCredentials(
      Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void addProxyCredentials(
      String host, int port, String realm, HttpClientCredentials credentials) {}
  @override
  set authenticate(
      Future<bool> Function(Uri url, String scheme, String? realm)? f) {}
  @override
  set authenticateProxy(
      Future<bool> Function(
              String host, int port, String scheme, String? realm)?
          f) {}
  @override
  set badCertificateCallback(
      bool Function(X509Certificate cert, String host, int port)? callback) {}
  @override
  set findProxy(String Function(Uri url)? f) {}
  @override
  set connectionFactory(dynamic f) {}
  @override
  set keyLog(dynamic f) {}

  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      _open();
  @override
  Future<HttpClientRequest> getUrl(Uri url) => _open();
  @override
  Future<HttpClientRequest> open(
          String method, String host, int port, String path) =>
      _open();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) => _open();
  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      _open();
  @override
  Future<HttpClientRequest> postUrl(Uri url) => _open();
  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      _open();
  @override
  Future<HttpClientRequest> putUrl(Uri url) => _open();
  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      _open();
  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => _open();
  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      _open();
  @override
  Future<HttpClientRequest> headUrl(Uri url) => _open();
  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      _open();
  @override
  Future<HttpClientRequest> patchUrl(Uri url) => _open();

  Future<HttpClientRequest> _open() async => _MockHttpClientRequest();
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  bool bufferOutput = true;
  @override
  int contentLength = 0;
  @override
  Encoding encoding = utf8;
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  bool persistentConnection = false;
  @override
  String get method => 'GET';
  @override
  Uri get uri => Uri.parse('http://localhost');

  @override
  final HttpHeaders headers = _MockHttpHeaders();
  @override
  final HttpConnectionInfo? connectionInfo = null;
  @override
  final List<Cookie> cookies = <Cookie>[];
  @override
  final Future<HttpClientResponse> done =
      Future.value(_MockHttpClientResponse());

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}
  @override
  void add(List<int> data) {}
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future addStream(Stream<List<int>> stream) => Future.value();
  @override
  Future<HttpClientResponse> close() => Future.value(_MockHttpClientResponse());
  @override
  void write(Object? obj) {}
  @override
  void writeAll(Iterable objects, [String separator = '']) {}
  @override
  void writeCharCode(int charCode) {}
  @override
  void writeln([Object? obj = '']) {}
  @override
  Future flush() => Future.value();
}

class _MockHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  final HttpHeaders headers = _MockHttpHeaders();
  @override
  final int statusCode = 200;
  @override
  final int contentLength = kTransparentImage.length;
  @override
  final HttpClientResponseCompressionState compressionState =
      HttpClientResponseCompressionState.notCompressed;
  @override
  final String reasonPhrase = 'OK';
  @override
  final bool isRedirect = false;
  @override
  final bool persistentConnection = false;
  @override
  final List<RedirectInfo> redirects = const [];
  @override
  final List<Cookie> cookies = const [];
  @override
  final X509Certificate? certificate = null;
  @override
  final HttpConnectionInfo? connectionInfo = null;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Future<Socket> detachSocket() {
    throw UnimplementedError();
  }

  @override
  Future<HttpClientResponse> redirect(
      [String? method, Uri? url, bool? followLoops]) {
    throw UnimplementedError();
  }
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  bool chunkedTransferEncoding = false;
  @override
  int contentLength = kTransparentImage.length;
  @override
  ContentType? contentType = ContentType('image', 'png');
  @override
  DateTime? date;
  @override
  DateTime? expires;
  @override
  String? host;
  @override
  DateTime? ifModifiedSince;
  @override
  bool persistentConnection = false;
  @override
  int? port;

  @override
  List<String>? operator [](String name) => null;
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void clear() {}
  @override
  void forEach(void Function(String name, List<String> values) action) {}
  @override
  void noFolding(String name) {}
  @override
  void remove(String name, Object value) {}
  @override
  void removeAll(String name) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  String? value(String name) => null;
}
