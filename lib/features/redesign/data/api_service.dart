import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../app/config.dart';

class ApiService {
  static String get baseUrl => '${AppConfig.apiBaseUrl}/api';
  String? _authToken;

  static String proxiedImageUrl(String imageUrl) {
    return '$baseUrl/app/image-proxy?url=${Uri.encodeComponent(imageUrl)}';
  }

  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // ── Auth ──

  /// Check if phone number exists in backend
  Future<Map<String, dynamic>> checkPhone(String phoneNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/check-phone'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'phoneNumber': phoneNumber}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to check phone');
  }

  /// Create or login session → returns {token, user}
  Future<Map<String, dynamic>> createSession(String phoneNumber, {String? name}) async {
    final body = <String, dynamic>{'phoneNumber': phoneNumber};
    if (name != null) body['name'] = name;

    final response = await http.post(
      Uri.parse('$baseUrl/users/session'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      _authToken = data['token'];
      return data;
    }
    throw Exception('Failed to create session');
  }

  /// Get current user profile
  Future<Map<String, dynamic>> getMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to get user profile');
  }

  /// Get user progress (story progress + katha progress)
  Future<Map<String, dynamic>> getProgress() async {
    final response = await http.get(
      Uri.parse('$baseUrl/app/me/progress'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to get progress');
  }

  // ── Stories ──

  Future<List<dynamic>> fetchStories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/app/stories'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['stories'] ?? [];
      } else {
        throw Exception('Failed to load stories');
      }
    } catch (e) {
      throw Exception('Error fetching stories: $e');
    }
  }

  Future<Map<String, dynamic>> fetchStoryDay(String storyId, int dayNumber) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/app/stories/$storyId/days/$dayNumber'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load story day');
      }
    } catch (e) {
      throw Exception('Error fetching story day: $e');
    }
  }

  Future<String?> fetchStoryHeadingImage(
    String storyId,
    int firstPublishedDayNumber,
  ) async {
    final data = await fetchStoryDay(storyId, firstPublishedDayNumber);
    final day = data['day'];
    if (day is Map) {
      final shareImage = day['shareCardImageUrl']?.toString().trim();
      if (shareImage != null && shareImage.startsWith('http')) {
        return shareImage;
      }
    }

    final photos = data['photos'];
    if (photos is List && photos.isNotEmpty) {
      final firstPhoto = photos.first;
      if (firstPhoto is Map) {
        final imageUrl = firstPhoto['imageUrl']?.toString().trim();
        if (imageUrl != null && imageUrl.startsWith('http')) {
          return imageUrl;
        }
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> checkAnswer(String questionId, String optionId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/app/questions/$questionId/check-answer'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'optionId': optionId}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to check answer');
      }
    } catch (e) {
      throw Exception('Error checking answer: $e');
    }
  }

  Future<void> completeStoryDay(String storyDayId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/app/story-days/$storyDayId/complete'),
        headers: _headers,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to complete story day');
      }
    } catch (e) {
      throw Exception('Error completing story day: $e');
    }
  }
}

final apiService = ApiService();
