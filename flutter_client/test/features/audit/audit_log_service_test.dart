import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invoicely_flutter/src/features/audit/data/audit_log.dart';
import 'package:invoicely_flutter/src/features/audit/data/audit_log_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuditLog Model Tests', () {
    test('JSON serialization & deserialization round-trip', () {
      final now = DateTime.now();
      final log = AuditLog(
        id: 1234,
        companyId: 99,
        userId: 42,
        userName: 'Admin User',
        userRole: 'ADMIN',
        module: 'INVOICE',
        action: 'CREATE',
        entityId: 'INV-1001',
        title: 'Created Invoice INV-1001',
        description: 'Billed ₹45,000 for client security services',
        createdAt: now,
      );

      final json = log.toJson();
      expect(json['id'], 1234);
      expect(json['module'], 'INVOICE');
      expect(json['action'], 'CREATE');
      expect(json['entityId'], 'INV-1001');

      final fromJson = AuditLog.fromJson(json);
      expect(fromJson.id, 1234);
      expect(fromJson.userName, 'Admin User');
      expect(fromJson.userRole, 'ADMIN');
      expect(fromJson.module, 'INVOICE');
      expect(fromJson.action, 'CREATE');
      expect(fromJson.entityId, 'INV-1001');
      expect(fromJson.title, 'Created Invoice INV-1001');
    });

    test('Helper getters return correct icons and colors', () {
      final invoiceLog = AuditLog(
        id: 1,
        userName: 'User',
        userRole: 'ADMIN',
        module: 'INVOICE',
        action: 'CREATE',
        title: 'Invoice created',
      );
      expect(invoiceLog.moduleColor, isNotNull);
      expect(invoiceLog.icon, isNotNull);

      final expenseLog = AuditLog(
        id: 2,
        userName: 'User',
        userRole: 'ADMIN',
        module: 'EXPENSE',
        action: 'CREATE',
        title: 'Expense created',
      );
      expect(expenseLog.moduleColor, isNotNull);
    });
  });

  group('AuditLogService Tests', () {
    test('Records logs locally and retrieves them in list and getRecent', () async {
      final service = AuditLogService();

      // Log an action
      final created = await AuditLogService.log(
        module: 'INVOICE',
        action: 'CREATE',
        title: 'Created test invoice INV-999',
        description: 'Test invoice description',
        entityId: 'INV-999',
        userName: 'Tester',
        userRole: 'ADMIN',
        userId: 1,
      );

      expect(created.entityId, 'INV-999');

      // Query recent logs
      final recent = await service.getRecent(count: 3);
      expect(recent.isNotEmpty, isTrue);
      expect(recent.first.entityId, 'INV-999');

      // Query with module filter
      final invoiceLogs = await service.list(module: 'INVOICE');
      expect(invoiceLogs.any((l) => l.entityId == 'INV-999'), isTrue);

      // Query with search query
      final searched = await service.list(searchQuery: 'INV-999');
      expect(searched.length, 1);
      expect(searched.first.entityId, 'INV-999');

      // Query with mismatched search returns empty
      final notFound = await service.list(searchQuery: 'NonExistentRandomText');
      expect(notFound.isEmpty, isTrue);
    });

    test('Filters by creator (onlyMyLogs and userId)', () async {
      final service = AuditLogService();

      await AuditLogService.log(
        module: 'EXPENSE',
        action: 'CREATE',
        title: 'User 1 expense',
        userId: 1,
      );

      await AuditLogService.log(
        module: 'EXPENSE',
        action: 'CREATE',
        title: 'User 2 expense',
        userId: 2,
      );

      final user1Logs = await service.list(onlyMyLogs: true, currentUserId: 1);
      expect(user1Logs.every((l) => l.userId == 1), isTrue);

      final user2Logs = await service.list(onlyMyLogs: true, currentUserId: 2);
      expect(user2Logs.every((l) => l.userId == 2), isTrue);
    });
  });
}
