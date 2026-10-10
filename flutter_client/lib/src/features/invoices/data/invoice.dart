import 'dart:convert';

class InvoiceItem {
  const InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.id = '',
    this.unit = 'pcs',
    this.dutyCount = 0,
    this.itemDetails = '',
    this.taxRate = 0,
    this.discountRate = 0,
  });

  final String id;
  final String description;
  final double quantity;
  final double unitPrice;
  final String unit;
  final double dutyCount;
  final String itemDetails;
  final double taxRate;
  final double discountRate;

  double get grossLineAmount => dutyCount > 0
      ? quantity * dutyCount * unitPrice
      : quantity * unitPrice;
  double get discountAmount => grossLineAmount * discountRate / 100;
  double get total => grossLineAmount - discountAmount;

  InvoiceItem copyWith({
    String? id,
    String? description,
    double? quantity,
    double? unitPrice,
    String? unit,
    double? dutyCount,
    String? itemDetails,
    double? taxRate,
    double? discountRate,
  }) =>
      InvoiceItem(
        id: id ?? this.id,
        description: description ?? this.description,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        unit: unit ?? this.unit,
        dutyCount: dutyCount ?? this.dutyCount,
        itemDetails: itemDetails ?? this.itemDetails,
        taxRate: taxRate ?? this.taxRate,
        discountRate: discountRate ?? this.discountRate,
      );

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
        id: _string(json['id']),
        description: _string(json['description']),
        quantity: _number(json['quantity'], fallback: 1),
        unitPrice: _number(json['unitPrice']),
        unit: _string(json['unit'], fallback: 'pcs'),
        dutyCount: _number(json['dutyCount'], fallback: 0),
        itemDetails: _string(json['itemDetails']),
        taxRate: _number(json['taxRate']),
        discountRate: _number(json['discountRate']),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'unit': unit,
        if (dutyCount > 0) 'dutyCount': dutyCount,
        if (itemDetails.isNotEmpty) 'itemDetails': itemDetails,
        'taxRate': taxRate,
        'discountRate': discountRate,
      };
}

class Invoice {
  const Invoice({
    this.id,
    required this.invoiceNumber,
    required this.clientName,
    required this.issueDate,
    required this.dueDate,
    this.clientId,
    this.clientCompany = '',
    this.clientEmail = '',
    this.clientPhone = '',
    this.clientAddress = '',
    this.clientTaxId = '',
    this.poNumber = '',
    this.paymentTerms = 'Net 30',
    this.currencyCode = 'INR',
    this.currencySymbol = '₹',
    this.items = const [],
    this.notes = '',
    this.terms = '',
    this.paymentInstructions = '',
    this.shippingDetailsJson = '{}',
    this.taxRate = 0,
    this.taxLabel = 'Tax',
    this.taxType = 'GST',
    this.isTaxInclusive = false,
    this.discountPercent = 0,
    this.discountAmount = 0,
    this.shippingFee = 0,
    this.additionalCharges = 0,
    this.roundOff = 0,
    this.amountPaid = 0,
    this.status = 'Draft',
    this.templateId = 'modern',
    this.createdAt,
    this.paidDate,
  });

  final int? id;
  final String invoiceNumber;
  final int? clientId;
  final String clientName;
  final String clientCompany;
  final String clientEmail;
  final String clientPhone;
  final String clientAddress;
  final String clientTaxId;
  final String issueDate;
  final String dueDate;
  final String poNumber;
  final String paymentTerms;
  final String currencyCode;
  final String currencySymbol;
  final List<InvoiceItem> items;
  final String notes;
  final String terms;
  final String paymentInstructions;
  final String shippingDetailsJson;
  final double taxRate;
  final String taxLabel;
  final String taxType;
  final bool isTaxInclusive;
  final double discountPercent;
  final double discountAmount;
  final double shippingFee;
  final double additionalCharges;
  final double roundOff;
  final double amountPaid;
  final String status;
  final String templateId;
  final int? createdAt;
  final int? paidDate;

