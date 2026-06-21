// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import '../../app/config.dart';
import '../errors/app_exception.dart';

class ApiClient {
  ApiClient({String? baseUrl, String? authToken})
    : _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
      _authToken = authToken;

  final String _baseUrl;
  final String? _authToken;

  Future<Map<String, dynamic>> getJson(String path) {
    return _send('GET', path);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) {
    return _send('POST', path, body: body);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await html.HttpRequest.request(
        '$_baseUrl$path',
        method: method,
        requestHeaders: {
          'Content-Type': 'application/json',
          if (_authToken?.isNotEmpty == true)
            'Authorization': 'Bearer $_authToken',
        },
        sendData: body == null ? null : jsonEncode(body),
      ).timeout(const Duration(seconds: 18));

      final status = response.status ?? 0;
      if (status < 200 || status >= 300) {
        throw AppException('Server returned $status. Please try again.');
      }

      final decoded = jsonDecode(response.responseText ?? '{}');
      if (decoded is Map<String, dynamic>) return decoded;
      throw const AppException('Unexpected server response.');
    } on TimeoutException {
      throw const AppException('The request timed out. Please try again.');
    } on html.ProgressEvent {
      throw AppException(
        'Could not reach Daily Katha API at $_baseUrl. '
        'Make sure the CMS server is running and CORS is enabled.',
      );
    } on FormatException {
      throw const AppException('The server response was not valid JSON.');
    }
  }
}
