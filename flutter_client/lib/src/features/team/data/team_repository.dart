import '../../../core/api/api_client.dart';

class TeamRepository {
  const TeamRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> loadCompany() =>
      _apiClient.getJson('api/v1/companies/my-company');

  Future<List<Map<String, dynamic>>> loadEmployees() =>
      _apiClient.getListJson('api/v1/companies/employees');

  Future<List<Map<String, dynamic>>> loadJoinRequests() =>
      _apiClient.getListJson(
        'api/v1/companies/join-requests',
        queryParameters: const <String, String>{'status': 'PENDING'},
      );

  Future<void> processJoinRequest({
    required int id,
    required String action,
  }) async {
    await _apiClient.postJson(
      'api/v1/companies/join-requests/$id/action',
      <String, Object?>{'action': action},
    );
  }

  Future<void> updatePermissions({
    required int employeeId,
    required Set<String> permissions,
  }) async {
    await _apiClient.putJson(
      'api/v1/companies/employees/$employeeId/permissions',
      <String, Object?>{'permissions': permissions.join(',')},
    );
  }
}
