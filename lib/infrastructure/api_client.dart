import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'app_config.dart';

/// The request never reached the server (no signal, DNS, timeout).
class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

/// The server answered with an error.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thin JSON client for the Flask backend. The app talks only to this API —
/// never to the database directly.
class ApiClient {
  final String baseUrl;
  final http.Client _http;
  final String? Function() tokenProvider;

  ApiClient({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  bool get isConfigured => baseUrl.isNotEmpty;

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<Map<String, dynamic>> post(String path, Object? body) =>
      _send('POST', path, body: body);

  Future<Map<String, dynamic>> delete(String path) => _send('DELETE', path);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    if (!isConfigured) throw const NetworkException('No server configured');
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Content-Type'] = 'application/json';
    final token = tokenProvider();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (body != null) request.body = jsonEncode(body);

    final http.Response response;
    try {
      final streamed = await _http.send(request).timeout(AppConfig.requestTimeout);
      response = await http.Response.fromStream(streamed);
    } on SocketException catch (e) {
      throw NetworkException(e.message);
    } on TimeoutException {
      throw const NetworkException('Request timed out');
    } on http.ClientException catch (e) {
      throw NetworkException(e.message);
    }

    final decoded = response.body.isEmpty ? <String, dynamic>{} : _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return decoded;
    throw ApiException(
      response.statusCode,
      decoded['error'] as String? ?? response.reasonPhrase ?? 'Request failed',
    );
  }

  Map<String, dynamic> _decode(String body) {
    try {
      final value = jsonDecode(body);
      return value is Map<String, dynamic> ? value : {'data': value};
    } on FormatException {
      return {'error': body};
    }
  }
}
