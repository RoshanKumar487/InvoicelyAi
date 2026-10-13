import 'package:flutter/material.dart';

/// Represents a batch monthly payroll processing run.
class PayrollRun {
  const PayrollRun({
    required this.id,
    required this.companyId,
    required this.periodMonth,
    required this.periodYear,
    required this.runTitle,
    this.status = 'DRAFT',
    this.scheduledPayDate,
    this.totalGross = 0.0,
    this.totalPaid = 0.0,
    this.totalPending = 0.0,
    this.totalOverdue = 0.0,
    this.totalDeductions = 0.0,
    this.totalNetPayable = 0.0,
    this.employeeCount = 0,
    this.entries = const [],
  });

  final int id;
  final int companyId;
  final int periodMonth;
  final int periodYear;
  final String runTitle;
  final String status;
  final String? scheduledPayDate;
  final double totalGross;
  final double totalPaid;
  final double totalPending;
  final double totalOverdue;
  final double totalDeductions;
  final double totalNetPayable;
  final int employeeCount;
  final List<PayrollEntry> entries;

  String get periodLabel {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final m = (periodMonth >= 1 && periodMonth <= 12) ? months[periodMonth] : 'Month $periodMonth';
    return '$m $periodYear';
  }

  factory PayrollRun.fromJson(Map<String, dynamic> json) {
    return PayrollRun(
      id: _parseInt(json['id']),
      companyId: _parseInt(json['companyId']),
      periodMonth: _parseInt(json['periodMonth'], fallback: 1),
      periodYear: _parseInt(json['periodYear'], fallback: 2026),
      runTitle: json['runTitle']?.toString() ?? '',
      status: json['status']?.toString() ?? 'DRAFT',
      scheduledPayDate: json['scheduledPayDate']?.toString(),
      totalGross: _parseDouble(json['totalGross']),
      totalPaid: _parseDouble(json['totalPaid']),
      totalPending: _parseDouble(json['totalPending']),
      totalOverdue: _parseDouble(json['totalOverdue']),
      totalDeductions: _parseDouble(json['totalDeductions']),
      totalNetPayable: _parseDouble(json['totalNetPayable']),
      employeeCount: _parseInt(json['employeeCount']),
      entries: (json['entries'] as List<dynamic>?)
              ?.map((e) => PayrollEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'periodMonth': periodMonth,
        'periodYear': periodYear,
        'runTitle': runTitle,
        'status': status,
        'scheduledPayDate': scheduledPayDate,
        'totalGross': totalGross,
        'totalPaid': totalPaid,
        'totalPending': totalPending,
        'totalOverdue': totalOverdue,
        'totalDeductions': totalDeductions,
        'totalNetPayable': totalNetPayable,
        'employeeCount': employeeCount,
        'entries': entries.map((e) => e.toJson()).toList(),
      };
}

/// An individual employee's salary record within a payroll run.
class PayrollEntry {
  const PayrollEntry({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.employeeName,
    this.employeeCode = '',
    this.designation = '',
    this.department = '',
    this.workingDays = 30,
    this.paidDays = 30.0,
    this.basicPay = 0.0,
    this.hra = 0.0,
    this.allowances = 0.0,
    this.grossEarnings = 0.0,
    this.pfEmployee = 0.0,
    this.esiEmployee = 0.0,
    this.professionalTax = 0.0,
    this.tdsTax = 0.0,
    this.otherDeductions = 0.0,
    this.totalDeductions = 0.0,
    this.netSalary = 0.0,
    this.paymentStatus = 'PENDING',
    this.scheduledPayDate,
    this.disbursedAt,
    this.bankAccountMask = '',
  });

  final int id;
  final int companyId;
  final int employeeId;
  final String employeeName;
  final String employeeCode;
  final String designation;
  final String department;
  final int workingDays;
  final double paidDays;
  final double basicPay;
  final double hra;
  final double allowances;
  final double grossEarnings;
  final double pfEmployee;
  final double esiEmployee;
  final double professionalTax;
  final double tdsTax;
  final double otherDeductions;
  final double totalDeductions;
  final double netSalary;
  final String paymentStatus;
  final String? scheduledPayDate;
  final String? disbursedAt;
  final String bankAccountMask;

  bool get isPaid => paymentStatus.toUpperCase() == 'PAID';
  bool get isPending => paymentStatus.toUpperCase() == 'PENDING';
  bool get isOverdue => paymentStatus.toUpperCase() == 'OVERDUE';
  bool get isOnHold => paymentStatus.toUpperCase() == 'ON_HOLD';

  Color get statusColor {
    switch (paymentStatus.toUpperCase()) {
      case 'PAID':
        return const Color(0xFF16A34A);
      case 'OVERDUE':
        return const Color(0xFFDC2626);
      case 'ON_HOLD':
        return const Color(0xFF64748B);
      case 'PENDING':
      default:
        return const Color(0xFFD97706);
    }
  }

  Color get statusBackgroundColor {
    switch (paymentStatus.toUpperCase()) {
      case 'PAID':
        return const Color(0xFFDCFCE7);
      case 'OVERDUE':
        return const Color(0xFFFEE2E2);
      case 'ON_HOLD':
        return const Color(0xFFF1F5F9);
      case 'PENDING':
      default:
        return const Color(0xFFFEF3C7);
    }
  }

  factory PayrollEntry.fromJson(Map<String, dynamic> json) {
    return PayrollEntry(
      id: _parseInt(json['id']),
      companyId: _parseInt(json['companyId']),
      employeeId: _parseInt(json['employeeId']),
      employeeName: json['employeeName']?.toString() ?? 'Unnamed Employee',
      employeeCode: json['employeeCode']?.toString() ?? '',
      designation: json['designation']?.toString() ?? 'Staff',
      department: json['department']?.toString() ?? 'General',
      workingDays: _parseInt(json['workingDays'], fallback: 30),
      paidDays: _parseDouble(json['paidDays'], fallback: 30.0),
      basicPay: _parseDouble(json['basicPay']),
      hra: _parseDouble(json['hra']),
      allowances: _parseDouble(json['allowances']),
      grossEarnings: _parseDouble(json['grossEarnings']),
      pfEmployee: _parseDouble(json['pfEmployee']),
      esiEmployee: _parseDouble(json['esiEmployee']),
      professionalTax: _parseDouble(json['professionalTax']),
      tdsTax: _parseDouble(json['tdsTax']),
      otherDeductions: _parseDouble(json['otherDeductions']),
      totalDeductions: _parseDouble(json['totalDeductions']),
      netSalary: _parseDouble(json['netSalary']),
      paymentStatus: json['paymentStatus']?.toString() ?? 'PENDING',
      scheduledPayDate: json['scheduledPayDate']?.toString(),
      disbursedAt: json['disbursedAt']?.toString(),
      bankAccountMask: json['bankAccountMask']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'employeeCode': employeeCode,
        'designation': designation,
        'department': department,
        'workingDays': workingDays,
        'paidDays': paidDays,
        'basicPay': basicPay,
        'hra': hra,
        'allowances': allowances,
        'grossEarnings': grossEarnings,
        'pfEmployee': pfEmployee,
        'esiEmployee': esiEmployee,
        'professionalTax': professionalTax,
        'tdsTax': tdsTax,
        'otherDeductions': otherDeductions,
        'totalDeductions': totalDeductions,
        'netSalary': netSalary,
        'paymentStatus': paymentStatus,
        'scheduledPayDate': scheduledPayDate,
        'disbursedAt': disbursedAt,
        'bankAccountMask': bankAccountMask,
      };

  PayrollEntry copyWith({
    String? paymentStatus,
    String? disbursedAt,
    double? grossEarnings,
    double? totalDeductions,
    double? netSalary,
  }) {
    return PayrollEntry(
      id: id,
      companyId: companyId,
      employeeId: employeeId,
      employeeName: employeeName,
      employeeCode: employeeCode,
      designation: designation,
      department: department,
      workingDays: workingDays,
      paidDays: paidDays,
      basicPay: basicPay,
      hra: hra,
      allowances: allowances,
      grossEarnings: grossEarnings ?? this.grossEarnings,
      pfEmployee: pfEmployee,
      esiEmployee: esiEmployee,
      professionalTax: professionalTax,
      tdsTax: tdsTax,
      otherDeductions: otherDeductions,
      totalDeductions: totalDeductions ?? this.totalDeductions,
      netSalary: netSalary ?? this.netSalary,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      scheduledPayDate: scheduledPayDate,
      disbursedAt: disbursedAt ?? this.disbursedAt,
      bankAccountMask: bankAccountMask,
    );
  }
}

/// 4 KPI Metrics matching invoice cards on top of payroll.
class PayrollSummaryKpi {
  const PayrollSummaryKpi({
    this.totalGross = 0.0,
    this.totalPaid = 0.0,
    this.totalPending = 0.0,
    this.totalOverdue = 0.0,
    this.totalEmployees = 0,
    this.pendingCount = 0,
    this.paidCount = 0,
    this.overdueCount = 0,
  });

  final double totalGross;
  final double totalPaid;
  final double totalPending;
  final double totalOverdue;
  final int totalEmployees;
  final int pendingCount;
  final int paidCount;
  final int overdueCount;

  factory PayrollSummaryKpi.fromJson(Map<String, dynamic> json) {
    return PayrollSummaryKpi(
      totalGross: _parseDouble(json['totalGross']),
      totalPaid: _parseDouble(json['totalPaid']),
      totalPending: _parseDouble(json['totalPending']),
      totalOverdue: _parseDouble(json['totalOverdue']),
      totalEmployees: _parseInt(json['totalEmployees']),
      pendingCount: _parseInt(json['pendingCount']),
      paidCount: _parseInt(json['paidCount']),
      overdueCount: _parseInt(json['overdueCount']),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalGross': totalGross,
        'totalPaid': totalPaid,
        'totalPending': totalPending,
        'totalOverdue': totalOverdue,
        'totalEmployees': totalEmployees,
        'pendingCount': pendingCount,
        'paidCount': paidCount,
        'overdueCount': overdueCount,
      };
}

int _parseInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double _parseDouble(dynamic value, {double fallback = 0.0}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}
