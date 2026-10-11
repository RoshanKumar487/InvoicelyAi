import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_card.dart';

Widget buildBusinessSettingsBanner(String title, String subtitle) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.tune_rounded, color: Colors.white, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class BusinessProfileTab extends StatelessWidget {
  const BusinessProfileTab({
    required this.profile,
    required this.localSettings,
    required this.currencySymbols,
    required this.onBusinessTypeChanged,
    required this.onSave,
    required this.saving,
    super.key,
  });

  final Map<String, dynamic> profile;
  final Map<String, Object?> localSettings;
  final Map<String, String> currencySymbols;
  final ValueChanged<String> onBusinessTypeChanged;
  final VoidCallback onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final currentBusinessType = profile['businessType']?.toString() ??
        localSettings['businessType']?.toString() ??
        localSettings['industryPresetId']?.toString() ??
        'security';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        buildBusinessSettingsBanner(
          'Registered Business Profile & Domain',
          'Manage legal company credentials, domain category, tax registrations, and default invoice currency.',
        ),
        const SizedBox(height: 14),

        // Domain Switcher Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.domain_rounded,
                        color: Color(0xFF2563EB), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Business Domain / Industry Type',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Sets specialized duty formulas, column labels & templates across the app',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: const [
                  'security',
                  'it',
                  'retail',
                  'wholesale',
                  'freelance',
                  'general'
                ].contains(currentBusinessType)
                    ? currentBusinessType
                    : 'security',
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Select Business Type',
                  prefixIcon: Icon(Icons.business_center_outlined),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'security',
                    child: Text('🛡️ Security Agency & Guard Services'),
                  ),
                  DropdownMenuItem(
                    value: 'it',
                    child: Text('💻 IT, Software & Tech Consulting'),
                  ),
                  DropdownMenuItem(
                    value: 'retail',
                    child: Text('🛍️ Retail Store & Supermarket'),
                  ),
                  DropdownMenuItem(
                    value: 'wholesale',
                    child: Text('🚚 Wholesale & Logistics'),
                  ),
                  DropdownMenuItem(
                    value: 'freelance',
                    child: Text('🎨 Freelance & Creative Agency'),
                  ),
                  DropdownMenuItem(
                    value: 'general',
                    child: Text('🏢 General Business & Services'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) onBusinessTypeChanged(val);
                },
              ),
              if (currentBusinessType == 'security') ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.verified_user_rounded,
                          color: Color(0xFF16A34A), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Security Agency Mode Active: Staff count, Duty/Days column, Monthly salary (Duty/26), and Security templates are automatically set everywhere.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF166534),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Company Details Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Company Registration & Contact',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: profile['businessName']?.toString() ??
                    profile['companyName']?.toString() ??
                    localSettings['businessName']?.toString() ??
                    '',
                decoration: const InputDecoration(
                  labelText: 'Company / Business Name *',
                  prefixIcon: Icon(Icons.business_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'Enter business name' : null,
                onChanged: (val) {
                  profile['businessName'] = val;
                  profile['companyName'] = val;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: profile['legalName']?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'Legal Entity Name (if different)',
                  prefixIcon: Icon(Icons.gavel_outlined),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => profile['legalName'] = val,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: profile['email']?.toString() ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Business Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (val) => profile['email'] = val,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      initialValue: profile['phone']?.toString() ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Business Phone',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (val) => profile['phone'] = val,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: profile['address']?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'Registered Office Address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                onChanged: (val) => profile['address'] = val,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: profile['website']?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'Company Website',
                  prefixIcon: Icon(Icons.language_outlined),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => profile['website'] = val,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Tax Identification Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tax Identifiers & Compliance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: profile['gstin']?.toString() ?? '',
                      decoration: const InputDecoration(
                        labelText: 'GSTIN',
                        hintText: 'e.g. 27AABCA1234A1Z5',
                        prefixIcon: Icon(Icons.receipt_long_outlined),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => profile['gstin'] = val,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      initialValue: profile['panNumber']?.toString() ?? '',
                      decoration: const InputDecoration(
                        labelText: 'PAN Number',
                        hintText: 'e.g. AABCA1234A',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => profile['panNumber'] = val,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: profile['taxId']?.toString() ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Tax ID / VAT No.',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => profile['taxId'] = val,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      initialValue: profile['placeOfSupply']?.toString() ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Place of Supply',
                        hintText: 'e.g. Maharashtra (27)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => profile['placeOfSupply'] = val,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Currency Configuration Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Default Billing Currency',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Applied as default currency across all new invoices, line items, and previews',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: profile['defaultCurrency']?.toString() ??
                    localSettings['defaultCurrency']?.toString() ??
                    'INR',
                decoration: const InputDecoration(
                  labelText: 'Default Currency',
                  prefixIcon: Icon(Icons.currency_exchange_rounded),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'INR', child: Text('INR — ₹ (Indian Rupee)')),
                  DropdownMenuItem(value: 'USD', child: Text('USD — \$ (US Dollar)')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR — € (Euro)')),
                  DropdownMenuItem(value: 'GBP', child: Text('GBP — £ (British Pound)')),
                  DropdownMenuItem(value: 'AED', child: Text('AED — UAE Dirham')),
                  DropdownMenuItem(value: 'CAD', child: Text('CAD — C\$ (Canadian Dollar)')),
                  DropdownMenuItem(value: 'AUD', child: Text('AUD — A\$ (Australian Dollar)')),
                  DropdownMenuItem(value: 'SGD', child: Text('SGD — S\$ (Singapore Dollar)')),
                  DropdownMenuItem(value: 'SAR', child: Text('SAR — Saudi Riyal')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  profile['defaultCurrency'] = value;
                  profile['defaultCurrencySymbol'] =
                      currencySymbols[value] ?? value;
                  localSettings['defaultCurrency'] = value;
                  localSettings['defaultCurrencySymbol'] =
                      currencySymbols[value] ?? value;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        FilledButton.icon(
          onPressed: saving ? null : onSave,
          icon: const Icon(Icons.check_circle_outline),
          label: Text(saving ? 'Saving...' : 'Save Business Profile'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class BusinessBankUpiTab extends StatelessWidget {
  const BusinessBankUpiTab({
    required this.profile,
    required this.localSettings,
    required this.onPickQr,
    required this.onRemoveQr,
    required this.onToggleBank,
    required this.onToggleQr,
    required this.onSave,
    required this.saving,
    super.key,
  });

  final Map<String, dynamic> profile;
  final Map<String, Object?> localSettings;
  final VoidCallback onPickQr;
  final VoidCallback onRemoveQr;
  final ValueChanged<bool> onToggleBank;
  final ValueChanged<bool> onToggleQr;
  final VoidCallback onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final showBank = localSettings['showBankDetails'] != false;
    final showQr = localSettings['showQrCode'] != false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        buildBusinessSettingsBanner(
          'Bank & Digital Payment Configuration',
          'Configure company bank account and UPI details. A Scan-to-Pay QR code is generated on invoices when UPI ID is provided.',
        ),
        const SizedBox(height: 14),

        // Display Options
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invoice Display Toggles',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show Bank Details on Invoices'),
                subtitle: const Text(
                  'Display bank name, account number and IFSC code on generated bills',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                value: showBank,
                onChanged: onToggleBank,
              ),
              const Divider(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show Payment QR Code on Invoices'),
                subtitle: const Text(
                  'Render Scan-to-Pay UPI QR code or uploaded QR code on bills',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                value: showQr,
                onChanged: onToggleQr,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Bank Details Form
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bank Account Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: profile['bankName']?.toString() ??
                    localSettings['bankName']?.toString() ??
                    '',
                decoration: const InputDecoration(
                  labelText: 'Bank Name',
                  hintText: 'e.g. State Bank of India, HDFC Bank',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  profile['bankName'] = val;
                  localSettings['bankName'] = val;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: profile['accountHolder']?.toString() ??
                    localSettings['accountHolder']?.toString() ??
                    '',
                decoration: const InputDecoration(
                  labelText: 'Account Holder Name',
                  hintText: 'e.g. Acme Security Services Pvt Ltd',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  profile['accountHolder'] = val;
                  localSettings['accountHolder'] = val;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: profile['accountNumber']?.toString() ??
                    localSettings['accountNumber']?.toString() ??
                    '',
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  prefixIcon: Icon(Icons.numbers_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  profile['accountNumber'] = val;
                  localSettings['accountNumber'] = val;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: profile['ifscCode']?.toString() ??
                          localSettings['ifscCode']?.toString() ??
                          '',
                      decoration: const InputDecoration(
                        labelText: 'IFSC Code',
                        hintText: 'e.g. SBIN0001234',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        profile['ifscCode'] = val;
                        localSettings['ifscCode'] = val;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      initialValue: profile['swiftBic']?.toString() ??
                          localSettings['swiftBic']?.toString() ??
                          '',
                      decoration: const InputDecoration(
                        labelText: 'SWIFT / BIC',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        profile['swiftBic'] = val;
                        localSettings['swiftBic'] = val;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Digital Payment UPI & Link
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Digital UPI & Online Payment Link',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: profile['upiId']?.toString() ??
                    localSettings['upiId']?.toString() ??
                    '',
                decoration: const InputDecoration(
                  labelText: 'UPI ID / VPA',
                  hintText: 'e.g. company@okhdfcbank or 9876543210@paytm',
                  prefixIcon: Icon(Icons.qr_code_2_rounded),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  profile['upiId'] = val;
                  localSettings['upiId'] = val;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: profile['paymentLink']?.toString() ??
                    localSettings['paymentLink']?.toString() ??
                    '',
                decoration: const InputDecoration(
                  labelText: 'Payment Gateway Link',
                  hintText: 'e.g. https://rzp.io/l/acme-bill',
                  prefixIcon: Icon(Icons.link_rounded),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  profile['paymentLink'] = val;
                  localSettings['paymentLink'] = val;
                },
              ),
              const SizedBox(height: 14),
              BusinessBrandingAssetTile(
                label: 'Custom Payment QR Code (Optional)',
                base64: localSettings['invoiceQrCode']?.toString(),
                onPick: onPickQr,
                onRemove: onRemoveQr,
                pickLabel: 'Upload QR',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        FilledButton.icon(
          onPressed: saving ? null : onSave,
          icon: const Icon(Icons.check_circle_outline),
          label: Text(saving ? 'Saving...' : 'Save Bank & UPI Settings'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class BusinessBrandTermsTab extends StatelessWidget {
  const BusinessBrandTermsTab({
    required this.profile,
    required this.localSettings,
    required this.onPickLogo,
    required this.onRemoveLogo,
    required this.onPickStamp,
    required this.onRemoveStamp,
    required this.onCaptureSignature,
    required this.onRemoveSignature,
    required this.onSave,
    required this.saving,
    super.key,
  });

  final Map<String, dynamic> profile;
  final Map<String, Object?> localSettings;
  final VoidCallback onPickLogo;
  final VoidCallback onRemoveLogo;
  final VoidCallback onPickStamp;
  final VoidCallback onRemoveStamp;
  final VoidCallback onCaptureSignature;
  final VoidCallback onRemoveSignature;
  final VoidCallback onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        buildBusinessSettingsBanner(
          'Brand Identity, Stamp & Legal Terms',
          'Upload official company logo, stamp, and authorized digital signature via DocuHub Signer for legally binding invoices.',
        ),
        const SizedBox(height: 14),

        // Brand Visual Assets
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Visual Branding Assets',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Assets are embedded into invoice previews, PDFs, and print outs',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              BusinessBrandingAssetTile(
                label: 'Company Logo',
                base64: localSettings['invoiceLogo']?.toString(),
                onPick: onPickLogo,
                onRemove: onRemoveLogo,
                pickLabel: 'Choose Logo',
              ),
              const SizedBox(height: 12),
              BusinessBrandingAssetTile(
                label: 'Official Company Stamp',
                base64: localSettings['invoiceStamp']?.toString(),
                onPick: onPickStamp,
                onRemove: onRemoveStamp,
                pickLabel: 'Upload Stamp',
              ),
              const SizedBox(height: 12),
              BusinessBrandingAssetTile(
                label: 'Authorized Signature',
                base64: localSettings['invoiceSignature']?.toString(),
                onPick: onCaptureSignature,
                onRemove: onRemoveSignature,
                pickLabel: 'Draw / Sign',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Signatory Details Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Authorized Signatory Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: profile['signeeName']?.toString() ??
                          localSettings['signeeName']?.toString() ??
                          '',
                      decoration: const InputDecoration(
                        labelText: 'Signatory Name',
                        hintText: 'e.g. Rajesh Sharma',
                        prefixIcon: Icon(Icons.person_pin_outlined),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        profile['signeeName'] = val;
                        localSettings['signeeName'] = val;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      initialValue: profile['signeeTitle']?.toString() ??
                          localSettings['signeeTitle']?.toString() ??
                          'Authorized Signatory',
                      decoration: const InputDecoration(
                        labelText: 'Designation / Title',
                        hintText: 'e.g. Managing Director',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        profile['signeeTitle'] = val;
                        localSettings['signeeTitle'] = val;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Default Notes and Terms
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Default Invoice Notes & Terms',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: profile['defaultNotes']?.toString() ??
                    localSettings['defaultNotes']?.toString() ??
                    '',
                decoration: const InputDecoration(
                  labelText: 'Default Notes',
                  hintText: 'e.g. Thank you for your business. Security attendance muster roll attached.',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (val) {
                  profile['defaultNotes'] = val;
                  localSettings['defaultNotes'] = val;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: profile['defaultTerms']?.toString() ??
                    localSettings['defaultTerms']?.toString() ??
                    '',
                decoration: const InputDecoration(
                  labelText: 'Default Terms & Conditions',
                  hintText: 'e.g. Payment due within 15 days of bill submission. Statutory compliances met.',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (val) {
                  profile['defaultTerms'] = val;
                  localSettings['defaultTerms'] = val;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: profile['brandColorHex']?.toString() ?? '#1E3A8A',
                decoration: const InputDecoration(
                  labelText: 'Primary Brand Color Hex',
                  hintText: 'e.g. #1E3A8A',
                  prefixIcon: Icon(Icons.palette_outlined),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => profile['brandColorHex'] = val,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        FilledButton.icon(
          onPressed: saving ? null : onSave,
          icon: const Icon(Icons.check_circle_outline),
          label: Text(saving ? 'Saving...' : 'Save Brand & Terms'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class BusinessBrandingAssetTile extends StatelessWidget {
  const BusinessBrandingAssetTile({
    required this.label,
    required this.base64,
    required this.onPick,
    required this.onRemove,
    this.pickLabel = 'Choose',
    super.key,
  });

  final String label;
  final String? base64;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final String pickLabel;

  @override
  Widget build(BuildContext context) {
    Uint8List? bytes;
    try {
      if (base64 != null && base64!.isNotEmpty) {
        bytes = base64Decode(base64!);
      }
    } on FormatException {
      bytes = null;
    }
    return Row(
      children: [
        Container(
          width: 64,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: bytes == null
              ? const Icon(Icons.image_outlined, color: Color(0xFF94A3B8))
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    bytes,
                    width: 62,
                    height: 52,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (bytes != null)
          IconButton(
            tooltip: 'Remove $label',
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        FilledButton.tonal(
          onPressed: onPick,
          child: Text(pickLabel),
        ),
      ],
    );
  }
}
