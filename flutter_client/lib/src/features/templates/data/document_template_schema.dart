import 'dart:convert';
import 'package:flutter/material.dart';

/// Supported paper sizes with dimensions in standard points (72 points/inch).
enum TemplatePageSize {
  a4('A4', 595.28, 841.89, 760.0, 1075.0),
  letter('US Letter', 612.0, 792.0, 780.0, 1010.0);

  const TemplatePageSize(
    this.label,
    this.pdfWidth,
    this.pdfHeight,
    this.previewWidth,
    this.previewHeight,
  );

  final String label;
  final double pdfWidth;
  final double pdfHeight;
  final double previewWidth;
  final double previewHeight;

  static TemplatePageSize fromString(String val) {
    if (val.toLowerCase() == 'letter') return TemplatePageSize.letter;
    return TemplatePageSize.a4;
  }
}

/// Overflow handling policy.
enum OverflowPolicy {
  paginate('paginate', 'Paginate across pages with repeated header'),
  scaleFont('scale_font', 'Auto-scale font size slightly'),
  truncate('truncate', 'Truncate with show more in preview');

  const OverflowPolicy(this.key, this.label);
  final String key;
  final String label;

  static OverflowPolicy fromString(String val) {
    switch (val.toLowerCase()) {
      case 'scale_font':
        return OverflowPolicy.scaleFont;
      case 'truncate':
        return OverflowPolicy.truncate;
      case 'paginate':
      default:
        return OverflowPolicy.paginate;
    }
  }
}

/// Signature positioning mode.
enum SignatureMode {
  fixedBottom('bottom', 'Fixed at page bottom (reserves height)'),
  inline('inline', 'Inline directly below totals'),
  floating('floating', 'Draggable floating stamp');

  const SignatureMode(this.key, this.label);
  final String key;
  final String label;

  static SignatureMode fromString(String val) {
    switch (val.toLowerCase()) {
      case 'inline':
        return SignatureMode.inline;
      case 'floating':
        return SignatureMode.floating;
      case 'bottom':
      default:
        return SignatureMode.fixedBottom;
    }
  }
}

/// Metadata describing the template.
class TemplateMetadata {
  const TemplateMetadata({
    required this.id,
    required this.name,
    this.category = 'Modern Enterprise',
    this.pageSize = TemplatePageSize.a4,
    this.orientation = 'portrait',
    this.marginTop = 24.0,
    this.marginRight = 20.0,
    this.marginBottom = 24.0,
    this.marginLeft = 20.0,
  });

  final String id;
  final String name;
  final String category;
  final TemplatePageSize pageSize;
  final String orientation;
  final double marginTop;
  final double marginRight;
  final double marginBottom;
  final double marginLeft;

  double get horizontalMargins => marginLeft + marginRight;
  double get verticalMargins => marginTop + marginBottom;

  factory TemplateMetadata.fromJson(Map<String, dynamic> json) {
    final margins = json['margins'] as Map<String, dynamic>? ?? {};
    return TemplateMetadata(
      id: json['id']?.toString() ?? 'custom_template',
      name: json['name']?.toString() ?? 'Custom Template',
      category: json['category']?.toString() ?? 'Modern Enterprise',
      pageSize: TemplatePageSize.fromString(json['pageSize']?.toString() ?? 'a4'),
      orientation: json['orientation']?.toString() ?? 'portrait',
      marginTop: _asDouble(margins['top'], 24.0),
      marginRight: _asDouble(margins['right'], 20.0),
      marginBottom: _asDouble(margins['bottom'], 24.0),
      marginLeft: _asDouble(margins['left'], 20.0),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'pageSize': pageSize.name,
        'orientation': orientation,
        'margins': {
          'top': marginTop,
          'right': marginRight,
          'bottom': marginBottom,
          'left': marginLeft,
        },
      };

  TemplateMetadata copyWith({
    String? name,
    TemplatePageSize? pageSize,
    double? marginTop,
    double? marginRight,
    double? marginBottom,
    double? marginLeft,
  }) {
    return TemplateMetadata(
      id: id,
      name: name ?? this.name,
      category: category,
      pageSize: pageSize ?? this.pageSize,
      orientation: orientation,
      marginTop: marginTop ?? this.marginTop,
      marginRight: marginRight ?? this.marginRight,
      marginBottom: marginBottom ?? this.marginBottom,
      marginLeft: marginLeft ?? this.marginLeft,
    );
  }
}

/// Visual style tokens for typography and color palette.
class TemplateStyle {
  const TemplateStyle({
    this.fontFamily = 'Inter',
    this.baseSize = 11.0,
    this.headingSize = 18.0,
    this.lineHeight = 1.35,
    this.primaryColor = '#1E3A8A',
    this.secondaryColor = '#0D9488',
    this.accentColor = '#F59E0B',
    this.surfaceColor = '#FFFFFF',
    this.borderColor = '#E2E8F0',
    this.zebraColor = '#F8FAFC',
    this.borderRadius = 6.0,
  });

