import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../../data/models/auth_models.dart';
import '../../../data/repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepository _repository;

  AuthSession? session;
  String? startupError;
  bool isRestoring = true;
  bool? isBackendConnected;

  Future<void> restoreSession() async {
    try {
      if (await _repository.hasSavedToken()) {
        session = await _repository.restoreSession();
      }
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _repository.logout();
      } else {
        startupError = error.message;
      }
    } on FormatException catch (error) {
      startupError = error.message;
    } finally {
      isRestoring = false;
      notifyListeners();
    }
  }

  Future<void> checkBackendConnection() async {
    isBackendConnected = await _repository.checkBackendConnection();
    notifyListeners();
  }

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    session = await _repository.login(
      identifier: identifier,
      password: password,
    );
    startupError = null;
    notifyListeners();
  }

  Future<void> registerCompany({
    required String fullName,
    required String email,
    required String mobile,
    required String password,
    required String companyName,
    required String gstin,
    required String location,
    required String details,
  }) async {
    session = await _repository.registerCompany(
      fullName: fullName,
      email: email,
      mobile: mobile,
      password: password,
      companyName: companyName,
      gstin: gstin,
      location: location,
      details: details,
    );
    startupError = null;
    notifyListeners();
  }

  Future<void> registerEmployee({
    required String fullName,
    required String email,
    required String mobile,
    required String password,
    required String companyCode,
    required String message,
  }) {
    return _repository.registerEmployee(
      fullName: fullName,
      email: email,
      mobile: mobile,
      password: password,
      companyCode: companyCode,
      message: message,
    );
  }

  Future<void> resetPassword({
    required String identifier,
    required String newPassword,
  }) {
    return _repository.resetPassword(
      identifier: identifier,
      newPassword: newPassword,
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    session = null;
    notifyListeners();
  }
}
