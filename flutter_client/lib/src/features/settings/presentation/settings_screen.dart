import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/storage/local_preferences.dart';
import '../../../shared/widgets/signature_pad_dialog.dart';
import '../data/settings_repository.dart';
import 'widgets/business_settings_tabs.dart';
import 'widgets/email_templates_tab.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.apiClient,
    this.localPreferences,
    this.initialLocalSettings = const <String, Object?>{},
    this.onSaveLocalSettings,
    this.onBack,
    super.key,
  });

  final ApiClient apiClient;
  final LocalPreferences? localPreferences;
  final Map<String, Object?> initialLocalSettings;
  final ValueChanged<Map<String, Object?>>? onSaveLocalSettings;
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
  late Map<String, Object?> _localSettings;

  static const _currencySymbols = <String, String>{
    'INR': '₹',
    'USD': r'$',
    'EUR': '€',
    'GBP': '£',
    'AED': 'AED',
    'CAD': r'CA$',
    'AUD': r'AU$',
    'JPY': '¥',
    'SGD': r'SG$',
    'SAR': 'SAR',
  };

  @override
  void initState() {
    super.initState();
    _localSettings = Map<String, Object?>.from(widget.initialLocalSettings);
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
      // Synchronize company currency and business details with local settings
      final cur = profile['defaultCurrency']?.toString();
      if (cur != null && cur.isNotEmpty) {
        final updated = Map<String, Object?>.from(_localSettings)
          ..['defaultCurrency'] = cur
          ..['defaultCurrencySymbol'] =
              profile['defaultCurrencySymbol']?.toString() ??
                  _currencySymbols[cur] ??
                  '₹'
          ..['defaultCurrencyFormat'] =
              profile['defaultCurrencyFormat']?.toString() ?? 'before';
        if (profile['companyName'] != null) {
          updated['businessName'] = profile['companyName'];
        }
        if (profile['address'] != null) {
          updated['businessAddress'] = profile['address'];
        }
        if (profile['gstin'] != null) {
          updated['businessGstin'] = profile['gstin'];
        }
        if (profile['upiId'] != null) {
          updated['upiId'] = profile['upiId'];
        }
        if (profile['bankName'] != null) {
          updated['bankName'] = profile['bankName'];
        }
        if (profile['accountNumber'] != null) {
          updated['accountNumber'] = profile['accountNumber'];
        }
        if (profile['ifscCode'] != null) {
          updated['ifscCode'] = profile['ifscCode'];
        }
        _localSettings = updated;
        widget.onSaveLocalSettings?.call(updated);
        widget.localPreferences?.writeMap('invoice_settings', updated);
      }
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
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      final currency = _profile['defaultCurrency']?.toString() ?? 'INR';
      final currencySymbol =
          _currencySymbols[currency] ?? _profile['defaultCurrencySymbol']?.toString() ?? '₹';
      final currencyFormat = _profile['defaultCurrencyFormat']?.toString() ?? 'before';

      _profile['defaultCurrency'] = currency;
      _profile['defaultCurrencySymbol'] = currencySymbol;
      _profile['defaultCurrencyFormat'] = currencyFormat;

      // Sync companyName and businessName
      if (_profile['businessName'] != null) {
        _profile['companyName'] = _profile['businessName'];
      }

      final result = await _repository.saveProfile(_profile);

      final updatedLocal = Map<String, Object?>.from(_localSettings)
        ..['defaultCurrency'] = currency
        ..['defaultCurrencySymbol'] = currencySymbol
        ..['defaultCurrencyFormat'] = currencyFormat
        ..['businessName'] = result['companyName'] ??
            _profile['companyName'] ??
            _localSettings['businessName'] ??
            ''
        ..['companyName'] = result['companyName'] ??
            _profile['companyName'] ??
            _localSettings['businessName'] ??
            ''
        ..['businessAddress'] = result['address'] ??
            _profile['address'] ??
            _localSettings['businessAddress'] ??
            ''
        ..['businessGstin'] = result['gstin'] ??
            _profile['gstin'] ??
            _localSettings['businessGstin'] ??
            ''
        ..['businessPan'] = result['panNumber'] ??
            _profile['panNumber'] ??
            _localSettings['businessPan'] ??
            ''
        ..['businessPhone'] = result['phone'] ??
            _profile['phone'] ??
            _localSettings['businessPhone'] ??
            ''
        ..['businessEmail'] = result['email'] ??
            _profile['email'] ??
            _localSettings['businessEmail'] ??
            ''
        ..['businessWebsite'] = result['website'] ??
            _profile['website'] ??
            _localSettings['businessWebsite'] ??
            ''
        ..['upiId'] = result['upiId'] ??
            _profile['upiId'] ??
            _localSettings['upiId'] ??
            ''
        ..['bankName'] = result['bankName'] ??
            _profile['bankName'] ??
            _localSettings['bankName'] ??
            ''
        ..['accountNumber'] = result['accountNumber'] ??
            _profile['accountNumber'] ??
            _localSettings['accountNumber'] ??
            ''
        ..['accountHolder'] = result['accountHolder'] ??
            _profile['accountHolder'] ??
            _localSettings['accountHolder'] ??
            ''
        ..['ifscCode'] = result['ifscCode'] ??
            _profile['ifscCode'] ??
            _localSettings['ifscCode'] ??
            ''
        ..['routingNumber'] = result['routingNumber'] ??
            _profile['routingNumber'] ??
            _localSettings['routingNumber'] ??
            ''
        ..['swiftBic'] = result['swiftBic'] ??
            _profile['swiftBic'] ??
            _localSettings['swiftBic'] ??
            ''
        ..['paymentLink'] = result['paymentLink'] ??
            _profile['paymentLink'] ??
            _localSettings['paymentLink'] ??
            ''
        ..['defaultNotes'] = _profile['defaultNotes'] ??
            _localSettings['defaultNotes'] ??
            ''
        ..['defaultTerms'] = _profile['defaultTerms'] ??
            _localSettings['defaultTerms'] ??
            ''
        ..['signeeName'] = _profile['signeeName'] ??
            _localSettings['signeeName'] ??
            ''
        ..['signeeTitle'] = _profile['signeeTitle'] ??
            _localSettings['signeeTitle'] ??
            '';

      _localSettings = updatedLocal;
      widget.onSaveLocalSettings?.call(updatedLocal);
      if (widget.localPreferences != null) {
        await widget.localPreferences!
            .writeMap('invoice_settings', updatedLocal);
      }

      if (!mounted) return;
      setState(() => _profile = Map<String, dynamic>.from(result));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF047857),
          content: Text('✓ All business profile, bank & branding settings saved!'),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } catch (error) {
      if (mounted) _showError('Could not save settings: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickBrandImage(String key, String label) async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        imageQuality: 75,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() => _localSettings[key] = base64Encode(bytes));
      widget.onSaveLocalSettings?.call(Map<String, Object?>.from(_localSettings));
      widget.localPreferences?.writeMap('invoice_settings', _localSettings);
    } catch (error) {
      if (mounted) _showError('Could not select $label: $error');
    }
  }

  Future<void> _captureSignature() async {
    final result = await SignaturePadDialog.show(
      context,
      initialSigneeName: _profile['signeeName']?.toString() ??
          _localSettings['signeeName']?.toString(),
      initialSigneeTitle: _profile['signeeTitle']?.toString() ??
          _localSettings['signeeTitle']?.toString(),
    );
    if (result != null) {
      setState(() {
        _localSettings['invoiceSignature'] = result.base64Png;
        if (result.signeeName != null) {
          _localSettings['signeeName'] = result.signeeName;
          _profile['signeeName'] = result.signeeName;
        }
        if (result.signeeTitle != null) {
          _localSettings['signeeTitle'] = result.signeeTitle;
          _profile['signeeTitle'] = result.signeeTitle;
        }
      });
      widget.onSaveLocalSettings?.call(Map<String, Object?>.from(_localSettings));
      widget.localPreferences?.writeMap('invoice_settings', _localSettings);
    }
  }

  void _removeBrandingAsset(String key) {
    setState(() => _localSettings.remove(key));
    widget.onSaveLocalSettings?.call(Map<String, Object?>.from(_localSettings));
    widget.localPreferences?.writeMap('invoice_settings', _localSettings);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onBusinessTypeChanged(String val) {
    setState(() {
      _profile['businessType'] = val;
      _profile['industryPresetId'] = val;
      final updated = Map<String, Object?>.from(_localSettings)
        ..['businessType'] = val
        ..['industryPresetId'] = val;
      if (val == 'security') {
        updated['businessCategory'] = 'Security Agency';
        updated['showItemDuty'] = true;
        updated['customDutyHeader'] = 'Duties';
        updated['customQtyHeader'] = 'Guards Count';
        updated['customRateHeader'] = 'Monthly Salary / Rate';
        updated['customItemHeader'] = 'Post / Designation';
        updated['defaultUnit'] = 'Duty';
        updated['itemCalculationFormula'] = 'monthly_salary_26';
        updated['standardDutyDays'] = 26.0;
        updated['showItemDiscount'] = false;
        updated['customTitle'] = 'SECURITY SERVICES BILL';
        updated['defaultNotes'] =
            'Thank you for your business. Security attendance verified by client site supervisor.';
        updated['defaultTerms'] =
            'Payment due within 15 days of bill submission. Statutory EPF & ESIC compliances met.';
        _profile['defaultNotes'] = updated['defaultNotes'];
        _profile['defaultTerms'] = updated['defaultTerms'];
      } else if (val == 'it') {
        updated['businessCategory'] = 'IT & Consulting';
        updated['showItemDuty'] = false;
        updated['customItemHeader'] = 'Services & Deliverables';
        updated['customQtyHeader'] = 'Hours';
        updated['customRateHeader'] = 'Hourly Rate';
        updated['defaultUnit'] = 'hrs';
        updated['itemCalculationFormula'] = 'standard';
        updated['showItemDiscount'] = false;
        updated['customTitle'] = 'Tax Invoice';
      } else if (val == 'retail') {
        updated['businessCategory'] = 'Retail & GST';
        updated['showItemDuty'] = false;
        updated['customItemHeader'] = 'Product Description';
        updated['customQtyHeader'] = 'Qty';
        updated['customRateHeader'] = 'Price';
        updated['defaultUnit'] = 'pcs';
        updated['itemCalculationFormula'] = 'standard';
        updated['showItemDiscount'] = false;
      } else if (val == 'wholesale') {
        updated['businessCategory'] = 'Corporate Suite';
        updated['showItemDuty'] = false;
        updated['customItemHeader'] = 'Material / Consignment';
        updated['customQtyHeader'] = 'Quantity';
        updated['customRateHeader'] = 'Rate per Unit';
        updated['defaultUnit'] = 'boxes';
        updated['itemCalculationFormula'] = 'standard';
        updated['showItemDiscount'] = false;
      }
      _localSettings = updated;
      widget.onSaveLocalSettings?.call(updated);
      widget.localPreferences?.writeMap('invoice_settings', updated);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Business domain set to ${_domainLabel(val)}. Custom templates & items applied!')),
    );
  }

  String _domainLabel(String key) {
    switch (key) {
      case 'security':
        return 'Security Agency';
      case 'it':
        return 'IT & Consulting';
      case 'retail':
        return 'Retail Store';
      case 'wholesale':
        return 'Wholesale & Logistics';
      case 'freelance':
        return 'Freelance & Creative';
      default:
        return 'General Trade';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          leading: widget.onBack == null
              ? null
              : IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
          title: const Text('Business Settings'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: _loading || _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check, size: 18),
                label: Text(_saving ? 'Saving...' : 'Save All'),
              ),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(icon: Icon(Icons.business_rounded), text: 'Business Profile'),
              Tab(icon: Icon(Icons.account_balance_rounded), text: 'Bank & UPI'),
              Tab(icon: Icon(Icons.draw_rounded), text: 'Brand & Terms'),
              Tab(icon: Icon(Icons.mark_email_read_rounded), text: 'Email & WhatsApp'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _SettingsError(message: _error!, onRetry: _load)
                : Form(
                    key: _formKey,
                    child: TabBarView(
                      children: [
                        BusinessProfileTab(
                          profile: _profile,
                          localSettings: _localSettings,
                          currencySymbols: _currencySymbols,
                          onBusinessTypeChanged: _onBusinessTypeChanged,
                          onSave: _save,
                          saving: _saving,
                        ),
                        BusinessBankUpiTab(
                          profile: _profile,
                          localSettings: _localSettings,
                          onPickQr: () => _pickBrandImage('invoiceQrCode', 'Payment QR Code'),
                          onRemoveQr: () => _removeBrandingAsset('invoiceQrCode'),
                          onToggleBank: (val) => setState(() => _localSettings['showBankDetails'] = val),
                          onToggleQr: (val) => setState(() => _localSettings['showQrCode'] = val),
                          onSave: _save,
                          saving: _saving,
                        ),
                        BusinessBrandTermsTab(
                          profile: _profile,
                          localSettings: _localSettings,
                          onPickLogo: () => _pickBrandImage('invoiceLogo', 'Company Logo'),
                          onRemoveLogo: () => _removeBrandingAsset('invoiceLogo'),
                          onPickStamp: () => _pickBrandImage('invoiceStamp', 'Company Stamp'),
                          onRemoveStamp: () => _removeBrandingAsset('invoiceStamp'),
                          onCaptureSignature: _captureSignature,
                          onRemoveSignature: () => _removeBrandingAsset('invoiceSignature'),
                          onSave: _save,
                          saving: _saving,
                        ),
                        EmailTemplatesTab(
                          apiClient: widget.apiClient,
                          profile: _profile,
                          localPreferences: widget.localPreferences,
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

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
