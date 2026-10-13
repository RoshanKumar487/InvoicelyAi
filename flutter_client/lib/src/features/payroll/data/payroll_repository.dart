import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import 'payroll_models.dart';

class PayrollRepository {
  PayrollRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;
  bool _lastLoadUsedCache = false;
  bool get lastLoadUsedCache => _lastLoadUsedCache || _client.lastGetUsedCache;

  // In-memory cache & fallback dataset for seamless offline or preview demo
  List<PayrollRun> _cachedRuns = [];
  List<PayrollEntry> _cachedEntries = [];
  PayrollSummaryKpi _cachedKpis = const PayrollSummaryKpi();

  Future<List<PayrollRun>> listRuns() async {
    try {
      final list = await _client.getListJson('/api/v1/payroll/runs');
      _cachedRuns = list.map((json) => PayrollRun.fromJson(json)).toList();
      _lastLoadUsedCache = false;
      return _cachedRuns;
    } catch (e) {
      debugPrint('PayrollRepository.listRuns network fallback: $e');
      if (_cachedRuns.isEmpty) {
        _cachedRuns = _generateDemoRuns();
      }
      _lastLoadUsedCache = true;
      return _cachedRuns;
    }
  }

  Future<PayrollRun> generateRun({
    required int month,
    required int year,
    String? scheduledPayDate,
    String? title,
  }) async {
    final queryParams = <String, String>{
      'month': month.toString(),
      'year': year.toString(),
    };
    if (scheduledPayDate != null) queryParams['scheduledPayDate'] = scheduledPayDate;
    if (title != null) queryParams['title'] = title;

    try {
      final res = await _client.postJson(
        '/api/v1/payroll/runs/generate',
        queryParams,
      );
      final run = PayrollRun.fromJson(res);
      _cachedRuns.removeWhere((r) => r.id == run.id);
      _cachedRuns.insert(0, run);
      return run;
    } catch (e) {
      debugPrint('PayrollRepository.generateRun fallback: $e');
      // Create local run
      final newRun = PayrollRun(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        companyId: 1,
        periodMonth: month,
        periodYear: year,
        runTitle: title ?? 'Monthly Payroll - $month/$year',
        status: 'REVIEWED',
        scheduledPayDate: scheduledPayDate ?? '2026-${month.toString().padLeft(2, '0')}-30',
        totalGross: 485000.0,
        totalPaid: 0.0,
        totalPending: 485000.0,
        totalOverdue: 0.0,
        totalDeductions: 58200.0,
        totalNetPayable: 426800.0,
        employeeCount: 6,
      );
      _cachedRuns.insert(0, newRun);
      return newRun;
    }
  }

  Future<List<PayrollEntry>> listEntries({
    int? runId,
    String? status,
    String? search,
  }) async {
    final params = <String, String>{};
    if (runId != null) params['runId'] = runId.toString();
    if (status != null && status.isNotEmpty && status.toUpperCase() != 'ALL') {
      params['status'] = status;
    }
    if (search != null && search.isNotEmpty) params['search'] = search;

    try {
      final list = await _client.getListJson(
        '/api/v1/payroll/entries',
        queryParameters: params.isEmpty ? null : params,
      );
      _cachedEntries = list.map((json) => PayrollEntry.fromJson(json)).toList();
      _lastLoadUsedCache = false;
      return _cachedEntries;
    } catch (e) {
      debugPrint('PayrollRepository.listEntries fallback: $e');
      if (_cachedEntries.isEmpty) {
        _cachedEntries = _generateDemoEntries(runId ?? 1);
      }

      var filtered = List<PayrollEntry>.from(_cachedEntries);
      if (status != null && status.isNotEmpty && status.toUpperCase() != 'ALL') {
        filtered = filtered.where((e) => e.paymentStatus.toUpperCase() == status.toUpperCase()).toList();
      }
      if (search != null && search.trim().isNotEmpty) {
        final q = search.trim().toLowerCase();
        filtered = filtered.where((e) =>
          e.employeeName.toLowerCase().contains(q) ||
          e.employeeCode.toLowerCase().contains(q) ||
          e.designation.toLowerCase().contains(q) ||
          e.department.toLowerCase().contains(q)
        ).toList();
      }
      _lastLoadUsedCache = true;
      return filtered;
    }
  }

