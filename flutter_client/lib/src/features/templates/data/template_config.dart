import 'dart:convert';

class TemplateConfig {
  const TemplateConfig({
    required this.id,
    required this.name,
    required this.title,
    required this.category,
    required this.color,
    required this.font,
    required this.itemHeader,
    this.secondaryColor = '#0D9488',
    this.quantityHeader = 'Qty',
    this.rateHeader = 'Rate',
    this.amountHeader = 'Amount',
    this.showLogo = true,
    this.showBillFrom = true,
    this.showBillTo = true,
    this.showBankDetails = true,
    this.showShipping = false,
    this.showNotes = true,
    this.showTerms = true,
    this.headerLayout = 'modern',
    this.tableStyle = 'clean',
    this.showTaxBreakdown = true,
    this.showPaymentInstructions = true,
    this.showSignature = true,
    this.footer =
        'This is a computer generated invoice and does not require physical signature unless specified.',
  });

  final String id;
  final String name;
  final String title;
  final String category;
  final String color;
  final String font;
  final String itemHeader;
  final String secondaryColor;
  final String quantityHeader;
  final String rateHeader;
  final String amountHeader;
  final bool showLogo;
  final bool showBillFrom;
  final bool showBillTo;
  final bool showBankDetails;
  final bool showShipping;
  final bool showNotes;
  final bool showTerms;
  final String headerLayout;
  final String tableStyle;
  final bool showTaxBreakdown;
  final bool showPaymentInstructions;
  final bool showSignature;
  final String footer;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'title': title,
        'category': category,
        'color': color,
        'font': font,
        'itemHeader': itemHeader,
        'secondaryColor': secondaryColor,
        'quantityHeader': quantityHeader,
        'rateHeader': rateHeader,
        'amountHeader': amountHeader,
        'showLogo': showLogo,
        'showBillFrom': showBillFrom,
        'showBillTo': showBillTo,
        'showBankDetails': showBankDetails,
        'showShipping': showShipping,
        'showNotes': showNotes,
        'showTerms': showTerms,
        'headerLayout': headerLayout,
        'tableStyle': tableStyle,
        'showTaxBreakdown': showTaxBreakdown,
        'showPaymentInstructions': showPaymentInstructions,
        'showSignature': showSignature,
        'footer': footer,
      };

  String encode() => jsonEncode(toJson());

  factory TemplateConfig.fromJson(Map<String, dynamic> json) => TemplateConfig(
        id: _requiredString(json, 'id'),
        name: _requiredString(json, 'name'),
        title: _requiredString(json, 'title'),
        category: _requiredString(json, 'category'),
        color: _requiredString(json, 'color'),
        font: _requiredString(json, 'font'),
        itemHeader: _requiredString(json, 'itemHeader'),
        secondaryColor: json['secondaryColor'] as String? ?? '#0D9488',
        quantityHeader: json['quantityHeader'] as String? ?? 'Qty',
        rateHeader: json['rateHeader'] as String? ?? 'Rate',
        amountHeader: json['amountHeader'] as String? ?? 'Amount',
        showLogo: json['showLogo'] as bool? ?? true,
        showBillFrom: json['showBillFrom'] as bool? ?? true,
        showBillTo: json['showBillTo'] as bool? ?? true,
        showBankDetails: json['showBankDetails'] as bool? ?? true,
        showShipping: json['showShipping'] as bool? ?? false,
        showNotes: json['showNotes'] as bool? ?? true,
        showTerms: json['showTerms'] as bool? ?? true,
        headerLayout: json['headerLayout'] as String? ?? 'modern',
        tableStyle: json['tableStyle'] as String? ?? 'clean',
        showTaxBreakdown: json['showTaxBreakdown'] as bool? ?? true,
        showPaymentInstructions:
            json['showPaymentInstructions'] as bool? ?? true,
        showSignature: json['showSignature'] as bool? ?? true,
        footer: json['footer'] as String? ??
            'This is a computer generated invoice and does not require physical signature unless specified.',
      );

  static TemplateConfig? tryDecode(String? value) {
    if (value == null) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return TemplateConfig.fromJson(decoded);
    } on FormatException {
      return null;
    }
    return null;
  }

  TemplateConfig copyWith({
    String? id,
    String? name,
    String? title,
    String? category,
    String? color,
    String? font,
    String? itemHeader,
    String? secondaryColor,
    String? quantityHeader,
    String? rateHeader,
    String? amountHeader,
    bool? showLogo,
    bool? showBillFrom,
    bool? showBillTo,
    bool? showBankDetails,
    bool? showShipping,
    bool? showNotes,
    bool? showTerms,
    String? headerLayout,
    String? tableStyle,
    bool? showTaxBreakdown,
    bool? showPaymentInstructions,
    bool? showSignature,
    String? footer,
  }) =>
      TemplateConfig(
        id: id ?? this.id,
        name: name ?? this.name,
        title: title ?? this.title,
        category: category ?? this.category,
        color: color ?? this.color,
        font: font ?? this.font,
        itemHeader: itemHeader ?? this.itemHeader,
        secondaryColor: secondaryColor ?? this.secondaryColor,
        quantityHeader: quantityHeader ?? this.quantityHeader,
        rateHeader: rateHeader ?? this.rateHeader,
        amountHeader: amountHeader ?? this.amountHeader,
        showLogo: showLogo ?? this.showLogo,
        showBillFrom: showBillFrom ?? this.showBillFrom,
        showBillTo: showBillTo ?? this.showBillTo,
        showBankDetails: showBankDetails ?? this.showBankDetails,
        showShipping: showShipping ?? this.showShipping,
        showNotes: showNotes ?? this.showNotes,
        showTerms: showTerms ?? this.showTerms,
        headerLayout: headerLayout ?? this.headerLayout,
        tableStyle: tableStyle ?? this.tableStyle,
        showTaxBreakdown: showTaxBreakdown ?? this.showTaxBreakdown,
        showPaymentInstructions:
            showPaymentInstructions ?? this.showPaymentInstructions,
        showSignature: showSignature ?? this.showSignature,
        footer: footer ?? this.footer,
      );
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Saved template is missing "$key".');
  }
  return value;
}

