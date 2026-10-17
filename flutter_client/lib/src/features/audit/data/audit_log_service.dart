import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import 'audit_log.dart';

class AuditLogService {
  static const _cacheKey = 'invoicely_company_audit_logs_v1';
  static final StreamController<AuditLog> _logStream = StreamController<AuditLog>.broadcast();

  static Stream<AuditLog> get onLogAdded => _logStream.stream;

  final ApiClient? _apiClient;

  AuditLogService({ApiClient? apiClient}) : _apiClient = apiClient;

  static Future<List<AuditLog>> _loadLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .whereType<Map<dynamic, dynamic>>()
              .map((e) => AuditLog.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    } catch (_) {}
    return _seedInitialLogs();
  }

  static List<AuditLog> _seedInitialLogs() {
    final now = DateTime.now();
    return [
      AuditLog(
        id: 101,
        userName: 'Admin',
        userRole: 'ADMIN',
        module: 'INVOICE',
        action: 'CREATE',
        entityId: 'INV-001',
        title: 'Created invoice INV-001',
        description: 'Issued bill to Horizon Retail Ltd for security services (₹38,500)',
        createdAt: now.subtract(const Duration(minutes: 12)),
      ),
      AuditLog(
        id: 102,
        userName: 'Admin',
        userRole: 'ADMIN',
        module: 'EMPLOYEE',
        action: 'SCAN_OCR',
        entityId: 'EMP-001',
        title: 'Scanned Aadhaar for Ramesh Kumar',
        description: 'UID 5489 2145 7890 verified and onboarded to Security staff',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 20)),
      ),
      AuditLog(
        id: 103,
        userName: 'Operations',
        userRole: 'MANAGER',
        module: 'EXPENSE',
        action: 'STATUS_CHANGE',
        entityId: 'EXP-104',
        title: 'Marked Expense EXP-104 as Paid',
        description: 'Paid security uniforms & badge supply vendor ₹14,200',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      AuditLog(
        id: 104,
        userName: 'Admin',
        userRole: 'ADMIN',
        module: 'TEAM',
        action: 'ROLE_CHANGE',
        entityId: 'USR-02',
        title: 'Granted Admin access to Office Manager',
        description: 'Promoted Vikram Singh to Administrator with full organizational tools',
        createdAt: now.subtract(const Duration(hours: 5, minutes: 45)),
      ),
      AuditLog(
        id: 105,
        userName: 'Admin',
        userRole: 'ADMIN',
        module: 'CLIENT',
        action: 'CREATE',
        entityId: 'CLI-05',
        title: 'Added Client Apex Logistics',
        description: 'Registered billing contact with Net 15 terms and GSTIN 07AAAAA0000A1Z5',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  static Future<void> _saveLocalCache(List<AuditLog> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = list.take(200).map((e) => e.toJson()).toList();
      await prefs.setString(_cacheKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  /// Global static method to record any action anywhere in the app
  static Future<AuditLog> log({
    required String module,
    required String action,
    required String title,
    String description = '',
    String entityId = '',
    String? userName,
    String? userRole,
    int? userId,
    int? companyId,
    Map<String, dynamic>? metadata,
    ApiClient? apiClient,
  }) async {
    final logItem = AuditLog(
      id: DateTime.now().millisecondsSinceEpoch,
      companyId: companyId,
      userId: userId,
      userName: userName ?? 'You',
      userRole: userRole ?? 'ADMIN',
      module: module.toUpperCase(),
      action: action.toUpperCase(),
      entityId: entityId,
      title: title,
      description: description,
      metadataJson: metadata != null ? jsonEncode(metadata) : '{}',
      createdAt: DateTime.now(),
    );

    // Save to local cache
    final local = await _loadLocalCache();
    local.insert(0, logItem);
    await _saveLocalCache(local);
    _logStream.add(logItem);

    // Optionally post to remote backend if apiClient is provided
    if (apiClient != null) {
      unawaited(
        () async {
          try {
            await apiClient.postJson('api/v1/audit-logs', logItem.toJson());
          } catch (_) {
            // Graceful fallback for offline
          }
        }(),
      );
    }

    return logItem;
  }

  Future<List<AuditLog>> list({
    String? module,
    String? action,
    String? searchQuery,
    bool onlyMyLogs = false,
    int? currentUserId,
  }) async {
    List<AuditLog> remoteLogs = [];
    bool remoteSuccess = false;

    if (_apiClient != null) {
      try {
        final params = <String, String>{};
        if (module != null && module != 'All') params['module'] = module;
        if (action != null && action != 'All') params['action'] = action;
        if (onlyMyLogs && currentUserId != null) params['userId'] = currentUserId.toString();

        final rows = await _apiClient.getListJson(
          'api/v1/audit-logs',
          queryParameters: params.isEmpty ? null : params,
        );
        remoteLogs = rows.map(AuditLog.fromJson).toList();
        remoteSuccess = true;
      } catch (_) {}
    }

    final localLogs = await _loadLocalCache();

    List<AuditLog> allLogs;
    if (remoteSuccess && remoteLogs.isNotEmpty) {
      final remoteIds = remoteLogs.map((e) => e.id).whereType<int>().toSet();
      final unsynced = localLogs.where((e) => e.id != null && !remoteIds.contains(e.id)).toList();
      allLogs = [...remoteLogs, ...unsynced];
      await _saveLocalCache(allLogs);
    } else {
      allLogs = localLogs;
    }

    final query = searchQuery?.trim().toLowerCase() ?? '';
    return allLogs.where((log) {
      if (module != null && module.isNotEmpty && module != 'All') {
        if (log.module.toUpperCase() != module.toUpperCase()) return false;
      }
      if (action != null && action.isNotEmpty && action != 'All') {
        if (log.action.toUpperCase() != action.toUpperCase()) return false;
      }
      if (onlyMyLogs && currentUserId != null) {
        if (log.userId != currentUserId) return false;
      }
      if (query.isNotEmpty) {
        final matches = log.title.toLowerCase().contains(query) ||
            log.description.toLowerCase().contains(query) ||
            log.userName.toLowerCase().contains(query) ||
            log.entityId.toLowerCase().contains(query) ||
            log.module.toLowerCase().contains(query);
        if (!matches) return false;
      }
      return true;
    }).toList(growable: false)
      ..sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
  }

  Future<List<AuditLog>> getRecent({int count = 4}) async {
    final list = await _loadLocalCache();
    return list.take(count).toList();
  }
}
