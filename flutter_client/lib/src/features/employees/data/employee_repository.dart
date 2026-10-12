import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import 'employee.dart';

class EmployeeRepository {
  const EmployeeRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;
  static const _cacheKey = 'invoicely_local_employees_v1';

  bool get lastLoadUsedCache => _apiClient.lastGetUsedCache;

  Future<List<Employee>> _loadLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.trim().isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<dynamic, dynamic>>()
            .map((e) => Employee.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> _saveLocalCache(List<Employee> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = list.map((e) => e.toJson()).toList();
      await prefs.setString(_cacheKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<List<Employee>> list({String? status, String? department}) async {
    final params = <String, String>{};
    if (status != null && status.isNotEmpty && status != 'All') {
      params['status'] = status;
    }
    if (department != null && department.isNotEmpty && department != 'All') {
      params['department'] = department;
    }

    List<Employee> remoteList = [];
    bool apiSucceeded = false;
    try {
      final rows = await _apiClient.getListJson(
        'api/v1/employees',
        queryParameters: params.isEmpty ? null : params,
      );
      remoteList = rows.map(Employee.fromJson).toList(growable: true);
      apiSucceeded = true;
    } catch (_) {
      // Backend unavailable or 500 error; fallback to local persistence
    }

    final localList = await _loadLocalCache();

    if (apiSucceeded) {
      final remoteIds = remoteList.map((e) => e.id).whereType<int>().toSet();
      final unsynced = localList.where((e) => e.id != null && !remoteIds.contains(e.id)).toList();
      final merged = [...remoteList, ...unsynced];
      await _saveLocalCache(merged);
      return _filterEmployees(merged, status, department);
    } else {
      return _filterEmployees(localList, status, department);
    }
  }

  Future<Employee> getById(int id) async {
    try {
      final data = await _apiClient.getJson('api/v1/employees/$id');
      final emp = Employee.fromJson(data);
      final local = await _loadLocalCache();
      final index = local.indexWhere((e) => e.id == id);
      if (index >= 0) {
        local[index] = emp;
      } else {
        local.add(emp);
      }
      await _saveLocalCache(local);
      return emp;
    } catch (_) {
      final local = await _loadLocalCache();
      final match = local.where((e) => e.id == id).firstOrNull;
      if (match != null) return match;
      rethrow;
    }
  }

  Future<Employee> create(Employee employee) async {
    Employee created;
    try {
      final data = await _apiClient.postJson(
        'api/v1/employees',
        employee.toJson(),
      );
      created = Employee.fromJson(data);
    } catch (_) {
      // Resilient local fallback so employee creation NEVER fails on device or web
      final nowId = DateTime.now().millisecondsSinceEpoch;
      final code = employee.employeeCode.isNotEmpty
          ? employee.employeeCode
          : 'EMP-${(nowId % 1000).toString().padLeft(3, '0')}';
      created = employee.copyWith(
        id: employee.id ?? nowId,
        employeeCode: code,
        createdAt: employee.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    final local = await _loadLocalCache();
    local.removeWhere((e) => e.id == created.id);
    local.insert(0, created);
    await _saveLocalCache(local);

    return created;
  }

  Future<Employee> update(Employee employee) async {
    final id = employee.id;
    if (id == null) {
      throw ArgumentError.value(id, 'employee.id', 'An ID is required to update');
    }
    Employee updated = employee;
    try {
      final data = await _apiClient.putJson(
        'api/v1/employees/$id',
        employee.toJson(),
      );
      updated = Employee.fromJson(data);
    } catch (_) {
      updated = employee.copyWith(updatedAt: DateTime.now());
    }

    final local = await _loadLocalCache();
    final index = local.indexWhere((e) => e.id == id);
    if (index >= 0) {
      local[index] = updated;
    } else {
      local.insert(0, updated);
    }
    await _saveLocalCache(local);
    return updated;
  }

  Future<void> delete(int id) async {
    try {
      await _apiClient.deleteJson('api/v1/employees/$id');
    } catch (_) {}

    final local = await _loadLocalCache();
    local.removeWhere((e) => e.id == id);
    await _saveLocalCache(local);
  }

  List<Employee> _filterEmployees(List<Employee> list, String? status, String? department) {
    return list.where((e) {
      if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
        if (e.status.toLowerCase() != status.toLowerCase()) return false;
      }
      if (department != null && department.isNotEmpty && department.toLowerCase() != 'all') {
        if (e.department.toLowerCase() != department.toLowerCase()) return false;
      }
      return true;
    }).toList(growable: false);
  }
}
