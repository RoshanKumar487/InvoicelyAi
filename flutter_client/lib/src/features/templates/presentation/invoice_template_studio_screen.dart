import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/api/api_client.dart';
import '../../../core/storage/local_preferences.dart';
import '../../../shared/widgets/signature_pad_dialog.dart';
import '../data/studio_section_model.dart';
import '../data/template_config.dart';
import 'widgets/invoice_section_accordion.dart';

class InvoiceTemplateStudioScreen extends StatefulWidget {
  const InvoiceTemplateStudioScreen({
    required this.apiClient,
    this.initialConfig,
    this.initialLocalSettings = const <String, Object?>{},
    this.onSaveLocalSettings,
    this.onSaveTemplate,
    this.onBack,
    super.key,
  });

  final ApiClient apiClient;
  final TemplateConfig? initialConfig;
  final Map<String, Object?> initialLocalSettings;
  final ValueChanged<Map<String, Object?>>? onSaveLocalSettings;
  final ValueChanged<TemplateConfig>? onSaveTemplate;
  final VoidCallback? onBack;

  @override
  State<InvoiceTemplateStudioScreen> createState() =>
      _InvoiceTemplateStudioScreenState();
}

class StudioTemplateOption {
  const StudioTemplateOption({
    required this.id,
    required this.name,
    required this.presetKey,
    required this.description,
    required this.primaryColor,
    this.isWasm = false,
  });

  final String id;
  final String name;
  final String presetKey;
  final String description;
  final Color primaryColor;
  final bool isWasm;
}

