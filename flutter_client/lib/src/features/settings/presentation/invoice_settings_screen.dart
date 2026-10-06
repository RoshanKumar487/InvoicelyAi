import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../theme/app_theme.dart';
import '../data/settings_repository.dart';

class InvoiceSettingsScreen extends StatefulWidget {
  const InvoiceSettingsScreen({
    required this.apiClient,
    this.initialLocalSettings = const <String, Object?>{},
    this.onBack,
    this.onSaveLocalSettings,
    super.key,
  });

  final ApiClient apiClient;
  final Map<String, Object?> initialLocalSettings;
  final VoidCallback? onBack;
  final Future<void> Function(Map<String, Object?>)? onSaveLocalSettings;

  @override
  State<InvoiceSettingsScreen> createState() => _InvoiceSettingsScreenState();
}

class _InvoiceSettingsScreenState extends State<InvoiceSettingsScreen> {
  late final SettingsRepository _repository;
  Map<String, dynamic> _profile = <String, dynamic>{};
  late Map<String, Object?> _localSettings;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  static const _supportedBackendFields = <String>{
    'id',
    'companyId',
    'businessName',
    'legalName',
    'email',
    'phone',
    'website',
    'address',
    'taxId',
    'gstin',
    'panNumber',
    'placeOfSupply',
    'upiId',
    'bankName',
    'accountHolder',
    'accountNumber',
    'ifscCode',
    'routingNumber',
    'swiftBic',
    'paymentLink',
    'defaultCurrency',
    'defaultCurrencySymbol',
    'defaultCurrencyFormat',
    'defaultTaxRate',
    'defaultTaxLabel',
    'defaultPaymentTerms',
    'defaultNotes',
    'defaultTerms',
    'signeeName',
    'signeeTitle',
    'brandColorHex',
  };

  static const _clientFields = <String, String>{
    'showClientCompany': 'Company name',
    'showClientEmail': 'Email',
    'showClientPhone': 'Phone',
    'showClientAddress': 'Address',
    'showClientTaxId': 'Tax ID',
  };

  static const _itemFields = <String, String>{
    'showItemUnit': 'Unit',
    'showItemQty': 'Quantity',
    'showItemRate': 'Rate',
    'showItemDiscount': 'Discount',
    'showItemTax': 'Item tax',
  };

  static const _sectionFields = <String, String>{
    'showShippingSection': 'Shipping section',
    'showNotesSection': 'Notes section',
    'showPaymentInstructions': 'Payment instructions',
    'showTerms': 'Terms & conditions',
    'showNotes': 'Notes',
    'showSignature': 'Signature block',
    'showStamp': 'Business stamp',
    'showStatus': 'Invoice status',
    'showIssueDate': 'Issue date',
    'showDueDate': 'Due date',
    'showPoNumber': 'Purchase order number',
    'showPaymentTerms': 'Payment terms',
  };

  static const _industryPresets = <String, String>{
    'general': 'General business',
    'it_services': 'IT & consulting',
    'retail': 'Retail & wholesale',
    'healthcare': 'Healthcare',
    'professional': 'Professional services',
  };

