import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/storage/local_preferences.dart';
import '../../../templates/data/company_letterhead.dart';
import '../../../templates/data/studio_section_model.dart';
import '../../../templates/data/template_config.dart';
import 'invoice_preview_widgets.dart';

class InvoiceLiveCustomizeSheet extends StatefulWidget {
  const InvoiceLiveCustomizeSheet({
    required this.selectedTemplateId,
    required this.localSettings,
    required this.studioPreferences,
    required this.onSettingsChanged,
    required this.onSelectTemplate,
    required this.onSetDefaultTemplate,
    required this.onOpenDocuHubSigner,
    this.activeBusinessCategory,
    super.key,
  });

  final String? selectedTemplateId;
  final Map<String, Object?> localSettings;
  final LocalPreferences studioPreferences;
  final ValueChanged<Map<String, Object?>> onSettingsChanged;
  final ValueChanged<TemplateConfig> onSelectTemplate;
  final ValueChanged<TemplateConfig> onSetDefaultTemplate;
  final VoidCallback onOpenDocuHubSigner;
  final String? activeBusinessCategory;

  @override
  State<InvoiceLiveCustomizeSheet> createState() =>
      _InvoiceLiveCustomizeSheetState();
}

class _InvoiceLiveCustomizeSheetState extends State<InvoiceLiveCustomizeSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, Object?> _settings;
  late List<StudioSection> _sections;
  String _selectedCategory = 'All';
  late String? _currentTemplateId = widget.selectedTemplateId;

  late final TextEditingController _serviceLocationCtrl;
  late final TextEditingController _billingPeriodCtrl;
  late final TextEditingController _signeeTitleCtrl;

  static const _brandColorSwatches = [
    ('#1E293B', 'Slate Navy', Color(0xFF1E293B)),
    ('#1E3A8A', 'Royal Blue', Color(0xFF1E3A8A)),
    ('#0F766E', 'Emerald Teal', Color(0xFF0F766E)),
    ('#4338CA', 'Indigo Pro', Color(0xFF4338CA)),
    ('#7C2D12', 'Executive Bronze', Color(0xFF7C2D12)),
    ('#881337', 'Crimson Rose', Color(0xFF881337)),
    ('#111827', 'Carbon Black', Color(0xFF111827)),
    ('#0369A1', 'Sky Ocean', Color(0xFF0369A1)),
  ];

  static const _docTitles = [
    'TAX INVOICE',
    'INVOICE',
    'PROFORMA INVOICE',
    'QUOTATION / ESTIMATE',
    'BILL OF SUPPLY',
  ];

  static const _watermarks = [
    'None',
    'ORIGINAL FOR RECIPIENT',
    'PAID',
    'DRAFT',
    'CONFIDENTIAL',
    'DUPLICATE FOR TRANSPORTER',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _settings = Map<String, Object?>.from(widget.localSettings);
    _sections = _parseOrBuildDefaultSections(_settings['studio_sections_json']);

    if (widget.activeBusinessCategory != null &&
        widget.activeBusinessCategory!.isNotEmpty &&
        widget.activeBusinessCategory != 'General' &&
        widget.activeBusinessCategory != 'All') {
      _selectedCategory = widget.activeBusinessCategory!;
    }

    _serviceLocationCtrl = TextEditingController(
      text: _getFieldDefault('sec_client', 'f_cli_loc', 'Main Gate & Perimeters, Tech Park Campus'),
    );
    _billingPeriodCtrl = TextEditingController(
      text: _getFieldDefault('sec_client', 'f_cli_period', '01 Oct 2026 to 31 Oct 2026'),
    );
    _signeeTitleCtrl = TextEditingController(
      text: _settings['signeeTitle']?.toString() ?? 'Authorized Signatory',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _serviceLocationCtrl.dispose();
    _billingPeriodCtrl.dispose();
    _signeeTitleCtrl.dispose();
    super.dispose();
  }

  List<StudioSection> _parseOrBuildDefaultSections(Object? rawJson) {
    if (rawJson is String && rawJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson);
        if (decoded is List) {
          final parsed = decoded
              .whereType<Map<dynamic, dynamic>>()
              .map((m) => StudioSection.fromJson(Map<String, dynamic>.from(m)))
              .toList();
          if (parsed.isNotEmpty) return parsed;
        }
      } catch (_) {}
    }
    return [
      StudioSection(
        id: 'sec_branding',
        title: 'Header & Branding',
        subtitle: 'Company Logo, Name, GSTIN & Address',
        icon: Icons.auto_awesome_outlined,
        enabled: true,
        fields: [
          StudioField(id: 'f_logo', label: 'Company Logo', isRequired: true),
          StudioField(id: 'f_comp_name', label: 'Company Name', isRequired: true),
          StudioField(id: 'f_comp_addr', label: 'Office Address'),
          StudioField(id: 'f_comp_gst', label: 'Company GSTIN', isRequired: true),
          StudioField(id: 'f_comp_pan', label: 'Company PAN No.'),
          StudioField(id: 'f_comp_cin', label: 'PSARA / License / CIN'),
          StudioField(id: 'f_comp_contact', label: 'Phone & Email'),
        ],
      ),
      StudioSection(
        id: 'sec_identity',
        title: 'Invoice Identity & Dates',
        subtitle: 'Invoice No, Issue Date, Due Date, PO/WO No',
        icon: Icons.receipt_long_outlined,
        enabled: true,
        fields: [
          StudioField(id: 'f_inv_title', label: 'Document Title (TAX INVOICE)', isRequired: true),
          StudioField(id: 'f_inv_num', label: 'Invoice Number', isRequired: true),
          StudioField(id: 'f_inv_date', label: 'Invoice Date', isRequired: true),
          StudioField(id: 'f_due_date', label: 'Due Date'),
          StudioField(id: 'f_po_num', label: 'PO / Work Order No.'),
          StudioField(id: 'f_place_supply', label: 'Place of Supply (State Code)'),
        ],
      ),
      StudioSection(
        id: 'sec_client',
        title: 'Client & Service Location',
        subtitle: 'Bill To Party, Client GSTIN & Deployment Site',
        icon: Icons.business_outlined,
        enabled: true,
        fields: [
          StudioField(id: 'f_cli_name', label: 'Client / Company Name', isRequired: true),
          StudioField(id: 'f_cli_addr', label: 'Billing Address'),
          StudioField(id: 'f_cli_gst', label: 'Client GSTIN'),
          StudioField(id: 'f_cli_loc', label: 'Service Location / Site Deployed', defaultValue: 'Main Gate & Perimeters, Tech Park Campus'),
          StudioField(id: 'f_cli_period', label: 'Billing Period', defaultValue: '01 Oct 2026 to 31 Oct 2026'),
          StudioField(id: 'f_cli_attn', label: 'Kind Attention / Contact Person'),
        ],
      ),
      StudioSection(
        id: 'sec_services',
        title: 'Line Items & Guard Deployment Table',
        subtitle: 'Columns for Particulars, Guards, Shifts/Days, Rate, Amount',
        icon: Icons.table_chart_outlined,
        enabled: true,
        fields: [
          StudioField(id: 'f_col_sno', label: 'S.No. Column', isRequired: true),
          StudioField(id: 'f_col_particulars', label: 'Particulars / Description', isRequired: true),
          StudioField(id: 'f_col_hsn', label: 'HSN / SAC Code (998525)', isVisible: false),
          StudioField(id: 'f_col_guards', label: 'No. of Guards / Qty'),
          StudioField(id: 'f_col_shift', label: 'Shift Hours (8hr / 12hr)', isVisible: false),
          StudioField(id: 'f_col_duty', label: 'Duty Days / Attendance'),
          StudioField(id: 'f_col_rate', label: 'Rate per Month / Unit', isRequired: true),
          StudioField(id: 'f_col_amount', label: 'Taxable Amount', isRequired: true),
        ],
      ),
      StudioSection(
        id: 'sec_tax_totals',
        title: 'GST Breakdown & Grand Total',
        subtitle: 'CGST, SGST, IGST, Round Off & Amount in Words',
        icon: Icons.calculate_outlined,
        enabled: true,
        fields: [
          StudioField(id: 'f_sub_total', label: 'Taxable Subtotal', isRequired: true),
          StudioField(id: 'f_cgst', label: 'CGST (9%)'),
          StudioField(id: 'f_sgst', label: 'SGST (9%)'),
          StudioField(id: 'f_igst', label: 'IGST (18%)', isVisible: false),
          StudioField(id: 'f_round_off', label: 'Round Off'),
          StudioField(id: 'f_grand_total', label: 'Total Amount Payable', isRequired: true),
          StudioField(id: 'f_amt_words', label: 'Total Amount in Words'),
        ],
      ),
      StudioSection(
        id: 'sec_bank',
        title: 'Bank & UPI Payment Details',
        subtitle: 'NEFT/RTGS Account Details & Dynamic QR Code',
        icon: Icons.account_balance_outlined,
        enabled: true,
        fields: [
          StudioField(id: 'f_bank_name', label: 'Bank Name & Branch'),
          StudioField(id: 'f_acc_name', label: 'Account Holder Name'),
          StudioField(id: 'f_acc_num', label: 'Account Number'),
          StudioField(id: 'f_ifsc', label: 'IFSC Code'),
          StudioField(id: 'f_upi_id', label: 'UPI ID'),
          StudioField(id: 'f_upi_qr', label: 'Scan & Pay UPI QR Code'),
        ],
      ),
      StudioSection(
        id: 'sec_terms',
        title: 'Terms, Stamp & Signatory',
        subtitle: 'Payment Terms, Legal Declaration & Digital Signature',
        icon: Icons.verified_outlined,
        enabled: true,
        fields: [
          StudioField(id: 'f_trm_list', label: 'Terms & Conditions List'),
          StudioField(id: 'f_trm_decl', label: 'GST Legal Declaration', isVisible: false),
          StudioField(id: 'f_trm_sign', label: 'Authorized Signatory Box', isRequired: true),
          StudioField(id: 'f_trm_stamp', label: 'Company Seal / Stamp Space'),
          StudioField(id: 'f_trm_title', label: 'Signatory Designation'),
          StudioField(id: 'f_trm_auto_stamp', label: 'System Generated Note'),
        ],
      ),
    ];
  }

  String _getFieldDefault(String secId, String fieldId, String fallback) {
    for (final s in _sections) {
      if (s.id == secId) {
        for (final f in s.fields) {
          if (f.id == fieldId && f.defaultValue.trim().isNotEmpty) {
            return f.defaultValue;
          }
        }
      }
    }
    return fallback;
  }

  void _setFieldDefault(String secId, String fieldId, String value) {
    for (final s in _sections) {
      if (s.id == secId) {
        for (final f in s.fields) {
          if (f.id == fieldId) {
            f.defaultValue = value;
          }
        }
      }
    }
    _saveSectionsAndNotify();
  }

  Future<void> _saveSectionsAndNotify() async {
    final encoded = jsonEncode(_sections.map((s) => s.toJson()).toList());
    _settings['studio_sections_json'] = encoded;
    await widget.studioPreferences.writeString('sections_cache', encoded);
    widget.onSettingsChanged(Map<String, Object?>.from(_settings));
  }

  Future<void> _updateSetting(String mapKey, Object? value, {String? studioKey}) async {
    setState(() {
      _settings[mapKey] = value;
    });
    if (studioKey != null && value != null) {
      await widget.studioPreferences.writeString(studioKey, value.toString());
    }
    widget.onSettingsChanged(Map<String, Object?>.from(_settings));
  }

  Future<void> _pickAndUploadImage(String settingKey, String label) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 900,
        maxHeight: 900,
        imageQuality: 90,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final b64 = base64Encode(bytes);
      await _updateSetting(settingKey, b64, studioKey: settingKey);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ $label updated on invoice!')),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Invoice Design & Customize Studio',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Instant changes apply to Preview, PDF, Print & Word (.docx)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF2563EB),
            unselectedLabelColor: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            indicatorColor: const Color(0xFF2563EB),
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            tabs: const [
              Tab(icon: Icon(Icons.palette_outlined, size: 17), text: 'Design & Style'),
              Tab(icon: Icon(Icons.checklist_rtl_rounded, size: 17), text: 'Sections & Fields'),
              Tab(icon: Icon(Icons.dashboard_customize_outlined, size: 17), text: 'Templates'),
            ],
          ),
          const Divider(height: 1),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDesignAndStyleTab(isDark),
                _buildSectionsAndFieldsTab(isDark),
                _buildTemplatesTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: DESIGN & STYLE TOOLS (Colors, Borders, Typography, Watermark, Assets)
  // ===========================================================================
  Widget _buildDesignAndStyleTab(bool isDark) {
    final currentColorHex = _settings['studio_primary_color']?.toString() ?? '#1E293B';
    final currentBorder = _settings['studio_table_border']?.toString() ?? 'boxed';
    final currentFont = _settings['studio_font_family']?.toString() ?? 'Inter';
    final currentScale = double.tryParse(_settings['studio_font_scale']?.toString() ?? '') ?? 1.0;
    final currentTitle = _settings['customTitle']?.toString() ?? 'TAX INVOICE';
    final currentWatermark = _settings['studio_watermark']?.toString() ?? 'None';
    final showQr = _settings['showQrCode'] != false;
    final lhEnabled = _settings['letterhead_enabled'] != false;
    final lhStyleId = _settings['letterhead_style_id']?.toString() ?? 'modern_ribbon';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 0. Official Company Letterhead (Header & Footer for All Documents)
        _buildSectionHeader('Company Letterhead (Header & Footer for All Documents)', Icons.branding_watermark_rounded, isDark),
        const SizedBox(height: 6),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Apply Company Letterhead Header & Footer (Invoice / Biodata)',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          subtitle: const Text(
            'Replaces standard top/bottom bars with your official letterhead banner',
            style: TextStyle(fontSize: 11),
          ),
          value: lhEnabled,
          onChanged: (val) => _updateSetting('letterhead_enabled', val, studioKey: 'letterhead_enabled'),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kLetterheadPresets.map((preset) {
            final isSel = lhStyleId == preset.id;
            return ChoiceChip(
              label: Text(
                preset.name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                  color: isSel ? Colors.white : null,
                ),
              ),
              selected: isSel,
              selectedColor: const Color(0xFF2563EB),
              onSelected: (_) async {
                await _updateSetting('letterhead_style_id', preset.id, studioKey: 'letterhead_style_id');
                if (preset.id == 'classic_traditional') {
                  await _updateSetting('letterhead_enabled', false, studioKey: 'letterhead_enabled');
                } else {
                  await _updateSetting('letterhead_enabled', true, studioKey: 'letterhead_enabled');
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // 1. Brand & Header Color Swatches
        _buildSectionHeader('Brand & Table Header Color', Icons.color_lens_outlined, isDark),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _brandColorSwatches.map((swatch) {
            final isSelected = currentColorHex.toUpperCase() == swatch.$1.toUpperCase();
            return InkWell(
              onTap: () => _updateSetting('studio_primary_color', swatch.$1, studioKey: 'studio_primary_color'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: swatch.$3.withAlpha(isDark ? 60 : 20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? swatch.$3 : Colors.grey.withAlpha(60),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: swatch.$3,
                        shape: BoxShape.circle,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 11, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      swatch.$2,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // 2. Table Grid & Border Style
        _buildSectionHeader('Line Items Table Style', Icons.grid_on_rounded, isDark),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final item in [
              ('boxed', 'Boxed Grid', Icons.border_all_rounded),
              ('striped', 'Zebra Striped', Icons.view_headline_rounded),
              ('minimal', 'Clean Dividers', Icons.horizontal_rule_rounded),
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.$3, size: 14, color: currentBorder == item.$1 ? Colors.white : null),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            item.$2,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: currentBorder == item.$1 ? Colors.white : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    selected: currentBorder == item.$1,
                    selectedColor: const Color(0xFF2563EB),
                    showCheckmark: false,
                    onSelected: (_) => _updateSetting(
                      'studio_table_border',
                      item.$1,
                      studioKey: 'studio_table_border',
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),

        // 3. Document Heading & Watermark Stamp
        _buildSectionHeader('Document Title & Watermark', Icons.title_rounded, isDark),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _docTitles.map((title) {
            final selected = currentTitle.toUpperCase() == title;
            return ChoiceChip(
              label: Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : null,
                ),
              ),
              selected: selected,
              selectedColor: const Color(0xFF2563EB),
              onSelected: (_) => _updateSetting('customTitle', title, studioKey: 'studio_doc_title'),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _watermarks.contains(currentWatermark) ? currentWatermark : 'None',
          decoration: const InputDecoration(
            labelText: 'Background Watermark Stamp',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: _watermarks
              .map((w) => DropdownMenuItem(value: w, child: Text(w, style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              _updateSetting('studio_watermark', val, studioKey: 'studio_watermark');
            }
          },
        ),
        const SizedBox(height: 20),

        // 4. Typography & Font Scaling
        _buildSectionHeader('Typography & Font Scale (${(currentScale * 100).round()}%)', Icons.text_fields_rounded, isDark),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final font in ['Inter', 'Roboto', 'Georgia', 'Courier'])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(font, style: TextStyle(fontFamily: font, fontSize: 12)),
                  selected: currentFont == font,
                  onSelected: (_) => _updateSetting('studio_font_family', font, studioKey: 'studio_font_family'),
                ),
              ),
          ],
        ),
        Slider(
          value: currentScale.clamp(0.8, 1.25),
          min: 0.8,
          max: 1.25,
          divisions: 9,
          label: '${(currentScale * 100).round()}%',
          onChanged: (val) => _updateSetting('studio_font_scale', val, studioKey: 'studio_font_scale'),
        ),
        const SizedBox(height: 12),

        // 5. Branding Assets & Digital Signatory Tools
        _buildSectionHeader('Branding Assets, Stamp & Digital Sign', Icons.verified_user_outlined, isDark),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.image_outlined, size: 17),
              label: const Text('Upload Logo', style: TextStyle(fontSize: 12)),
              onPressed: () => _pickAndUploadImage('invoiceLogo', 'Company Logo'),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.approval_rounded, size: 17),
              label: const Text('Upload Company Stamp', style: TextStyle(fontSize: 12)),
              onPressed: () => _pickAndUploadImage('invoiceStamp', 'Company Seal / Stamp'),
            ),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.draw_rounded, size: 17),
              label: const Text('DocuHub Digital Sign', style: TextStyle(fontSize: 12)),
              onPressed: () {
                Navigator.pop(context);
                widget.onOpenDocuHubSigner();
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show Dynamic UPI QR Code on Invoice', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: const Text('Scannable vector QR in Preview & PDF export', style: TextStyle(fontSize: 11)),
          value: showQr,
          onChanged: (val) => _updateSetting('showQrCode', val, studioKey: 'studio_show_qr'),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 2: SECTIONS, COLUMNS & INLINE FIELD VALUES
  // ===========================================================================
  Widget _buildSectionsAndFieldsTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Quick Inline Editor for Service Location & Billing Period
        _buildSectionHeader('Deployment Site & Billing Period Values', Icons.edit_location_alt_outlined, isDark),
        const SizedBox(height: 10),
        TextField(
          controller: _serviceLocationCtrl,
          decoration: const InputDecoration(
            labelText: 'Service Location / Site Deployed',
            border: OutlineInputBorder(),
            isDense: true,
            prefixIcon: Icon(Icons.location_on_outlined, size: 18),
          ),
          onChanged: (val) => _setFieldDefault('sec_client', 'f_cli_loc', val),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _billingPeriodCtrl,
                decoration: const InputDecoration(
                  labelText: 'Billing Period',
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: Icon(Icons.date_range_outlined, size: 18),
                ),
                onChanged: (val) => _setFieldDefault('sec_client', 'f_cli_period', val),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _signeeTitleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Signatory Designation',
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: Icon(Icons.badge_outlined, size: 18),
                ),
                onChanged: (val) => _updateSetting('signeeTitle', val, studioKey: 'signeeTitle'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _buildSectionHeader('Toggle Invoice Sections & Columns', Icons.view_agenda_outlined, isDark),
        const SizedBox(height: 6),
        Text(
          'Turn sections or specific fields/columns on or off. PDF, Print & DOCX automatically match.',
          style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey[400] : const Color(0xFF64748B)),
        ),
        const SizedBox(height: 10),

        ..._sections.map((section) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: ExpansionTile(
              initiallyExpanded: section.id == 'sec_services' || section.id == 'sec_client',
              leading: Switch(
                value: section.enabled,
                onChanged: (val) {
                  setState(() => section.enabled = val);
                  _saveSectionsAndNotify();
                },
              ),
              title: Text(
                section.title,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                section.subtitle,
                style: const TextStyle(fontSize: 11),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: section.fields.map((field) {
                    return FilterChip(
                      label: Text(
                        field.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: field.isVisible ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                      selected: field.isVisible,
                      onSelected: (val) {
                        setState(() => field.isVisible = val);
                        _saveSectionsAndNotify();
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // TAB 3: INDUSTRY TEMPLATE PRESETS
  // ===========================================================================
  Widget _buildTemplatesTab(bool isDark) {
    const categories = [
      ('All', 'All Categories'),
      ('Security Agency', '🛡️ Security Agency'),
      ('HR & Staffing', '👥 HR & Staffing'),
      ('IT & Consulting', '💻 IT & Consulting'),
      ('Retail & GST', '🛍️ Retail & GST'),
      ('Corporate Suite', '🏢 Corporate Suite'),
    ];

    final filtered = templatePresets.where((TemplateConfig p) {
      return _selectedCategory == 'All' || p.businessCategory == _selectedCategory;
    }).toList();

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: categories.map((cat) {
              final isSelected = _selectedCategory == cat.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    cat.$2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final preset = filtered[index];
              final isSelected = preset.id == _currentTemplateId;
              final color = parseTemplateColor(preset.color, Colors.blue);

              return InkWell(
                onTap: () {
                  setState(() => _currentTemplateId = preset.id);
                  _updateSetting('studio_primary_color', preset.color, studioKey: 'studio_primary_color');
                  widget.onSelectTemplate(preset);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? const Color(0xFF1E3A8A).withAlpha(60) : const Color(0xFFEFF6FF))
                        : (isDark ? const Color(0xFF334155).withAlpha(50) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : (isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color.withAlpha(35),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: color, width: 1.5),
                        ),
                        child: Center(
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              preset.name,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${preset.businessCategory} • ${preset.designStyle}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          _updateSetting('studio_primary_color', preset.color, studioKey: 'studio_primary_color');
                          widget.onSetDefaultTemplate(preset);
                          Navigator.pop(context);
                        },
                        child: const Text('Set Default', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF2563EB)),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
