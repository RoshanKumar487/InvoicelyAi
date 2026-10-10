import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_card.dart';

class InvoiceSettingsBankTab extends StatelessWidget {
  const InvoiceSettingsBankTab({
    super.key,
    required this.profile,
    required this.localSettings,
    required this.onChanged,
    required this.onSave,
  });

  final Map<String, dynamic> profile;
  final Map<String, Object?> localSettings;
  final VoidCallback onChanged;
  final VoidCallback onSave;

  Widget _buildInfoBanner(String title, String subtitle) {
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

  @override
  Widget build(BuildContext context) {
    final bankName = profile['bankName']?.toString() ??
        localSettings['bankName']?.toString() ??
        '';
    final accHolder = profile['accountHolder']?.toString() ??
        localSettings['accountHolder']?.toString() ??
        '';
    final accNo = profile['accountNumber']?.toString() ??
        localSettings['accountNumber']?.toString() ??
        '';
    final ifsc = profile['ifscCode']?.toString() ??
        localSettings['ifscCode']?.toString() ??
        '';
    final swift = profile['swiftBic']?.toString() ??
        localSettings['swiftBic']?.toString() ??
        '';
    final upi = profile['upiId']?.toString() ??
        localSettings['upiId']?.toString() ??
        '';
    final payLink = profile['paymentLink']?.toString() ??
        localSettings['paymentLink']?.toString() ??
        '';

    final showBank = localSettings['showBankDetails'] != false;
    final showQr = localSettings['showQrCode'] != false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoBanner(
          'Bank & Digital Payment Configuration',
          'Configure your company bank account and optional UPI ID. When UPI ID or payment link is provided, a Scan-to-Pay QR code will be generated on invoices.',
        ),
        const SizedBox(height: 14),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Display Options',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show Bank & Payment Details on Invoices',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text(
                  'Displays account number, IFSC code, and beneficiary details on invoices',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                value: showBank,
                onChanged: (val) {
                  localSettings['showBankDetails'] = val;
                  onChanged();
                },
              ),
              const Divider(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show Scan-to-Pay QR Code (Optional)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text(
                  'Strictly optional: generated only if UPI ID or payment link is provided below. If left blank, QR code is hidden.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                value: showQr,
                onChanged: (val) {
                  localSettings['showQrCode'] = val;
                  onChanged();
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.account_balance, color: Color(0xFF2563EB), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Bank Account Information',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: bankName,
                decoration: const InputDecoration(
                  labelText: 'Bank Name',
                  hintText: 'e.g. HDFC Bank, State Bank of India, ICICI Bank',
                  prefixIcon: Icon(Icons.business_outlined, size: 18),
                ),
                onChanged: (val) {
                  profile['bankName'] = val.trim();
                  localSettings['bankName'] = val.trim();
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: accHolder,
                decoration: const InputDecoration(
                  labelText: 'Account Holder / Beneficiary Name',
                  hintText: 'e.g. Acme Security Services Pvt Ltd',
                  prefixIcon: Icon(Icons.person_outline, size: 18),
                ),
                onChanged: (val) {
                  profile['accountHolder'] = val.trim();
                  localSettings['accountHolder'] = val.trim();
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: TextFormField(
                      initialValue: accNo,
                      decoration: const InputDecoration(
                        labelText: 'Account Number',
                        hintText: 'e.g. 50200012345678',
                        prefixIcon: Icon(Icons.credit_card_outlined, size: 18),
                      ),
                      onChanged: (val) {
                        profile['accountNumber'] = val.trim();
                        localSettings['accountNumber'] = val.trim();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      initialValue: ifsc,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'IFSC Code',
                        hintText: 'e.g. HDFC0001234',
                        prefixIcon: Icon(Icons.pin_outlined, size: 18),
                      ),
                      onChanged: (val) {
                        profile['ifscCode'] = val.trim().toUpperCase();
                        localSettings['ifscCode'] = val.trim().toUpperCase();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: swift,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'SWIFT / BIC (Optional for international)',
                  hintText: 'e.g. HDFCINBBXXX',
                  prefixIcon: Icon(Icons.language_outlined, size: 18),
                ),
                onChanged: (val) {
                  profile['swiftBic'] = val.trim().toUpperCase();
                  localSettings['swiftBic'] = val.trim().toUpperCase();
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.qr_code_2, color: Color(0xFF047857), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Instant Digital Payment & UPI (Optional)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Customers can scan the QR code using Google Pay, PhonePe, Paytm, BHIM, or any UPI app to pay invoice balance directly.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: upi,
                decoration: const InputDecoration(
                  labelText: 'UPI ID / VPA (Optional)',
                  hintText: 'e.g. yourbusiness@okhdfcbank, 9876543210@paytm',
                  prefixIcon: Icon(Icons.flash_on_outlined, size: 18, color: Color(0xFF047857)),
                  helperText: 'Creates dynamic Scan-to-Pay QR code on invoice',
                ),
                onChanged: (val) {
                  profile['upiId'] = val.trim();
                  localSettings['upiId'] = val.trim();
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: payLink,
                decoration: const InputDecoration(
                  labelText: 'Payment Gateway Link (Optional)',
                  hintText: 'e.g. https://rzp.io/l/yourlink or https://stripe.com/...',
                  prefixIcon: Icon(Icons.link_outlined, size: 18),
                  helperText: 'Shown as clickable payment link on invoice & PDF',
                ),
                onChanged: (val) {
                  profile['paymentLink'] = val.trim();
                  localSettings['paymentLink'] = val.trim();
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Save All Invoice Customizations'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