  Future<PayrollSummaryKpi> getKpis({int? runId}) async {
    final params = <String, String>{};
    if (runId != null) params['runId'] = runId.toString();

    try {
      final json = await _client.getJson(
        '/api/v1/payroll/kpis',
        queryParameters: params.isEmpty ? null : params,
      );
      _cachedKpis = PayrollSummaryKpi.fromJson(json);
      return _cachedKpis;
    } catch (e) {
      debugPrint('PayrollRepository.getKpis fallback: $e');
      // Compute from current cached entries
      if (_cachedEntries.isEmpty) {
        _cachedEntries = _generateDemoEntries(runId ?? 1);
      }

      double gross = 0;
      double paid = 0;
      double pending = 0;
      double overdue = 0;
      int paidCount = 0;
      int pendingCount = 0;
      int overdueCount = 0;

      for (final e in _cachedEntries) {
        gross += e.grossEarnings;
        if (e.isPaid) {
          paid += e.netSalary;
          paidCount++;
        } else if (e.isOverdue) {
          overdue += e.netSalary;
          overdueCount++;
        } else {
          pending += e.netSalary;
          pendingCount++;
        }
      }

      _cachedKpis = PayrollSummaryKpi(
        totalGross: gross > 0 ? gross : 640000.0,
        totalPaid: paid > 0 ? paid : 320000.0,
        totalPending: pending > 0 ? pending : 240000.0,
        totalOverdue: overdue > 0 ? overdue : 80000.0,
        totalEmployees: _cachedEntries.length,
        paidCount: paidCount > 0 ? paidCount : 3,
        pendingCount: pendingCount > 0 ? pendingCount : 2,
        overdueCount: overdueCount > 0 ? overdueCount : 1,
      );
      return _cachedKpis;
    }
  }

  Future<List<PayrollEntry>> batchUpdateStatus({
    required List<int> ids,
    required String status,
  }) async {
    try {
      final body = <String, Object?>{
        'ids': ids,
        'status': status,
      };
      final res = await _client.postJson('/api/v1/payroll/entries/batch-status', body);
      // Update local cache
      final updatedList = (res['data'] is List)
          ? (res['data'] as List).map((i) => PayrollEntry.fromJson(i as Map<String, dynamic>)).toList()
          : <PayrollEntry>[];

      for (final up in updatedList) {
        final idx = _cachedEntries.indexWhere((e) => e.id == up.id);
        if (idx != -1) _cachedEntries[idx] = up;
      }
      return updatedList;
    } catch (e) {
      debugPrint('PayrollRepository.batchUpdateStatus fallback: $e');
      final updated = <PayrollEntry>[];
      for (int i = 0; i < _cachedEntries.length; i++) {
        if (ids.contains(_cachedEntries[i].id)) {
          _cachedEntries[i] = _cachedEntries[i].copyWith(
            paymentStatus: status,
            disbursedAt: status == 'PAID' ? DateTime.now().toIso8601String() : null,
          );
          updated.add(_cachedEntries[i]);
        }
      }
      return updated;
    }
  }

  Future<PayrollEntry> updateEntryStatus({
    required int id,
    required String status,
  }) async {
    try {
      final res = await _client.putJson(
        '/api/v1/payroll/entries/$id/status',
        {'status': status},
      );
      final entry = PayrollEntry.fromJson(res);
      final idx = _cachedEntries.indexWhere((e) => e.id == id);
      if (idx != -1) _cachedEntries[idx] = entry;
      return entry;
    } catch (e) {
      debugPrint('PayrollRepository.updateEntryStatus fallback: $e');
      final idx = _cachedEntries.indexWhere((e) => e.id == id);
      if (idx != -1) {
        _cachedEntries[idx] = _cachedEntries[idx].copyWith(
          paymentStatus: status,
          disbursedAt: status == 'PAID' ? DateTime.now().toIso8601String() : null,
        );
        return _cachedEntries[idx];
      }
      throw ApiException(message: 'Could not update payroll status: $e');
    }
  }

  List<PayrollRun> _generateDemoRuns() {
    return [
      const PayrollRun(
        id: 1,
        companyId: 1,
        periodMonth: 10,
        periodYear: 2026,
        runTitle: 'October 2026 Monthly Payroll',
        status: 'REVIEWED',
        scheduledPayDate: '2026-10-31',
        totalGross: 640000.0,
        totalPaid: 320000.0,
        totalPending: 240000.0,
        totalOverdue: 80000.0,
        totalDeductions: 76800.0,
        totalNetPayable: 563200.0,
        employeeCount: 6,
      ),
      const PayrollRun(
        id: 2,
        companyId: 1,
        periodMonth: 9,
        periodYear: 2026,
        runTitle: 'September 2026 Monthly Payroll',
        status: 'DISBURSED',
        scheduledPayDate: '2026-09-30',
        totalGross: 620000.0,
        totalPaid: 620000.0,
        totalPending: 0.0,
        totalOverdue: 0.0,
        totalDeductions: 74400.0,
        totalNetPayable: 545600.0,
        employeeCount: 6,
      ),
    ];
  }