class _InvoiceTemplateStudioScreenState
    extends State<InvoiceTemplateStudioScreen> {
  // Top Header State
  String _templateName = 'Security Services — GST Invoice';
  String _templateStatus = 'Draft';
  bool _isEditingName = false;
  late final TextEditingController _nameController;

  // Active Top Navigation Tab
  int _activeTopTabIndex = 0;
  final List<String> _topTabs = const [
    'Template & Branding',
    'Invoice Details & Billing',
    'Line Items & Duty',
    'Tax & Totals',
    'Bank, Adjustments & Signature',
    'Advanced',
  ];

  // Industry Presets & Templates List
  String _activePreset = 'security_agency';
  String _selectedTemplateId = 'security_gst';
  String _companyDefaultTemplateId = 'security_gst';

  final List<StudioTemplateOption> _availableTemplates = const [
    StudioTemplateOption(
      id: 'security_gst',
      name: 'Security Services — GST Invoice',
      presetKey: 'security_agency',
      description: 'Optimized for security agencies: Guard counts, Duty days, shifts & GST.',
      primaryColor: Color(0xFF1E3A8A),
    ),
    StudioTemplateOption(
      id: 'gst_service',
      name: 'Professional GST Service Invoice',
      presetKey: 'gst_service',
      description: 'SAC codes, professional service billing, CGST/SGST/IGST breakdown.',
      primaryColor: Color(0xFF2563EB),
    ),
    StudioTemplateOption(
      id: 'consulting',
      name: 'Corporate Consulting Invoice',
      presetKey: 'consulting',
      description: 'Deliverables, retainer fees, advisory hours and professional disbursements.',
      primaryColor: Color(0xFF0F172A),
    ),
    StudioTemplateOption(
      id: 'retail',
      name: 'Standard Retail Store Invoice',
      presetKey: 'retail',
      description: 'Inventory items, SKU numbers, MRP, discounts and counter checkout.',
      primaryColor: Color(0xFF059669),
    ),
    StudioTemplateOption(
      id: 'modern',
      name: 'Executive Modern Clean Invoice',
      presetKey: 'modern',
      description: 'Minimalist high-contrast layout for executive billing and tech contractors.',
      primaryColor: Color(0xFF4F46E5),
    ),
  ];

  // Typography & Styling State
  String _fontFamily = 'Inter';
  double _fontScale = 1.0;
  bool _uppercaseHeadings = true;
  String _documentTitle = 'TAX INVOICE';
  Color _primaryColor = const Color(0xFF1E3A8A);
  Color _tableHeaderTextColor = Colors.white;
  String _tableBorderStyle = 'boxed'; // 'boxed', 'lines', 'striped'
  bool _showQrCode = true;
  String _watermark = 'None';
  String _pageMargin = 'Standard (16mm)';

  // Visual Branding & Authorized Signature State (DocuHub Signer)
  String? _logoBase64;
  String? _stampBase64;
  String? _signatureBase64;
  String? _signeeName;
  String? _signeeTitle;

  // Sections Model List
  late List<StudioSection> _sections;

  // Preview Workspace State
  double _zoomLevel = 1.0;
  final String _paperFormat = 'A4';
  final int _currentPage = 1;
  final int _totalPages = 1;
  String _sampleDataset = 'Security Agency (Northstar)';
  bool _previewOnlyOnMobile = false;
  bool _saving = false;
  String _saveMessage = 'Changes saved';

  // Local storage cache
  late final LocalPreferences _localPreferences;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _templateName);
    _localPreferences = LocalPreferences(scope: 'template_studio');
    _sections = StudioSection.defaultSections(preset: _activePreset);

    // Explicitly collapse all sections by default
    for (final s in _sections) {
      s.isExpanded = false;
    }

    // Apply initial settings if provided
    _initFromInitialSettings();
    _loadSavedSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedSettings() async {
    try {
      final defId = await _localPreferences.readString('company_default_template_id');
      if (defId != null && defId.isNotEmpty && mounted) {
        setState(() => _companyDefaultTemplateId = defId);
      }
      final savedFont = await _localPreferences.readString('studio_font_family');
      if (savedFont != null && savedFont.isNotEmpty && mounted) {
        setState(() => _fontFamily = savedFont);
      }
      final savedScale = await _localPreferences.readString('studio_font_scale');
      if (savedScale != null && savedScale.isNotEmpty && mounted) {
        final parsed = double.tryParse(savedScale);
        if (parsed != null && parsed > 0) {
          setState(() => _fontScale = parsed);
        }
      }
      final savedBorder = await _localPreferences.readString('studio_table_border');
      if (savedBorder != null && savedBorder.isNotEmpty && mounted) {
        setState(() => _tableBorderStyle = savedBorder);
      }
      final savedTitle = await _localPreferences.readString('studio_doc_title');
      if (savedTitle != null && savedTitle.isNotEmpty && mounted) {
        setState(() => _documentTitle = savedTitle);
      }
      final savedLogo = await _localPreferences.readString('invoiceLogo');
      if (savedLogo != null && savedLogo.isNotEmpty && mounted) {
        setState(() => _logoBase64 ??= savedLogo);
      }
      final savedStamp = await _localPreferences.readString('invoiceStamp');
      if (savedStamp != null && savedStamp.isNotEmpty && mounted) {
        setState(() => _stampBase64 ??= savedStamp);
      }
      final savedSig = await _localPreferences.readString('invoiceSignature');
      if (savedSig != null && savedSig.isNotEmpty && mounted) {
        setState(() => _signatureBase64 ??= savedSig);
      }
      final savedName = await _localPreferences.readString('signeeName');
      if (savedName != null && savedName.isNotEmpty && mounted) {
        setState(() => _signeeName ??= savedName);
      }
      final savedTitleSig = await _localPreferences.readString('signeeTitle');
      if (savedTitleSig != null && savedTitleSig.isNotEmpty && mounted) {
        setState(() => _signeeTitle ??= savedTitleSig);
      }
    } catch (_) {}
  }

  void _initFromInitialSettings() {
    if (widget.initialLocalSettings.isNotEmpty) {
      final name = widget.initialLocalSettings['studio_template_name']?.toString();
      if (name != null && name.isNotEmpty) {
        _templateName = name;
        _nameController.text = name;
      }
      final defaultTpl = widget.initialLocalSettings['preferredTemplateId']?.toString() ??
          widget.initialLocalSettings['company_default_template_id']?.toString();
      if (defaultTpl != null && defaultTpl.isNotEmpty) {
        _companyDefaultTemplateId = defaultTpl;
        _selectedTemplateId = defaultTpl;
      }
      _logoBase64 = widget.initialLocalSettings['invoiceLogo']?.toString();
      _stampBase64 = widget.initialLocalSettings['invoiceStamp']?.toString();
      _signatureBase64 = widget.initialLocalSettings['invoiceSignature']?.toString();
      _signeeName = widget.initialLocalSettings['signeeName']?.toString();
      _signeeTitle = widget.initialLocalSettings['signeeTitle']?.toString();

      final savedSectionsJson =
          widget.initialLocalSettings['studio_sections_json']?.toString();
      if (savedSectionsJson != null && savedSectionsJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(savedSectionsJson) as List<dynamic>;
          final parsed = decoded
              .map((e) => StudioSection.fromJson(e as Map<String, dynamic>))
              .toList();
          if (parsed.isNotEmpty) {
            _sections = parsed;
          }
        } catch (_) {}
      }
    }
    // Ensure all loaded sections remain collapsed by default
    for (final s in _sections) {
      s.isExpanded = false;
    }
  }

  void _switchPreset(String presetKey) {
    setState(() {
      _activePreset = presetKey;
      final matched = _availableTemplates.firstWhere(
        (t) => t.presetKey == presetKey,
        orElse: () => _availableTemplates.first,
      );
      _selectedTemplateId = matched.id;
      _templateName = matched.name;
      _nameController.text = _templateName;
      _primaryColor = matched.primaryColor;

      if (presetKey == 'security_agency') {
        _tableBorderStyle = 'boxed';
        _sampleDataset = 'Security Agency (Northstar)';
      } else if (presetKey == 'gst_service') {
        _sampleDataset = 'GST Service Tech';
      } else if (presetKey == 'consulting') {
        _sampleDataset = 'Apex Consulting';
      } else {
        _sampleDataset = 'Retail Mart';
      }

      _sections = StudioSection.defaultSections(preset: presetKey);
      // Ensure all sections are collapsed by default
      for (final s in _sections) {
        s.isExpanded = false;
      }
      _markSaved();
    });
  }

  void _selectTemplate(StudioTemplateOption t) {
    setState(() {
      _selectedTemplateId = t.id;
    });
    _switchPreset(t.presetKey);
  }

  Future<void> _setAsCompanyDefault() async {
    setState(() {
      _companyDefaultTemplateId = _selectedTemplateId;
      _saveMessage = 'Set as Default';
    });
    await _localPreferences.writeString('company_default_template_id', _selectedTemplateId);
    await _localPreferences.writeString('preferredTemplateId', _selectedTemplateId);
    await _localPreferences.writeString('company_default_template_name', _templateName);
    await _autoSaveLocal();

    widget.onSaveTemplate?.call(
      TemplateConfig(
        id: _selectedTemplateId,
        name: _templateName,
        title: _documentTitle.isNotEmpty ? _documentTitle : _templateName,
        category: _activePreset,
        color: '#${_primaryColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
        font: _fontFamily,
        itemHeader: _activePreset == 'security_agency' ? 'Particulars' : 'Description',
        businessCategory: _activePreset == 'security_agency' ? 'Security Agency' : 'Corporate Suite',
        dutyHeader: 'Duty Days',
        showDuty: true,
        quantityHeader: _activePreset == 'security_agency' ? 'Guards' : 'Qty',
        rateHeader: 'Rate (₹)',
        amountHeader: 'Amount (₹)',
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('★ "$_templateName" set as your company default invoice template!'),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 400,
        imageQuality: 85,
      );
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      final base64Str = base64Encode(bytes);
      setState(() => _logoBase64 = base64Str);
      _markSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Company Logo uploaded & updated in live preview!'),
            backgroundColor: Color(0xFF0F172A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not upload logo: $e')),
        );
      }
    }
  }

  void _removeLogo() {
    setState(() => _logoBase64 = null);
    _localPreferences.remove('invoiceLogo');
    _markSaved();
  }

  Future<void> _pickStamp() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      final base64Str = base64Encode(bytes);
      setState(() => _stampBase64 = base64Str);
      _markSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Official Company Stamp uploaded & updated in live preview!'),
            backgroundColor: Color(0xFF0F172A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not upload stamp: $e')),
        );
      }
    }
  }

  void _removeStamp() {
    setState(() => _stampBase64 = null);
    _localPreferences.remove('invoiceStamp');
    _markSaved();
  }

  Future<void> _captureSignatureInStudio() async {
    final result = await SignaturePadDialog.show(
      context,
      initialSigneeName: _signeeName,
      initialSigneeTitle: _signeeTitle,
    );
    if (result == null) return;
    setState(() {
      _signatureBase64 = result.base64Png;
      if (result.signeeName != null && result.signeeName!.isNotEmpty) {
        _signeeName = result.signeeName;
      }
      if (result.signeeTitle != null && result.signeeTitle!.isNotEmpty) {
        _signeeTitle = result.signeeTitle;
      }
    });
    _markSaved();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Digital Signature captured via DocuHub Signer!'),
          backgroundColor: Color(0xFF0F172A),
        ),
      );
    }
  }

  void _removeSignature() {
    setState(() => _signatureBase64 = null);
    _localPreferences.remove('invoiceSignature');
    _markSaved();
  }

  void _onSectionEnabledChanged(StudioSection section, bool enabled) {
    setState(() {
      section.enabled = enabled;
      _markSaved();
    });
  }

  void _onSectionExpansionChanged(StudioSection section, bool isExpanded) {
    setState(() {
      section.isExpanded = isExpanded;
    });
  }

  void _onFieldVisibilityChanged(StudioSection section, StudioField field, bool isVisible) {
    setState(() {
      field.isVisible = isVisible;
      _markSaved();
    });
  }

  void _markSaved() {
    _saveMessage = 'Changes saved';
    _autoSaveLocal();
  }

  Future<void> _autoSaveLocal() async {
    final sectionsJson =
        jsonEncode(_sections.map((s) => s.toJson()).toList());
    final data = <String, Object?>{
      'studio_template_name': _templateName,
      'studio_preset': _activePreset,
      'studio_sections_json': sectionsJson,
      'businessCategory': _activePreset == 'security_agency' ? 'Security Agency' : 'Corporate Suite',
      'dutyHeader': 'Duty Days',
      'showDuty': true,
      'preferredTemplateId': _selectedTemplateId,
      'company_default_template_id': _companyDefaultTemplateId,
      'templateId': _selectedTemplateId,
      'customTitle': _documentTitle,
      'invoiceLogo': _logoBase64,
      'invoiceStamp': _stampBase64,
      'invoiceSignature': _signatureBase64,
      'signeeName': _signeeName,
      'signeeTitle': _signeeTitle,
      'showLogo': _logoBase64 != null && _logoBase64!.isNotEmpty,
      'showStamp': _stampBase64 != null && _stampBase64!.isNotEmpty,
      'showSignature': _signatureBase64 != null && _signatureBase64!.isNotEmpty,
    };
    widget.onSaveLocalSettings?.call(data);
    await _localPreferences.writeString('sections_cache', sectionsJson);
    if (_logoBase64 != null) {
      await _localPreferences.writeString('invoiceLogo', _logoBase64!);
    }
    if (_stampBase64 != null) {
      await _localPreferences.writeString('invoiceStamp', _stampBase64!);
    }
    if (_signatureBase64 != null) {
      await _localPreferences.writeString('invoiceSignature', _signatureBase64!);
    }
    if (_signeeName != null) {
      await _localPreferences.writeString('signeeName', _signeeName!);
    }
    if (_signeeTitle != null) {
      await _localPreferences.writeString('signeeTitle', _signeeTitle!);
    }
  }

  Future<void> _saveDraft() async {
    setState(() => _saving = true);
    try {
      final sectionsJson =
          jsonEncode(_sections.map((s) => s.toJson()).toList());
      final payload = {
        'name': _templateName,
        'title': _templateName,
        'industryPreset': _activePreset,
        'status': 'DRAFT',
        'configurationJson': sectionsJson,
        'businessCategory': _activePreset == 'security_agency' ? 'Security' : 'Corporate',
      };

      try {
        await widget.apiClient.postJson('/api/v1/templates', payload);
      } catch (_) {
        // Fallback gracefully for offline/local resilience
      }

      await _autoSaveLocal();
      setState(() {
        _templateStatus = 'Draft';
        _saveMessage = 'Draft saved to server';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Template draft saved successfully!'),
            backgroundColor: Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _publishTemplate() async {
    setState(() => _saving = true);
    try {
      final sectionsJson =
          jsonEncode(_sections.map((s) => s.toJson()).toList());
      final payload = {
        'name': _templateName,
        'title': _templateName,
        'industryPreset': _activePreset,
        'status': 'PUBLISHED',
        'isDefault': true,
        'configurationJson': sectionsJson,
      };

      try {
        await widget.apiClient.postJson('/api/v1/templates', payload);
      } catch (_) {
        // Fallback for offline/local resilience
      }

      await _autoSaveLocal();

      // Notify parent template config
      widget.onSaveTemplate?.call(
        TemplateConfig(
          id: 'tpl_$_activePreset',
          name: _templateName,
          title: _templateName,
          category: _activePreset,
          color: '#2563EB',
          font: 'Inter',
          itemHeader: 'Particulars',
          businessCategory: _activePreset == 'security_agency' ? 'Security' : 'Corporate',
          dutyHeader: 'Duty Days',
          showDuty: true,
          quantityHeader: 'Guards',
          rateHeader: 'Rate (₹)',
          amountHeader: 'Amount (₹)',
        ),
      );

      setState(() {
        _templateStatus = 'Published';
        _saveMessage = 'Published & Active';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚀 Template published and set as company default!'),
            backgroundColor: Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showAddFieldDialog(StudioSection section) {
    final labelCtrl = TextEditingController();
    final defaultValCtrl = TextEditingController();
    StudioFieldType selectedType = StudioFieldType.text;
    bool isRequired = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.add_circle_outline, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text('Add Custom Field to "${section.title}"',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Field Label *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: labelCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Supervisor Name, Shift ID',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Field Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<StudioFieldType>(
                  value: selectedType,
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: StudioFieldType.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Row(
                        children: [
                          Icon(t.icon, size: 16, color: const Color(0xFF475569)),
                          const SizedBox(width: 8),
                          Text(t.label),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 14),
                const Text('Default Value (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: defaultValCtrl,
                  decoration: InputDecoration(
                    hintText: 'Initial value',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Required Field', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  value: isRequired,
                  activeColor: const Color(0xFF2563EB),
                  onChanged: (val) => setDlgState(() => isRequired = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final label = labelCtrl.text.trim();
                if (label.isEmpty) return;
                setState(() {
                  section.fields.add(
                    StudioField(
                      id: 'fld_${DateTime.now().microsecondsSinceEpoch}',
                      label: label,
                      type: selectedType,
                      isRequired: isRequired,
                      isVisible: true,
                      defaultValue: defaultValCtrl.text.trim(),
                    ),
                  );
                  _markSaved();
                });
                Navigator.of(ctx).pop();
              },
              child: const Text('Add Field'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditFieldDialog(StudioSection section, StudioField field) {
    final labelCtrl = TextEditingController(text: field.label);
    final defaultValCtrl = TextEditingController(text: field.defaultValue);
    StudioFieldType selectedType = field.type;
    bool isRequired = field.isRequired;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Edit Field "${field.label}"',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Field Label', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: labelCtrl,
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Field Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<StudioFieldType>(
                  value: selectedType,
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: StudioFieldType.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Row(
                        children: [
                          Icon(t.icon, size: 16, color: const Color(0xFF475569)),
                          const SizedBox(width: 8),
                          Text(t.label),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 14),
                const Text('Default Value', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: defaultValCtrl,
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Required Field', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  value: isRequired,
                  activeColor: const Color(0xFF2563EB),
                  onChanged: (val) => setDlgState(() => isRequired = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final label = labelCtrl.text.trim();
                if (label.isEmpty) return;
                setState(() {
                  field.label = label;
                  field.type = selectedType;
                  field.isRequired = isRequired;
                  field.defaultValue = defaultValCtrl.text.trim();
                  _markSaved();
                });
                Navigator.of(ctx).pop();
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _duplicateField(StudioSection section, StudioField field) {
    setState(() {
      final copy = field.copyWith(
        id: 'fld_${DateTime.now().microsecondsSinceEpoch}',
        label: '${field.label} (Copy)',
      );
      final idx = section.fields.indexOf(field);
      if (idx != -1) {
        section.fields.insert(idx + 1, copy);
      } else {
        section.fields.add(copy);
      }
      _markSaved();
    });
  }

  void _deleteField(StudioSection section, StudioField field) {
    if (field.isRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot remove required field "${field.label}"'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      section.fields.remove(field);
      _markSaved();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Field "${field.label}" removed from template'),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          textColor: const Color(0xFF93C5FD),
          onPressed: () {
            setState(() {
              section.fields.add(field);
              _markSaved();
            });
          },
        ),
      ),
    );
  }

  void _showStyleDialog() {
    String tempFont = _fontFamily;
    double tempScale = _fontScale;
    bool tempUppercase = _uppercaseHeadings;
    String tempTitle = _documentTitle;
    Color tempPrimary = _primaryColor;
    Color tempHeaderText = _tableHeaderTextColor;
    String tempBorderStyle = _tableBorderStyle;
    final titleCtrl = TextEditingController(text: tempTitle);

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.palette_outlined, color: Color(0xFF2563EB), size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Document Style & Typography',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // 1. Document Title Text
                  const Text('Document Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. TAX INVOICE',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (v) => tempTitle = v,
                  ),
                  const SizedBox(height: 12),

                  // Uppercase headings toggle
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Uppercase Headings', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Display titles in capital letters (TAX INVOICE)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    value: tempUppercase,
                    activeColor: const Color(0xFF2563EB),
                    onChanged: (v) => setDlgState(() => tempUppercase = v),
                  ),
                  const Divider(height: 20),

                  // 2. Font Family
                  const Text('Font Family', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: ['Inter', 'Roboto', 'Poppins', 'Merriweather', 'Courier'].map((font) {
                      final isSel = tempFont == font;
                      return ChoiceChip(
                        label: Text(font, style: TextStyle(fontSize: 11.5, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                        selected: isSel,
                        selectedColor: const Color(0xFF2563EB),
                        labelStyle: TextStyle(color: isSel ? Colors.white : const Color(0xFF334155)),
                        onSelected: (_) => setDlgState(() => tempFont = font),
                      );
                    }).toList(),
                  ),
                  const Divider(height: 20),

                  // 3. Text Size Scale
                  const Text('Font Size Scaling', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildScaleBtn('Compact (88%)', 0.88, tempScale, (s) => setDlgState(() => tempScale = s)),
                      const SizedBox(width: 8),
                      _buildScaleBtn('Standard (100%)', 1.0, tempScale, (s) => setDlgState(() => tempScale = s)),
                      const SizedBox(width: 8),
                      _buildScaleBtn('Large (112%)', 1.12, tempScale, (s) => setDlgState(() => tempScale = s)),
                    ],
                  ),
                  const Divider(height: 20),

                  // 4. Primary Brand / Table Header Color
                  const Text('Brand & Table Header Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: const [
                      Color(0xFF1E3A8A), // Navy
                      Color(0xFF2563EB), // Royal Blue
                      Color(0xFF0284C7), // Sky Tech
                      Color(0xFF0F172A), // Slate Dark
                      Color(0xFF059669), // Emerald
                      Color(0xFF991B1B), // Crimson
                      Color(0xFFD97706), // Amber
                      Color(0xFF7C3AED), // Purple
                      Color(0xFF0D9488), // Teal
                    ].map((col) {
                      final isSel = tempPrimary == col;
                      return InkWell(
                        onTap: () => setDlgState(() => tempPrimary = col),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: col,
                            shape: BoxShape.circle,
                            border: Border.all(color: isSel ? Colors.white : Colors.transparent, width: 2),
                            boxShadow: [
                              if (isSel)
                                BoxShadow(color: col.withValues(alpha: 0.5), blurRadius: 6, spreadRadius: 2),
                            ],
                          ),
                          child: isSel ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const Divider(height: 20),

                  // 5. Table Header Text Color
                  const Text('Table Header Text Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('White Text', style: TextStyle(fontSize: 11)),
                        selected: tempHeaderText == Colors.white,
                        selectedColor: const Color(0xFF0F172A),
                        labelStyle: TextStyle(color: tempHeaderText == Colors.white ? Colors.white : const Color(0xFF334155)),
                        onSelected: (_) => setDlgState(() => tempHeaderText = Colors.white),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Dark Text', style: TextStyle(fontSize: 11)),
                        selected: tempHeaderText == const Color(0xFF1E293B),
                        selectedColor: const Color(0xFF0F172A),
                        labelStyle: TextStyle(color: tempHeaderText == const Color(0xFF1E293B) ? Colors.white : const Color(0xFF334155)),
                        onSelected: (_) => setDlgState(() => tempHeaderText = const Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // 6. Table Border Style (Boxed vs Lines vs Striped)
                  const Text('Line Items Border Style', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildBorderBtn('Boxed Borders', 'boxed', tempBorderStyle, (b) => setDlgState(() => tempBorderStyle = b)),
                      const SizedBox(width: 8),
                      _buildBorderBtn('Clean Dividers', 'lines', tempBorderStyle, (b) => setDlgState(() => tempBorderStyle = b)),
                      const SizedBox(width: 8),
                      _buildBorderBtn('Striped Rows', 'striped', tempBorderStyle, (b) => setDlgState(() => tempBorderStyle = b)),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                setState(() {
                  _fontFamily = tempFont;
                  _fontScale = tempScale;
                  _uppercaseHeadings = tempUppercase;
                  _documentTitle = titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : tempTitle;
                  _primaryColor = tempPrimary;
                  _tableHeaderTextColor = tempHeaderText;
                  _tableBorderStyle = tempBorderStyle;
                  _markSaved();
                });
                _localPreferences.writeString('studio_font_family', _fontFamily);
                _localPreferences.writeString('studio_font_scale', _fontScale.toString());
                _localPreferences.writeString('studio_table_border', _tableBorderStyle);
                _localPreferences.writeString('studio_doc_title', _documentTitle);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Style applied to invoice template!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Apply Style', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScaleBtn(String label, double scale, double current, ValueChanged<double> onSelect) {
    final isSel = (current - scale).abs() < 0.01;
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          backgroundColor: isSel ? const Color(0xFF2563EB) : Colors.white,
          side: BorderSide(color: isSel ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => onSelect(scale),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
            color: isSel ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildBorderBtn(String label, String key, String current, ValueChanged<String> onSelect) {
    final isSel = current == key;
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          backgroundColor: isSel ? const Color(0xFF2563EB) : Colors.white,
          side: BorderSide(color: isSel ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => onSelect(key),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
            color: isSel ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  void _showPageSettingsDialog() {
    bool tempQr = _showQrCode;
    String tempWatermark = _watermark;
    String tempMargin = _pageMargin;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.tune_rounded, color: Color(0xFF2563EB), size: 18),
              SizedBox(width: 8),
              Text('Page & Document Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Paper Format', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              const SizedBox(height: 6),
              Row(
                children: const [
                  Chip(label: Text('A4 (210 × 297 mm)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)))),
                  SizedBox(width: 8),
                  Chip(label: Text('Letter (8.5 × 11 in)', style: TextStyle(fontSize: 11))),
                ],
              ),
              const Divider(height: 20),
              const Text('Page Margins', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: ['Compact (10mm)', 'Standard (16mm)', 'Spacious (24mm)'].map((m) {
                  final isSel = tempMargin == m;
                  return ChoiceChip(
                    label: Text(m, style: const TextStyle(fontSize: 11)),
                    selected: isSel,
                    selectedColor: const Color(0xFF2563EB),
                    labelStyle: TextStyle(color: isSel ? Colors.white : const Color(0xFF334155)),
                    onSelected: (_) => setDlgState(() => tempMargin = m),
                  );
                }).toList(),
              ),
              const Divider(height: 20),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Show UPI Scan & Pay QR Code', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                value: tempQr,
                activeColor: const Color(0xFF2563EB),
                onChanged: (v) => setDlgState(() => tempQr = v),
              ),
              const Divider(height: 20),
              const Text('Watermark', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: ['None', 'DRAFT', 'ORIGINAL FOR RECIPIENT'].map((w) {
                  final isSel = tempWatermark == w;
                  return ChoiceChip(
                    label: Text(w, style: const TextStyle(fontSize: 11)),
                    selected: isSel,
                    selectedColor: const Color(0xFF2563EB),
                    labelStyle: TextStyle(color: isSel ? Colors.white : const Color(0xFF334155)),
                    onSelected: (_) => setDlgState(() => tempWatermark = w),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                setState(() {
                  _showQrCode = tempQr;
                  _watermark = tempWatermark;
                  _pageMargin = tempMargin;
                  _markSaved();
                });
                Navigator.of(ctx).pop();
              },
              child: const Text('Save Settings', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showTemplateSelectorDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_mosaic_rounded, color: Color(0xFF2563EB), size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Select Invoice Template',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                for (final t in _availableTemplates) ...[
                  _buildTemplateOptionCard(ctx, t),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildTemplateOptionCard(BuildContext ctx, StudioTemplateOption t) {
    final isCurrent = _activePreset == t.presetKey;
    final isDefault = _companyDefaultTemplateId == t.id;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
          width: isCurrent ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: t.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                t.isWasm ? Icons.view_compact_rounded : Icons.description_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.name,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isCurrent ? const Color(0xFF1E3A8A) : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, size: 12, color: Color(0xFFD97706)),
                            SizedBox(width: 3),
                            Text(
                              'Default',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (t.isWasm) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'WASM Engine',
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  t.description,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCurrent ? const Color(0xFF0F172A) : const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () {
                        _selectTemplate(t);
                        Navigator.of(ctx).pop();
                      },
                      child: Text(
                        isCurrent ? 'Active & Editing' : 'Select & Edit',
                        style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!isDefault)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () {
                          _selectTemplate(t);
                          _setAsCompanyDefault();
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Set as Default', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSectionDialog() {
    final titleCtrl = TextEditingController();
    final subtitleCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.library_add_outlined, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Add Custom Section', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Section Title *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Compliance & Approvals',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Subtitle / Description', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: subtitleCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Regulatory compliance and statutory details',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;
              setState(() {
                _sections.add(
                  StudioSection(
                    id: 'sec_${DateTime.now().microsecondsSinceEpoch}',
                    title: title,
                    subtitle: subtitleCtrl.text.trim(),
                    icon: Icons.layers_outlined,
                    enabled: true,
                    isExpanded: true,
                    fields: [
                      StudioField(
                        id: 'fld_${DateTime.now().microsecondsSinceEpoch}',
                        label: 'Reference ID',
                        type: StudioFieldType.text,
                        isRequired: false,
                        isVisible: true,
                      ),
                    ],
                  ),
                );
                _markSaved();
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Create Section'),
          ),
        ],
      ),
    );
  }

  void _exportPdfDocument() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'NORTHSTAR SECURITY SERVICES',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('1E3A8A'),
                        ),
                      ),
                      pw.Text(
                        'Safe People | Secure Tomorrow',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColor.fromHex('64748B'),
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Northstar Security Services Ltd.',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('#12, Green Park, Bengaluru - 560076', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('GSTIN: 29ABCDE1234F1Z5 | PAN: ABCDE1234F', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(color: PdfColor.fromHex('2563EB'), thickness: 1.5),
              pw.SizedBox(height: 12),

              // Title and Meta
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TAX INVOICE',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Invoice No: INV-2025-0148', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Issue Date: 15 Apr 2025', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Due Date: 30 Apr 2025', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Client Box
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromHex('CBD5E1')),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Bill To:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          pw.Text('ABC Industries Pvt. Ltd.', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          pw.Text('101, Business Tower, MG Road, Bengaluru - 560001', style: const pw.TextStyle(fontSize: 8)),
                          pw.Text('GSTIN: 29AABCA1234B1Z2', style: const pw.TextStyle(fontSize: 8)),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Service Location & Billing Period:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          pw.Text('Tech Park, Whitefield, Bengaluru - 560066', style: const pw.TextStyle(fontSize: 8)),
                          pw.Text('Period: 01 Apr 2025 - 30 Apr 2025 (30 Days)', style: const pw.TextStyle(fontSize: 8)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColor.fromHex('E2E8F0')),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(2),
                  4: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('1E3A8A')),
                    children: [
                      _pdfTh('Particulars'),
                      _pdfTh('Guards'),
                      _pdfTh('Duty Days'),
                      _pdfTh('Rate (INR)'),
                      _pdfTh('Amount (INR)'),
                    ],
                  ),
                  _pdfTr('Security Guard (12-hour shift)', '4', '26', '2,150.00', '2,23,600.00'),
                  _pdfTr('Armed Guard (12-hour shift)', '2', '26', '2,850.00', '1,48,200.00'),
                ],
              ),
              pw.SizedBox(height: 16),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 220,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        _pdfTotalRow('Subtotal', 'INR 3,71,800.00'),
                        _pdfTotalRow('Discount', '(-) INR 5,000.00'),
                        _pdfTotalRow('Taxable Amount', 'INR 3,66,800.00'),
                        _pdfTotalRow('CGST (9%)', 'INR 33,012.00'),
                        _pdfTotalRow('SGST (9%)', 'INR 33,012.00'),
                        pw.Divider(color: PdfColor.fromHex('CBD5E1')),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Grand Total', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                            pw.Text('INR 4,32,824.00', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('1E3A8A'))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),

              // Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Thank you for your business!', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('Page 1 of 1', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_Template_Export.pdf',
    );
  }

  pw.Widget _pdfTh(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  pw.TableRow _pdfTr(String c1, String c2, String c3, String c4, String c5) {
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(c1, style: const pw.TextStyle(fontSize: 8))),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(c2, style: const pw.TextStyle(fontSize: 8))),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(c3, style: const pw.TextStyle(fontSize: 8))),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(c4, style: const pw.TextStyle(fontSize: 8))),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(c5, style: const pw.TextStyle(fontSize: 8))),
      ],
    );
  }

  pw.Widget _pdfTotalRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Studio Bar
            _buildTopStudioBar(),

            // 2. Sub-Header Navigation Tabs
            _buildTopSubHeaderTabs(),

            // 3. Main Split Content Area
            Expanded(
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Pane: Accordion Studio
                        SizedBox(
                          width: 490,
                          child: _buildLeftAccordionEditor(),
                        ),
                        const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),

                        // Right Pane: A4 Document Canvas Workspace
                        Expanded(
                          child: _buildRightPreviewWorkspace(),
                        ),
                      ],
                    )
                  : _buildMobileView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileView() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Accordion Studio')),
                  selected: !_previewOnlyOnMobile,
                  onSelected: (val) => setState(() => _previewOnlyOnMobile = !val),
                  selectedColor: const Color(0xFFEFF6FF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('A4 Preview')),
                  selected: _previewOnlyOnMobile,
                  onSelected: (val) => setState(() => _previewOnlyOnMobile = val),
                  selectedColor: const Color(0xFFEFF6FF),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _previewOnlyOnMobile
              ? _buildRightPreviewWorkspace()
              : _buildLeftAccordionEditor(),
        ),
      ],
    );
  }

  // 1. Top Studio Bar
  Widget _buildTopStudioBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
            tooltip: 'Back to settings',
            onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 8),

          // Studio Badge Icon (Blue rounded square)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome_mosaic_rounded, size: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),

          // Title
          const Text(
            'Invoice Template Studio',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 14),

          // Separator Pipe
          Container(width: 1.5, height: 18, color: const Color(0xFFCBD5E1)),
          const SizedBox(width: 14),

          // Template Selector Dropdown Pill
          if (_isEditingName)
            SizedBox(
              width: 250,
              child: TextField(
                controller: _nameController,
                autofocus: true,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onSubmitted: (val) {
                  setState(() {
                    _templateName = val.trim().isNotEmpty ? val.trim() : _templateName;
                    _isEditingName = false;
                    _markSaved();
                  });
                },
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: _showTemplateSelectorDialog,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.style_outlined,
                          size: 15,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 7),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 240),
                          child: Text(
                            _templateName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF64748B)),
                  tooltip: 'Rename Template',
                  onPressed: () => setState(() => _isEditingName = true),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                ),
              ],
            ),
          const SizedBox(width: 10),

          // Default Template Pill or "Set Default" Action
          if (_companyDefaultTemplateId == _selectedTemplateId)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, size: 13, color: Color(0xFFD97706)),
                  SizedBox(width: 3),
                  Text(
                    'Default',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                  ),
                ],
              ),
            )
          else
            OutlinedButton.icon(
              icon: const Icon(Icons.star_border_rounded, size: 13, color: Color(0xFFD97706)),
              label: const Text('Set Default', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFB45309))),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                side: const BorderSide(color: Color(0xFFFDE68A)),
                backgroundColor: const Color(0xFFFFFBEB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: _setAsCompanyDefault,
            ),
          const SizedBox(width: 10),

          // Draft / Published Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
            decoration: BoxDecoration(
              color: _templateStatus == 'Published' ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _templateStatus == 'Published' ? const Color(0xFFA7F3D0) : const Color(0xFFCBD5E1),
              ),
            ),
            child: Text(
              _templateStatus,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _templateStatus == 'Published' ? const Color(0xFF059669) : const Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Save status indicator
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF16A34A)),
              const SizedBox(width: 4),
              Text(
                _saveMessage,
                style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w500),
              ),
            ],
          ),

          const Spacer(),

          // Right Action Buttons
          OutlinedButton.icon(
            icon: const Icon(Icons.visibility_outlined, size: 15, color: Color(0xFF334155)),
            label: const Text('Preview', style: TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() => _previewOnlyOnMobile = true);
            },
          ),
          const SizedBox(width: 10),

          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              side: const BorderSide(color: Color(0xFF93C5FD)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _saving ? null : _saveDraft,
            child: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save Draft', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
          ),
          const SizedBox(width: 10),

          ElevatedButton.icon(
            icon: const Icon(Icons.rocket_launch_rounded, size: 15, color: Colors.white),
            label: const Text('Publish', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: _saving ? null : _publishTemplate,
          ),
          const SizedBox(width: 6),

          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onSelected: (val) {
              if (val == 'reset') {
                setState(() => _sections = StudioSection.defaultSections(preset: _activePreset));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sections reset to default')));
              } else if (val == 'export') {
                _exportPdfDocument();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'export', child: Text('Export PDF Document')),
              const PopupMenuItem(value: 'duplicate', child: Text('Duplicate Template')),
              const PopupMenuItem(value: 'reset', child: Text('Reset to Preset Defaults')),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Sub-Header Navigation Tabs
  Widget _buildTopSubHeaderTabs() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < _topTabs.length; i++)
              _buildTopTabItem(
                title: _topTabs[i],
                isSelected: _activeTopTabIndex == i,
                onTap: () {
                  setState(() => _activeTopTabIndex = i);
                  _onTabSelected(i);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTabItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    IconData icon = switch (title) {
      'Template & Branding' => Icons.view_quilt_outlined,
      'Invoice Details & Billing' => Icons.description_outlined,
      'Line Items & Duty' => Icons.format_list_bulleted_rounded,
      'Tax & Totals' => Icons.percent_rounded,
      'Bank, Adjustments & Signature' => Icons.account_balance_outlined,
      _ => Icons.tune_outlined,
    };

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTabSelected(int index) {
    // Expand matching sections in the accordion
    final targetSectionIds = switch (index) {
      0 => ['sec_branding'],
      1 => ['sec_identity', 'sec_client'],
      2 => ['sec_services'],
      3 => ['sec_tax_totals'],
      4 => ['sec_bank', 'sec_terms'],
      _ => <String>[],
    };

    if (targetSectionIds.isNotEmpty) {
      setState(() {
        for (final s in _sections) {
          if (targetSectionIds.contains(s.id)) {
            s.isExpanded = true;
          }
        }
      });
    }
  }

  Widget _buildBrandingAssetsCustomContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.palette_outlined, size: 16, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              const Text(
                'Branding Assets (Company Logo & Official Stamp)',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Live Sync',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Upload your official company logo and round/oval seal for live A4 document branding and PDF generation.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          // Logo Row
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: _logoBase64 != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.memory(
                          base64Decode(_logoBase64!),
                          fit: BoxFit.contain,
                        ),
                      )
                    : const Icon(Icons.business_outlined, color: Color(0xFF94A3B8), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Company Logo',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    ),
                    Text(
                      _logoBase64 != null ? 'Logo uploaded & active on invoices' : 'No logo uploaded (using preset icon)',
                      style: TextStyle(fontSize: 11, color: _logoBase64 != null ? const Color(0xFF059669) : const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                icon: Icon(_logoBase64 != null ? Icons.edit_outlined : Icons.upload_outlined, size: 14),
                label: Text(_logoBase64 != null ? 'Replace' : 'Upload Logo', style: const TextStyle(fontSize: 11.5)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: const BorderSide(color: Color(0xFF93C5FD)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  backgroundColor: Colors.white,
                ),
                onPressed: _pickLogo,
              ),
              if (_logoBase64 != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                  tooltip: 'Remove Logo',
                  onPressed: _removeLogo,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 10),
          // Stamp Row
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: _stampBase64 != null
                    ? ClipOval(
                        child: Image.memory(
                          base64Decode(_stampBase64!),
                          fit: BoxFit.contain,
                        ),
                      )
                    : const Icon(Icons.verified_outlined, color: Color(0xFF94A3B8), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Official Company Stamp / Seal',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    ),
                    Text(
                      _stampBase64 != null ? 'Stamp uploaded & applied to signature block' : 'No stamp uploaded',
                      style: TextStyle(fontSize: 11, color: _stampBase64 != null ? const Color(0xFF059669) : const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                icon: Icon(_stampBase64 != null ? Icons.edit_outlined : Icons.upload_outlined, size: 14),
                label: Text(_stampBase64 != null ? 'Replace' : 'Upload Stamp', style: const TextStyle(fontSize: 11.5)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: const BorderSide(color: Color(0xFF93C5FD)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  backgroundColor: Colors.white,
                ),
                onPressed: _pickStamp,
              ),
              if (_stampBase64 != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                  tooltip: 'Remove Stamp',
                  onPressed: _removeStamp,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBankCustomContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.account_balance_outlined, color: Color(0xFF2563EB), size: 18),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bank Account & Payment QR',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                Text(
                  'Bank transfer details & UPI QR codes automatically display in payment box.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.draw_rounded, size: 14),
            label: const Text('Capture Signature', style: TextStyle(fontSize: 11)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              side: const BorderSide(color: Color(0xFF93C5FD)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              backgroundColor: Colors.white,
            ),
            onPressed: _captureSignatureInStudio,
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureCustomContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.draw_rounded, size: 16, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              const Text(
                'Authorized Digital Signature (DocuHub Signer)',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Text(
                  'Legal Signatory',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Draw ink signature or create styled typography to sign generated invoices and PDF documents.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          // Signature Preview & Capture Action
          Row(
            children: [
              Container(
                width: 140,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: _signatureBase64 != null
                    ? Padding(
                        padding: const EdgeInsets.all(4),
                        child: Image.memory(
                          base64Decode(_signatureBase64!),
                          fit: BoxFit.contain,
                        ),
                      )
                    : const Center(
                        child: Text(
                          'No Signature Saved',
                          style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.draw_outlined, size: 15),
                      label: Text(
                        _signatureBase64 != null ? 'Redraw / Edit Signature' : 'Capture / Draw Signature',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _captureSignatureInStudio,
                    ),
                    if (_signatureBase64 != null) ...[
                      const SizedBox(height: 4),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFEF4444)),
                        label: const Text('Clear Signature', style: TextStyle(fontSize: 11, color: Color(0xFFEF4444))),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: _removeSignature,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Metadata Fields: Signatory Name & Title
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _signeeName ?? '',
                  decoration: InputDecoration(
                    labelText: 'Signatory Name',
                    hintText: 'e.g. R. K. Sharma',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (val) {
                    _signeeName = val;
                    _markSaved();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: _signeeTitle ?? 'Authorized Signatory',
                  decoration: InputDecoration(
                    labelText: 'Signatory Title',
                    hintText: 'e.g. Director / Partner',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (val) {
                    _signeeTitle = val;
                    _markSaved();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Left Column: Accordion Section Editor
  Widget _buildLeftAccordionEditor() {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Industry Preset Block
          _buildIndustryPresetsHeader(),
          const SizedBox(height: 16),

          // Accordion Section Cards
          for (final section in _sections)
            InvoiceSectionAccordion(
              section: section,
              customContent: switch (section.id) {
                'sec_branding' => _buildBrandingAssetsCustomContent(),
                'sec_bank' => _buildBankCustomContent(),
                'sec_terms' => _buildSignatureCustomContent(),
                _ => null,
              },
              onEnabledChanged: (val) => _onSectionEnabledChanged(section, val),
              onExpansionChanged: (val) => _onSectionExpansionChanged(section, val),
              onFieldVisibilityChanged: (field, isVis) =>
                  _onFieldVisibilityChanged(section, field, isVis),
              onAddField: () => _showAddFieldDialog(section),
              onEditField: (field) => _showEditFieldDialog(section, field),
              onDuplicateField: (field) => _duplicateField(section, field),
              onDeleteField: (field) => _deleteField(section, field),
              onDeleteSection: section.isLocked ? null : () {
                setState(() {
                  _sections.remove(section);
                  _markSaved();
                });
              },
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildIndustryPresetsHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Industry Preset',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Choose a preset to get started quickly or customize from scratch.',
          style: TextStyle(
            fontSize: 11.5,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 10),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPresetChip('security_agency', 'Security Agency', Icons.security_rounded),
              const SizedBox(width: 8),
              _buildPresetChip('gst_service', 'GST Service', Icons.apartment_rounded),
              const SizedBox(width: 8),
              _buildPresetChip('consulting', 'Consulting', Icons.person_outline_rounded),
              const SizedBox(width: 8),
              _buildPresetChip('retail', 'Retail', Icons.shopping_cart_outlined),
              const SizedBox(width: 8),
              _buildPresetChip('modern', 'Modern Clean', Icons.auto_awesome_rounded),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 14, color: Color(0xFF2563EB)),
                label: const Text(
                  'Add Section',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  side: const BorderSide(color: Color(0xFF93C5FD)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  backgroundColor: Colors.white,
                ),
                onPressed: _showAddSectionDialog,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String key, String label, IconData icon) {
    final isSelected = _activePreset == key;
    return InkWell(
      onTap: () => _switchPreset(key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Right Column: Document Preview Workspace
  Widget _buildRightPreviewWorkspace() {
    final pagePadding = switch (_pageMargin) {
      'Compact (10mm)' => const EdgeInsets.all(20),
      'Spacious (24mm)' => const EdgeInsets.all(44),
      _ => const EdgeInsets.all(32),
    };

    return Container(
      color: const Color(0xFFF1F5F9),
      child: Column(
        children: [
          // Preview Top Toolbar
          _buildWorkspaceToolbar(),

          // Preview Canvas Scroll Container
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth - 32;
                final isNarrow = availableWidth < 760;

                Widget canvas = Transform.scale(
                  scale: _zoomLevel,
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 760,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: pagePadding,
                    child: Stack(
                      children: [
                        if (_watermark != 'None')
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Center(
                                child: Transform.rotate(
                                  angle: -0.35,
                                  child: Text(
                                    _watermark,
                                    style: TextStyle(
                                      fontFamily: _fontFamily,
                                      fontSize: 60 * _fontScale,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                                      letterSpacing: 8,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        _buildA4DocumentContent(),
                      ],
                    ),
                  ),
                );

                if (isNarrow) {
                  canvas = FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.topCenter,
                    child: canvas,
                  );
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.all(isNarrow ? 12 : 24),
                  child: Center(child: canvas),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceToolbar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          // Left mode tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF2563EB), width: 2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.visibility_rounded, size: 14, color: Color(0xFF2563EB)),
                SizedBox(width: 6),
                Text('Preview', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              ],
            ),
          ),
          const SizedBox(width: 16),
          InkWell(
            onTap: _showPageSettingsDialog,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: const Row(
                children: [
                  Icon(Icons.tune_rounded, size: 14, color: Color(0xFF64748B)),
                  SizedBox(width: 6),
                  Text('Page settings', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          InkWell(
            onTap: _showStyleDialog,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: const Row(
                children: [
                  Icon(Icons.palette_outlined, size: 14, color: Color(0xFF64748B)),
                  SizedBox(width: 6),
                  Text('Style', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Sample Data Pill Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sampleDataset,
                isDense: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                items: const [
                  DropdownMenuItem(value: 'Security Agency (Northstar)', child: Text('📋 Security Agency Sample')),
                  DropdownMenuItem(value: 'WASM Security & Tech', child: Text('📋 WASM Boxed Sample')),
                  DropdownMenuItem(value: 'GST Service Tech', child: Text('📋 GST Service Data')),
                  DropdownMenuItem(value: 'Apex Consulting', child: Text('📋 Consulting Data')),
                  DropdownMenuItem(value: 'Retail Mart', child: Text('📋 Retail Data')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _sampleDataset = val);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Zoom Controls
          IconButton(
            icon: const Icon(Icons.remove, size: 14, color: Color(0xFF64748B)),
            tooltip: 'Zoom Out',
            onPressed: () {
              if (_zoomLevel > 0.6) setState(() => _zoomLevel -= 0.1);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
          ),
          Text('${(_zoomLevel * 100).round()}%',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          IconButton(
            icon: const Icon(Icons.add, size: 14, color: Color(0xFF64748B)),
            tooltip: 'Zoom In',
            onPressed: () {
              if (_zoomLevel < 1.4) setState(() => _zoomLevel += 0.1);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
          ),
          const SizedBox(width: 8),

          // Page indicator
          Text('$_currentPage/$_totalPages ▾',
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
          const SizedBox(width: 12),

          // Format
          Text('$_paperFormat ▾',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          const SizedBox(width: 12),

          // Download PDF Action
          IconButton(
            icon: const Icon(Icons.download_rounded, size: 18, color: Color(0xFF475569)),
            tooltip: 'Download PDF',
            onPressed: _exportPdfDocument,
          ),

          // Print Action
          IconButton(
            icon: const Icon(Icons.print_outlined, size: 18, color: Color(0xFF475569)),
            tooltip: 'Print Invoice',
            onPressed: _exportPdfDocument,
          ),
        ],
      ),
    );
  }

  // 5. Rendered A4 Document Matching Screenshot & Settings
  TextStyle _docStyle({
    double fontSize = 10,
    FontWeight fontWeight = FontWeight.normal,
    Color color = const Color(0xFF1E293B),
    FontStyle fontStyle = FontStyle.normal,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontSize: fontSize * _fontScale,
      fontWeight: fontWeight,
      color: color,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
    );
  }

  Widget _buildA4DocumentContent() {
    final brandingSection = _sections.firstWhere((s) => s.id == 'sec_branding', orElse: () => _sections.first);
    final identitySection = _sections.firstWhere((s) => s.id == 'sec_identity', orElse: () => _sections.first);
    final clientSection = _sections.firstWhere((s) => s.id == 'sec_client', orElse: () => _sections.first);
    final servicesSection = _sections.firstWhere((s) => s.id == 'sec_services', orElse: () => _sections.first);
    final taxTotalsSection = _sections.firstWhere((s) => s.id == 'sec_tax_totals', orElse: () => _sections.first);
    final bankSection = _sections.firstWhere((s) => s.id == 'sec_bank', orElse: () => _sections.first);
    final termsSection = _sections.firstWhere((s) => s.id == 'sec_terms', orElse: () => _sections.first);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A. Header (Business & Branding)
        if (brandingSection.enabled) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo & Brand Name
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_isFieldVisible(brandingSection, 'f_biz_logo')) ...[
                    Container(
                      width: 46 * _fontScale,
                      height: 52 * _fontScale,
                      decoration: BoxDecoration(
                        color: _logoBase64 != null ? Colors.transparent : _primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: _logoBase64 != null
                            ? Image.memory(
                                base64Decode(_logoBase64!),
                                width: 46 * _fontScale,
                                height: 52 * _fontScale,
                                fit: BoxFit.contain,
                              )
                            : Icon(
                                _activePreset == 'security_agency'
                                    ? Icons.shield_rounded
                                    : Icons.business_rounded,
                                size: 28 * _fontScale,
                                color: Colors.white,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isFieldVisible(brandingSection, 'f_biz_name'))
                        Text(
                          _activePreset == 'security_agency'
                              ? (_uppercaseHeadings ? 'NORTHSTAR' : 'Northstar')
                              : (_uppercaseHeadings ? 'ENTERPRISE TECH' : 'Enterprise Tech'),
                          style: _docStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: _primaryColor,
                          ),
                        ),
                      Text(
                        _activePreset == 'security_agency'
                            ? (_uppercaseHeadings ? 'SECURITY SERVICES' : 'Security Services')
                            : (_uppercaseHeadings ? 'SOLUTIONS & SERVICES' : 'Solutions & Services'),
                        style: _docStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: _primaryColor,
                        ),
                      ),
                      if (_isFieldVisible(brandingSection, 'f_biz_tagline')) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Safe People  |  Secure Tomorrow',
                          style: _docStyle(
                            fontSize: 9.5,
                            color: const Color(0xFF64748B),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              // Company Metadata
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_isFieldVisible(brandingSection, 'f_biz_name'))
                    Text(
                      'Northstar Security Services Ltd.',
                      style: _docStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                    ),
                  const SizedBox(height: 1),
                  if (_isFieldVisible(brandingSection, 'f_biz_addr')) ...[
                    Text('#12, 3rd Floor, Green Park, Bengaluru,', style: _docStyle(fontSize: 9.5, color: const Color(0xFF64748B))),
                    Text('Karnataka - 560076', style: _docStyle(fontSize: 9.5, color: const Color(0xFF64748B))),
                  ],
                  if (_isFieldVisible(brandingSection, 'f_biz_gstin'))
                    Text('GSTIN: 29ABCDE1234F1Z5', style: _docStyle(fontSize: 9.5, color: const Color(0xFF64748B))),
                  if (_isFieldVisible(brandingSection, 'f_biz_pan'))
                    Text('PAN: ABCDE1234F', style: _docStyle(fontSize: 9.5, color: const Color(0xFF64748B))),
                  const SizedBox(height: 2),
                  Text('📞 +91 98765 43210', style: _docStyle(fontSize: 9.5, color: const Color(0xFF64748B))),
                  Text('✉ info@northstarsecurity.in', style: _docStyle(fontSize: 9.5, color: const Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: _primaryColor, thickness: 1.5),
          const SizedBox(height: 16),
        ],

        // B. Document Title & Details
        if (identitySection.enabled) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _uppercaseHeadings ? _documentTitle.toUpperCase() : _documentTitle,
                style: _docStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                children: [
                  if (_isFieldVisible(identitySection, 'f_doc_number'))
                    _metaRow('Invoice No.', 'INV-2025-0148'),
                  if (_isFieldVisible(identitySection, 'f_doc_issue'))
                    _metaRow('Issue Date', '15 Apr 2025'),
                  if (_isFieldVisible(identitySection, 'f_doc_due'))
                    _metaRow('Due Date', '30 Apr 2025'),
                  if (_isFieldVisible(identitySection, 'f_doc_po'))
                    _metaRow('PO No.', 'PO-4587/2025'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // C. Bill To & Service Location Boxes
        if (clientSection.enabled) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bill To Box
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _uppercaseHeadings ? 'BILL TO' : 'Bill To',
                        style: _docStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
                      ),
                      const SizedBox(height: 4),
                      if (_isFieldVisible(clientSection, 'f_cli_name'))
                        Text('ABC Industries Pvt. Ltd.', style: _docStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      if (_isFieldVisible(clientSection, 'f_cli_addr')) ...[
                        Text('101, Business Tower, MG Road,', style: _docStyle(fontSize: 10, color: const Color(0xFF475569))),
                        Text('Bengaluru, Karnataka - 560001', style: _docStyle(fontSize: 10, color: const Color(0xFF475569))),
                      ],
                      const SizedBox(height: 2),
                      if (_isFieldVisible(clientSection, 'f_cli_gstin'))
                        Text('GSTIN: 29AABCA1234B1Z2', style: _docStyle(fontSize: 10, color: const Color(0xFF475569))),
                      if (_isFieldVisible(clientSection, 'f_cli_contact'))
                        Text('Contact: Mr. Rahul Sharma', style: _docStyle(fontSize: 10, color: const Color(0xFF475569))),
                      if (_isFieldVisible(clientSection, 'f_cli_phone'))
                        Text('Phone: +91 98800 11223', style: _docStyle(fontSize: 10, color: const Color(0xFF475569))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Service Location Box
              if (_isFieldVisible(servicesSection, 'f_srv_loc') || _isFieldVisible(servicesSection, 'f_srv_period')) ...[
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isFieldVisible(servicesSection, 'f_srv_loc')) ...[
                          Text(_uppercaseHeadings ? 'SERVICE LOCATION' : 'Service Location', style: _docStyle(fontSize: 10, color: const Color(0xFF64748B))),
                          const SizedBox(height: 2),
                          Text('Tech Park, Whitefield', style: _docStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                          Text('Bengaluru, Karnataka - 560066', style: _docStyle(fontSize: 10, color: const Color(0xFF475569))),
                          const SizedBox(height: 8),
                        ],
                        if (_isFieldVisible(servicesSection, 'f_srv_period')) ...[
                          Text(_uppercaseHeadings ? 'BILLING PERIOD' : 'Billing Period', style: _docStyle(fontSize: 10, color: const Color(0xFF64748B))),
                          const SizedBox(height: 2),
                          Text('01 Apr 2025 - 30 Apr 2025', style: _docStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                          Text('(30 Days)', style: _docStyle(fontSize: 9.5, color: const Color(0xFF64748B))),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
        ],

        // D. Duty & Line Items Table (Dynamic Presets & Boxed Layout)
        if (servicesSection.enabled) ...[
          _buildDynamicLineItemsTable(servicesSection),
          const SizedBox(height: 16),
        ],

        // E. Financial Summary & Totals Box
        if (taxTotalsSection.enabled) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 260,
                child: Column(
                  children: [
                    if (_isFieldVisible(taxTotalsSection, 'f_tot_sub'))
                      _buildSummaryRow('Subtotal', '₹ 3,71,800.00'),
                    if (_isFieldVisible(taxTotalsSection, 'f_tot_disc'))
                      _buildSummaryRow('Discount', '(-) ₹ 5,000.00'),
                    if (_isFieldVisible(taxTotalsSection, 'f_tot_taxable'))
                      _buildSummaryRow('Taxable Amount', '₹ 3,66,800.00', isBold: true),
                    if (_isFieldVisible(taxTotalsSection, 'f_tot_cgst'))
                      _buildSummaryRow('CGST (9%)', '₹ 33,012.00'),
                    if (_isFieldVisible(taxTotalsSection, 'f_tot_sgst'))
                      _buildSummaryRow('SGST (9%)', '₹ 33,012.00'),
                    if (_isFieldVisible(taxTotalsSection, 'f_tot_grand')) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: _primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _primaryColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _uppercaseHeadings ? 'GRAND TOTAL' : 'Grand Total',
                              style: _docStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _primaryColor),
                            ),
                            Text(
                              '₹ 4,32,824.00',
                              style: _docStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _primaryColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // F. Payment Details & UPI QR Code
        if (bankSection.enabled) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _uppercaseHeadings ? 'PAYMENT DETAILS' : 'Payment Details',
                        style: _docStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      if (_isFieldVisible(bankSection, 'f_bnk_name'))
                        Text('Bank Name : INDFC Bank', style: _docStyle(fontSize: 10, color: const Color(0xFF475569))),
                      if (_isFieldVisible(bankSection, 'f_bnk_ac'))
                        Text('A/C No.      : 50200012345678', style: _docStyle(fontSize: 10, color: const Color(0xFF475569))),
                      if (_isFieldVisible(bankSection, 'f_bnk_ifsc'))
                        Text('IFSC           : HDFC0001234', style: _docStyle(fontSize: 10, color: const Color(0xFF475569))),
                      if (_isFieldVisible(bankSection, 'f_bnk_upi'))
                        Text('UPI             : northstar@hdfcbank', style: _docStyle(fontSize: 10, color: const Color(0xFF475569))),
                    ],
                  ),
                ),
                if (_showQrCode && _isFieldVisible(bankSection, 'f_bnk_qr'))
                  Column(
                    children: [
                      Container(
                        width: 56 * _fontScale,
                        height: 56 * _fontScale,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Center(
                          child: Icon(Icons.qr_code_2_rounded, size: 48 * _fontScale, color: const Color(0xFF1E293B)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('Scan to Pay', style: _docStyle(fontSize: 8.5, color: const Color(0xFF64748B))),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // G. Terms & Conditions and Signature
        if (termsSection.enabled) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _uppercaseHeadings ? 'TERMS & CONDITIONS' : 'Terms & Conditions',
                      style: _docStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    if (_isFieldVisible(termsSection, 'f_trm_lines')) ...[
                      Text('1. Payment due within 15 days from the date of invoice.', style: _docStyle(fontSize: 8.5, color: const Color(0xFF475569))),
                      Text('2. Late payment attracts 18% annual interest.', style: _docStyle(fontSize: 8.5, color: const Color(0xFF475569))),
                      Text('3. Security personnel are deployed as per the agreed schedule.', style: _docStyle(fontSize: 8.5, color: const Color(0xFF475569))),
                      Text('4. Any dispute must be reported within 7 days of service completion.', style: _docStyle(fontSize: 8.5, color: const Color(0xFF475569))),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_isFieldVisible(termsSection, 'f_trm_company'))
                      Text('For Northstar Security Services Ltd.', style: _docStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    // Render Signature and Stamp
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (_stampBase64 != null) ...[
                          Container(
                            width: 36 * _fontScale,
                            height: 36 * _fontScale,
                            margin: const EdgeInsets.only(right: 6),
                            child: Image.memory(
                              base64Decode(_stampBase64!),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                        if (_signatureBase64 != null) ...[
                          Container(
                            height: 32 * _fontScale,
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Image.memory(
                              base64Decode(_signatureBase64!),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ] else ...[
                          SizedBox(height: 26 * _fontScale),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Container(width: 110, height: 1, color: const Color(0xFFCBD5E1)),
                    const SizedBox(height: 3),
                    if (_isFieldVisible(termsSection, 'f_trm_title'))
                      Text(_signeeTitle ?? 'Authorized Signatory', style: _docStyle(fontSize: 9, color: const Color(0xFF64748B))),
                    if (_isFieldVisible(termsSection, 'f_trm_auto_stamp'))
                      Text('(This is a system generated invoice)', style: _docStyle(fontSize: 7.5, color: const Color(0xFF94A3B8))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],

        // H. Custom Sections added by user
        for (final customSec in _sections.where((s) => !s.id.startsWith('sec_')))
          if (customSec.enabled && customSec.fields.any((f) => f.isVisible)) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _uppercaseHeadings ? customSec.title.toUpperCase() : customSec.title,
                    style: _docStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  ),
                  if (customSec.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(customSec.subtitle, style: _docStyle(fontSize: 9, color: const Color(0xFF64748B))),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: customSec.fields.where((f) => f.isVisible).map((f) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${f.label}: ', style: _docStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                          Text(f.defaultValue.isNotEmpty ? f.defaultValue : '—', style: _docStyle(fontSize: 9.5, color: const Color(0xFF1E293B))),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],

        // I. Document Footer
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Thank you for your business!', style: _docStyle(fontSize: 9, color: const Color(0xFF64748B), fontStyle: FontStyle.italic)),
            Text('Page 1 of 1', style: _docStyle(fontSize: 8.5, color: const Color(0xFF94A3B8))),
          ],
        ),
      ],
    );
  }

  Widget _buildDynamicLineItemsTable(StudioSection section) {
    final isBoxed = _tableBorderStyle == 'boxed';
    final isStriped = _tableBorderStyle == 'striped';

    // Determine columns based on preset
    final List<({String label, int flex, TextAlign align})> columns;
    final List<List<String>> rows;

    if (_activePreset == 'gst_service') {
      columns = [
        (label: 'Service Description & Scope', flex: 5, align: TextAlign.left),
        (label: 'SAC Code', flex: 2, align: TextAlign.center),
        (label: 'Qty / Hrs', flex: 2, align: TextAlign.center),
        (label: 'Rate (₹)', flex: 3, align: TextAlign.right),
        (label: 'Amount (₹)', flex: 3, align: TextAlign.right),
      ];
      rows = [
        ['Enterprise Cloud & Security Architecture', '998313', '160 Hrs', '1,500.00', '2,40,000.00'],
        ['Cybersecurity Audit & Penetration Testing', '998314', '1 Audit', '1,25,000.00', '1,25,000.00'],
      ];
    } else if (_activePreset == 'consulting') {
      columns = [
        (label: 'Scope & Deliverables', flex: 5, align: TextAlign.left),
        (label: 'Lead Consultant', flex: 3, align: TextAlign.center),
        (label: 'Hours / Days', flex: 2, align: TextAlign.center),
        (label: 'Rate (₹)', flex: 3, align: TextAlign.right),
        (label: 'Amount (₹)', flex: 3, align: TextAlign.right),
      ];
      rows = [
        ['Strategic IT Security Advisory - Phase 1', 'Principal Advisor', '40 Hrs', '5,500.00', '2,20,000.00'],
        ['Compliance Certification Preparation', 'Senior Specialist', '20 Hrs', '4,200.00', '84,000.00'],
      ];
    } else if (_activePreset == 'retail') {
      columns = [
        (label: 'Item Description', flex: 5, align: TextAlign.left),
        (label: 'SKU / HSN', flex: 2, align: TextAlign.center),
        (label: 'Qty', flex: 2, align: TextAlign.center),
        (label: 'MRP (₹)', flex: 3, align: TextAlign.right),
        (label: 'Net Total (₹)', flex: 3, align: TextAlign.right),
      ];
      rows = [
        ['Smart Biometric Access Terminal Pro', 'BIO-901', '5', '18,500.00', '92,500.00'],
        ['HD Night-Vision CCTV Camera 4K', 'CAM-402', '12', '4,200.00', '50,400.00'],
      ];
    } else {
      // security_agency and default
      columns = [
        (label: 'Particulars', flex: 5, align: TextAlign.left),
        (label: 'Guards', flex: 2, align: TextAlign.center),
        (label: 'Duty Days', flex: 2, align: TextAlign.center),
        (label: 'Rate (₹)', flex: 3, align: TextAlign.right),
        (label: 'Amount (₹)', flex: 3, align: TextAlign.right),
      ];
      rows = [
        ['Security Guard (12-hour shift)', '4', '26', '2,150.00', '2,23,600.00'],
        ['Armed Guard (12-hour shift)', '2', '26', '2,850.00', '1,48,200.00'],
      ];
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header Row
          Container(
            color: _primaryColor,
            child: Row(
              children: [
                for (int c = 0; c < columns.length; c++)
                  Expanded(
                    flex: columns[c].flex,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        border: isBoxed && c < columns.length - 1
                            ? const Border(right: BorderSide(color: Color(0x33FFFFFF), width: 1))
                            : null,
                      ),
                      child: Text(
                        _uppercaseHeadings ? columns[c].label.toUpperCase() : columns[c].label,
                        textAlign: columns[c].align,
                        style: _docStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _tableHeaderTextColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Body Rows
          for (int r = 0; r < rows.length; r++) ...[
            if (r > 0 && !isBoxed)
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Container(
              color: isStriped && r.isOdd ? const Color(0xFFF8FAFC) : Colors.white,
              decoration: isBoxed
                  ? const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFCBD5E1))),
                    )
                  : null,
              child: Row(
                children: [
                  for (int c = 0; c < rows[r].length; c++)
                    Expanded(
                      flex: columns[c].flex,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          border: isBoxed && c < rows[r].length - 1
                              ? const Border(right: BorderSide(color: Color(0xFFCBD5E1)))
                              : null,
                        ),
                        child: Text(
                          rows[r][c],
                          textAlign: columns[c].align,
                          style: _docStyle(
                            fontSize: 10,
                            fontWeight: c == 0
                                ? FontWeight.w600
                                : (c == rows[r].length - 1 ? FontWeight.bold : FontWeight.normal),
                            color: c == rows[r].length - 1
                                ? const Color(0xFF0F172A)
                                : (c == 0 ? const Color(0xFF1E293B) : const Color(0xFF475569)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  TableRow _metaRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 4),
          child: Text(label, style: _docStyle(fontSize: 9.5, color: const Color(0xFF64748B))),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5),
          child: Text(':', style: _docStyle(fontSize: 9.5, color: const Color(0xFF64748B))),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 4),
          child: Text(value, style: _docStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: _docStyle(fontSize: 10, color: const Color(0xFF64748B), fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: _docStyle(fontSize: 10, color: const Color(0xFF1E293B), fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }

  bool _isFieldVisible(StudioSection section, String fieldId) {
    final fld = section.fields.firstWhere((f) => f.id == fieldId, orElse: () => StudioField(id: '', label: ''));
    return fld.id.isNotEmpty && fld.isVisible;
  }
}
