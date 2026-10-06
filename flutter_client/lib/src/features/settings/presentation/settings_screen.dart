import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../theme/app_theme.dart';
import '../data/settings_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.apiClient,
    this.onBack,
    super.key,
  });

  final ApiClient apiClient;
  final VoidCallback? onBack;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final SettingsRepository _repository;
  Map<String, dynamic> _profile = <String, dynamic>{};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  static const _editableStringFields = <String, String>{
    'businessName': 'Business name',
    'legalName': 'Legal name',
    'email': 'Business email',
    'phone': 'Phone',
    'website': 'Website',
    'address': 'Business address',
    'taxId': 'Tax ID',
    'gstin': 'GSTIN',
    'panNumber': 'PAN number',
    'placeOfSupply': 'Place of supply',
    'upiId': 'UPI ID',
    'bankName': 'Bank name',
    'accountHolder': 'Account holder',
    'accountNumber': 'Account number',
    'ifscCode': 'IFSC code',
    'routingNumber': 'Routing number',
    'swiftBic': 'SWIFT / BIC',
    'paymentLink': 'Payment link',
    'defaultNotes': 'Default invoice notes',
    'defaultTerms': 'Default invoice terms',
    'signeeName': 'Authorized signatory',
    'signeeTitle': 'Signatory title',
  };

  @override
  void initState() {
    super.initState();
    _repository = SettingsRepository(apiClient: widget.apiClient);
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
        _error = 'Could not load business settings: $error';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final result = await _repository.saveProfile(_profile);
      if (!mounted) return;
      setState(() => _profile = result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business settings saved.')),
      );
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } catch (error) {
      if (mounted) _showError('Could not save settings: $error');
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
          title: const Text('Business Settings'),
          actions: [
            IconButton(
              onPressed: _loading || _saving ? null : _save,
              tooltip: 'Save settings',
              icon: const Icon(Icons.save_outlined),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _SettingsError(message: _error!, onRetry: _load)
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Business profile',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 12),
                              ..._editableStringFields.entries.map(
                                (field) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TextFormField(
                                    initialValue:
                                        _profile[field.key]?.toString() ?? '',
                                    decoration: InputDecoration(
                                      labelText: field.value,
                                    ),
                                    keyboardType: field.key == 'email'
                                        ? TextInputType.emailAddress
                                        : field.key == 'address' ||
                                                field.key == 'defaultNotes' ||
                                                field.key == 'defaultTerms'
                                            ? TextInputType.multiline
                                            : TextInputType.text,
                                    maxLines: field.key == 'address' ||
                                            field.key == 'defaultNotes' ||
                                            field.key == 'defaultTerms'
                                        ? 3
                                        : 1,
                                    validator: field.key == 'email'
                                        ? _validateEmail
                                        : null,
                                    onChanged: (value) =>
                                        _profile[field.key] = value,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Currency & invoice defaults',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: _currencyCode,
                                decoration: const InputDecoration(
                                  labelText: 'Default currency',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'INR', child: Text('INR — ₹')),
                                  DropdownMenuItem(
                                      value: 'USD', child: Text('USD — \$')),
                                  DropdownMenuItem(
                                      value: 'EUR', child: Text('EUR — €')),
                                  DropdownMenuItem(
                                      value: 'GBP', child: Text('GBP — £')),
                                  DropdownMenuItem(
                                      value: 'AED', child: Text('AED')),
                                  DropdownMenuItem(
                                      value: 'CAD', child: Text('CAD — C\$')),
                                  DropdownMenuItem(
                                      value: 'AUD', child: Text('AUD — A\$')),
                                  DropdownMenuItem(
                                      value: 'JPY', child: Text('JPY — ¥')),
                                  DropdownMenuItem(
                                      value: 'SGD', child: Text('SGD — S\$')),
                                  DropdownMenuItem(
                                      value: 'SAR', child: Text('SAR')),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _profile['defaultCurrency'] = value;
                                    _profile['defaultCurrencySymbol'] =
                                        _currencySymbols[value] ?? value;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: _currencyFormat,
                                decoration: const InputDecoration(
                                  labelText: 'Currency symbol position',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'before',
                                    child: Text('Prefix (₹ 1,500.00)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'after',
                                    child: Text('Suffix (1,500.00 ₹)'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() =>
                                        _profile['defaultCurrencyFormat'] =
                                            value);
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
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
                              const SizedBox(height: 12),
                              TextFormField(
                                initialValue: _profile['defaultTaxRate']
                                        ?.toString() ??
                                    '0',
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
                              const SizedBox(height: 12),
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Brand color',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue:
                                    _profile['brandColorHex']?.toString() ??
                                        '#1E3A8A',
                                decoration: const InputDecoration(
                                  labelText: 'Hex color (for example #1E3A8A)',
                                ),
                                validator: _validateHexColor,
                                onChanged: (value) =>
                                    _profile['brandColorHex'] = value,
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
                          label: Text(_saving ? 'Saving…' : 'Save settings'),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Server URL, account sync controls, invoice deletion and local reset actions are not exposed by the Flutter backend API.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
      );

  String get _currencyCode =>
      _profile['defaultCurrency']?.toString() ?? 'INR';

  String get _currencyFormat =>
      _profile['defaultCurrencyFormat']?.toString() ?? 'before';

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validateRate(String? value) {
    final rate = double.tryParse(value ?? '');
    if (rate == null || rate < 0 || rate > 100) {
      return 'Enter a rate from 0 to 100.';
    }
    return null;
  }

  String? _validateHexColor(String? value) {
    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value?.trim() ?? '')) {
      return 'Use a six-digit hex color such as #1E3A8A.';
    }
    return null;
  }
}

const _currencySymbols = <String, String>{
  'INR': '₹',
  'USD': r'$',
  'EUR': '€',
  'GBP': '£',
  'AED': 'AED',
  'CAD': 'C\$',
  'AUD': 'A\$',
  'JPY': '¥',
  'SGD': 'S\$',
  'SAR': 'SAR',
};

class _SettingsError extends StatelessWidget {
  const _SettingsError({required this.message, required this.onRetry});

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
