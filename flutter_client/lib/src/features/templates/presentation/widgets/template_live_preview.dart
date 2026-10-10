import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_card.dart';
import '../../data/template_config.dart';

Color parseHexColor(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  try {
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (_) {
    return const Color(0xFF2563EB);
  }
}

class TemplateLivePreview extends StatelessWidget {
  const TemplateLivePreview({
    super.key,
    required this.config,
    required this.profile,
    required this.logoImage,
    required this.saved,
  });

  final TemplateConfig config;
  final Map<String, dynamic> profile;
  final Widget? logoImage;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final brandColor = parseHexColor(config.color);
    final secondaryColor = parseHexColor(config.secondaryColor);

    final bizName = profile['businessName']?.toString().isNotEmpty == true
        ? profile['businessName'].toString()
        : 'Acme Technologies Pvt Ltd';
    final bizGstin = profile['gstin']?.toString().isNotEmpty == true
        ? profile['gstin'].toString()
        : (profile['taxId']?.toString().isNotEmpty == true
            ? profile['taxId'].toString()
            : '27AABCA1234A1Z5');
    final bizAddress = profile['address']?.toString().isNotEmpty == true
        ? profile['address'].toString()
        : 'Tech Park, Level 4, Silicon Road, Mumbai 400001';
    final bizPhone = profile['phone']?.toString().isNotEmpty == true
        ? profile['phone'].toString()
        : '+91 98765 43210';
    final bizEmail = profile['email']?.toString().isNotEmpty == true
        ? profile['email'].toString()
        : 'billing@acme.com';

    final bankName = profile['bankName']?.toString().isNotEmpty == true
        ? profile['bankName'].toString()
        : 'HDFC Bank';
    final accNo = profile['accountNumber']?.toString().isNotEmpty == true
        ? profile['accountNumber'].toString()
        : '50100234567890';
    final ifsc = profile['ifscCode']?.toString().isNotEmpty == true
        ? profile['ifscCode'].toString()
        : 'HDFC0001234';
    final upi = profile['upiId']?.toString().isNotEmpty == true
        ? profile['upiId'].toString()
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
              if (saved)
                const Chip(
                  backgroundColor: Color(0xFFECFDF5),
                  label: Text('Default', style: TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold)),
                  avatar: Icon(Icons.check, size: 16, color: Color(0xFF047857)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${config.name} · ${config.category} · Style: ${config.tableStyle.toUpperCase()}',
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
                if (config.headerLayout == 'classic') ...[
                  // Centered Letterhead
                  Center(
                    child: Column(
                      children: [
                        if (config.showLogo && logoImage != null) ...[
                          logoImage!,
                          const SizedBox(height: 6),
                        ],
                        if (config.showBillFrom) ...[
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
                          config.title.isEmpty ? 'INVOICE' : config.title,
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
                            if (config.showLogo && logoImage != null) ...[
                              logoImage!,
                              const SizedBox(height: 6),
                            ],
                            if (config.showBillFrom) ...[
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
                            config.title.isEmpty ? 'INVOICE' : config.title,
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
                    if (config.showBillTo)
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
                    if (config.showShipping) ...[
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
                          config.itemHeader,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        '${config.quantityHeader}    ${config.rateHeader}    ${config.amountHeader}',
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                _previewTableRow('Professional Consulting Services', '1.0', '₹5,000.00', '₹5,000.00', isAlt: config.tableStyle == 'striped'),
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
                        if (config.showTaxBreakdown)
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
                      child: config.showBankDetails
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
                                  if (config.showQrCode) ...[
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
                      child: config.showSignature
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
                if (config.showNotes || config.showTerms) ...[
                  const SizedBox(height: 8),
                  if (config.showNotes)
                    const Text('Notes: Thank you for your business!', style: TextStyle(fontSize: 7.5, color: Color(0xFF64748B))),
                  if (config.showTerms)
                    const Text('Terms: Payment due within specified period.', style: TextStyle(fontSize: 7, color: Color(0xFF94A3B8))),
                ],

                if (config.footer.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      config.footer,
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
}
