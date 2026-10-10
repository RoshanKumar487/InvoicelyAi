import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../theme/app_theme.dart';
import '../../settings/data/settings_repository.dart';
import '../data/template_config.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({
    this.apiClient,
    this.initialConfig,
    this.initialLocalSettings = const <String, Object?>{},
    this.onSaveLocalSettings,
    this.onBack,
    this.onSave,
    super.key,
  });

  final ApiClient? apiClient;
  final TemplateConfig? initialConfig;
  final Map<String, Object?> initialLocalSettings;
  final ValueChanged<Map<String, Object?>>? onSaveLocalSettings;
  final VoidCallback? onBack;
  final ValueChanged<TemplateConfig>? onSave;

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  late TemplateConfig _config;
  late Map<String, Object?> _localSettings;
  Map<String, dynamic> _profile = <String, dynamic>{};
  String _presetId = 'gst_tax';
  bool _saved = false;
  String _selectedCategory = 'All';
  String _selectedStyle = 'All';

  static const _categories = [
    ('All', 'All Categories'),
    ('Security Agency', '🛡️ Security Agency'),
    ('HR & Staffing', '👥 HR & Staffing'),
    ('IT & Consulting', '💻 IT & Consulting'),
    ('Retail & GST', '🛍️ Retail & GST'),
    ('Corporate Suite', '🏢 Corporate Suite'),
  ];

  static const _styles = [
    'All',
    'Modern',
    'Classic',
    'Corporate',
    'Smart',
    'Minimal',
    'Industry',
  ];

  @override
  void initState() {
    super.initState();
    _localSettings = Map<String, Object?>.from(widget.initialLocalSettings);
    _config = widget.initialConfig ??
        templatePresets.firstWhere((preset) => preset.id == 'gst_tax');
    _presetId = templatePresets.any((preset) => preset.id == _config.id)
        ? _config.id
        : 'gst_tax';

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (widget.apiClient == null) return;
    try {
      final repo = SettingsRepository(apiClient: widget.apiClient!);
      final profile = await repo.loadProfile();
      if (!mounted) return;
      setState(() => _profile = profile);
    } catch (_) {}
  }

  void _selectPreset(String? id) {
    if (id == null) return;
    final preset = templatePresets.firstWhere((template) => template.id == id);
    setState(() {
      _presetId = id;
      _config = preset.copyWith(
        showLogo: _config.showLogo,
        showBillFrom: _config.showBillFrom,
        showBillTo: _config.showBillTo,
        showBankDetails: _config.showBankDetails,
        showShipping: _config.showShipping,
        showNotes: _config.showNotes,
        showTerms: _config.showTerms,
        showSignature: _config.showSignature,
        showTaxBreakdown: preset.showTaxBreakdown,
        showPaymentInstructions: preset.showPaymentInstructions,
      );
      _saved = false;
    });
  }

  Future<void> _pickLogo(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 400,
        imageQuality: 80,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      final base64 = base64Encode(bytes);
      final updatedSettings = Map<String, Object?>.from(_localSettings)
        ..['invoiceLogo'] = base64
        ..['showLogo'] = true;
      setState(() {
        _localSettings = updatedSettings;
        _config = _config.copyWith(showLogo: true);
        _saved = false;
      });
      widget.onSaveLocalSettings?.call(updatedSettings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF047857),
            content: Text('✓ Template business logo saved successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick logo: $e')),
        );
      }
    }
  }

  void _removeLogo() {
    final updatedSettings = Map<String, Object?>.from(_localSettings)
      ..remove('invoiceLogo');
    setState(() {
      _localSettings = updatedSettings;
      _saved = false;
    });
    widget.onSaveLocalSettings?.call(updatedSettings);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logo removed from template.')),
    );
  }

  Image? _getLogoImage({double height = 45}) {
    final encoded = _localSettings['invoiceLogo']?.toString() ?? '';
    if (encoded.isEmpty) return null;
    try {
      return Image.memory(
        base64Decode(encoded),
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    } catch (_) {
      return null;
    }
  }

  void _save() {
    if (_colorError(_config.color) != null ||
        _colorError(_config.secondaryColor) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid six-digit primary brand color.'),
        ),
      );
      return;
    }

    // Synchronize section visibility into localSettings so preview and editor follow
    final updatedSettings = Map<String, Object?>.from(_localSettings)
      ..['preferredTemplateId'] = _config.id
      ..['showLogo'] = _config.showLogo
      ..['showBillFrom'] = _config.showBillFrom
      ..['showBillTo'] = _config.showBillTo
      ..['showBankDetails'] = _config.showBankDetails
      ..['showShippingSection'] = _config.showShipping
      ..['showNotes'] = _config.showNotes
      ..['showTerms'] = _config.showTerms
      ..['showSignature'] = _config.showSignature
      ..['showTax'] = _config.showTaxBreakdown
      ..['showPaymentInstructions'] = _config.showPaymentInstructions
      ..['customTitle'] = _config.title
      ..['customItemHeader'] = _config.itemHeader
      ..['customQtyHeader'] = _config.quantityHeader
      ..['customRateHeader'] = _config.rateHeader
      ..['customAmountHeader'] = _config.amountHeader
      ..['customDutyHeader'] = _config.dutyHeader
      ..['showItemDuty'] = _config.showDuty;

    widget.onSave?.call(_config);
    widget.onSaveLocalSettings?.call(updatedSettings);
    setState(() {
      _localSettings = updatedSettings;
      _saved = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF047857),
        content: Text(
          '✓ Default template customized & saved! Applied to all invoice previews and exports.',
        ),
      ),
    );
  }

  void _update(TemplateConfig next) {
    setState(() {
      _config = next;
      _saved = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: widget.onBack == null
              ? null
              : IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
          title: const Text('Template Customization Studio'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check, size: 18),
                label: Text(_saved ? 'Saved as Default' : 'Set as Default'),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Live Real-Time A4 Template Sample Preview
            _samplePreview(context),
            const SizedBox(height: 16),

            // SECTION 1: SECTION VISIBILITY IN TEMPLATE
            _buildSectionsVisibilityCard(),
            const SizedBox(height: 14),

            // SECTION 2: TEMPLATE LOGO STUDIO
            _buildLogoStudioCard(),
            const SizedBox(height: 14),

            // SECTION 3: TEMPLATE PRESETS SELECTOR
            _buildPresetsCard(),
            const SizedBox(height: 14),

            // SECTION 4: LAYOUT & TABLE STYLING
            _buildLayoutAndStylingCard(),
            const SizedBox(height: 14),

            // SECTION 5: BRAND COLORS & TYPOGRAPHY
            _buildColorsAndTypographyCard(),
            const SizedBox(height: 14),

            // SECTION 6: DOCUMENT LABELS & FOOTER
            _buildLabelsCard(),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                _saved ? 'Default Template Saved' : 'Apply & Set as Default Template',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      );

  // ---------------------------------------------------------------------------
  // LIVE A4 TEMPLATE SAMPLE PREVIEW
  // ---------------------------------------------------------------------------
  Widget _samplePreview(BuildContext context) {
    final logoImage = _getLogoImage(height: 36);
    final brandColor = _parseColor(_config.color);
    final secondaryColor = _parseColor(_config.secondaryColor);

    final bizName = _profile['businessName']?.toString().isNotEmpty == true
        ? _profile['businessName'].toString()
        : 'Acme Technologies Pvt Ltd';
    final bizGstin = _profile['gstin']?.toString().isNotEmpty == true
        ? _profile['gstin'].toString()
        : (_profile['taxId']?.toString().isNotEmpty == true
            ? _profile['taxId'].toString()
            : '27AABCA1234A1Z5');
    final bizAddress = _profile['address']?.toString().isNotEmpty == true
        ? _profile['address'].toString()
        : 'Tech Park, Level 4, Silicon Road, Mumbai 400001';
    final bizPhone = _profile['phone']?.toString().isNotEmpty == true
        ? _profile['phone'].toString()
        : '+91 98765 43210';
    final bizEmail = _profile['email']?.toString().isNotEmpty == true
        ? _profile['email'].toString()
        : 'billing@acme.com';

    final bankName = _profile['bankName']?.toString().isNotEmpty == true
        ? _profile['bankName'].toString()
        : 'HDFC Bank';
    final accNo = _profile['accountNumber']?.toString().isNotEmpty == true
        ? _profile['accountNumber'].toString()
        : '50100234567890';
    final ifsc = _profile['ifscCode']?.toString().isNotEmpty == true
        ? _profile['ifscCode'].toString()
        : 'HDFC0001234';
    final upi = _profile['upiId']?.toString().isNotEmpty == true
        ? _profile['upiId'].toString()
        : 'acme@hdfcbank';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.preview_rounded, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Live Template Design Preview',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (_saved)
                const Chip(
                  backgroundColor: Color(0xFFECFDF5),
                  label: Text('Default', style: TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold)),
                  avatar: Icon(Icons.check, size: 16, color: Color(0xFF047857)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_config.name} · ${_config.category} · Style: ${_config.tableStyle.toUpperCase()}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),

          // Mini A4 Paper Representation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER SECTION (Layout based)
                if (_config.headerLayout == 'classic') ...[
                  // Centered Letterhead
                  Center(
                    child: Column(
                      children: [
                        if (_config.showLogo && logoImage != null) ...[
                          logoImage,
                          const SizedBox(height: 6),
                        ],
                        if (_config.showBillFrom) ...[
                          Text(
                            bizName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: brandColor,
                            ),
                          ),
                          Text(
                            '$bizAddress · GSTIN: $bizGstin',
                            style: const TextStyle(fontSize: 8, color: Color(0xFF64748B)),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Phone: $bizPhone · Email: $bizEmail',
                            style: const TextStyle(fontSize: 8, color: Color(0xFF64748B)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          _config.title.isEmpty ? 'INVOICE' : _config.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: brandColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Modern Side-by-Side (Default)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Logo & Bill From
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_config.showLogo && logoImage != null) ...[
                              logoImage,
                              const SizedBox(height: 6),
                            ],
                            if (_config.showBillFrom) ...[
                              Text(
                                bizName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                bizAddress,
                                style: const TextStyle(fontSize: 8, color: Color(0xFF64748B)),
                              ),
                              Text(
                                'GSTIN/PAN: $bizGstin',
                                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                              ),
                              Text(
                                '$bizPhone · $bizEmail',
                                style: const TextStyle(fontSize: 8, color: Color(0xFF64748B)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Right: Document Title & Metadata
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _config.title.isEmpty ? 'INVOICE' : _config.title,
                            style: TextStyle(
                              color: brandColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Invoice #: INV-2026-001',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'Date: 10 Oct 2026',
                            style: TextStyle(fontSize: 8, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 10),
                Container(height: 2, color: secondaryColor),
                const SizedBox(height: 10),

                // BILL TO & SHIP TO ROW
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_config.showBillTo)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BILL TO',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: brandColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Text(
                              'Acme Studio / Client Pvt Ltd',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              '45 Commercial St, Bangalore 560001\nGSTIN: 29AABCB5678B1Z2',
                              style: TextStyle(fontSize: 8, color: Color(0xFF475569)),
                            ),
                          ],
                        ),
                      ),
                    if (_config.showShipping) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SHIP TO / DISPATCH',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: brandColor,
                                ),
                              ),
                              const Text(
                                'FedEx Express · AWB #9876543210\nWarehouse 3, Industrial Area',
                                style: TextStyle(fontSize: 7.5, color: Color(0xFF475569)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // ITEMS TABLE (Style based)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                  color: brandColor,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(
                          _config.itemHeader,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        '${_config.quantityHeader}    ${_config.rateHeader}    ${_config.amountHeader}',
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                _previewTableRow('Professional Consulting Services', '1.0', '₹5,000.00', '₹5,000.00', isAlt: _config.tableStyle == 'striped'),
                _previewTableRow('Software Setup & Deployment', '1.0', '₹3,500.00', '₹3,500.00', isAlt: false),

                const SizedBox(height: 8),

                // TOTALS SECTION
                Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Column(
                      children: [
                        _miniTotalLine('Subtotal', '₹8,500.00'),
                        if (_config.showTaxBreakdown)
                          _miniTotalLine('GST (18%)', '₹1,530.00'),
                        const Divider(height: 8),
                        _miniTotalLine('Total', '₹10,030.00', bold: true, color: brandColor),
                      ],
                    ),
                  ),
                ),

                // ROW: BANK & PAYMENT DETAILS + QR (LEFT) & SIGNATURE / STAMP (RIGHT)
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT: Bank Details & Mini QR
                    Expanded(
                      flex: 6,
                      child: _config.showBankDetails
                          ? Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.account_balance_rounded, size: 11, color: Color(0xFF15803D)),
                                            const SizedBox(width: 3),
                                            Text(
                                              'BANK & PAYMENT DETAILS',
                                              style: TextStyle(
                                                fontSize: 7.5,
                                                fontWeight: FontWeight.w800,
                                                color: brandColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text('Bank: $bankName  |  A/C: $accNo', style: const TextStyle(fontSize: 7, color: Color(0xFF166534))),
                                        Text('IFSC: $ifsc  |  UPI: $upi', style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                                      ],
                                    ),
                                  ),
                                  if (_config.showQrCode) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(color: const Color(0xFFCBD5E1)),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: const Icon(Icons.qr_code_2_rounded, size: 24, color: Color(0xFF0F172A)),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(width: 10),

                    // RIGHT: Signature & Stamp
                    Expanded(
                      flex: 4,
                      child: _config.showSignature
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'For $bizName',
                                  style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                  textAlign: TextAlign.end,
                                ),
                                const SizedBox(height: 12),
                                Container(width: 80, height: 1, color: const Color(0xFF94A3B8)),
                                const SizedBox(height: 2),
                                const Text(
                                  'Authorized Signatory',
                                  style: TextStyle(fontSize: 7, fontStyle: FontStyle.italic, color: Color(0xFF475569)),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),

                // NOTES & TERMS (Full Width Below)
                if (_config.showNotes || _config.showTerms) ...[
                  const SizedBox(height: 8),
                  if (_config.showNotes)
                    const Text('Notes: Thank you for your business!', style: TextStyle(fontSize: 7.5, color: Color(0xFF64748B))),
                  if (_config.showTerms)
                    const Text('Terms: Payment due within specified period.', style: TextStyle(fontSize: 7, color: Color(0xFF94A3B8))),
                ],

                if (_config.footer.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      _config.footer,
                      style: const TextStyle(fontSize: 6.5, color: Color(0xFF94A3B8)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewTableRow(String title, String qty, String rate, String total, {bool isAlt = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      color: isAlt ? const Color(0xFFF8FAFC) : Colors.transparent,
      child: Row(
        children: [
          Expanded(flex: 5, child: Text(title, style: const TextStyle(fontSize: 8))),
          Text('$qty    $rate    $total', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _miniTotalLine(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 8, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 8, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 1: SECTION VISIBILITY IN TEMPLATE
  // ---------------------------------------------------------------------------
  Widget _buildSectionsVisibilityCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dashboard_customize_outlined, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Template Sections & Layout Tool',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Control which sections appear on your invoice template. Enabled sections are visible across all generated invoices and previews.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          _buildSectionSwitch(
            title: 'Bill From (Your Business Details)',
            subtitle: 'Show your business name, address, GSTIN/PAN, and contact info in header',
            value: _config.showBillFrom,
            isDefault: true,
            onChanged: (val) => _update(_config.copyWith(showBillFrom: val)),
          ),
          const Divider(),

          _buildSectionSwitch(
            title: 'Business Logo in Header',
            subtitle: 'Display your company logo on the invoice',
            value: _config.showLogo,
            isDefault: true,
            onChanged: (val) => _update(_config.copyWith(showLogo: val)),
          ),
          const Divider(),

          _buildSectionSwitch(
            title: 'Bill To (Client / Customer Info)',
            subtitle: 'Display client name, billing address, phone, email & tax ID',
            value: _config.showBillTo,
            isDefault: true,
            onChanged: (val) => _update(_config.copyWith(showBillTo: val)),
          ),
          const Divider(),

          _buildSectionSwitch(
            title: 'Bank & Payment Details',
            subtitle: 'Display bank account number, IFSC, bank name & UPI ID for customer transfers',
            value: _config.showBankDetails,
            isDefault: true,
            onChanged: (val) => _update(_config.copyWith(showBankDetails: val)),
          ),
          const Divider(),

          _buildSectionSwitch(
            title: 'Shipments & Dispatch Details',
            subtitle: 'Show courier/carrier, tracking number, and delivery shipping address',
            value: _config.showShipping,
            isDefault: false,
            onChanged: (val) => _update(_config.copyWith(showShipping: val)),
          ),
          const Divider(),

          _buildSectionSwitch(
            title: 'Tax Breakdown & Adjustments',
            subtitle: 'Display detailed tax percentages, discount rows, and charges breakdown',
            value: _config.showTaxBreakdown,
            isDefault: true,
            onChanged: (val) => _update(_config.copyWith(showTaxBreakdown: val)),
          ),
          const Divider(),

          _buildSectionSwitch(
            title: 'DocuHub Digital Signature & Stamp',
            subtitle: 'Include signature image, signee name, and official designation block',
            value: _config.showSignature,
            isDefault: true,
            onChanged: (val) => _update(_config.copyWith(showSignature: val)),
          ),
          const Divider(),

          _buildSectionSwitch(
            title: 'Notes & Client Message',
            subtitle: 'Include personalized notes or thank-you message',
            value: _config.showNotes,
            isDefault: true,
            onChanged: (val) => _update(_config.copyWith(showNotes: val)),
          ),
          const Divider(),

          _buildSectionSwitch(
            title: 'Terms and Conditions',
            subtitle: 'Display payment terms, warranty or cancellation policies',
            value: _config.showTerms,
            isDefault: true,
            onChanged: (val) => _update(_config.copyWith(showTerms: val)),
          ),
          const Divider(),

          _buildSectionSwitch(
            title: 'Payment Instructions',
            subtitle: 'Display explicit instructions for check, wire, or cash payment',
            value: _config.showPaymentInstructions,
            isDefault: true,
            onChanged: (val) => _update(_config.copyWith(showPaymentInstructions: val)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required bool isDefault,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
          if (isDefault)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('DEFAULT ON', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
            ),
        ],
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      value: value,
      onChanged: onChanged,
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 2: TEMPLATE LOGO STUDIO
  // ---------------------------------------------------------------------------
  Widget _buildLogoStudioCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.image_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Template Business Logo',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Text(
                      'Shown in invoice header when added',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_getLogoImage(height: 60) case final logo?) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  logo,
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _pickLogo(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library, size: 16),
                        label: const Text('Change Logo'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _pickLogo(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt, size: 16),
                        label: const Text('Camera'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _removeLogo,
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        label: const Text('Remove', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 6),
                  const Text(
                    'No logo attached to this template yet',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => _pickLogo(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library, size: 17),
                        label: const Text('Upload Gallery'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.tonalIcon(
                        onPressed: () => _pickLogo(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt, size: 17),
                        label: const Text('Take Photo'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 3: TEMPLATE PRESETS SELECTOR (BY BUSINESS CATEGORY & STYLE)
  // ---------------------------------------------------------------------------
  Widget _buildPresetsCard() {
    final filtered = templatePresets.where((p) {
      final matchCat =
          _selectedCategory == 'All' || p.businessCategory == _selectedCategory;
      final matchStyle =
          _selectedStyle == 'All' || p.designStyle == _selectedStyle;
      return matchCat && matchStyle;
    }).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.category_rounded, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Business Category & Style Templates',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  '${filtered.length} Templates',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D4ED8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Select templates tailored for your industry (Security Agencies, Staffing, IT, Retail & GST) with specialized duty & salary formulas.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          // 1. Business Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      cat.$2,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : null,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF2563EB),
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategory = cat.$1);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // 2. Design Style Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text(
                  'Style: ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
                ..._styles.map((style) {
                  final isSelected = _selectedStyle == style;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(
                        style,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFF2563EB) : null,
                        ),
                      ),
                      selected: isSelected,
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      onSelected: (val) {
                        setState(() => _selectedStyle = style);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Grid of Filtered Templates
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 550 ? 3 : 2;
              return GridView.builder(
                itemCount: filtered.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: constraints.maxWidth > 550 ? 1.4 : 1.15,
                ),
                itemBuilder: (context, index) {
                  final preset = filtered[index];
                  final selected = preset.id == _presetId;
                  final color = _parseColor(preset.color);

                  return InkWell(
                    onTap: () => _selectPreset(preset.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : AppColors.border,
                          width: selected ? 2.2 : 1,
                        ),
                        color: selected
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.08)
                            : Theme.of(context).colorScheme.surface,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                    color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  preset.businessCategory,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (selected)
                                const Icon(Icons.check_circle,
                                    size: 16, color: Color(0xFF10B981)),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            preset.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  selected ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  preset.designStyle,
                                  style: const TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF475569)),
                                ),
                              ),
                              if (preset.showDuty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text(
                                    'Duty Calc',
                                    style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF166534)),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 4: LAYOUT & TABLE STYLING
  // ---------------------------------------------------------------------------
  Widget _buildLayoutAndStylingCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Header & Table Layout Style', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'Select how the header and items table are formatted on your invoices.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          // Header Layout Selector
          const Text('Header Alignment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'modern', label: Text('Modern Split'), icon: Icon(Icons.splitscreen_rounded, size: 16)),
              ButtonSegment(value: 'classic', label: Text('Centered Letterhead'), icon: Icon(Icons.align_horizontal_center, size: 16)),
            ],
            selected: {_config.headerLayout},
            onSelectionChanged: (set) => _update(_config.copyWith(headerLayout: set.first)),
          ),

          const SizedBox(height: 16),

          // Table Style Selector
          const Text('Items Table Grid Style', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'clean', label: Text('Clean Minimal'), icon: Icon(Icons.table_rows_outlined, size: 16)),
              ButtonSegment(value: 'striped', label: Text('Striped Rows'), icon: Icon(Icons.format_line_spacing, size: 16)),
              ButtonSegment(value: 'boxed', label: Text('Boxed Grid'), icon: Icon(Icons.grid_on_rounded, size: 16)),
            ],
            selected: {_config.tableStyle},
            onSelectionChanged: (set) => _update(_config.copyWith(tableStyle: set.first)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 5: BRAND COLORS & TYPOGRAPHY
  // ---------------------------------------------------------------------------
  Widget _buildColorsAndTypographyCard() {
    const swatches = [
      {'name': 'Navy Blue', 'hex': '#1E3A8A'},
      {'name': 'Zoho Sky', 'hex': '#0284C7'},
      {'name': 'Emerald Teal', 'hex': '#0F766E'},
      {'name': 'Midnight Slate', 'hex': '#0F172A'},
      {'name': 'Royal Indigo', 'hex': '#4F46E5'},
      {'name': 'Crimson Red', 'hex': '#DC2626'},
      {'name': 'Forest Green', 'hex': '#059669'},
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Colors & Typography', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text('Choose the primary color and font family for this template.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 12),

          // Swatches
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: swatches.map((swatch) {
              final hex = swatch['hex']!;
              final color = _parseColor(hex);
              final isSelected = _config.color.toUpperCase() == hex.toUpperCase();
              return InkWell(
                onTap: () => _update(_config.copyWith(color: hex)),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    color: isSelected ? color.withAlpha(25) : Colors.transparent,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(swatch['name']!, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _textField(
                  label: 'Primary brand color hex',
                  value: _config.color,
                  onChanged: (value) => _update(_config.copyWith(color: value)),
                  validator: _colorError,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _textField(
                  label: 'Secondary accent color hex',
                  value: _config.secondaryColor,
                  onChanged: (value) => _update(_config.copyWith(secondaryColor: value)),
                  validator: _colorError,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            key: ValueKey<String>('font-${_config.font}'),
            value: _config.font,
            decoration: const InputDecoration(labelText: 'Font Family'),
            items: const [
              DropdownMenuItem(value: 'Calibri', child: Text('Calibri (Modern Clean)')),
              DropdownMenuItem(value: 'Arial', child: Text('Arial (Standard Swiss)')),
              DropdownMenuItem(value: 'Times New Roman', child: Text('Times New Roman (Formal / Legal)')),
              DropdownMenuItem(value: 'Consolas', child: Text('Consolas (Monospace / Tech)')),
            ],
            onChanged: (font) {
              if (font != null) _update(_config.copyWith(font: font));
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 6: DOCUMENT LABELS & FOOTER
  // ---------------------------------------------------------------------------
  Widget _buildLabelsCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Document Title & Table Headers', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text('Custom text for document title and table headers.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 12),

          _textField(
            label: 'Invoice document title (e.g. TAX INVOICE)',
            value: _config.title,
            onChanged: (value) => _update(_config.copyWith(title: value)),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: _textField(
                  label: 'Item description header',
                  value: _config.itemHeader,
                  onChanged: (value) => _update(_config.copyWith(itemHeader: value)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _textField(
                  label: 'Qty header',
                  value: _config.quantityHeader,
                  onChanged: (value) => _update(_config.copyWith(quantityHeader: value)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _textField(
                  label: 'Rate header',
                  value: _config.rateHeader,
                  onChanged: (value) => _update(_config.copyWith(rateHeader: value)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _textField(
                  label: 'Amount header',
                  value: _config.amountHeader,
                  onChanged: (value) => _update(_config.copyWith(amountHeader: value)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          _textField(
            label: 'Template footer note / disclaimer',
            value: _config.footer,
            maxLines: 2,
            onChanged: (value) => _update(_config.copyWith(footer: value)),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        initialValue: value,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        validator: validator,
        onChanged: onChanged,
      );

  Color _parseColor(String hex) {
    try {
      final sanitized = hex.replaceAll('#', '').trim();
      return Color(int.parse('FF$sanitized', radix: 16));
    } catch (_) {
      return const Color(0xFF1E3A8A);
    }
  }

  String? _colorError(String? value) {
    final sanitized = (value ?? '').replaceAll('#', '').trim();
    if (sanitized.length != 6 || int.tryParse(sanitized, radix: 16) == null) {
      return 'Enter a 6-digit hex code';
    }
    return null;
  }
}
