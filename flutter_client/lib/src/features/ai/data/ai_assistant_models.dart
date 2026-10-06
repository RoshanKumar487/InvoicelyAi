class AiChatResponse {
  const AiChatResponse({
    required this.answer,
    required this.groundedSources,
    required this.readOnly,
    this.pendingCommandId,
    this.actionType,
    this.resourceType,
    this.resourceId,
  });

  final String answer;
  final List<String> groundedSources;
  final bool readOnly;
  final String? pendingCommandId;
  final String? actionType;
  final String? resourceType;
  final int? resourceId;

  factory AiChatResponse.fromJson(Map<String, dynamic> json) {
    final Object? sourcesValue = json['groundedSources'];
    final Object? readOnlyValue = json['readOnly'];
    final sources = <String>[];
    if (sourcesValue != null) {
      if (sourcesValue is! List<Object?>) {
        throw const FormatException('AI sources were not a list of strings.');
      }
      for (final Object? source in sourcesValue) {
        if (source is! String) {
          throw const FormatException('AI sources were not a list of strings.');
        }
        sources.add(source);
      }
    }
    if (readOnlyValue is! bool) {
      throw const FormatException('The AI response is missing a valid "readOnly" value.');
    }

    return AiChatResponse(
      answer: _requiredString(json, 'answer'),
      groundedSources: sources,
      readOnly: readOnlyValue,
      pendingCommandId: _optionalString(json, 'pendingCommandId'),
      actionType: _optionalString(json, 'actionType'),
      resourceType: _optionalString(json, 'resourceType'),
      resourceId: _optionalInt(json, 'resourceId'),
    );
  }
}

class AiInvoiceDraftResponse {
  const AiInvoiceDraftResponse({
    required this.message,
    this.invoice,
  });

  final String message;
  final AiInvoiceDraft? invoice;

  factory AiInvoiceDraftResponse.fromJson(Map<String, dynamic> json) {
    final Object? invoiceValue = json['invoice'];
    if (invoiceValue != null && invoiceValue is! Map<String, dynamic>) {
      throw const FormatException('The invoice draft was not an object.');
    }
    return AiInvoiceDraftResponse(
      message: _requiredString(json, 'message'),
      invoice: invoiceValue == null
          ? null
          : AiInvoiceDraft.fromJson(invoiceValue as Map<String, dynamic>),
    );
  }
}

class AiInvoiceDraft {
  const AiInvoiceDraft({
    required this.invoiceNumber,
    required this.clientName,
    required this.clientCompany,
    required this.issueDate,
    required this.dueDate,
    required this.currencyCode,
    required this.itemsJson,
    required this.notes,
    required this.terms,
    required this.status,
    required this.taxRate,
    required this.discountPercent,
    required this.shippingFee,
  });

  final String invoiceNumber;
  final String clientName;
  final String clientCompany;
  final String issueDate;
  final String dueDate;
  final String currencyCode;
  final String itemsJson;
  final String notes;
  final String terms;
  final String status;
  final double taxRate;
  final double discountPercent;
  final double shippingFee;

  factory AiInvoiceDraft.fromJson(Map<String, dynamic> json) {
    return AiInvoiceDraft(
      invoiceNumber: _stringOrDefault(json, 'invoiceNumber'),
      clientName: _stringOrDefault(json, 'clientName'),
      clientCompany: _stringOrDefault(json, 'clientCompany'),
      issueDate: _stringOrDefault(json, 'issueDate'),
      dueDate: _stringOrDefault(json, 'dueDate'),
      currencyCode: _stringOrDefault(json, 'currencyCode', fallback: 'USD'),
      itemsJson: _stringOrDefault(json, 'itemsJson', fallback: '[]'),
      notes: _stringOrDefault(json, 'notes'),
      terms: _stringOrDefault(json, 'terms'),
      status: _stringOrDefault(json, 'status', fallback: 'Draft'),
      taxRate: _doubleOrDefault(json, 'taxRate'),
      discountPercent: _doubleOrDefault(json, 'discountPercent'),
      shippingFee: _doubleOrDefault(json, 'shippingFee'),
    );
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value is! String) {
    throw FormatException('The AI response is missing a valid "$key" value.');
  }
  return value;
}

String? _optionalString(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value == null) return null;
  if (value is! String) {
    throw FormatException('The AI response contains an invalid "$key" value.');
  }
  return value;
}

String _stringOrDefault(
  Map<String, dynamic> json,
  String key, {
  String fallback = '',
}) {
  final Object? value = json[key];
  if (value == null) return fallback;
  if (value is! String) {
    throw FormatException('The invoice draft contains an invalid "$key" value.');
  }
  return value;
}

int? _optionalInt(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value == null) return null;
  if (value is! int) {
    throw FormatException('The AI response contains an invalid "$key" value.');
  }
  return value;
}

double _doubleOrDefault(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value == null) return 0;
  if (value is! num) {
    throw FormatException('The invoice draft contains an invalid "$key" value.');
  }
  return value.toDouble();
}
