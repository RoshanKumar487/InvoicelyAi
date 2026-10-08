import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../models/auth_models.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<bool> hasSavedToken() async {
    final token = await _tokenStorage.readToken();
    return token != null && token.isNotEmpty;
  }

  Future<AuthSession> login({
    required String identifier,
    required String password,
  }) async {
    final data = await _apiClient.postJson('api/v1/auth/login', {
      'identifier': identifier,
      'password': password,
    });
    return _saveSession(data);
  }

  Future<AuthSession> registerCompany({
    required String fullName,
    required String email,
    required String mobile,
    required String password,
    required String companyName,
    required String gstin,
    required String location,
    required String details,
  }) async {
    final data = await _apiClient.postJson('api/v1/auth/register-company', {
      'fullName': fullName,
      'email': email,
      'mobile': mobile,
      'password': password,
      'companyName': companyName,
      'gstin': gstin,
      'location': location,
      'details': details,
    });
    return _saveSession(data);
  }

  Future<void> registerEmployee({
    required String fullName,
    required String email,
    required String mobile,
    required String password,
    required String companyCode,
    required String message,
  }) async {
    await _apiClient.postJson('api/v1/auth/register-employee', {
      'fullName': fullName,
      'email': email,
      'mobile': mobile,
      'password': password,
      'companyCode': companyCode,
      'requestMessage': message,
    });
  }

  Future<void> resetPassword({
    required String identifier,
    required String newPassword,
  }) async {
    await _apiClient.postJson('api/v1/auth/reset-password', {
      'identifier': identifier,
      'newPassword': newPassword.trim(),
    });
  }

  Future<AuthSession> restoreSession() async {
    final data = await _apiClient.getJson('api/v1/auth/me');
    return AuthSession.fromJson(data);
  }

  Future<void> logout() => _tokenStorage.clearToken();

  Future<bool> checkBackendConnection() async {
    try {
      await _apiClient.getJson('api/v1/health');
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<AuthSession> _saveSession(Map<String, dynamic> data) async {
    final token = data['token'];
    if (token is! String || token.isEmpty) {
      throw const ApiException(
        message: 'The server did not provide a valid session token.',
      );
    }
    final session = AuthSession.fromJson(data);
    await _tokenStorage.saveToken(token);
    return session;
  }
}
