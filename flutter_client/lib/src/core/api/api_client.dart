import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    http.Client? client,
  })  : _tokenStorage = tokenStorage,
        _client = client ?? http.Client();

  final TokenStorage _tokenStorage;
  final http.Client _client;
  bool _lastGetUsedCache = false;

  bool get lastGetUsedCache => _lastGetUsedCache;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = _uri(path, queryParameters);
    _lastGetUsedCache = false;
    try {
      final response = await _send(
        (headers) => _client.get(uri, headers: headers),
      );
      final data = _readEnvelope(response);
      await _saveCache(uri, data);
      return data;
    } on ApiException catch (error) {
      if (error.statusCode != null) rethrow;
      final data = await _readCache(uri);
      if (data is Map<String, dynamic>) {
        _lastGetUsedCache = true;
        return data;
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getListJson(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = _uri(path, queryParameters);
    _lastGetUsedCache = false;
    try {
      final response = await _send(
        (headers) => _client.get(uri, headers: headers),
      );
      final data = _readEnvelopeData(response);
      if (data is! List<Object?> ||
          data.any((item) => item is! Map<String, dynamic>)) {
        throw const ApiException(
          message: 'The server response did not contain a valid list.',
        );
      }
      final records = data.cast<Map<String, dynamic>>();
      await _saveCache(uri, records);
      return records;
    } on ApiException catch (error) {
      if (error.statusCode != null) rethrow;
      final data = await _readCache(uri);
      if (data is List<Object?> &&
          data.every((item) => item is Map<String, dynamic>)) {
        _lastGetUsedCache = true;
        return data.cast<Map<String, dynamic>>();
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, Object?> body,
  ) async {
    final response = await _send(
      (headers) => _client.post(
        _uri(path, null),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
    return _readEnvelope(response);
  }

  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, Object?> body, {
    Map<String, String>? queryParameters,
  }) async {
    final response = await _send(
      (headers) => _client.put(
        _uri(path, queryParameters),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
    return _readEnvelope(response);
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, Object?>? body,
  }) async {
    final response = await _send(
      (headers) => _client.patch(
        _uri(path, queryParameters),
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _readEnvelope(response);
  }

  Future<void> deleteJson(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final response = await _send(
      (headers) => _client.delete(
        _uri(path, queryParameters),
        headers: headers,
      ),
    );
    _readEnvelopeData(response);
  }

  Uri _uri(String path, Map<String, String>? queryParameters) {
    final uri = AppConfig.apiBaseUri.resolve(path);
    if (queryParameters == null || queryParameters.isEmpty) return uri;
    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        ...queryParameters,
      },
    );
  }

  Future<String?> _cacheKey(Uri uri) async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) return null;
    final digest = sha256.convert(utf8.encode('$token|$uri'));
    return 'invoicely_cache_$digest';
  }

  Future<void> _saveCache(Uri uri, Object data) async {
    final key = await _cacheKey(uri);
    if (key == null) return;
    final encoded = jsonEncode(data);
    if (encoded.length > 1000000) {
      debugPrint('Skipped API cache entry larger than 1 MB: $uri');
      return;
    }
    try {
      await _tokenStorage.writeValue(key, encoded);
    } catch (error) {
      debugPrint('Could not persist API cache for $uri: $error');
    }
  }

  Future<Object?> _readCache(Uri uri) async {
    final key = await _cacheKey(uri);
    if (key == null) return null;
    final encoded = await _tokenStorage.readValue(key);
    if (encoded == null) return null;
    try {
      return jsonDecode(encoded);
    } on FormatException catch (error) {
      await _tokenStorage.deleteValue(key);
      debugPrint('Removed invalid API cache for $uri: $error');
      return null;
    }
  }

  Future<http.Response> _send(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final token = await _tokenStorage.readToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      return await request(headers).timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const ApiException(message: 'The server took too long to respond.');
    } on http.ClientException catch (error) {
      throw ApiException(message: 'Could not connect to the server: $error');
    }
  }

  Map<String, dynamic> _readEnvelope(http.Response response) {
    final data = _readEnvelopeData(response);
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'The server response did not contain the expected data.',
      );
    }
    return data;
  }

  Object? _readEnvelopeData(http.Response response) {
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw ApiException(
        message: response.statusCode >= 200 && response.statusCode < 300
            ? 'The server returned an invalid response.'
            : 'The server request failed (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw ApiException(
        message: 'The server returned an unexpected response.',
        statusCode: response.statusCode,
      );
    }

    final message = decoded['message'] is String
        ? decoded['message'] as String
        : 'The request failed (${response.statusCode}).';
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded['success'] != true) {
      throw ApiException(message: message, statusCode: response.statusCode);
    }

    return decoded['data'];
  }

  void close() => _client.close();
}
