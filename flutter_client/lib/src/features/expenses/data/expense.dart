class Expense {
  const Expense({
    this.id,
    this.companyId,
    this.createdByUserId,
    this.createdByUserName,
    required this.title,
    this.category = 'General',
    this.amount = 0,
    this.currency = 'INR',
    this.currencySymbol = '₹',
    this.date = '',
    this.vendor = '',
    this.paymentMethod = 'Credit Card',
    this.taxDeductible = true,
    this.taxAmount = 0,
    this.receiptImageUri,
    this.notes = '',
    this.status = 'Paid',
    this.dueDate = '',
    this.employeeId,
    this.employeeName,
    this.isSalaryAdvance = false,
    this.advanceSettled = false,
    this.settledPayrollRunId,
  });

  final int? id;
  final int? companyId;
  final int? createdByUserId;
  final String? createdByUserName;
  final String title;
  final String category;
  final double amount;
  final String currency;
  final String currencySymbol;
  final String date;
  final String vendor;
  final String paymentMethod;
  final bool taxDeductible;
  final double taxAmount;
  final String? receiptImageUri;
  final String notes;
  final String status;
  final String dueDate;
  final int? employeeId;
  final String? employeeName;
  final bool isSalaryAdvance;
  final bool advanceSettled;
  final int? settledPayrollRunId;

  bool get isDue => status.trim().toUpperCase() == 'DUE' || status.trim().toUpperCase() == 'PENDING';
  bool get isAdvance => isSalaryAdvance || category.toLowerCase().contains('advance') || (employeeName != null && employeeName!.isNotEmpty);

  factory Expense.fromJson(Map<String, dynamic> json) {
    final cat = _asString(json['category'], fallback: 'General');
    final isAdv = json['isSalaryAdvance'] == true ||
        json['is_salary_advance'] == true ||
        cat.toLowerCase().contains('advance');
    return Expense(
      id: _asInt(json['id']),
      companyId: _asInt(json['companyId'] ?? json['company_id']),
      createdByUserId: _asInt(json['createdByUserId'] ?? json['created_by_user_id']),
      createdByUserName: (json['createdByUserName'] ?? json['created_by_user_name']) as String?,
      title: _asString(json['title']),
      category: cat,
      amount: _asDouble(json['amount']),
      currency: _asString(json['currency'], fallback: 'INR'),
      currencySymbol: _asString(json['currencySymbol'] ?? json['currency_symbol'], fallback: '₹'),
      date: _asString(json['date']),
      vendor: _asString(json['vendor']),
      paymentMethod:
          _asString(json['paymentMethod'] ?? json['payment_method'], fallback: 'Credit Card'),
      taxDeductible: json['taxDeductible'] is bool
          ? json['taxDeductible'] as bool
          : (json['tax_deductible'] is bool ? json['tax_deductible'] as bool : true),
      taxAmount: _asDouble(json['taxAmount'] ?? json['tax_amount']),
      receiptImageUri: (json['receiptImageUri'] ?? json['receipt_image_uri']) as String?,
      notes: _asString(json['notes']),
      status: _asString(json['status'], fallback: 'Paid'),
      dueDate: _asString(json['dueDate'] ?? json['due_date']),
      employeeId: _asInt(json['employeeId'] ?? json['employee_id']),
      employeeName: (json['employeeName'] ?? json['employee_name']) as String?,
      isSalaryAdvance: isAdv,
      advanceSettled: json['advanceSettled'] == true || json['advance_settled'] == true,
      settledPayrollRunId: _asInt(json['settledPayrollRunId'] ?? json['settled_payroll_run_id']),
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'companyId': companyId,
        'createdByUserId': createdByUserId,
        'createdByUserName': createdByUserName,
        'title': title,
        'category': category,
        'amount': amount,
        'currency': currency,
        'currencySymbol': currencySymbol,
        'date': date,
        'vendor': vendor,
        'paymentMethod': paymentMethod,
        'taxDeductible': taxDeductible,
        'taxAmount': taxAmount,
        'receiptImageUri': receiptImageUri,
        'notes': notes,
        'status': status,
        'dueDate': dueDate,
        'employeeId': employeeId,
        'employeeName': employeeName,
        'isSalaryAdvance': isSalaryAdvance,
        'advanceSettled': advanceSettled,
        'settledPayrollRunId': settledPayrollRunId,
      };
}

int? _asInt(Object? value) => value is num ? value.toInt() : null;

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

String _asString(Object? value, {String fallback = ''}) =>
    value is String ? value : fallback;