const templatePresets = <TemplateConfig>[
  TemplateConfig(
    id: 'gst_tax',
    name: 'GST Standard Tax Invoice',
    title: 'TAX INVOICE',
    category: 'Indian Biz',
    color: '#1E3A8A',
    font: 'Calibri',
    itemHeader: 'Description of Goods / Services',
  ),
  TemplateConfig(
    id: 'zoho_elegance',
    name: 'Zoho Invoice Clean',
    title: 'INVOICE',
    category: 'Zoho Style',
    color: '#0284C7',
    font: 'Arial',
    itemHeader: 'Item & Description',
  ),
  TemplateConfig(
    id: 'vyapar_classic',
    name: 'Vyapar / Tally Boxed',
    title: 'TAX INVOICE / BILL OF SUPPLY',
    category: 'Indian Biz',
    color: '#0F766E',
    font: 'Times New Roman',
    itemHeader: 'Particulars / Item Name',
  ),
  TemplateConfig(
    id: 'modern',
    name: 'Modern Minimalist',
    title: 'INVOICE',
    category: 'Modern',
    color: '#2563EB',
    font: 'Calibri',
    itemHeader: 'Description / Service',
  ),
  TemplateConfig(
    id: 'corporate',
    name: 'Corporate Executive',
    title: 'COMMERCIAL INVOICE',
    category: 'Corporate',
    color: '#0F172A',
    font: 'Arial',
    itemHeader: 'Item & Scope of Work',
  ),
  TemplateConfig(
    id: 'creative',
    name: 'Creative Studio & Agency',
    title: 'CREATIVE INVOICE',
    category: 'Creative',
    color: '#4F46E5',
    font: 'Calibri',
    itemHeader: 'Project Deliverable',
  ),
  TemplateConfig(
    id: 'it_consulting',
    name: 'IT & Tech Consulting',
    title: 'SERVICES & SPRINT INVOICE',
    category: 'Services',
    color: '#0891B2',
    font: 'Consolas',
    itemHeader: 'Sprint / Task Description',
  ),
  TemplateConfig(
    id: 'retail_wholesale',
    name: 'Retail & Wholesale Traders',
    title: 'RETAIL INVOICE',
    category: 'Indian Biz',
    color: '#DC2626',
    font: 'Arial',
    itemHeader: 'Item / SKU Details',
  ),
  TemplateConfig(
    id: 'luxury_enterprise',
    name: 'Luxury Enterprise & Legal',
    title: 'STATEMENT OF ACCOUNT',
    category: 'Executive',
    color: '#78350F',
    font: 'Times New Roman',
    itemHeader: 'Matter / Professional Service',
  ),
  TemplateConfig(
    id: 'healthcare_prof',
    name: 'Healthcare & Professional',
    title: 'PROFESSIONAL FEE BILL',
    category: 'Professional',
    color: '#059669',
    font: 'Calibri',
    itemHeader: 'Service / Consultation / Procedure',
  ),
  TemplateConfig(
    id: 'minimalist',
    name: 'Clean Minimalist Letterhead',
    title: 'INVOICE',
    category: 'Minimalist',
    color: '#1E293B',
    font: 'Calibri',
    itemHeader: 'Description / Service',
  ),
  TemplateConfig(
    id: 'classic_letterhead',
    name: 'Classic Formal Business Letterhead',
    title: 'TAX INVOICE & STATEMENT OF ACCOUNT',
    category: 'Formal',
    color: '#0F172A',
    font: 'Times New Roman',
    itemHeader: 'Particulars / Service Scope',
  ),
  TemplateConfig(
    id: 'tech_clean',
    name: 'Tech & SaaS Modern Strip Letterhead',
    title: 'SERVICES & DELIVERABLES INVOICE',
    category: 'Technology',
    color: '#2563EB',
    font: 'Consolas',
    itemHeader: 'Sprint / Architecture Deliverable',
  ),
  TemplateConfig(
    id: 'compact_ledger',
    name: 'Compact Ledger / Retail Bill',
    title: 'RETAIL INVOICE',
    category: 'Retail',
    color: '#0F172A',
    font: 'Arial',
    itemHeader: 'Item / Barcode',
  ),
  TemplateConfig(
    id: 'ecommerce',
    name: 'E-Commerce Dispatch Letterhead',
    title: 'ORDER TAX INVOICE',
    category: 'E-Commerce',
    color: '#1E3A8A',
    font: 'Calibri',
    itemHeader: 'Product Details',
  ),
  TemplateConfig(
    id: 'healthcare',
    name: 'Healthcare & Clinic Letterhead',
    title: 'MEDICAL CONSULTATION & FEE BILL',
    category: 'Healthcare',
    color: '#0D9488',
    font: 'Calibri',
    itemHeader: 'Procedure / Consultation',
  ),
];