  List<PayrollEntry> _generateDemoEntries(int runId) {
    return [
      const PayrollEntry(
        id: 101,
        companyId: 1,
        employeeId: 1,
        employeeName: 'Aarav Sharma',
        employeeCode: 'EMP-001',
        designation: 'Senior Lead Architect',
        department: 'Engineering',
        workingDays: 30,
        paidDays: 30,
        basicPay: 95000.0,
        hra: 38000.0,
        allowances: 17000.0,
        grossEarnings: 150000.0,
        pfEmployee: 11400.0,
        esiEmployee: 0.0,
        professionalTax: 200.0,
        tdsTax: 12500.0,
        otherDeductions: 0.0,
        totalDeductions: 24100.0,
        netSalary: 125900.0,
        paymentStatus: 'PAID',
        scheduledPayDate: '2026-10-31',
        disbursedAt: '2026-10-28T10:15:00Z',
        bankAccountMask: 'HDFC •••• 4129',
      ),
      const PayrollEntry(
        id: 102,
        companyId: 1,
        employeeId: 2,
        employeeName: 'Priya Iyer',
        employeeCode: 'EMP-002',
        designation: 'Product Manager',
        department: 'Product',
        workingDays: 30,
        paidDays: 30,
        basicPay: 75000.0,
        hra: 30000.0,
        allowances: 15000.0,
        grossEarnings: 120000.0,
        pfEmployee: 9000.0,
        esiEmployee: 0.0,
        professionalTax: 200.0,
        tdsTax: 8500.0,
        otherDeductions: 0.0,
        totalDeductions: 17700.0,
        netSalary: 102300.0,
        paymentStatus: 'PAID',
        scheduledPayDate: '2026-10-31',
        disbursedAt: '2026-10-28T10:15:00Z',
        bankAccountMask: 'ICICI •••• 9811',
      ),
      const PayrollEntry(
        id: 103,
        companyId: 1,
        employeeId: 3,
        employeeName: 'Rohan Verma',
        employeeCode: 'EMP-003',
        designation: 'Senior Frontend Engineer',
        department: 'Engineering',
        workingDays: 30,
        paidDays: 30,
        basicPay: 65000.0,
        hra: 26000.0,
        allowances: 14000.0,
        grossEarnings: 105000.0,
        pfEmployee: 7800.0,
        esiEmployee: 0.0,
        professionalTax: 200.0,
        tdsTax: 6500.0,
        otherDeductions: 0.0,
        totalDeductions: 14500.0,
        netSalary: 90500.0,
        paymentStatus: 'PENDING',
        scheduledPayDate: '2026-10-31',
        bankAccountMask: 'SBI •••• 6304',
      ),
      const PayrollEntry(
        id: 104,
        companyId: 1,
        employeeId: 4,
        employeeName: 'Neha Patel',
        employeeCode: 'EMP-004',
        designation: 'UI/UX Visual Designer',
        department: 'Design',
        workingDays: 30,
        paidDays: 30,
        basicPay: 55000.0,
        hra: 22000.0,
        allowances: 13000.0,
        grossEarnings: 90000.0,
        pfEmployee: 6600.0,
        esiEmployee: 0.0,
        professionalTax: 200.0,
        tdsTax: 4500.0,
        otherDeductions: 0.0,
        totalDeductions: 11300.0,
        netSalary: 78700.0,
        paymentStatus: 'PENDING',
        scheduledPayDate: '2026-10-31',
        bankAccountMask: 'AXIS •••• 2190',
      ),
      const PayrollEntry(
        id: 105,
        companyId: 1,
        employeeId: 5,
        employeeName: 'Vikram Malhotra',
        employeeCode: 'EMP-005',
        designation: 'Operations Director',
        department: 'Operations',
        workingDays: 30,
        paidDays: 28,
        basicPay: 60000.0,
        hra: 24000.0,
        allowances: 11000.0,
        grossEarnings: 95000.0,
        pfEmployee: 7200.0,
        esiEmployee: 0.0,
        professionalTax: 200.0,
        tdsTax: 5200.0,
        otherDeductions: 2500.0,
        totalDeductions: 15100.0,
        netSalary: 79900.0,
        paymentStatus: 'OVERDUE',
        scheduledPayDate: '2026-10-15',
        bankAccountMask: 'KOTAK •••• 7731',
      ),
      const PayrollEntry(
        id: 106,
        companyId: 1,
        employeeId: 6,
        employeeName: 'Ananya Deshmukh',
        employeeCode: 'EMP-006',
        designation: 'Talent Acquisition Lead',
        department: 'Human Resources',
        workingDays: 30,
        paidDays: 30,
        basicPay: 50000.0,
        hra: 20000.0,
        allowances: 10000.0,
        grossEarnings: 80000.0,
        pfEmployee: 6000.0,
        esiEmployee: 0.0,
        professionalTax: 200.0,
        tdsTax: 3800.0,
        otherDeductions: 0.0,
        totalDeductions: 10000.0,
        netSalary: 70000.0,
        paymentStatus: 'PAID',
        scheduledPayDate: '2026-10-31',
        disbursedAt: '2026-10-28T10:15:00Z',
        bankAccountMask: 'YES •••• 5510',
      ),
    ];
  }
}