  final String fontFamily;
  final double baseSize;
  final double headingSize;
  final double lineHeight;
  final String primaryColor;
  final String secondaryColor;
  final String accentColor;
  final String surfaceColor;
  final String borderColor;
  final String zebraColor;
  final double borderRadius;

  Color get primaryFlutterColor => _parseColor(primaryColor, const Color(0xFF1E3A8A));
  Color get secondaryFlutterColor => _parseColor(secondaryColor, const Color(0xFF0D9488));
  Color get accentFlutterColor => _parseColor(accentColor, const Color(0xFFF59E0B));
  Color get borderFlutterColor => _parseColor(borderColor, const Color(0xFFE2E8F0));
  Color get zebraFlutterColor => _parseColor(zebraColor, const Color(0xFFF8FAFC));

  factory TemplateStyle.fromJson(Map<String, dynamic> json) {
    return TemplateStyle(
      fontFamily: json['fontFamily']?.toString() ?? 'Inter',
      baseSize: _asDouble(json['baseSize'], 11.0),
      headingSize: _asDouble(json['headingSize'], 18.0),
      lineHeight: _asDouble(json['lineHeight'], 1.35),
      primaryColor: json['primaryColor']?.toString() ?? '#1E3A8A',
      secondaryColor: json['secondaryColor']?.toString() ?? '#0D9488',
      accentColor: json['accentColor']?.toString() ?? '#F59E0B',
      surfaceColor: json['surfaceColor']?.toString() ?? '#FFFFFF',
      borderColor: json['borderColor']?.toString() ?? '#E2E8F0',
      zebraColor: json['zebraColor']?.toString() ?? '#F8FAFC',
      borderRadius: _asDouble(json['borderRadius'], 6.0),
    );
  }

  Map<String, dynamic> toJson() => {
        'fontFamily': fontFamily,
        'baseSize': baseSize,
        'headingSize': headingSize,
        'lineHeight': lineHeight,
        'primaryColor': primaryColor,
        'secondaryColor': secondaryColor,
        'accentColor': accentColor,
        'surfaceColor': surfaceColor,
        'borderColor': borderColor,
        'zebraColor': zebraColor,
        'borderRadius': borderRadius,
      };

  TemplateStyle copyWith({
    String? fontFamily,
    double? baseSize,
    double? headingSize,
    String? primaryColor,
    String? secondaryColor,
    String? accentColor,
  }) {
    return TemplateStyle(
      fontFamily: fontFamily ?? this.fontFamily,
      baseSize: baseSize ?? this.baseSize,
      headingSize: headingSize ?? this.headingSize,
      lineHeight: lineHeight,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      surfaceColor: surfaceColor,
      borderColor: borderColor,
      zebraColor: zebraColor,
      borderRadius: borderRadius,
    );
  }
}

/// Column definition for item table with priority collapsing.
class TemplateColumnConfig {
  const TemplateColumnConfig({
    required this.key,
    required this.label,
    this.width = 'auto', // 'auto', 'flex', or numeric points/px e.g. '80'
    this.priority = 1, // 1: never drop, 2: drop on tight width, 3: drop on mobile
    this.align = 'left', // 'left', 'center', 'right'
    this.minWidth = 50.0,
  });

