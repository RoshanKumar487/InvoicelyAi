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

  bool get isDue => status.trim().toUpperCase() == 'DUE' || status.trim().toUpperCase() == 'PENDING';

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: _asInt(json['id']),
      companyId: _asInt(json['companyId']),
      createdByUserId: _asInt(json['createdByUserId']),
      createdByUserName: json['createdByUserName'] as String?,
      title: _asString(json['title']),
      category: _asString(json['category'], fallback: 'General'),
      amount: _asDouble(json['amount']),
      currency: _asString(json['currency'], fallback: 'INR'),
      currencySymbol: _asString(json['currencySymbol'], fallback: '₹'),
      date: _asString(json['date']),
      vendor: _asString(json['vendor']),
      paymentMethod:
          _asString(json['paymentMethod'], fallback: 'Credit Card'),
      taxDeductible: json['taxDeductible'] is bool
          ? json['taxDeductible'] as bool
          : true,
      taxAmount: _asDouble(json['taxAmount']),
      receiptImageUri: json['receiptImageUri'] as String?,
      notes: _asString(json['notes']),
      status: _asString(json['status'], fallback: 'Paid'),
      dueDate: _asString(json['dueDate'] ?? json['due_date']),
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
