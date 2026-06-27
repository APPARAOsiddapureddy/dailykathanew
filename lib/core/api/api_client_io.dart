import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../app/config.dart';
import '../errors/app_exception.dart';

class ApiClient {
  ApiClient({String? baseUrl, String? authToken})
    : _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
      _authToken = authToken;

  final String _baseUrl;
  final String? _authToken;
  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 12);

  Future<Map<String, dynamic>> getJson(String path) async {
    final request = await _open('GET', path);
    return _send(request);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final request = await _open('POST', path);
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(body));
    return _send(request);
  }

  Future<void> deleteJson(String path) async {
    final request = await _open('DELETE', path);
    await _sendVoid(request);
  }

  Future<HttpClientRequest> _open(String method, String path) {
    final uri = Uri.parse('$_baseUrl$path');
    return _client
        .openUrl(method, uri)
        .timeout(const Duration(seconds: 12))
        .then((request) {
          if (_authToken?.isNotEmpty == true) {
            request.headers.set(
              HttpHeaders.authorizationHeader,
              'Bearer $_authToken',
            );
          }
          return request;
        });
  }

  Future<Map<String, dynamic>> _send(HttpClientRequest request) async {
    try {
      final response = await request.close().timeout(
        const Duration(seconds: 18),
      );
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException(
          'Server returned ${response.statusCode}. Please try again.',
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw const AppException('Unexpected server response.');
    } on TimeoutException {
      throw const AppException('The request timed out. Please try again.');
    } on SocketException {
      throw AppException(
        'Could not reach Daily Katha API at $_baseUrl. '
        'If you are using a physical phone, use your computer LAN IP instead of localhost.',
      );
    } on FormatException {
      throw const AppException('The server response was not valid JSON.');
    }
  }

  Future<void> _sendVoid(HttpClientRequest request) async {
    try {
      final response = await request.close().timeout(
        const Duration(seconds: 18),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AppException(
          'Server returned ${response.statusCode}. Please try again.',
        );
      }

      await response.drain<void>();
    } on TimeoutException {
      throw const AppException('The request timed out. Please try again.');
    } on SocketException {
      throw AppException(
        'Could not reach Daily Katha API at $_baseUrl. '
        'If you are using a physical phone, use your computer LAN IP instead of localhost.',
      );
    }
  }
}