  final String key;
  final String label;
  final String width;
  final int priority;
  final String align;
  final double minWidth;

  bool get isFlex => width == 'flex';
  bool get isAuto => width == 'auto';
  double? get fixedWidth => double.tryParse(width);

  factory TemplateColumnConfig.fromJson(Map<String, dynamic> json) {
    return TemplateColumnConfig(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      width: json['width']?.toString() ?? 'auto',
      priority: (json['priority'] as num?)?.toInt() ?? 1,
      align: json['align']?.toString() ?? 'left',
      minWidth: _asDouble(json['minWidth'], 50.0),
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'width': width,
        'priority': priority,
        'align': align,
        'minWidth': minWidth,
      };

  TemplateColumnConfig copyWith({
    String? label,
    String? width,
    int? priority,
    String? align,
  }) {
    return TemplateColumnConfig(
      key: key,
      label: label ?? this.label,
      width: width ?? this.width,
      priority: priority ?? this.priority,
      align: align ?? this.align,
      minWidth: minWidth,
    );
  }
}

/// Configuration for sections.
class TemplateSectionConfig {
  const TemplateSectionConfig({
    this.columns = const [],
    this.rowMinHeight = 22.0,
    this.repeatHeader = true,
    this.stripedRows = true,
    this.showBorders = true,
    this.logoMaxWidth = 140.0,
    this.logoMaxHeight = 65.0,
    this.companyBlockAlign = 'left',
    this.totalsAlign = 'right',
    this.keepWithPrevious = true,
    this.signatureMode = SignatureMode.fixedBottom,
    this.signatureHeight = 72.0,
    this.signatureLabel = 'Authorized Signatory',
    this.signeeTitle = 'Director / Partner',
    this.requireReservation = true,
    this.qrSize = 85.0,
    this.showQr = true,
    this.extra = const {},
  });

  // Table config
  final List<TemplateColumnConfig> columns;
  final double rowMinHeight;
  final bool repeatHeader;
  final bool stripedRows;
  final bool showBorders;

  // Header config
  final double logoMaxWidth;
  final double logoMaxHeight;
  final String companyBlockAlign;

  // Totals config
  final String totalsAlign;
  final bool keepWithPrevious;

  // Signature config
  final SignatureMode signatureMode;
  final double signatureHeight;
  final String signatureLabel;
  final String signeeTitle;
  final bool requireReservation;

  // Bank & QR config
  final double qrSize;
  final bool showQr;

  final Map<String, dynamic> extra;

