import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../employees/data/employee.dart';
import '../../employees/data/employee_repository.dart';
import '../../expenses/data/expense.dart';
import '../../expenses/data/expenses_repository.dart';
import 'payroll_models.dart';

class PayrollRepository {
  PayrollRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;
  ApiClient get apiClient => _client;

  bool _lastLoadUsedCache = false;
  bool get lastLoadUsedCache => _lastLoadUsedCache || _client.lastGetUsedCache;

  // In-memory cache & fallback dataset for seamless offline or preview demo
  List<PayrollRun> _cachedRuns = [];
  List<PayrollEntry> _cachedEntries = [];
  PayrollSummaryKpi _cachedKpis = const PayrollSummaryKpi();

  Future<List<PayrollRun>> listRuns() async {
    try {
      final list = await _client.getListJson('/api/v1/payroll/runs');
      var runs = list.map((json) => PayrollRun.fromJson(json)).toList();

      if (runs.isEmpty) {
        // Build run from real employees if available
        runs = await _buildRunsFromRealEmployees();
      }

      _cachedRuns = runs;
      _lastLoadUsedCache = false;
      return _cachedRuns;
    } catch (e) {
      debugPrint('PayrollRepository.listRuns network fallback: $e');
      if (_cachedRuns.isEmpty) {
        _cachedRuns = await _buildRunsFromRealEmployees();
        if (_cachedRuns.isEmpty) {
          _cachedRuns = _generateDemoRuns();
        }
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
      // Create local run based on real employees
      final emps = await _fetchRealEmployees();
      double grossSum = 0;
      for (final emp in emps) {
        grossSum += emp.monthlySalary > 0 ? emp.monthlySalary : 25000.0;
      }
      final newRun = PayrollRun(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        companyId: 1,
        periodMonth: month,
        periodYear: year,
        runTitle: title ?? 'Monthly Payroll - $month/$year',
        status: 'REVIEWED',
        scheduledPayDate: scheduledPayDate ?? '2026-${month.toString().padLeft(2, '0')}-30',
        totalGross: grossSum > 0 ? grossSum : 485000.0,
        totalPaid: 0.0,
        totalPending: grossSum > 0 ? grossSum : 485000.0,
        totalOverdue: 0.0,
        totalDeductions: grossSum * 0.12,
        totalNetPayable: grossSum * 0.88,
        employeeCount: emps.isNotEmpty ? emps.length : 6,
      );
      _cachedRuns.insert(0, newRun);
      return newRun;
    }
  }

  Future<void> syncEmployees(int runId) async {
    try {
      await _client.postJson('/api/v1/payroll/runs/$runId/sync-employees', {});
    } catch (e) {
      debugPrint('PayrollRepository.syncEmployees network fallback: $e');
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

    List<PayrollEntry> fetched = [];
    try {
      final list = await _client.getListJson(
        '/api/v1/payroll/entries',
        queryParameters: params.isEmpty ? null : params,
      );
      fetched = list.map((json) => PayrollEntry.fromJson(json)).toList();
    } catch (e) {
      debugPrint('PayrollRepository.listEntries network fallback: $e');
    }

    // CRITICAL: Fetch real employees and ensure all already-added employees are in payroll!
    final realEmployees = await _fetchRealEmployees();
    final realAdvances = await _fetchRealAdvances();

    if (fetched.isEmpty) {
      // Build entries directly from real employees
      if (realEmployees.isNotEmpty) {
        fetched = _buildEntriesFromEmployees(realEmployees, realAdvances, runId ?? 1);
      } else {
        fetched = _generateDemoEntries(runId ?? 1);
      }
    } else if (realEmployees.isNotEmpty) {
      // Merge any missing real employees that aren't yet in fetched
      final existingEmpNames = fetched.map((e) => e.employeeName.trim().toLowerCase()).toSet();
      final existingEmpIds = fetched.map((e) => e.employeeId).whereType<int>().toSet();

      for (final emp in realEmployees) {
        final matchesId = emp.id != null && existingEmpIds.contains(emp.id!);
        final matchesName = existingEmpNames.contains(emp.fullName.trim().toLowerCase());
        if (!matchesId && !matchesName) {
          final newEntry = _buildSingleEntryFromEmployee(emp, realAdvances, runId ?? 1, 1000 + (emp.id ?? 1));
          fetched.add(newEntry);
        }
      }
    }

    _cachedEntries = fetched;
    _lastLoadUsedCache = false;

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
    return filtered;
  }

  Future<PayrollEntry> updateEntry(PayrollEntry entry) async {
    final id = entry.id;
    try {
      final res = await _client.putJson(
        '/api/v1/payroll/entries/$id',
        entry.toJson(),
      );
      final updated = PayrollEntry.fromJson(res);
      final idx = _cachedEntries.indexWhere((e) => e.id == id);
      if (idx != -1) _cachedEntries[idx] = updated;
      return updated;
    } catch (e) {
      debugPrint('PayrollRepository.updateEntry fallback: $e');
      final idx = _cachedEntries.indexWhere((e) => e.id == id);
      if (idx != -1) {
        _cachedEntries[idx] = entry;
      }
      return entry;
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

  Future<List<Expense>> getEmployeeAdvanceHistory({
    required int employeeId,
    String? employeeName,
  }) async {
    final params = <String, String>{};
    if (employeeName != null && employeeName.isNotEmpty) {
      params['employeeName'] = employeeName;
    }
    try {
      final list = await _client.getListJson(
        '/api/v1/payroll/employees/$employeeId/advances',
        queryParameters: params.isEmpty ? null : params,
      );
      return list.map((j) => Expense.fromJson(j)).toList();
    } catch (e) {
      debugPrint('PayrollRepository.getEmployeeAdvanceHistory fallback: $e');
      return _generateDemoAdvanceHistory(employeeId, employeeName);
    }
  }

  List<Expense> _generateDemoAdvanceHistory(int employeeId, String? employeeName) {
    final name = employeeName ?? 'Employee #$employeeId';
    return [
      Expense(
        id: 901,
        companyId: 1,
        title: 'Mid-Month Festival Advance • $name',
        category: 'Salary Advance',
        amount: 15000.0,
        currency: 'INR',
        currencySymbol: '₹',
        date: '2026-10-12',
        vendor: 'Finance Department',
        createdByUserName: 'Finance Accountant',
        paymentMethod: 'Bank Transfer',
        status: 'Paid',
        employeeId: employeeId,
        employeeName: name,
        isSalaryAdvance: true,
        advanceSettled: false,
        notes: 'Festival salary advance approved by HR Manager. Recoverable from October payroll.',
      ),
      Expense(
        id: 902,
        companyId: 1,
        title: 'Emergency Medical Advance • $name',
        category: 'Salary Advance',
        amount: 10000.0,
        currency: 'INR',
        currencySymbol: '₹',
        date: '2026-09-08',
        vendor: 'Corporate Petty Cash',
        createdByUserName: 'Operations Head',
        paymentMethod: 'Cash',
        status: 'Paid',
        employeeId: employeeId,
        employeeName: name,
        isSalaryAdvance: true,
        advanceSettled: true,
        notes: 'Emergency medical advance. Successfully recovered in September salary.',
      ),
    ];
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
        totalPaid: 298200.0,
        totalPending: 245000.0,
        totalOverdue: 74900.0,
        totalDeductions: 96800.0,
        totalNetPayable: 543200.0,
        totalAdvances: 35000.0,
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
        totalPaid: 545600.0,
        totalPending: 0.0,
        totalOverdue: 0.0,
        totalDeductions: 74400.0,
        totalNetPayable: 545600.0,
        totalAdvances: 10000.0,
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
        advanceAmount: 0.0,
        advanceDeduction: 0.0,
        pendingMonthsCount: 1,
        pendingMonthsDetails: 'Current Month (10/2026)',
        cumulativePayable: 125900.0,
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
        advanceAmount: 0.0,
        advanceDeduction: 0.0,
        pendingMonthsCount: 1,
        pendingMonthsDetails: 'Current Month (10/2026)',
        cumulativePayable: 102300.0,
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
        advanceAmount: 15000.0,
        advanceDeduction: 15000.0,
        totalDeductions: 29500.0,
        netSalary: 75500.0,
        paymentStatus: 'PENDING',
        scheduledPayDate: '2026-10-31',
        bankAccountMask: 'SBI •••• 6304',
        pendingMonthsCount: 1,
        pendingMonthsDetails: 'Current Month (10/2026)',
        cumulativePayable: 75500.0,
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
        advanceAmount: 5000.0,
        advanceDeduction: 5000.0,
        totalDeductions: 16300.0,
        netSalary: 73700.0,
        paymentStatus: 'PENDING',
        scheduledPayDate: '2026-10-31',
        bankAccountMask: 'AXIS •••• 2190',
        pendingMonthsCount: 2,
        pendingMonthsDetails: '2 Months Pending (09/2026, 10/2026)',
        cumulativePayable: 152400.0,
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
        advanceAmount: 15000.0,
        advanceDeduction: 15000.0,
        totalDeductions: 30100.0,
        netSalary: 64900.0,
        paymentStatus: 'OVERDUE',
        scheduledPayDate: '2026-10-15',
        bankAccountMask: 'KOTAK •••• 7731',
        pendingMonthsCount: 3,
        pendingMonthsDetails: '3 Months Pending (08/2026, 09/2026, 10/2026)',
        cumulativePayable: 224700.0,
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
        advanceAmount: 0.0,
        advanceDeduction: 0.0,
        pendingMonthsCount: 1,
        pendingMonthsDetails: 'Current Month (10/2026)',
        cumulativePayable: 70000.0,
      ),
    ];
  }

  Future<List<Employee>> _fetchRealEmployees() async {
    try {
      final repo = EmployeeRepository(apiClient: _client);
      final list = await repo.list();
      return list;
    } catch (e) {
      debugPrint('PayrollRepository._fetchRealEmployees error: $e');
      return [];
    }
  }

  Future<List<Expense>> _fetchRealAdvances() async {
    try {
      final repo = ExpensesRepository(apiClient: _client);
      final list = await repo.list();
      return list.where((e) => e.isAdvance && !e.advanceSettled).toList();
    } catch (e) {
      debugPrint('PayrollRepository._fetchRealAdvances error: $e');
      return [];
    }
  }

  Future<List<PayrollRun>> _buildRunsFromRealEmployees() async {
    final emps = await _fetchRealEmployees();
    final now = DateTime.now();
    final curMonth = now.month;
    final curYear = now.year;

    double grossSum = 0;
    for (final emp in emps) {
      grossSum += emp.monthlySalary > 0 ? emp.monthlySalary : 25000.0;
    }

    if (grossSum <= 0 && emps.isEmpty) {
      return _generateDemoRuns();
    }

    final deductions = grossSum * 0.12;
    final netPayable = grossSum - deductions;

    return [
      PayrollRun(
        id: 1,
        companyId: 1,
        periodMonth: curMonth,
        periodYear: curYear,
        runTitle: 'Monthly Payroll Run - $curMonth/$curYear',
        status: 'REVIEWED',
        scheduledPayDate: '$curYear-${curMonth.toString().padLeft(2, '0')}-30',
        totalGross: grossSum,
        totalPaid: 0.0,
        totalPending: netPayable,
        totalOverdue: 0.0,
        totalDeductions: deductions,
        totalNetPayable: netPayable,
        employeeCount: emps.length,
      ),
    ];
  }

  List<PayrollEntry> _buildEntriesFromEmployees(
    List<Employee> employees,
    List<Expense> advances,
    int runId,
  ) {
    final entries = <PayrollEntry>[];
    for (int i = 0; i < employees.length; i++) {
      entries.add(_buildSingleEntryFromEmployee(employees[i], advances, runId, 101 + i));
    }
    return entries;
  }

  PayrollEntry _buildSingleEntryFromEmployee(
    Employee emp,
    List<Expense> advances,
    int runId,
    int generatedId,
  ) {
    final gross = emp.monthlySalary > 0 ? emp.monthlySalary : 25000.0;
    final basic = (gross * 0.50).roundToDouble();
    final hra = (gross * 0.30).roundToDouble();
    final allowances = gross - basic - hra;

    // Statutory PF, PT
    final pf = (basic.clamp(0, 15000) * 0.12).roundToDouble();
    final pt = 200.0;
    final statutory = pf + pt;

    // Sum unrecovered advances from Expenses for this employee
    double empAdvance = 0.0;
    for (final adv in advances) {
      final matchesId = adv.employeeId != null && adv.employeeId == emp.id;
      final matchesName = adv.employeeName != null &&
          adv.employeeName!.trim().toLowerCase() == emp.fullName.trim().toLowerCase();
      if (matchesId || matchesName) {
        empAdvance += adv.amount;
      }
    }

    final netBeforeAdvance = (gross - statutory).clamp(0.0, double.infinity);
    final advanceDeduction = empAdvance.clamp(0.0, netBeforeAdvance);
    final totalDeductions = statutory + advanceDeduction;
    final netSalary = (gross - totalDeductions).clamp(0.0, double.infinity);

    final bankMask = emp.bankAccountNumber.length > 4
        ? '${emp.bankName.isNotEmpty ? emp.bankName : "Bank"} •••• ${emp.bankAccountNumber.substring(emp.bankAccountNumber.length - 4)}'
        : 'Direct Bank NEFT';

    final now = DateTime.now();

    return PayrollEntry(
      id: emp.id != null ? (emp.id! + 100) : generatedId,
      companyId: emp.companyId ?? 1,
      employeeId: emp.id ?? generatedId,
      employeeName: emp.fullName,
      employeeCode: emp.employeeCode.isNotEmpty ? emp.employeeCode : 'EMP-${generatedId.toString().padLeft(3, '0')}',
      designation: emp.designation.isNotEmpty ? emp.designation : 'Staff Member',
      department: emp.department.isNotEmpty ? emp.department : 'Operations',
      workingDays: 30,
      paidDays: 30,
      basicPay: basic,
      hra: hra,
      allowances: allowances,
      grossEarnings: gross,
      pfEmployee: pf,
      esiEmployee: 0.0,
      professionalTax: pt,
      tdsTax: 0.0,
      otherDeductions: 0.0,
      advanceAmount: empAdvance,
      advanceDeduction: advanceDeduction,
      totalDeductions: totalDeductions,
      netSalary: netSalary,
      paymentStatus: 'PENDING',
      scheduledPayDate: '${now.year}-${now.month.toString().padLeft(2, '0')}-30',
      bankAccountMask: bankMask,
      pendingMonthsCount: 1,
      pendingMonthsDetails: 'Current Month (${now.month}/${now.year})',
      cumulativePayable: netSalary,
    );
  }
}
