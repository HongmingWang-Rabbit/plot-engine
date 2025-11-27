import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../config/env_config.dart';

/// API client for communicating with the PlotEngine backend
class ApiClient {
  final String baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? EnvConfig.apiBaseUrl;

  /// Get authentication headers with JWT token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Store JWT token securely
  Future<void> setToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  /// Get stored JWT token
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  /// Clear stored JWT token
  Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
  }

  /// Perform GET request
  Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  /// Perform POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  /// Perform PATCH request
  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  /// Perform DELETE request
  Future<void> delete(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    _handleResponse(response);
  }

  /// Handle HTTP responses and errors
  dynamic _handleResponse(http.Response response) {
    // Handle 204 No Content
    if (response.statusCode == 204) {
      return null;
    }

    // Handle success responses (2xx)
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    }

    // Handle unauthorized (token expired or invalid)
    if (response.statusCode == 401) {
      throw UnauthorizedException('Token expired or invalid');
    }

    // Handle other errors
    try {
      final error = json.decode(response.body);
      final message = error['error'] ?? error['message'] ?? 'Request failed';
      throw ApiException(
        message,
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ApiException || e is UnauthorizedException) rethrow;

      // If we can't parse the error, include the status code and body
      final body = response.body.isNotEmpty ? response.body : 'No error details';
      throw ApiException(
        'Backend error (${response.statusCode}): $body',
        statusCode: response.statusCode,
      );
    }
  }
}

/// Exception thrown when API requests fail
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, {required this.statusCode});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// Exception thrown when authentication token is invalid or expired
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);

  @override
  String toString() => 'UnauthorizedException: $message';
}
