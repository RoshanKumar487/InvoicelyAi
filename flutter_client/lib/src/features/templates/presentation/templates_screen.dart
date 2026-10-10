import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/widgets/app_card.dart';
import '../../settings/data/settings_repository.dart';
import '../data/template_config.dart';
import 'widgets/template_live_preview.dart';
import 'widgets/template_logo_studio.dart';
import 'widgets/template_presets_gallery.dart';

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
            TemplateLivePreview(
              config: _config,
              profile: _profile,
              logoImage: _getLogoImage(height: 36),
              saved: _saved,
            ),
            const SizedBox(height: 16),

            // SECTION 1: SECTION VISIBILITY IN TEMPLATE
            _buildSectionsVisibilityCard(),
            const SizedBox(height: 14),

            // SECTION 2: TEMPLATE LOGO STUDIO
            TemplateLogoStudioCard(
              logoWidget: _getLogoImage(height: 60),
              onPickGallery: () => _pickLogo(ImageSource.gallery),
              onPickCamera: () => _pickLogo(ImageSource.camera),
              onRemoveLogo: _removeLogo,
            ),
            const SizedBox(height: 14),

            // SECTION 3: TEMPLATE PRESETS SELECTOR
            TemplatePresetsGallery(
              selectedPresetId: _presetId,
              selectedCategory: _selectedCategory,
              selectedStyle: _selectedStyle,
              categories: _categories,
              styles: _styles,
              onSelectPreset: _selectPreset,
              onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
              onStyleChanged: (style) => setState(() => _selectedStyle = style),
            ),
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
