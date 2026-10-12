import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:invoicely_flutter/src/core/api/api_client.dart';
import 'package:invoicely_flutter/src/core/storage/token_storage.dart';
import 'package:invoicely_flutter/src/features/employees/data/employee.dart';
import 'package:invoicely_flutter/src/features/employees/data/employee_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('EmployeeRepository Offline Resilience Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('creates employee with offline fallback when remote API is unreachable', () async {
      // Mock client that returns 500 error simulating un-deployed endpoint
      final failingClient = http.Client();
      final apiClient = ApiClient(tokenStorage: TokenStorage(), client: failingClient);
      final repo = EmployeeRepository(apiClient: apiClient);

      const newEmp = Employee(
        fullName: 'Vikram Singh',
        designation: 'Security Supervisor',
        department: 'Security',
        monthlySalary: 24000.0,
      );

      final created = await repo.create(newEmp);

      expect(created.id, isNotNull);
      expect(created.fullName, equals('Vikram Singh'));
      expect(created.employeeCode, startsWith('EMP-'));

      // Check that it persisted into local cache
      final list = await repo.list();
      expect(list.length, equals(1));
      expect(list.first.fullName, equals('Vikram Singh'));
      expect(list.first.monthlySalary, equals(24000.0));
    });

    test('updates and deletes employee in local cache seamlessly', () async {
      final failingClient = http.Client();
      final apiClient = ApiClient(tokenStorage: TokenStorage(), client: failingClient);
      final repo = EmployeeRepository(apiClient: apiClient);

      final created = await repo.create(const Employee(
        fullName: 'Anita Sharma',
        designation: 'Receptionist',
        department: 'Front Desk',
        monthlySalary: 18000.0,
      ));

      expect(created.id, isNotNull);

      final updated = await repo.update(created.copyWith(
        monthlySalary: 22000.0,
        status: 'ACTIVE',
      ));
      expect(updated.monthlySalary, equals(22000.0));

      var list = await repo.list();
      expect(list.first.monthlySalary, equals(22000.0));

      await repo.delete(created.id!);
      list = await repo.list();
      expect(list.isEmpty, isTrue);
    });
  });
}