  factory TemplateSectionConfig.fromJson(Map<String, dynamic> json) {
    return TemplateSectionConfig(
      columns: (json['columns'] as List<dynamic>?)
              ?.map((c) => TemplateColumnConfig.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
      rowMinHeight: _asDouble(json['rowMinHeight'], 22.0),
      repeatHeader: json['repeatHeader'] != false,
      stripedRows: json['stripedRows'] != false,
      showBorders: json['showBorders'] != false,
      logoMaxWidth: _asDouble(json['logoMaxWidth'], 140.0),
      logoMaxHeight: _asDouble(json['logoMaxHeight'], 65.0),
      companyBlockAlign: json['companyBlockAlign']?.toString() ?? 'left',
      totalsAlign: json['totalsAlign']?.toString() ?? 'right',
      keepWithPrevious: json['keepWithPrevious'] != false,
      signatureMode: SignatureMode.fromString(json['signatureMode']?.toString() ?? 'bottom'),
      signatureHeight: _asDouble(json['signatureHeight'], 72.0),
      signatureLabel: json['signatureLabel']?.toString() ?? 'Authorized Signatory',
      signeeTitle: json['signeeTitle']?.toString() ?? 'Director / Partner',
      requireReservation: json['requireReservation'] != false,
      qrSize: _asDouble(json['qrSize'], 85.0),
      showQr: json['showQr'] != false,
      extra: json['extra'] as Map<String, dynamic>? ?? const {},
    );
  }

  Map<String, dynamic> toJson() => {
        if (columns.isNotEmpty) 'columns': columns.map((c) => c.toJson()).toList(),
        'rowMinHeight': rowMinHeight,
        'repeatHeader': repeatHeader,
        'stripedRows': stripedRows,
        'showBorders': showBorders,
        'logoMaxWidth': logoMaxWidth,
        'logoMaxHeight': logoMaxHeight,
        'companyBlockAlign': companyBlockAlign,
        'totalsAlign': totalsAlign,
        'keepWithPrevious': keepWithPrevious,
        'signatureMode': signatureMode.key,
        'signatureHeight': signatureHeight,
        'signatureLabel': signatureLabel,
        'signeeTitle': signeeTitle,
        'requireReservation': requireReservation,
        'qrSize': qrSize,
        'showQr': showQr,
        'extra': extra,
      };

  TemplateSectionConfig copyWith({
    List<TemplateColumnConfig>? columns,
    bool? repeatHeader,
    bool? stripedRows,
    SignatureMode? signatureMode,
    double? signatureHeight,
    String? signatureLabel,
  }) {
    return TemplateSectionConfig(
      columns: columns ?? this.columns,
      rowMinHeight: rowMinHeight,
      repeatHeader: repeatHeader ?? this.repeatHeader,
      stripedRows: stripedRows ?? this.stripedRows,
      showBorders: showBorders,
      logoMaxWidth: logoMaxWidth,
      logoMaxHeight: logoMaxHeight,
      companyBlockAlign: companyBlockAlign,
      totalsAlign: totalsAlign,
      keepWithPrevious: keepWithPrevious,
      signatureMode: signatureMode ?? this.signatureMode,
      signatureHeight: signatureHeight ?? this.signatureHeight,
      signatureLabel: signatureLabel ?? this.signatureLabel,
      signeeTitle: signeeTitle,
      requireReservation: requireReservation,
      qrSize: qrSize,
      showQr: showQr,
      extra: extra,
    );
  }
}

/// An individual section in the template pipeline.
class TemplateSection {
  const TemplateSection({
    required this.id,
    required this.type, // 'header', 'party_details', 'item_table', 'totals', 'notes_terms', 'bank_qr', 'signature', 'footer'
    this.isEnabled = true,
    this.config = const TemplateSectionConfig(),
  });

  final String id;
  final String type;
  final bool isEnabled;
  final TemplateSectionConfig config;