  @override
  void initState() {
    super.initState();
    _repository = SettingsRepository(apiClient: widget.apiClient);
    _localSettings = Map<String, Object?>.from(widget.initialLocalSettings);
    const localDefaults = <String, Object?>{
      'showShippingSection': false,
      'showNotesSection': false,
      'showPoNumber': false,
    };
    for (final field in <String, String>{
      ..._clientFields,
      ..._itemFields,
      ..._sectionFields,
    }.keys) {
      _localSettings.putIfAbsent(field, () => localDefaults[field] ?? true);
    }
    _localSettings.putIfAbsent('industryPresetId', () => 'general');
    _localSettings.putIfAbsent('defaultIsRcm', () => false);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _repository.loadProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load invoice settings: $error';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final rate = double.tryParse(_profile['defaultTaxRate']?.toString() ?? '');
    if (rate == null || rate < 0 || rate > 100) {
      _showError('Enter a default tax rate from 0 to 100.');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSaveLocalSettings?.call(
        Map<String, Object?>.unmodifiable(_localSettings),
      );
      final payload = <String, Object?>{
        for (final entry in _profile.entries)
          if (_supportedBackendFields.contains(entry.key))
            entry.key: entry.value,
      };
      final savedProfile = await _repository.saveProfile(payload);
      if (!mounted) return;
      setState(() => _profile = savedProfile);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.onSaveLocalSettings == null
              ? 'Server-supported defaults saved. Field visibility and presets only apply during this screen session.'
              : 'Invoice defaults and local field settings applied.'),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) {
        _showError(
          widget.onSaveLocalSettings == null
              ? error.message
              : 'Local display settings were saved, but server defaults failed: ${error.message}',
        );
      }
    } catch (error) {
      if (mounted) _showError('Could not save invoice settings: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
          title: const Text('Invoice Settings'),
          actions: [
            IconButton(
              onPressed: _loading || _saving ? null : _save,
              tooltip: 'Save invoice settings',
              icon: const Icon(Icons.save_outlined),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _InvoiceSettingsError(message: _error!, onRetry: _load)
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Industry preset',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              initialValue: _industryId,
                              decoration: const InputDecoration(
                                labelText: 'Business category',
                              ),
                              items: _industryPresets.entries
                                  .map(
                                    (entry) => DropdownMenuItem<String>(
                                      value: entry.key,
                                      child: Text(entry.value),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() =>
                                      _localSettings['industryPresetId'] =
                                          value);
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Preset selection is client-side. Item-column builder and DOCX template associations are not supported by the backend.',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tax & totals defaults',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 10),
                            TextFormField(
                              initialValue:
                                  _profile['defaultTaxLabel']?.toString() ??
                                      'Tax',
                              decoration: const InputDecoration(
                                labelText: 'Default tax label',
                              ),
                              onChanged: (value) =>
                                  _profile['defaultTaxLabel'] = value,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              initialValue:
                                  _profile['defaultTaxRate']?.toString() ?? '0',
                              decoration: const InputDecoration(
                                labelText: 'Default tax rate (%)',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: _validateRate,
                              onChanged: (value) {
                                final rate = double.tryParse(value);
                                if (rate != null) {
                                  _profile['defaultTaxRate'] = rate;
                                }
                              },
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              initialValue:
                                  _profile['defaultPaymentTerms']?.toString() ??
                                      'Net 30',
                              decoration: const InputDecoration(
                                labelText: 'Default payment terms',
                              ),
                              onChanged: (value) =>
                                  _profile['defaultPaymentTerms'] = value,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              initialValue:
                                  _profile['defaultNotes']?.toString() ?? '',
                              decoration: const InputDecoration(
                                labelText: 'Default notes',
                              ),
                              maxLines: 3,
                              onChanged: (value) =>
                                  _profile['defaultNotes'] = value,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              initialValue:
                                  _profile['defaultTerms']?.toString() ?? '',
                              decoration: const InputDecoration(
                                labelText: 'Default terms & conditions',
                              ),
                              maxLines: 3,
                              onChanged: (value) =>
                                  _profile['defaultTerms'] = value,
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Reverse charge default'),
                              value: _localSettings['defaultIsRcm'] == true,
                              onChanged: (value) => setState(
                                () => _localSettings['defaultIsRcm'] = value,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _visibilityCard(
                        title: 'Client details fields',
                        description: 'Choose which client inputs to display.',
                        fields: _clientFields,
                      ),
                      const SizedBox(height: 12),
                      _visibilityCard(
                        title: 'Item columns',
                        description:
                            'Choose which item details appear in invoice previews and exports.',
                        fields: _itemFields,
                      ),
                      const SizedBox(height: 12),
                      _visibilityCard(
                        title: 'Invoice sections & metadata',
                        description:
                            'Control invoice header, footer and optional sections.',
                        fields: _sectionFields,
                      ),
                      const SizedBox(height: 12),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Display labels',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 10),
                            for (final item in const <MapEntry<String, String>>[
                              MapEntry('colHeaderItem', 'Item / service'),
                              MapEntry('colHeaderQty', 'Quantity'),
                              MapEntry('colHeaderUnit', 'Unit'),
                              MapEntry('colHeaderRate', 'Rate'),
                              MapEntry('colHeaderAmount', 'Amount'),
                            ])
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: TextFormField(
                                  initialValue:
                                      _localSettings[item.key]?.toString() ??
                                          _defaultLabel(item.key),
                                  decoration:
                                      InputDecoration(labelText: item.value),
                                  onChanged: (value) =>
                                      _localSettings[item.key] = value,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(_saving ? 'Saving…' : 'Save & Apply'),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Only tax, payment terms and default text fields are persisted by the existing profile endpoint. Visibility, industry presets and custom columns have no server endpoint.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
      );

  Widget _visibilityCard({
    required String title,
    required String description,
    required Map<String, String> fields,
  }) =>
      AppCard(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(description, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 6),
            for (final field in fields.entries)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(field.value),
                value: _localSettings[field.key] == true,
                onChanged: (value) =>
                    setState(() => _localSettings[field.key] = value),
              ),
          ],
        ),
      );

  String get _industryId => _industryPresets.containsKey(
        _localSettings['industryPresetId']?.toString(),
      )
          ? _localSettings['industryPresetId']!.toString()
          : 'general';

  String? _validateRate(String? value) {
    final rate = double.tryParse(value ?? '');
    if (rate == null || rate < 0 || rate > 100) {
      return 'Enter a tax rate from 0 to 100.';
    }
    return null;
  }
}

String _defaultLabel(String key) {
  switch (key) {
    case 'colHeaderItem':
      return 'Description / Service';
    case 'colHeaderQty':
      return 'Qty';
    case 'colHeaderUnit':
      return 'Unit';
    case 'colHeaderRate':
      return 'Rate';
    default:
      return 'Amount';
  }
}

class _InvoiceSettingsError extends StatelessWidget {
  const _InvoiceSettingsError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}
