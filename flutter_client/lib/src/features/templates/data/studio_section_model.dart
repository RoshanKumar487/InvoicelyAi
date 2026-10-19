import 'package:flutter/material.dart';

enum StudioFieldType {
  text('Text', Icons.text_fields_rounded),
  date('Date', Icons.calendar_today_rounded),
  number('Number', Icons.tag_rounded),
  currency('Currency', Icons.currency_rupee_rounded),
  dropdown('Dropdown', Icons.arrow_drop_down_circle_outlined),
  checkbox('Checkbox', Icons.check_box_outlined),
  multiline('Multiline', Icons.notes_rounded),
  email('Email', Icons.email_outlined),
  phone('Phone', Icons.phone_outlined);

  const StudioFieldType(this.label, this.icon);
  final String label;
  final IconData icon;

  static StudioFieldType fromString(String val) {
    for (final t in values) {
      if (t.name.toLowerCase() == val.toLowerCase() || t.label.toLowerCase() == val.toLowerCase()) {
        return t;
      }
    }
    return StudioFieldType.text;
  }
}

class StudioField {
  StudioField({
    required this.id,
    required this.label,
    this.type = StudioFieldType.text,
    this.isRequired = false,
    this.isVisible = true,
    this.defaultValue = '',
    this.placeholder = '',
    this.options = const [],
    this.isSystem = false,
    this.formula = '',
  });

  final String id;
  String label;
  StudioFieldType type;
  bool isRequired;
  bool isVisible;
  String defaultValue;
  String placeholder;
  List<String> options;
  bool isSystem;
  String formula;