  double get subtotal =>
      items.fold<double>(0, (sum, item) => sum + item.grossLineAmount);
  double get itemDiscount =>
      items.fold<double>(0, (sum, item) => sum + item.discountAmount);
  double get totalDiscount =>
      itemDiscount + (subtotal - itemDiscount) * discountPercent / 100 + discountAmount;
  double get taxableAmount =>
      (subtotal - totalDiscount).clamp(0, double.infinity).toDouble();
  double get taxAmount => isTaxInclusive
      ? taxableAmount - taxableAmount / (1 + taxRate / 100)
      : taxableAmount * taxRate / 100;
  double get total => (taxableAmount +
          (isTaxInclusive ? 0 : taxAmount) +
          shippingFee +
          additionalCharges +
          roundOff)
      .clamp(0, double.infinity)
      .toDouble();
  double get balanceDue =>
      (total - amountPaid).clamp(0, double.infinity).toDouble();

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final rawItems = json['itemsJson'];
    final items = <InvoiceItem>[];
    if (rawItems is String && rawItems.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawItems);
        if (decoded is List<dynamic>) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              items.add(InvoiceItem.fromJson(item));
            }
          }
        }
      } on FormatException {
        // Keep the record visible even if a legacy invoice has malformed item data.
      }
    } else if (rawItems is List<dynamic>) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          items.add(InvoiceItem.fromJson(item));
        }
      }
    }

    return Invoice(
      id: _integer(json['id']),
      invoiceNumber: _string(json['invoiceNumber']),
      clientId: _integer(json['clientId']),
      clientName: _string(json['clientName']),
      clientCompany: _string(json['clientCompany']),
      clientEmail: _string(json['clientEmail']),
      clientPhone: _string(json['clientPhone']),
      clientAddress: _string(json['clientAddress']),
      clientTaxId: _string(json['clientTaxId']),
      issueDate: _string(json['issueDate']),
      dueDate: _string(json['dueDate']),
      poNumber: _string(json['poNumber']),
      paymentTerms: _string(json['paymentTerms'], fallback: 'Net 30'),
      currencyCode: _string(json['currencyCode'], fallback: 'INR'),
      currencySymbol: _string(json['currencySymbol'], fallback: '₹'),
      items: items,
      notes: _string(json['notes']),
      terms: _string(json['terms']),
      paymentInstructions: _string(json['paymentInstructions']),
      shippingDetailsJson: _string(json['shippingDetailsJson'], fallback: '{}'),
      taxRate: _number(json['taxRate']),
      taxLabel: _string(json['taxLabel'], fallback: 'Tax'),
      taxType: _string(json['taxType'], fallback: 'GST'),
      isTaxInclusive: json['isTaxInclusive'] as bool? ?? false,
      discountPercent: _number(json['discountPercent']),
      discountAmount: _number(json['discountAmount']),
      shippingFee: _number(json['shippingFee']),
      additionalCharges: _number(json['additionalCharges']),
      roundOff: _number(json['roundOff']),
      amountPaid: _number(json['amountPaid']),
      status: _string(json['status'], fallback: 'Draft'),
      templateId: _string(json['templateId'], fallback: 'modern'),
      createdAt: _integer(json['createdAt']),
      paidDate: _integer(json['paidDate']),
    );
  }

  Map<String, Object?> toJson() => {
        if (id != null) 'id': id,
        'invoiceNumber': invoiceNumber,
        'clientId': clientId,
        'clientName': clientName,
        'clientCompany': clientCompany,
        'clientEmail': clientEmail,
        'clientPhone': clientPhone,
        'clientAddress': clientAddress,
        'clientTaxId': clientTaxId,
        'issueDate': issueDate,
        'dueDate': dueDate,
        'poNumber': poNumber,
        'paymentTerms': paymentTerms,
        'currencyCode': currencyCode,
        'currencySymbol': currencySymbol,
        'itemsJson': jsonEncode(items.map((item) => item.toJson()).toList()),
        'notes': notes,
        'terms': terms,
        'paymentInstructions': paymentInstructions,
        'shippingDetailsJson': shippingDetailsJson,
        'taxRate': taxRate,
        'taxLabel': taxLabel,
        'taxType': taxType,
        'isTaxInclusive': isTaxInclusive,
        'discountPercent': discountPercent,
        'discountAmount': discountAmount,
        'shippingFee': shippingFee,
        'additionalCharges': additionalCharges,
        'roundOff': roundOff,
        'amountPaid': amountPaid,
        'status': status,
        'templateId': templateId,
        if (createdAt != null) 'createdAt': createdAt,
        if (paidDate != null) 'paidDate': paidDate,
      };

  Invoice copyWith({
    int? id,
    String? invoiceNumber,
    int? clientId,
    String? clientName,
    String? clientCompany,
    String? clientEmail,
    String? clientPhone,
    String? clientAddress,
    String? clientTaxId,
    String? issueDate,
    String? dueDate,
    String? poNumber,
    String? paymentTerms,
    String? currencyCode,
    String? currencySymbol,
    List<InvoiceItem>? items,
    String? notes,
    String? terms,
    String? paymentInstructions,
    String? shippingDetailsJson,
    double? taxRate,
    String? taxLabel,
    String? taxType,
    bool? isTaxInclusive,
    double? discountPercent,
    double? discountAmount,
    double? shippingFee,
    double? additionalCharges,
    double? roundOff,
    double? amountPaid,
    String? status,
    String? templateId,
    int? createdAt,
    int? paidDate,
  }) =>
      Invoice(
        id: id ?? this.id,
        invoiceNumber: invoiceNumber ?? this.invoiceNumber,
        clientId: clientId ?? this.clientId,
        clientName: clientName ?? this.clientName,
        clientCompany: clientCompany ?? this.clientCompany,
        clientEmail: clientEmail ?? this.clientEmail,
        clientPhone: clientPhone ?? this.clientPhone,
        clientAddress: clientAddress ?? this.clientAddress,
        clientTaxId: clientTaxId ?? this.clientTaxId,
        issueDate: issueDate ?? this.issueDate,
        dueDate: dueDate ?? this.dueDate,
        poNumber: poNumber ?? this.poNumber,
        paymentTerms: paymentTerms ?? this.paymentTerms,
        currencyCode: currencyCode ?? this.currencyCode,
        currencySymbol: currencySymbol ?? this.currencySymbol,
        items: items ?? this.items,
        notes: notes ?? this.notes,
        terms: terms ?? this.terms,
        paymentInstructions: paymentInstructions ?? this.paymentInstructions,
        shippingDetailsJson: shippingDetailsJson ?? this.shippingDetailsJson,
        taxRate: taxRate ?? this.taxRate,
        taxLabel: taxLabel ?? this.taxLabel,
        taxType: taxType ?? this.taxType,
        isTaxInclusive: isTaxInclusive ?? this.isTaxInclusive,
        discountPercent: discountPercent ?? this.discountPercent,
        discountAmount: discountAmount ?? this.discountAmount,
        shippingFee: shippingFee ?? this.shippingFee,
        additionalCharges: additionalCharges ?? this.additionalCharges,
        roundOff: roundOff ?? this.roundOff,
        amountPaid: amountPaid ?? this.amountPaid,
        status: status ?? this.status,
        templateId: templateId ?? this.templateId,
        createdAt: createdAt ?? this.createdAt,
        paidDate: paidDate ?? this.paidDate,
      );
}

String currencySymbolFor(String? code) {
  if (code == null || code.isEmpty) return '₹';
  final normalized = code.toUpperCase().trim();
  switch (normalized) {
    case 'INR':
      return '₹';
    case 'USD':
      return r'$';
    case 'EUR':
      return '€';
    case 'GBP':
      return '£';
    case 'AED':
      return 'AED ';
    case 'CAD':
      return r'CA$';
    case 'AUD':
      return r'AU$';
    case 'SGD':
      return r'SG$';
    default:
      if (normalized.length <= 3 && !RegExp(r'^[A-Z]+$').hasMatch(normalized)) {
        return normalized;
      }
      return '₹';
  }
}

String _string(Object? value, {String fallback = ''}) =>
    value is String ? value : fallback;

double _number(Object? value, {double fallback = 0}) =>
    value is num ? value.toDouble() : fallback;

int? _integer(Object? value) => value is num ? value.toInt() : null;
