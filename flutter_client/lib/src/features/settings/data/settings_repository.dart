import '../../../core/api/api_client.dart';

class SettingsRepository {
  const SettingsRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> loadProfile() =>
      _apiClient.getJson('api/v1/profile');

  Future<Map<String, dynamic>> saveProfile(Map<String, Object?> profile) =>
      _apiClient.putJson('api/v1/profile', profile);
}
