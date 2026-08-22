import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:cms/core/error/session_manager.dart';

class SessionTimeoutHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final inner = super.createHttpClient(context);
    inner.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return SessionTimeoutHttpClient(inner);
  }
}

class SessionTimeoutHttpClient implements HttpClient {
  final HttpClient _inner;
  SessionTimeoutHttpClient(this._inner);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    final request = await _inner.openUrl(method, url);
    return SessionTimeoutHttpClientRequest(request);
  }

  @override
  Future<HttpClientRequest> open(String method, String host, int port, String path) async {
    final request = await _inner.open(method, host, port, path);
    return SessionTimeoutHttpClientRequest(request);
  }

  @override
  Future<HttpClientRequest> get(String host, int port, String path) => open("GET", host, port, path);

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl("GET", url);

  @override
  Future<HttpClientRequest> post(String host, int port, String path) => open("POST", host, port, path);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl("POST", url);

  @override
  Future<HttpClientRequest> put(String host, int port, String path) => open("PUT", host, port, path);

  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl("PUT", url);

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) => open("DELETE", host, port, path);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl("DELETE", url);

  @override
  Future<HttpClientRequest> head(String host, int port, String path) => open("HEAD", host, port, path);

  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl("HEAD", url);

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) => open("PATCH", host, port, path);

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl("PATCH", url);

  @override
  set connectionTimeout(Duration? value) => _inner.connectionTimeout = value;
  @override
  Duration? get connectionTimeout => _inner.connectionTimeout;

  @override
  set idleTimeout(Duration value) => _inner.idleTimeout = value;
  @override
  Duration get idleTimeout => _inner.idleTimeout;

  @override
  set maxConnectionsPerHost(int? value) => _inner.maxConnectionsPerHost = value;
  @override
  int? get maxConnectionsPerHost => _inner.maxConnectionsPerHost;

  @override
  set autoUncompress(bool value) => _inner.autoUncompress = value;
  @override
  bool get autoUncompress => _inner.autoUncompress;

  @override
  set userAgent(String? value) => _inner.userAgent = value;
  @override
  String? get userAgent => _inner.userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) =>
      _inner.addCredentials(url, realm, credentials);

  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) =>
      _inner.addProxyCredentials(host, port, realm, credentials);

  @override
  set authenticate(Future<bool> Function(Uri url, String scheme, String? realm)? f) => _inner.authenticate = f;

  @override
  set authenticateProxy(Future<bool> Function(String host, int port, String scheme, String? realm)? f) =>
      _inner.authenticateProxy = f;

  @override
  set findProxy(String Function(Uri url)? f) => _inner.findProxy = f;

  @override
  void close({bool force = false}) => _inner.close(force: force);

  @override
  set badCertificateCallback(bool Function(X509Certificate cert, String host, int port)? callback) =>
      _inner.badCertificateCallback = callback;

  @override
  set connectionFactory(Future<ConnectionTask<Socket>> Function(Uri url, String? proxyHost, int? proxyPort)? f) =>
      _inner.connectionFactory = f;

  @override
  set keyLog(void Function(String line)? callback) => _inner.keyLog = callback;
}

class SessionTimeoutHttpClientRequest implements HttpClientRequest {
  final HttpClientRequest _inner;
  SessionTimeoutHttpClientRequest(this._inner);

  @override
  Future<HttpClientResponse> close() async {
    final response = await _inner.close();
    final isAuthRequest = uri.path.contains('login') ||
        uri.path.contains('auth') ||
        uri.path.contains('logout');
    if (!isAuthRequest && (response.statusCode == 401 || response.statusCode == 403)) {
      SessionManager.triggerLogout(
        'You are not permitted to access this resource or your session has expired. Logging out.',
      );
    }
    return response;
  }

  @override
  bool get followRedirects => _inner.followRedirects;
  @override
  set followRedirects(bool value) => _inner.followRedirects = value;

  @override
  int get maxRedirects => _inner.maxRedirects;
  @override
  set maxRedirects(int value) => _inner.maxRedirects = value;

  @override
  bool get persistentConnection => _inner.persistentConnection;
  @override
  set persistentConnection(bool value) => _inner.persistentConnection = value;

  @override
  int get contentLength => _inner.contentLength;
  @override
  set contentLength(int value) => _inner.contentLength = value;

  @override
  bool get bufferOutput => _inner.bufferOutput;
  @override
  set bufferOutput(bool value) => _inner.bufferOutput = value;

  @override
  HttpHeaders get headers => _inner.headers;

  @override
  List<Cookie> get cookies => _inner.cookies;

  @override
  Future<HttpClientResponse> get done => _inner.done;

  @override
  void add(List<int> data) => _inner.add(data);

  @override
  void write(Object? obj) => _inner.write(obj);

  @override
  void writeAll(Iterable objects, [String separator = ""]) => _inner.writeAll(objects, separator);

  @override
  void writeCharCode(int charCode) => _inner.writeCharCode(charCode);

  @override
  void writeln([Object? obj = ""]) => _inner.writeln(obj);

  @override
  void addError(Object error, [StackTrace? stackTrace]) => _inner.addError(error, stackTrace);

  @override
  Future addStream(Stream<List<int>> stream) => _inner.addStream(stream);

  @override
  Future flush() => _inner.flush();

  @override
  Encoding get encoding => _inner.encoding;
  @override
  set encoding(Encoding value) => _inner.encoding = value;

  @override
  void abort([Object? exception, StackTrace? stackTrace]) => _inner.abort(exception, stackTrace);

  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;

  @override
  String get method => _inner.method;

  @override
  Uri get uri => _inner.uri;
}