  StudioField copyWith({
    String? id,
    String? label,
    StudioFieldType? type,
    bool? isRequired,
    bool? isVisible,
    String? defaultValue,
    String? placeholder,
    List<String>? options,
    bool? isSystem,
    String? formula,
  }) {
    return StudioField(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      isRequired: isRequired ?? this.isRequired,
      isVisible: isVisible ?? this.isVisible,
      defaultValue: defaultValue ?? this.defaultValue,
      placeholder: placeholder ?? this.placeholder,
      options: options ?? List.from(this.options),
      isSystem: isSystem ?? this.isSystem,
      formula: formula ?? this.formula,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'type': type.name,
        'isRequired': isRequired,
        'isVisible': isVisible,
        'defaultValue': defaultValue,
        'placeholder': placeholder,
        'options': options,
        'isSystem': isSystem,
        'formula': formula,
      };

  factory StudioField.fromJson(Map<String, dynamic> json) {
    return StudioField(
      id: json['id']?.toString() ?? 'fld_${DateTime.now().microsecondsSinceEpoch}',
      label: json['label']?.toString() ?? 'Field',
      type: StudioFieldType.fromString(json['type']?.toString() ?? 'text'),
      isRequired: json['isRequired'] == true,
      isVisible: json['isVisible'] != false,
      defaultValue: json['defaultValue']?.toString() ?? '',
      placeholder: json['placeholder']?.toString() ?? '',
      options: (json['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      isSystem: json['isSystem'] == true,
      formula: json['formula']?.toString() ?? '',
    );
  }
}

class StudioSection {
  StudioSection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.enabled = true,
    this.isExpanded = false,
    this.isLocked = false,
    List<StudioField>? fields,
  }) : fields = fields ?? [];

  final String id;
  String title;
  String subtitle;
  IconData icon;
  bool enabled;
  bool isExpanded;
  bool isLocked;
  List<StudioField> fields;

  int get totalFieldCount => fields.length;
  int get visibleFieldCount => fields.where((f) => f.isVisible).length;

  StudioSection copyWith({
    String? id,
    String? title,
    String? subtitle,
    IconData? icon,
    bool? enabled,
    bool? isExpanded,
    bool? isLocked,
    List<StudioField>? fields,
  }) {
    return StudioSection(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      enabled: enabled ?? this.enabled,
      isExpanded: isExpanded ?? this.isExpanded,
      isLocked: isLocked ?? this.isLocked,
      fields: fields ?? this.fields.map((f) => f.copyWith()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'enabled': enabled,
        'isExpanded': isExpanded,
        'isLocked': isLocked,
        'fields': fields.map((f) => f.toJson()).toList(),
      };

  factory StudioSection.fromJson(Map<String, dynamic> json) {
    return StudioSection(
      id: json['id']?.toString() ?? 'sec_${DateTime.now().microsecondsSinceEpoch}',
      title: json['title']?.toString() ?? 'Section',
      subtitle: json['subtitle']?.toString() ?? '',
      icon: _iconForSection(json['id']?.toString()),
      enabled: json['enabled'] != false,
      isExpanded: json['isExpanded'] == true,
      isLocked: json['isLocked'] == true,
      fields: (json['fields'] as List<dynamic>?)
              ?.map((f) => StudioField.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static IconData _iconForSection(String? id) {
    return switch (id) {
      'sec_branding' => Icons.business_outlined,
      'sec_identity' => Icons.description_outlined,
      'sec_client' => Icons.person_outline_rounded,
      'sec_services' => Icons.shield_outlined,
      'sec_tax_totals' => Icons.percent_rounded,
      'sec_bank' => Icons.account_balance_outlined,
      'sec_terms' => Icons.draw_outlined,
      _ => Icons.widgets_outlined,
    };
  }

  /// Builds the default canonical sections matching the screenshot
  static List<StudioSection> defaultSections({String preset = 'security_agency'}) {
    return [
      // 1. Business & Branding
      StudioSection(
        id: 'sec_branding',
        title: 'Business & Branding',
        subtitle: 'Company details, logo, colors and branding elements',
        icon: Icons.business_outlined,
        enabled: true,
        fields: [
          StudioField(id: 'f_biz_name', label: 'Company Name', type: StudioFieldType.text, isRequired: true, isVisible: true, defaultValue: 'Northstar Security Services Ltd.'),
          StudioField(id: 'f_biz_tagline', label: 'Tagline', type: StudioFieldType.text, isRequired: false, isVisible: true, defaultValue: 'Safe People | Secure Tomorrow'),
          StudioField(id: 'f_biz_logo', label: 'Company Logo', type: StudioFieldType.text, isRequired: false, isVisible: true),
          StudioField(id: 'f_biz_addr', label: 'Office Address', type: StudioFieldType.multiline, isRequired: true, isVisible: true, defaultValue: '#12, 3rd Floor, Green Park, Bengaluru, Karnataka - 560076'),
          StudioField(id: 'f_biz_gstin', label: 'GSTIN', type: StudioFieldType.text, isRequired: true, isVisible: true, defaultValue: '29ABCDE1234F1Z5'),
          StudioField(id: 'f_biz_pan', label: 'PAN Number', type: StudioFieldType.text, isRequired: false, isVisible: true, defaultValue: 'ABCDE1234F'),
        ],
      ),

      // 2. Document Identity (Collapsed by default)
      StudioSection(
        id: 'sec_identity',
        title: 'Document Identity',
        subtitle: 'Invoice title, number, dates and reference details',
        icon: Icons.description_outlined,
        enabled: true,
        isExpanded: false,
        fields: [
          StudioField(id: 'f_doc_number', label: 'Invoice Number', type: StudioFieldType.text, isRequired: true, isVisible: true, defaultValue: 'INV-2025-0148'),
          StudioField(id: 'f_doc_issue', label: 'Issue Date', type: StudioFieldType.date, isRequired: true, isVisible: true, defaultValue: '15 Apr 2025'),
          StudioField(id: 'f_doc_due', label: 'Due Date', type: StudioFieldType.date, isRequired: false, isVisible: true, defaultValue: '30 Apr 2025'),
          StudioField(id: 'f_doc_po', label: 'Purchase Order No.', type: StudioFieldType.text, isRequired: false, isVisible: false, defaultValue: 'PO-4587/2025'),
        ],
      ),

      // 3. Client Details
      StudioSection(
        id: 'sec_client',
        title: 'Client Details',
        subtitle: 'Client name, address, GSTIN and contact info',
        icon: Icons.person_outline_rounded,
        enabled: true,
        fields: [
          StudioField(id: 'f_cli_name', label: 'Client / Company Name', type: StudioFieldType.text, isRequired: true, isVisible: true, defaultValue: 'ABC Industries Pvt. Ltd.'),
          StudioField(id: 'f_cli_addr', label: 'Billing Address', type: StudioFieldType.multiline, isRequired: true, isVisible: true, defaultValue: '101, Business Tower, MG Road, Bengaluru, Karnataka - 560001'),
          StudioField(id: 'f_cli_gstin', label: 'Client GSTIN', type: StudioFieldType.text, isRequired: true, isVisible: true, defaultValue: '29ABCA1234B1Z2'),
          StudioField(id: 'f_cli_contact', label: 'Contact Person', type: StudioFieldType.text, isRequired: false, isVisible: true, defaultValue: 'Mr. Rahul Sharma'),
          StudioField(id: 'f_cli_phone', label: 'Contact Phone', type: StudioFieldType.phone, isRequired: false, isVisible: true, defaultValue: '+91 98800 11223'),
        ],
      ),

      // 4. Services & Duty
      StudioSection(
        id: 'sec_services',
        title: switch (preset) {
          'creative_vibrant' || 'creative' => 'Campaign & Creative Deliverables',
          'construction_contractor' || 'construction' => 'BOQ Items & Labor Shifts',
          'healthcare_clinic' || 'healthcare' => 'Medical & Consultation Services',
          'logistics_freight' || 'logistics' => 'Consignment & Freight Particulars',
          'legal_counsel' || 'legal' => 'Case Matter & Legal Counsel',
          'hospitality_catering' || 'hospitality' => 'Catering & Event Services',
          _ => 'Services & Duty',
        },
        subtitle: switch (preset) {
          'creative_vibrant' || 'creative' => 'Asset milestones, revisions and deliverables',
          'construction_contractor' || 'construction' => 'Material supply, BOQ measurement and shifts',
          'healthcare_clinic' || 'healthcare' => 'Doctor consultations, diagnostics and tests',
          'logistics_freight' || 'logistics' => 'LR consignment, cargo weight and vehicle transit',
          'legal_counsel' || 'legal' => 'Legal advice, retainer and court appearances',
          'hospitality_catering' || 'hospitality' => 'Pax count, menu selections and venue service',
          _ => 'Guard details, duty days, shifts and service location',
        },
        icon: Icons.shield_outlined,
        enabled: true,
        fields: [
          StudioField(id: 'f_srv_loc', label: 'Service Location / Venue', type: StudioFieldType.text, isRequired: true, isVisible: true, defaultValue: 'Tech Park, Whitefield, Bengaluru, Karnataka - 560066'),
          StudioField(id: 'f_srv_period', label: 'Billing Period', type: StudioFieldType.text, isRequired: true, isVisible: true, defaultValue: '01 Apr 2025 - 30 Apr 2025 (30 Days)'),
          StudioField(
            id: 'f_col_particulars',
            label: 'Particulars Column',
            type: StudioFieldType.text,
            isRequired: true,
            isVisible: true,
            defaultValue: switch (preset) {
              'creative_vibrant' || 'creative' => 'Deliverable / Campaign Asset',
              'construction_contractor' || 'construction' => 'BOQ Item / Work Scope',
              'healthcare_clinic' || 'healthcare' => 'Medical Consultation / Treatment',
              'logistics_freight' || 'logistics' => 'Consignment / Cargo Particulars',
              'legal_counsel' || 'legal' => 'Case Matter / Advisory Scope',
              'hospitality_catering' || 'hospitality' => 'Event Menu / Hospitality Package',
              _ => 'Particulars',
            },
          ),
          StudioField(
            id: 'f_col_guards',
            label: 'Qty / Headcount Column',
            type: StudioFieldType.number,
            isRequired: true,
            isVisible: true,
            defaultValue: switch (preset) {
              'security_agency' => 'Guards',
              'construction_contractor' || 'construction' => 'Measurement / Qty',
              'healthcare_clinic' || 'healthcare' => 'Visits / Count',
              'logistics_freight' || 'logistics' => 'Trips / Consignments',
              'hospitality_catering' || 'hospitality' => 'Guests / Pax',
              _ => 'Qty',
            },
          ),
          StudioField(id: 'f_col_duty', label: 'Duty / Shifts Column', type: StudioFieldType.number, isRequired: true, isVisible: true, defaultValue: 'Duty'),
          StudioField(id: 'f_col_rate', label: 'Rate Column', type: StudioFieldType.currency, isRequired: true, isVisible: true, defaultValue: 'Rate (₹)', formula: 'Monthly Rate ÷ Month Days'),
          StudioField(id: 'f_col_amount', label: 'Total Column', type: StudioFieldType.currency, isRequired: true, isVisible: true, defaultValue: 'Total (₹)', formula: '(Monthly Rate ÷ 30) × Qty × Duty'),
          StudioField(id: 'f_srv_shift', label: 'Shift Hours Breakdown', type: StudioFieldType.text, isRequired: false, isVisible: false, defaultValue: '12-Hour Shift'),
        ],
      ),

      // 5. Tax & Totals
      StudioSection(
        id: 'sec_tax_totals',
        title: 'Tax & Totals (Subtotal & GST)',
        subtitle: 'Automatic daily wage subtotal, discounts, GST and grand total',
        icon: Icons.percent_rounded,
        enabled: true,
        fields: [
          StudioField(id: 'f_tot_sub', label: 'Taxable Subtotal', type: StudioFieldType.currency, isRequired: true, isVisible: true, formula: 'SUM((Rate ÷ MonthDays) × Qty × Duty)'),
          StudioField(id: 'f_tot_disc', label: 'Special Discount', type: StudioFieldType.currency, isRequired: false, isVisible: true),
          StudioField(id: 'f_tot_taxable', label: 'Net Taxable Amount', type: StudioFieldType.currency, isRequired: true, isVisible: true, formula: 'Subtotal - Discount'),
          StudioField(id: 'f_tot_cgst', label: 'CGST (9%)', type: StudioFieldType.currency, isRequired: true, isVisible: true, formula: 'Taxable × 9%'),
          StudioField(id: 'f_tot_sgst', label: 'SGST (9%)', type: StudioFieldType.currency, isRequired: true, isVisible: true, formula: 'Taxable × 9%'),
          StudioField(id: 'f_tot_grand', label: 'Grand Total Payable', type: StudioFieldType.currency, isRequired: true, isVisible: true, formula: 'Taxable + CGST + SGST'),
        ],
      ),

      // 6. Bank & Payment
      StudioSection(
        id: 'sec_bank',
        title: 'Bank & Payment',
        subtitle: 'Bank details, payment terms and QR code',
        icon: Icons.account_balance_outlined,
        enabled: true,
        fields: [
          StudioField(id: 'f_bnk_name', label: 'Bank Name', type: StudioFieldType.text, isRequired: true, isVisible: true, defaultValue: 'INDFC Bank'),
          StudioField(id: 'f_bnk_ac', label: 'Account Number', type: StudioFieldType.text, isRequired: true, isVisible: true, defaultValue: '50200012345678'),
          StudioField(id: 'f_bnk_ifsc', label: 'IFSC Code', type: StudioFieldType.text, isRequired: true, isVisible: true, defaultValue: 'HDFC0001234'),
          StudioField(id: 'f_bnk_upi', label: 'UPI ID', type: StudioFieldType.text, isRequired: false, isVisible: true, defaultValue: 'northstar@hdfcbank'),
          StudioField(id: 'f_bnk_qr', label: 'UPI Scan & Pay QR', type: StudioFieldType.checkbox, isRequired: false, isVisible: true),
        ],
      ),

      // 7. Terms & Signature
      StudioSection(
        id: 'sec_terms',
        title: 'Terms & Signature',
        subtitle: 'Terms, notes, signatory and company stamp',
        icon: Icons.draw_outlined,
        enabled: true,
        fields: [
          StudioField(id: 'f_trm_lines', label: 'Contractual Terms', type: StudioFieldType.multiline, isRequired: true, isVisible: true, defaultValue: '1. Payment due within 15 days from the date of invoice.\n2. Late payment attracts 18% annual interest.\n3. Security personnel are deployed as per the agreed schedule.\n4. Any dispute must be reported within 7 days of service completion.'),
          StudioField(id: 'f_trm_company', label: 'Authorized Company Signee', type: StudioFieldType.text, isRequired: true, isVisible: true, defaultValue: 'For Northstar Security Services Ltd.'),
          StudioField(id: 'f_trm_title', label: 'Designation Title', type: StudioFieldType.text, isRequired: true, isVisible: true, defaultValue: 'Authorized Signatory'),
          StudioField(id: 'f_trm_auto_stamp', label: 'Computer Generated Disclaimer', type: StudioFieldType.text, isRequired: false, isVisible: false, defaultValue: 'This is a system generated invoice'),
        ],
      ),
    ];
  }
}