  factory TemplateSection.fromJson(Map<String, dynamic> json) {
    return TemplateSection(
      id: json['id']?.toString() ?? json['type']?.toString() ?? 'section',
      type: json['type']?.toString() ?? 'custom',
      isEnabled: json['isEnabled'] != false,
      config: TemplateSectionConfig.fromJson(
        json['config'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'isEnabled': isEnabled,
        'config': config.toJson(),
      };

  TemplateSection copyWith({
    bool? isEnabled,
    TemplateSectionConfig? config,
  }) {
    return TemplateSection(
      id: id,
      type: type,
      isEnabled: isEnabled ?? this.isEnabled,
      config: config ?? this.config,
    );
  }
}

/// Canonical Document Template Schema. Single source of truth.
class DocumentTemplateSchema {
  const DocumentTemplateSchema({
    required this.metadata,
    this.style = const TemplateStyle(),
    this.sections = const [],
    this.overflowPolicy = OverflowPolicy.paginate,
    this.columnPriorityDropping = true,
    this.minItemRowsPerPage = 3,
  });

  final TemplateMetadata metadata;
  final TemplateStyle style;
  final List<TemplateSection> sections;
  final OverflowPolicy overflowPolicy;
  final bool columnPriorityDropping;
  final int minItemRowsPerPage;

  TemplateSection? sectionOfType(String type) {
    try {
      return sections.firstWhere((s) => s.type == type && s.isEnabled);
    } catch (_) {
      return null;
    }
  }

  factory DocumentTemplateSchema.fromJson(Map<String, dynamic> json) {
    return DocumentTemplateSchema(
      metadata: TemplateMetadata.fromJson(
        json['metadata'] as Map<String, dynamic>? ?? json,
      ),
      style: TemplateStyle.fromJson(
        json['style'] as Map<String, dynamic>? ?? const {},
      ),
      sections: (json['sections'] as List<dynamic>?)
              ?.map((s) => TemplateSection.fromJson(s as Map<String, dynamic>))
              .toList() ??
          _defaultSections(),
      overflowPolicy: OverflowPolicy.fromString(
        json['overflowPolicy']?.toString() ?? json['rules']?['overflowPolicy']?.toString() ?? 'paginate',
      ),
      columnPriorityDropping: json['columnPriorityDropping'] != false,
      minItemRowsPerPage: (json['minItemRowsPerPage'] as num?)?.toInt() ?? 3,
    );
  }

  Map<String, dynamic> toJson() => {
        'metadata': metadata.toJson(),
        'style': style.toJson(),
        'overflowPolicy': overflowPolicy.key,
        'columnPriorityDropping': columnPriorityDropping,
        'minItemRowsPerPage': minItemRowsPerPage,
        'sections': sections.map((s) => s.toJson()).toList(),
      };

  String encode() => jsonEncode(toJson());

  static DocumentTemplateSchema decode(String jsonStr) {
    return DocumentTemplateSchema.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }

  factory DocumentTemplateSchema.fromSettings({
    required Map<String, Object?> localSettings,
    String? templateId,
    String? templateName,
    String? businessCategory,
    String? defaultColor,
    String? defaultSecondaryColor,
  }) {
    final primaryHex = localSettings['brandColorHex']?.toString().trim().isNotEmpty == true
        ? localSettings['brandColorHex']!.toString().trim()
        : (defaultColor ?? '#1E3A8A');
    final secondaryHex = localSettings['secondaryColorHex']?.toString().trim().isNotEmpty == true
        ? localSettings['secondaryColorHex']!.toString().trim()
        : (defaultSecondaryColor ?? '#0D9488');

    final tableStyle = localSettings['tableStyle']?.toString() ?? 'boxed';
    final baseFont = (localSettings['baseFontSize'] as num?)?.toDouble() ?? 10.5;
    final fontFamily = localSettings['fontFamily']?.toString() ?? 'Inter';
    final density = localSettings['tableDensity']?.toString() ?? 'normal';
    final rowHeight = density == 'compact' ? 18.0 : (density == 'spacious' ? 28.0 : 22.0);

    final isSecurity = businessCategory == 'Security Agency' ||
        localSettings['industryPresetId'] == 'security_agency' ||
        localSettings['industryPresetId'] == 'security';

    final cols = <TemplateColumnConfig>[];

    if (localSettings['showItemNumber'] == true) {
      cols.add(const TemplateColumnConfig(
        key: '#',
        label: '#',
        width: '32',
        priority: 1,
        align: 'center',
      ));
    }

    final itemLabel = localSettings['customItemHeader']?.toString().trim().isNotEmpty == true
        ? localSettings['customItemHeader']!.toString().trim()
        : (isSecurity ? 'Particulars' : 'Item & Description');
    cols.add(TemplateColumnConfig(
      key: 'item',
      label: itemLabel,
      width: 'flex',
      priority: 1,
      align: 'left',
    ));

    if (localSettings['showItemQty'] != false) {
      final qtyLabel = localSettings['customQtyHeader']?.toString().trim().isNotEmpty == true
          ? localSettings['customQtyHeader']!.toString().trim()
          : 'Qty.';
      cols.add(TemplateColumnConfig(
        key: 'qty',
        label: qtyLabel,
        width: '45',
        priority: 2,
        align: 'center',
      ));
    }

    final showDuty = localSettings['showItemDuty'] == true || (isSecurity && localSettings['showItemDuty'] != false);
    if (showDuty) {
      final dutyLabel = localSettings['customDutyHeader']?.toString().trim().isNotEmpty == true
          ? localSettings['customDutyHeader']!.toString().trim()
          : 'Duty';
      cols.add(TemplateColumnConfig(
        key: 'duty',
        label: dutyLabel,
        width: '65',
        priority: 2,
        align: 'center',
      ));
    }

    final rawCustom = localSettings['customColumns_items'];
    if (rawCustom is List) {
      for (final c in rawCustom) {
        if (c is Map && c['isVisible'] != false) {
          cols.add(TemplateColumnConfig(
            key: c['id']?.toString() ?? c['label']?.toString().toLowerCase() ?? 'custom',
            label: c['label']?.toString() ?? 'Field',
            width: '70',
            priority: 2,
            align: 'center',
          ));
        }
      }
    }

    if (localSettings['showItemUnit'] == true) {
      final unitLabel = localSettings['customUnitHeader']?.toString().trim().isNotEmpty == true
          ? localSettings['customUnitHeader']!.toString().trim()
          : 'Unit';
      cols.add(TemplateColumnConfig(
        key: 'unit',
        label: unitLabel,
        width: '50',
        priority: 3,
        align: 'center',
      ));
    }

    if (localSettings['showItemTax'] == true) {
      cols.add(const TemplateColumnConfig(
        key: 'hsn',
        label: 'HSN/SAC',
        width: '65',
        priority: 3,
        align: 'center',
      ));
    }

    if (localSettings['showItemRate'] != false) {
      final rateLabel = localSettings['customRateHeader']?.toString().trim().isNotEmpty == true
          ? localSettings['customRateHeader']!.toString().trim()
          : 'Rate';
      cols.add(TemplateColumnConfig(
        key: 'rate',
        label: rateLabel,
        width: '85',
        priority: 2,
        align: 'right',
      ));
    }

    if (localSettings['showItemDiscount'] == true) {
      cols.add(const TemplateColumnConfig(
        key: 'discount',
        label: 'Disc %',
        width: '50',
        priority: 3,
        align: 'center',
      ));
    }

    final amountLabel = localSettings['customAmountHeader']?.toString().trim().isNotEmpty == true
        ? localSettings['customAmountHeader']!.toString().trim()
        : 'Amount';
    cols.add(TemplateColumnConfig(
      key: 'amount',
      label: amountLabel,
      width: '95',
      priority: 1,
      align: 'right',
    ));

    final sections = [
      TemplateSection(
        id: 'sec_header',
        type: 'header',
        isEnabled: localSettings['showDocumentTitle'] != false,
        config: const TemplateSectionConfig(
          logoMaxWidth: 140,
          logoMaxHeight: 65,
          companyBlockAlign: 'left',
        ),
      ),
      TemplateSection(
        id: 'sec_party',
        type: 'party_details',
        isEnabled: localSettings['showBillFrom'] != false ||
            localSettings['showBillTo'] != false ||
            localSettings['showShippingSection'] == true,
      ),
      TemplateSection(
        id: 'sec_items',
        type: 'item_table',
        isEnabled: true,
        config: TemplateSectionConfig(
          columns: cols,
          rowMinHeight: rowHeight,
          stripedRows: tableStyle != 'clean',
          showBorders: tableStyle == 'boxed',
          repeatHeader: true,
        ),
      ),
      const TemplateSection(
        id: 'sec_totals',
        type: 'totals',
        isEnabled: true,
        config: TemplateSectionConfig(totalsAlign: 'right', keepWithPrevious: true),
      ),
      TemplateSection(
        id: 'sec_bank_qr',
        type: 'bank_qr',
        isEnabled: localSettings['showBankDetails'] != false || localSettings['showQrCode'] != false,
        config: TemplateSectionConfig(
          showQr: localSettings['showQrCode'] != false,
          qrSize: 85,
        ),
      ),
      TemplateSection(
        id: 'sec_notes',
        type: 'notes_terms',
        isEnabled: localSettings['showNotes'] != false ||
            localSettings['showTerms'] != false ||
            localSettings['showPaymentInstructions'] != false,
      ),
      TemplateSection(
        id: 'sec_sign',
        type: 'signature',
        isEnabled: localSettings['showSignature'] != false,
        config: TemplateSectionConfig(
          signatureMode: SignatureMode.fixedBottom,
          signatureHeight: 70,
          signatureLabel: localSettings['signeeTitle']?.toString().trim().isNotEmpty == true
              ? localSettings['signeeTitle']!.toString().trim()
              : 'Authorized Signatory',
        ),
      ),
      const TemplateSection(
        id: 'sec_footer',
        type: 'footer',
        isEnabled: true,
      ),
    ];

    return DocumentTemplateSchema(
      metadata: TemplateMetadata(
        id: templateId ?? 'wysiwyg_custom',
        name: templateName ?? 'WYSIWYG Template',
        category: businessCategory ?? (isSecurity ? 'Security Agency' : 'General'),
        pageSize: TemplatePageSize.a4,
      ),
      style: TemplateStyle(
        fontFamily: fontFamily,
        baseSize: baseFont,
        primaryColor: primaryHex,
        secondaryColor: secondaryHex,
        accentColor: '#F59E0B',
        zebraColor: tableStyle == 'striped' ? '#F8FAFC' : '#FFFFFF',
        borderRadius: tableStyle == 'boxed' ? 4 : 6,
      ),
      sections: sections,
    );
  }

  DocumentTemplateSchema copyWith({
    TemplateMetadata? metadata,
    TemplateStyle? style,
    List<TemplateSection>? sections,
    OverflowPolicy? overflowPolicy,
    bool? columnPriorityDropping,
  }) {
    return DocumentTemplateSchema(
      metadata: metadata ?? this.metadata,
      style: style ?? this.style,
      sections: sections ?? this.sections,
      overflowPolicy: overflowPolicy ?? this.overflowPolicy,
      columnPriorityDropping: columnPriorityDropping ?? this.columnPriorityDropping,
      minItemRowsPerPage: minItemRowsPerPage,
    );
  }

  static List<TemplateSection> _defaultSections() {
    return [
      const TemplateSection(
        id: 'sec_header',
        type: 'header',
        config: TemplateSectionConfig(logoMaxWidth: 130, companyBlockAlign: 'left'),
      ),
      const TemplateSection(
        id: 'sec_party',
        type: 'party_details',
      ),
      TemplateSection(
        id: 'sec_items',
        type: 'item_table',
        config: TemplateSectionConfig(
          columns: defaultColumns(),
          repeatHeader: true,
          stripedRows: true,
        ),
      ),
      const TemplateSection(
        id: 'sec_totals',
        type: 'totals',
        config: TemplateSectionConfig(totalsAlign: 'right', keepWithPrevious: true),
      ),
      const TemplateSection(
        id: 'sec_bank_qr',
        type: 'bank_qr',
        config: TemplateSectionConfig(showQr: true, qrSize: 85),
      ),
      const TemplateSection(
        id: 'sec_notes',
        type: 'notes_terms',
      ),
      const TemplateSection(
        id: 'sec_sign',
        type: 'signature',
        config: TemplateSectionConfig(
          signatureMode: SignatureMode.fixedBottom,
          signatureHeight: 70,
          signatureLabel: 'Authorized Signatory',
        ),
      ),
      const TemplateSection(
        id: 'sec_footer',
        type: 'footer',
      ),
    ];
  }

  static List<TemplateColumnConfig> defaultColumns() {
    return const [
      TemplateColumnConfig(key: 'item', label: 'Item & Description', width: 'flex', priority: 1, align: 'left'),
      TemplateColumnConfig(key: 'hsn', label: 'HSN/SAC', width: '70', priority: 3, align: 'center'),
      TemplateColumnConfig(key: 'qty', label: 'Qty', width: '55', priority: 2, align: 'center'),
      TemplateColumnConfig(key: 'rate', label: 'Unit Rate', width: '85', priority: 2, align: 'right'),
      TemplateColumnConfig(key: 'amount', label: 'Amount', width: '95', priority: 1, align: 'right'),
    ];
  }

  // ---------------------------------------------------------------------------
  // Canonical Built-in Presets
  // ---------------------------------------------------------------------------
  static List<DocumentTemplateSchema> builtInPresets() {
    return [
      // 1. Modern Tech Gradient
      DocumentTemplateSchema(
        metadata: const TemplateMetadata(
          id: 'modern_tech_gradient',
          name: 'Modern Tech Gradient',
          category: 'IT & Consulting',
        ),
        style: const TemplateStyle(
          fontFamily: 'Inter',
          primaryColor: '#0284C7',
          secondaryColor: '#6366F1',
          accentColor: '#38BDF8',
          zebraColor: '#F0F9FF',
          borderRadius: 8,
        ),
        sections: _defaultSections(),
      ),

      // 2. Minimalist Corporate A4
      DocumentTemplateSchema(
        metadata: const TemplateMetadata(
          id: 'minimal_corporate_a4',
          name: 'Minimal Corporate A4',
          category: 'Corporate Suite',
        ),
        style: const TemplateStyle(
          fontFamily: 'Inter',
          primaryColor: '#0F172A',
          secondaryColor: '#475569',
          accentColor: '#0284C7',
          zebraColor: '#F8FAFC',
          borderRadius: 4,
        ),
        sections: _defaultSections(),
      ),

      // 3. GST Enterprise Suite
      DocumentTemplateSchema(
        metadata: const TemplateMetadata(
          id: 'gst_enterprise_suite',
          name: 'GST Enterprise Suite',
          category: 'Retail & GST',
        ),
        style: const TemplateStyle(
          fontFamily: 'Inter',
          primaryColor: '#047857',
          secondaryColor: '#0D9488',
          accentColor: '#F59E0B',
          zebraColor: '#F0FDF4',
          borderRadius: 6,
        ),
        sections: _defaultSections(),
      ),

      // 4. Executive Formal
      DocumentTemplateSchema(
        metadata: const TemplateMetadata(
          id: 'executive_formal',
          name: 'Executive Formal',
          category: 'Security Agency',
        ),
        style: const TemplateStyle(
          fontFamily: 'Inter',
          primaryColor: '#1E1B4B',
          secondaryColor: '#4338CA',
          accentColor: '#E11D48',
          zebraColor: '#EEF2FF',
          borderRadius: 6,
        ),
        sections: _defaultSections(),
      ),
    ];
  }
}

/// Validates any template schema against enterprise constraints.
class TemplateSchemaValidator {
  static List<String> validate(DocumentTemplateSchema schema) {
    final issues = <String>[];

    if (schema.metadata.id.trim().isEmpty) {
      issues.add('Metadata ID is required.');
    }
    if (schema.metadata.name.trim().isEmpty) {
      issues.add('Metadata Name is required.');
    }
    if (schema.metadata.horizontalMargins > 150) {
      issues.add('Horizontal margins are too large (> 150pt), table might overflow.');
    }
    if (schema.metadata.verticalMargins > 200) {
      issues.add('Vertical margins are too large (> 200pt).');
    }

    final itemSec = schema.sectionOfType('item_table');
    if (itemSec == null) {
      issues.add('Template must contain an "item_table" section.');
    } else {
      if (itemSec.config.columns.isEmpty) {
        issues.add('Item table must specify at least one column.');
      }
      final hasFlex = itemSec.config.columns.any((c) => c.isFlex);
      if (!hasFlex) {
        issues.add('Warning: No flex column specified in item_table. Auto-stretch might be rigid.');
      }
    }

    final signSec = schema.sectionOfType('signature');
    if (signSec != null && signSec.config.signatureHeight > 180) {
      issues.add('Signature height is exceptionally large (> 180pt).');
    }

    return issues;
  }
}

double _asDouble(dynamic val, double fallback) {
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? fallback;
  return fallback;
}

Color _parseColor(String hex, Color fallback) {
  try {
    var clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) clean = 'FF$clean';
    return Color(int.parse(clean, radix: 16));
  } catch (_) {
    return fallback;
  }
}
