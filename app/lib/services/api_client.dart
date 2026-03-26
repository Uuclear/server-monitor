import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/metrics.dart';

/// Communicates with a server-monitor agent via REST API.
class ApiClient {
  final String baseUrl;
  final String token;

  ApiClient({required this.baseUrl, this.token = ''});

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Fetch all metrics from the agent
  Future<MetricsSnapshot> fetchMetrics() async {
    final uri = Uri.parse('$baseUrl/metrics');
    final response = await http.get(uri, headers: _headers).timeout(
      const Duration(seconds: 10),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return MetricsSnapshot.fromJson(json);
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw ApiException('Authentication failed', response.statusCode);
    } else {
      throw ApiException('Failed to fetch metrics', response.statusCode);
    }
  }

  /// Health check - returns true if agent is reachable
  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final response = await http.get(uri, headers: _headers).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

/// API-specific exception
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
