import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String _activeBaseUrl = kResolvedApiBaseUrl;

  Uri _endpoint(String path, {String? baseUrl}) {
    return Uri.parse(baseUrl ?? _activeBaseUrl).resolve(path);
  }

  Map<String, String> _headers({bool includeJsonContentType = false}) {
    final String? token = kApiToken;

    return <String, String>{
      'Accept': 'application/json',
      if (includeJsonContentType) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> getJson(String path) async {
    final http.Response response = await _withBaseUrlFallback(
      path: path,
      request: (String baseUrl) =>
          _client.get(_endpoint(path, baseUrl: baseUrl), headers: _headers()),
    );

    return _decodeResponseBody(response);
  }

  Future<dynamic> postJson(String path, Map<String, dynamic> body) async {
    final http.Response response = await _withBaseUrlFallback(
      path: path,
      request: (String baseUrl) => _client.post(
        _endpoint(path, baseUrl: baseUrl),
        headers: _headers(includeJsonContentType: true),
        body: jsonEncode(body),
      ),
    );

    if (response.body.trim().isEmpty) {
      return null;
    }

    return _decodeResponseBody(response);
  }

  Future<http.Response> _withBaseUrlFallback({
    required String path,
    required Future<http.Response> Function(String baseUrl) request,
  }) async {
    final List<String> candidates = <String>[
      _activeBaseUrl,
      ...kApiBaseUrlCandidates.where((String url) => url != _activeBaseUrl),
    ];

    Object? lastError;
    for (final String baseUrl in candidates) {
      try {
        final http.Response response = await request(baseUrl);
        _throwForStatus(path: path, response: response);
        _activeBaseUrl = baseUrl;
        return response;
      } catch (error) {
        if (error is ApiException && error.statusCode != 404) {
          _activeBaseUrl = baseUrl;
          rethrow;
        }

        lastError = error;
      }
    }

    if (lastError is ApiException) {
      throw lastError;
    }

    throw ApiException(
      'Request failed for $path on all base URLs: ${candidates.join(', ')}'
      '${lastError == null ? '' : ' | last error: $lastError'}',
    );
  }

  dynamic _decodeResponseBody(http.Response response) {
    final String body = response.body.trim();
    if (body.isEmpty) {
      return null;
    }

    final dynamic decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic> && decoded.containsKey('success')) {
      final bool success = decoded['success'] == true;
      if (!success) {
        throw ApiException((decoded['message'] ?? 'Request failed').toString());
      }
      return decoded['data'];
    }

    return decoded;
  }

  void _throwForStatus({
    required String path,
    required http.Response response,
  }) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    final String message = _extractErrorMessage(response.body);
    throw ApiException(
      'Request $path failed: ${response.statusCode}'
      '${message.isEmpty ? '' : ' - $message'}',
      statusCode: response.statusCode,
    );
  }

  String _extractErrorMessage(String rawBody) {
    final String body = rawBody.trim();
    if (body.isEmpty) {
      return '';
    }

    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final Object? details = decoded['details'];
        if (details is List && details.isNotEmpty) {
          final String firstDetail = details.first.toString().trim();
          if (firstDetail.isNotEmpty) {
            return firstDetail;
          }
        }

        final Object? message = decoded['message'];
        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }
    } catch (_) {
      // Ignore parse errors and return a snippet from raw response body.
    }

    return body.length > 160 ? '${body.substring(0, 160)}...' : body;
  }
}
