class SummaryCardDto {
  const SummaryCardDto({
    required this.id,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String value;
  final String subtitle;
  final String icon;
  final String color;

  factory SummaryCardDto.fromJson(Map<String, dynamic> json) {
    return SummaryCardDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      value: json['value'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      icon: json['icon'] as String? ?? 'document',
      color: json['color'] as String? ?? 'burgundy',
    );
  }
}

class InsightCardDto {
  const InsightCardDto({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.actionType,
    required this.actionTarget,
  });

  final String title;
  final String message;
  final String actionLabel;
  final String actionType;
  final String actionTarget;

  factory InsightCardDto.fromJson(Map<String, dynamic> json) {
    return InsightCardDto(
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      actionLabel: json['actionLabel'] as String? ?? '',
      actionType: json['actionType'] as String? ?? '',
      actionTarget: json['actionTarget'] as String? ?? '',
    );
  }
}

class RecordCardDto {
  const RecordCardDto({
    required this.id,
    required this.recordType,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.status,
    required this.statusColor,
    required this.updatedAt,
  });

  final String id;
  final String recordType;
  final String title;
  final String subtitle;
  final String amount;
  final String status;
  final String statusColor;
  final String updatedAt;

  factory RecordCardDto.fromJson(Map<String, dynamic> json) {
    return RecordCardDto(
      id: json['id'] as String? ?? '',
      recordType: json['recordType'] as String? ?? 'INVOICE',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      amount: json['amount'] as String? ?? '',
      status: json['status'] as String? ?? '',
      statusColor: json['statusColor'] as String? ?? 'blue',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}

class AiChatResponse {
  const AiChatResponse({
    required this.answer,
    required this.groundedSources,
    required this.readOnly,
    this.pendingCommandId,
    this.actionType,
    this.resourceType,
    this.resourceId,
    this.summaryCards = const [],
    this.insightCard,
    this.recordCards = const [],
  });

  final String answer;
  final List<String> groundedSources;
  final bool readOnly;
  final String? pendingCommandId;
  final String? actionType;
  final String? resourceType;
  final int? resourceId;
  final List<SummaryCardDto> summaryCards;
  final InsightCardDto? insightCard;
  final List<RecordCardDto> recordCards;

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

    final summaryList = <SummaryCardDto>[];
    if (json['summaryCards'] is List) {
      for (final item in json['summaryCards'] as List) {
        if (item is Map<String, dynamic>) {
          summaryList.add(SummaryCardDto.fromJson(item));
        }
      }
    }

    InsightCardDto? insight;
    if (json['insightCard'] is Map<String, dynamic>) {
      insight = InsightCardDto.fromJson(json['insightCard'] as Map<String, dynamic>);
    }

    final recordsList = <RecordCardDto>[];
    if (json['recordCards'] is List) {
      for (final item in json['recordCards'] as List) {
        if (item is Map<String, dynamic>) {
          recordsList.add(RecordCardDto.fromJson(item));
        }
      }
    }

    return AiChatResponse(
      answer: _requiredString(json, 'answer'),
      groundedSources: sources,
      readOnly: readOnlyValue,
      pendingCommandId: _optionalString(json, 'pendingCommandId'),
      actionType: _optionalString(json, 'actionType'),
      resourceType: _optionalString(json, 'resourceType'),
      resourceId: _optionalInt(json, 'resourceId'),
      summaryCards: summaryList,
      insightCard: insight,
      recordCards: recordsList,
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
