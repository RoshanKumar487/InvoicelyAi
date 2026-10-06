import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:invoicely_flutter/src/core/api/api_client.dart';
import 'package:invoicely_flutter/src/core/api/api_exception.dart';
import 'package:invoicely_flutter/src/core/storage/token_storage.dart';

class _MemoryTokenStorage extends TokenStorage {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> readToken() async => 'test-token';

  @override
  Future<String?> readValue(String key) async => values[key];

  @override
  Future<void> writeValue(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> deleteValue(String key) async {
    values.remove(key);
  }
}

void main() {
  group('ApiClient', () {
    test('sends bearer token and query parameters', () async {
      final client = ApiClient(
        tokenStorage: _MemoryTokenStorage(),
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer test-token');
          expect(request.url.path, '/api/v1/clients');
          expect(request.url.queryParameters, {'search': 'Northwind'});
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Success',
              'data': {'id': 7, 'name': 'Northwind'},
            }),
            200,
          );
        }),
      );

      final data = await client.getJson(
        'api/v1/clients',
        queryParameters: {'search': 'Northwind'},
      );

      expect(data['name'], 'Northwind');
      client.close();
    });

    test('decodes list responses', () async {
      final client = ApiClient(
        tokenStorage: _MemoryTokenStorage(),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {'id': 1},
                {'id': 2},
              ],
            }),
            200,
          ),
        ),
      );

      final data = await client.getListJson('api/v1/clients');

      expect(data, hasLength(2));
      expect(data.last['id'], 2);
      client.close();
    });

    test('reports backend error messages', () async {
      final client = ApiClient(
        tokenStorage: _MemoryTokenStorage(),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'success': false,
              'message': 'Access denied',
              'data': null,
            }),
            403,
          ),
        ),
      );

      await expectLater(
        client.getJson('api/v1/private'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.message, 'message', 'Access denied')
              .having((error) => error.statusCode, 'statusCode', 403),
        ),
      );
      client.close();
    });

    test('uses authenticated GET cache only after a network failure', () async {
      final storage = _MemoryTokenStorage();
      var online = true;
      final client = ApiClient(
        tokenStorage: storage,
        client: MockClient((_) async {
          if (!online) throw http.ClientException('offline');
          return http.Response(
            '{"success":true,"data":[{"id":7}]}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      expect(await client.getListJson('/api/v1/invoices'), [
        {'id': 7},
      ]);
      expect(client.lastGetUsedCache, isFalse);

      online = false;
      expect(await client.getListJson('/api/v1/invoices'), [
        {'id': 7},
      ]);
      expect(client.lastGetUsedCache, isTrue);
      client.close();
    });

    test('does not use stale GET cache for HTTP errors', () async {
      final storage = _MemoryTokenStorage();
      var statusCode = 200;
      final client = ApiClient(
        tokenStorage: storage,
        client: MockClient((_) async => http.Response(
              statusCode == 200
                  ? '{"success":true,"data":[{"id":7}]}'
                  : '{"success":false,"message":"Unauthorized"}',
              statusCode,
              headers: {'content-type': 'application/json'},
            )),
      );

      await client.getListJson('/api/v1/invoices');
      statusCode = 401;
      await expectLater(
        client.getListJson('/api/v1/invoices'),
        throwsA(isA<ApiException>()),
      );
      expect(client.lastGetUsedCache, isFalse);
      client.close();
    });
  });
}
