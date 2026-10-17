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
      // Synchronize company currency, branding assets, and business details with local settings
      final cur = profile['defaultCurrency']?.toString() ?? 'INR';
      final updated = Map<String, Object?>.from(_localSettings);
      if (cur.isNotEmpty) {
        updated['defaultCurrency'] = cur;
        updated['defaultCurrencySymbol'] =
            profile['defaultCurrencySymbol']?.toString() ??
                _currencySymbols[cur] ??
                '₹';
        updated['defaultCurrencyFormat'] =
            profile['defaultCurrencyFormat']?.toString() ?? 'before';
      }
      final rawBizName = (profile['businessName']?.toString().trim().isNotEmpty == true
              ? profile['businessName'].toString().trim()
              : (profile['companyName']?.toString().trim().isNotEmpty == true
                  ? profile['companyName'].toString().trim()
                  : profile['legalName']?.toString().trim())) ??
          '';
      if (rawBizName.isNotEmpty &&
          rawBizName.toLowerCase() != 'apex nova dynamics') {
        updated['businessName'] = rawBizName;
        updated['companyName'] = rawBizName;
        _profile['businessName'] = rawBizName;
        _profile['companyName'] = rawBizName;
        final curLh = updated['letterhead_company_name']?.toString().trim().toLowerCase() ?? '';
        if (curLh.isEmpty ||
            curLh == 'northstar security services pvt. ltd.' ||
            curLh == 'northstar security services ltd.') {
          updated['letterhead_company_name'] = rawBizName;
        }
      }
      if (profile['address']?.toString().trim().isNotEmpty == true) {
        updated['businessAddress'] = profile['address'];
      }
      if (profile['gstin']?.toString().trim().isNotEmpty == true) {
        updated['businessGstin'] = profile['gstin'];
      }
      if (profile['panNumber']?.toString().trim().isNotEmpty == true) {
        updated['businessPan'] = profile['panNumber'];
      }
      if (profile['phone']?.toString().trim().isNotEmpty == true) {
        updated['businessPhone'] = profile['phone'];
      }
      if (profile['email']?.toString().trim().isNotEmpty == true) {
        updated['businessEmail'] = profile['email'];
      }
      if (profile['website']?.toString().trim().isNotEmpty == true) {
        updated['businessWebsite'] = profile['website'];
      }
      if (profile['upiId']?.toString().trim().isNotEmpty == true) {
        updated['upiId'] = profile['upiId'];
      }
      if (profile['bankName']?.toString().trim().isNotEmpty == true) {
        updated['bankName'] = profile['bankName'];
      }
      if (profile['accountNumber']?.toString().trim().isNotEmpty == true) {
        updated['accountNumber'] = profile['accountNumber'];
      }
      if (profile['accountHolder']?.toString().trim().isNotEmpty == true) {
        updated['accountHolder'] = profile['accountHolder'];
      }
      if (profile['ifscCode']?.toString().trim().isNotEmpty == true) {
        updated['ifscCode'] = profile['ifscCode'];
      }
      if (profile['signeeName']?.toString().trim().isNotEmpty == true) {
        updated['signeeName'] = profile['signeeName'];
      }
      if (profile['signeeTitle']?.toString().trim().isNotEmpty == true) {
        updated['signeeTitle'] = profile['signeeTitle'];
      }
      // Sync organization-scoped branding files from server profile
      if (profile['logoUrl']?.toString().trim().isNotEmpty == true) {
        updated['invoiceLogo'] = profile['logoUrl'];
      }
      if (profile['stampUrl']?.toString().trim().isNotEmpty == true) {
        updated['invoiceStamp'] = profile['stampUrl'];
      }
      if (profile['signatureUrl']?.toString().trim().isNotEmpty == true) {
        updated['invoiceSignature'] = profile['signatureUrl'];
      }
      if (profile['qrCodeUrl']?.toString().trim().isNotEmpty == true) {
        updated['invoiceQrCode'] = profile['qrCodeUrl'];
      }
      _localSettings = updated;
      widget.onSaveLocalSettings?.call(updated);
      widget.localPreferences?.writeMap('invoice_settings', updated);
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
      final resolvedBizName = (_profile['businessName']?.toString().trim().isNotEmpty == true
              ? _profile['businessName'].toString().trim()
              : (_profile['companyName']?.toString().trim().isNotEmpty == true
                  ? _profile['companyName'].toString().trim()
                  : _localSettings['businessName']?.toString().trim())) ??
          '';
      if (resolvedBizName.isNotEmpty) {
        _profile['businessName'] = resolvedBizName;
        _profile['companyName'] = resolvedBizName;
        _profile['legalName'] = _profile['legalName']?.toString().trim().isNotEmpty == true
            ? _profile['legalName']
            : resolvedBizName;
      }

      // Attach organization branding assets (logo, stamp, signature, qr) to server profile
      _profile['logoUrl'] = _localSettings['invoiceLogo']?.toString() ?? '';
      _profile['stampUrl'] = _localSettings['invoiceStamp']?.toString() ?? '';
      _profile['signatureUrl'] = _localSettings['invoiceSignature']?.toString() ?? '';
      _profile['qrCodeUrl'] = _localSettings['invoiceQrCode']?.toString() ?? '';

      final result = await _repository.saveProfile(_profile);

      // Also sync backend Company entity (preserving organization code) so Team Management & Header show the updated name
      if (resolvedBizName.isNotEmpty) {
        try {
          await widget.apiClient.putJson('api/v1/companies/my-company', {
            'companyName': resolvedBizName,
            if (_profile['gstin'] != null) 'gstin': _profile['gstin'],
            if (_profile['address'] != null) 'location': _profile['address'],
            if (_profile['email'] != null) 'email': _profile['email'],
            if (_profile['phone'] != null) 'phone': _profile['phone'],
            if (_profile['website'] != null) 'website': _profile['website'],
            if (_localSettings['invoiceStamp'] != null)
              'signatureStampUrl': _localSettings['invoiceStamp'],
          });
        } catch (_) {}
      }

      final finalBizName = result['businessName']?.toString().trim().isNotEmpty == true
          ? result['businessName'].toString().trim()
          : (result['companyName']?.toString().trim().isNotEmpty == true
              ? result['companyName'].toString().trim()
              : resolvedBizName);

      final updatedLocal = Map<String, Object?>.from(_localSettings)
        ..['defaultCurrency'] = currency
        ..['defaultCurrencySymbol'] = currencySymbol
        ..['defaultCurrencyFormat'] = currencyFormat
        ..['businessName'] = finalBizName
        ..['companyName'] = finalBizName
        ..['letterhead_company_name'] = finalBizName
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
          content: Text('✓ All business profile, bank & organization branding settings saved!'),
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

  Future<void> _syncBrandingAssetsToServer() async {
    try {
      _profile['logoUrl'] = _localSettings['invoiceLogo']?.toString() ?? '';
      _profile['stampUrl'] = _localSettings['invoiceStamp']?.toString() ?? '';
      _profile['signatureUrl'] = _localSettings['invoiceSignature']?.toString() ?? '';
      _profile['qrCodeUrl'] = _localSettings['invoiceQrCode']?.toString() ?? '';
      await _repository.saveProfile(_profile);
    } catch (_) {}
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
      final b64 = base64Encode(bytes);
      setState(() => _localSettings[key] = b64);
      widget.onSaveLocalSettings?.call(Map<String, Object?>.from(_localSettings));
      await widget.localPreferences?.writeMap('invoice_settings', _localSettings);
      await _syncBrandingAssetsToServer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF047857),
            content: Text('✓ $label uploaded & saved for your organization!'),
          ),
        );
      }
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
      await widget.localPreferences?.writeMap('invoice_settings', _localSettings);
      await _syncBrandingAssetsToServer();
    }
  }

  void _removeBrandingAsset(String key) {
    setState(() => _localSettings.remove(key));
    widget.onSaveLocalSettings?.call(Map<String, Object?>.from(_localSettings));
    widget.localPreferences?.writeMap('invoice_settings', _localSettings);
    _syncBrandingAssetsToServer();
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
