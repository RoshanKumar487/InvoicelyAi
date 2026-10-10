import 'dart:convert';
import 'package:flutter/material.dart';

import '../../data/invoice.dart';
import '../../../templates/data/template_config.dart';
import 'invoice_preview_widgets.dart';

const double a4PaperWidth = 760.0;
const double a4PaperMinHeight = 1075.0;

class InvoicePreviewA4Paper extends StatelessWidget {
  const InvoicePreviewA4Paper({
    required this.invoice,
    required this.template,
    required this.templateColor,
    required this.isMobile,
    required this.localSettings,
    required this.profile,
    this.onSignTap,
    super.key,
  });

  final Invoice invoice;
  final TemplateConfig? template;
  final Color templateColor;
  final bool isMobile;
  final Map<String, Object?> localSettings;
  final Map<String, Object?> profile;
  final VoidCallback? onSignTap;

  bool _show(String key, {bool fallback = true}) {
    if (localSettings.containsKey(key)) {
      return localSettings[key] == true;
    }
    return fallback;
  }

  String _label(String key, String fallback) {
    final custom = localSettings[key]?.toString().trim();
    return (custom != null && custom.isNotEmpty) ? custom : fallback;
  }

  List<Map<String, dynamic>> _customFields(String key) {
    final raw = localSettings[key];
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } catch (_) {}
    }
    return <Map<String, dynamic>>[];
  }

  Image? _brandImage(String key, {double height = 65}) {
    final encoded = localSettings[key]?.toString() ?? '';
    if (encoded.isEmpty) return null;
    try {
      return Image.memory(
        base64Decode(encoded),
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    } on FormatException {
      return null;
    }
  }

  List<String> _shippingLines() {
    final json = invoice.shippingDetailsJson;
    if (json.trim().isEmpty || json.trim() == '{}') return const [];
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map<String, dynamic> || decoded['isEnabled'] != true) {
        return const [];
      }
      const fields = <String, String>{
        'shippingAddress': 'Shipping address',
        'deliveryAddress': 'Delivery address',
        'shippingMethod': 'Shipping method',
        'courier': 'Carrier',
        'trackingNumber': 'Tracking',
        'expectedDelivery': 'Expected delivery',
      };
      return fields.entries
          .where((entry) =>
              decoded[entry.key]?.toString().trim().isNotEmpty == true)
          .map((entry) => '${entry.value}: ${decoded[entry.key]}')
          .toList(growable: false);
    } on FormatException {
      return const ['Shipping details could not be displayed.'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final signatureImage =
        _show('showSignature') ? _brandImage('invoiceSignature') : null;
    final stampImage = _show('showStamp') ? _brandImage('invoiceStamp') : null;
    final logoImage =
        (_show('showLogo') && (template?.showLogo ?? true)) ? _brandImage('invoiceLogo') : null;

    final documentTitle = _label(
      'customTitle',
      template?.title ?? 'INVOICE',
    );
    final invoiceNoLabel = _label('customInvoiceNoLabel', 'Invoice #');
    final issueDateLabel = _label('customDateLabel', 'Creation Date');
    final dueDateLabel = _label('customDueDateLabel', 'Due Date');
    final poLabel = _label('customPoLabel', 'PO Number');
    final billToLabel = _label('customBillToLabel', 'BILL TO');
    final notesLabel = _label('customNotesLabel', 'Notes');
    final termsLabel = _label('customTermsLabel', 'Terms and conditions');
    final signeeTitle = _label('signeeTitle', 'Authorized Signatory');
    final signeeName = _label('signeeName', '');

    final customDetails = _customFields('customFields_details');
    final customBilling = _customFields('customFields_billing');
    final customAdjustments = _customFields('customFields_adjustments');
    final customFooter = _customFields('customFields_footer');

    final showBillFrom = _show('showBillFrom', fallback: true) && (template?.showBillFrom ?? true);
    final showBank = _show('showBankDetails', fallback: true) && (template?.showBankDetails ?? true);
    final showBillTo = _show('showBillTo', fallback: true) && (template?.showBillTo ?? true);

    final bizName = profile['businessName']?.toString().trim().isNotEmpty == true
        ? profile['businessName'].toString()
        : (localSettings['businessName']?.toString().trim().isNotEmpty == true
            ? localSettings['businessName'].toString()
            : '');
    final bizLegalName = profile['legalName']?.toString().trim().isNotEmpty == true
        ? profile['legalName'].toString()
        : '';
    final bizAddress = profile['address']?.toString().trim().isNotEmpty == true
        ? profile['address'].toString()
        : (localSettings['businessAddress']?.toString().trim().isNotEmpty == true
            ? localSettings['businessAddress'].toString()
            : '');
    final bizGstin = profile['gstin']?.toString().trim().isNotEmpty == true
        ? profile['gstin'].toString()
        : (profile['taxId']?.toString().trim().isNotEmpty == true
            ? profile['taxId'].toString()
            : (localSettings['businessGstin']?.toString().trim().isNotEmpty == true
                ? localSettings['businessGstin'].toString()
                : ''));
    final bizPan = profile['panNumber']?.toString().trim().isNotEmpty == true
        ? profile['panNumber'].toString()
        : (localSettings['businessPan']?.toString().trim().isNotEmpty == true
            ? localSettings['businessPan'].toString()
            : '');
    final bizPhone = profile['phone']?.toString().trim().isNotEmpty == true
        ? profile['phone'].toString()
        : (localSettings['businessPhone']?.toString().trim().isNotEmpty == true
            ? localSettings['businessPhone'].toString()
            : '');
    final bizEmail = profile['email']?.toString().trim().isNotEmpty == true
        ? profile['email'].toString()
        : (localSettings['businessEmail']?.toString().trim().isNotEmpty == true
            ? localSettings['businessEmail'].toString()
            : '');
    final bizWebsite = profile['website']?.toString().trim().isNotEmpty == true
        ? profile['website'].toString()
        : (localSettings['businessWebsite']?.toString().trim().isNotEmpty == true
            ? localSettings['businessWebsite'].toString()
            : '');

    final bankName = profile['bankName']?.toString().trim().isNotEmpty == true
        ? profile['bankName'].toString()
        : (localSettings['bankName']?.toString().trim().isNotEmpty == true
            ? localSettings['bankName'].toString()
            : '');
    final accountHolder = profile['accountHolder']?.toString().trim().isNotEmpty == true
        ? profile['accountHolder'].toString()
        : (localSettings['accountHolder']?.toString().trim().isNotEmpty == true
            ? localSettings['accountHolder'].toString()
            : '');
    final accountNumber = profile['accountNumber']?.toString().trim().isNotEmpty == true
        ? profile['accountNumber'].toString()
        : (localSettings['accountNumber']?.toString().trim().isNotEmpty == true
            ? localSettings['accountNumber'].toString()
            : '');
    final ifscCode = profile['ifscCode']?.toString().trim().isNotEmpty == true
        ? profile['ifscCode'].toString()
        : (localSettings['ifscCode']?.toString().trim().isNotEmpty == true
            ? localSettings['ifscCode'].toString()
            : '');
    final upiId = profile['upiId']?.toString().trim().isNotEmpty == true
        ? profile['upiId'].toString()
        : (localSettings['upiId']?.toString().trim().isNotEmpty == true
            ? localSettings['upiId'].toString()
            : '');
    final paymentLink = profile['paymentLink']?.toString().trim().isNotEmpty == true
        ? profile['paymentLink'].toString()
        : (localSettings['paymentLink']?.toString().trim().isNotEmpty == true
            ? localSettings['paymentLink'].toString()
            : '');

    return Container(
      width: a4PaperWidth,
      constraints: const BoxConstraints(minHeight: a4PaperMinHeight),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 28,
            spreadRadius: 4,
            offset: Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Layout based (Classic Centered vs Modern Side-by-Side)
          if (template?.headerLayout == 'classic') ...[
            Center(
              child: Column(
                children: [
                  if (logoImage != null) ...[
                    logoImage,
                    const SizedBox(height: 8),
                  ],
                  if (showBillFrom && bizName.isNotEmpty) ...[
                    Text(
                      bizName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: templateColor,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (bizLegalName.isNotEmpty && bizLegalName != bizName)
                      Text(bizLegalName, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)), textAlign: TextAlign.center),
                    if (bizAddress.isNotEmpty)
                      Text(bizAddress, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), textAlign: TextAlign.center),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      children: [
                        if (bizGstin.isNotEmpty) Text('GSTIN: $bizGstin', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        if (bizPan.isNotEmpty) Text('PAN: $bizPan', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        if (bizPhone.isNotEmpty) Text('Ph: $bizPhone', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        if (bizEmail.isNotEmpty) Text('Email: $bizEmail', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    documentTitle,
                    style: TextStyle(
                      color: templateColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    children: [
                      Text('$invoiceNoLabel: ${invoice.invoiceNumber}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      if (_show('showIssueDate', fallback: true))
                        Text('$issueDateLabel: ${invoice.issueDate}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                      if (_show('showDueDate', fallback: false))
                        Text('$dueDateLabel: ${invoice.dueDate}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      if (_show('showStatus', fallback: false))
                        PreviewStatusChip(status: invoice.status),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // Modern Side-by-Side (Default)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (logoImage != null) ...[
                        logoImage,
                        const SizedBox(height: 8),
                      ],
                      if (showBillFrom && bizName.isNotEmpty) ...[
                        Text(
                          bizName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (bizLegalName.isNotEmpty && bizLegalName != bizName)
                          Text(bizLegalName, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                        if (bizAddress.isNotEmpty)
                          Text(bizAddress, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        if (bizGstin.isNotEmpty || bizPan.isNotEmpty)
                          Text([if (bizGstin.isNotEmpty) 'GSTIN: $bizGstin', if (bizPan.isNotEmpty) 'PAN: $bizPan'].join('  |  '),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                        if (bizPhone.isNotEmpty || bizEmail.isNotEmpty)
                          Text([if (bizPhone.isNotEmpty) bizPhone, if (bizEmail.isNotEmpty) bizEmail].join(' • '),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        if (bizWebsite.isNotEmpty)
                          Text(bizWebsite, style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB))),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      documentTitle,
                      style: TextStyle(
                        color: templateColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$invoiceNoLabel: ${invoice.invoiceNumber}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    if (_show('showStatus', fallback: false)) ...[
                      const SizedBox(height: 6),
                      PreviewStatusChip(status: invoice.status),
                    ],
                    const SizedBox(height: 6),
                    if (_show('showIssueDate', fallback: true))
                      Text(
                        '$issueDateLabel: ${invoice.issueDate}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF475569),
                        ),
                      ),
                    if (_show('showDueDate', fallback: false))
                      Text(
                        '$dueDateLabel: ${invoice.dueDate}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    if (_show('showPoNumber', fallback: false) && invoice.poNumber.isNotEmpty)
                      Text(
                        '$poLabel: ${invoice.poNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    if (_show('showPaymentTerms', fallback: false) && invoice.paymentTerms.isNotEmpty)
                      Text(
                        'Terms: ${invoice.paymentTerms}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    for (final field in customDetails)
                      if (field['isVisible'] != false && field['label']?.toString().isNotEmpty == true)
                        Text(
                          '${field['label']}: ${field['value'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                  ],
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),
          Container(height: 2.5, color: templateColor),
          const SizedBox(height: 20),

          // Bill To & Ship To Details
          if (showBillTo || ((_show('showShippingSection', fallback: false) || (template?.showShipping ?? false)) && _shippingLines().isNotEmpty)) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showBillTo)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          billToLabel,
                          style: TextStyle(
                            color: templateColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          invoice.clientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (_show('showClientCompany') && invoice.clientCompany.isNotEmpty)
                          Text(invoice.clientCompany, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF334155))),
                        if (_show('showClientEmail') && invoice.clientEmail.isNotEmpty)
                          Text(invoice.clientEmail, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                        if (_show('showClientPhone') && invoice.clientPhone.isNotEmpty)
                          Text(invoice.clientPhone, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                        if (_show('showClientAddress') && invoice.clientAddress.isNotEmpty)
                          Text(invoice.clientAddress, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
                        if (_show('showClientTaxId') && invoice.clientTaxId.isNotEmpty)
                          Text('${_label('customClientTaxIdLabel', 'Tax ID')}: ${invoice.clientTaxId}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                        for (final field in customBilling)
                          if (field['isVisible'] != false && field['label']?.toString().isNotEmpty == true)
                            Text('${field['label']}: ${field['value'] ?? ''}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF334155))),
                      ],
                    ),
                  ),
                if ((_show('showShippingSection', fallback: false) || (template?.showShipping ?? false)) && _shippingLines().isNotEmpty) ...[
                  if (showBillTo) const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _label('customShipToLabel', 'SHIPPING DETAILS'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: templateColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          for (final line in _shippingLines())
                            Text(line, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
          ],

          // LINE ITEMS TABLE
          LineItemsTable(
            invoice: invoice,
            localSettings: localSettings,
            template: template,
            headerColor: templateColor,
          ),

          const SizedBox(height: 18),

          // TOTALS SECTION
          Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                children: [
                  PreviewTotalLine(
                    label: _label('customSubtotalLabel', 'Subtotal'),
                    value: formatMoney(invoice.subtotal, invoice.currencySymbol),
                  ),
                  if (invoice.totalDiscount > 0 && _show('showDiscount', fallback: true))
                    PreviewTotalLine(
                      label: _label('customDiscountLabel', 'Discount'),
                      value: '−${formatMoney(invoice.totalDiscount, invoice.currencySymbol)}',
                    ),
                  if (template?.showTaxBreakdown != false && _show('showTax', fallback: true))
                    PreviewTotalLine(
                      label: _label('customTaxLabel', '${invoice.taxLabel} (${invoice.taxRate}%)'),
                      value: formatMoney(invoice.taxAmount, invoice.currencySymbol),
                    ),
                  if (invoice.shippingFee > 0 || _show('showShippingFee', fallback: false))
                    PreviewTotalLine(
                      label: _label('customShippingLabel', 'Shipping'),
                      value: formatMoney(invoice.shippingFee, invoice.currencySymbol),
                    ),
                  if (invoice.additionalCharges > 0 || _show('showAdditionalCharges', fallback: false))
                    PreviewTotalLine(
                      label: _label('customAdjustmentsLabel', 'Additional charges'),
                      value: formatMoney(invoice.additionalCharges, invoice.currencySymbol),
                    ),
                  if (invoice.roundOff != 0 || _show('showRoundOff', fallback: false))
                    PreviewTotalLine(
                      label: _label('customRoundOffLabel', 'Round off'),
                      value: formatMoney(invoice.roundOff, invoice.currencySymbol),
                    ),
                  for (final adj in customAdjustments)
                    if (adj['isVisible'] != false && adj['label']?.toString().isNotEmpty == true)
                      PreviewTotalLine(
                        label: adj['label'] as String,
                        value: adj['value'] != null && adj['value'].toString().isNotEmpty
                            ? '${invoice.currencySymbol}${adj['value']}'
                            : '−',
                      ),
                  const Divider(thickness: 1.5),
                  PreviewTotalLine(
                    label: _label('customTotalLabel', 'Total'),
                    value: formatMoney(invoice.total, invoice.currencySymbol),
                    bold: true,
                    fontSize: 16,
                  ),
                  if (_show('showAmountPaid', fallback: true))
                    PreviewTotalLine(
                      label: _label('customAmountPaidLabel', 'Amount paid'),
                      value: formatMoney(invoice.amountPaid, invoice.currencySymbol),
                    ),
                  if (_show('showBalanceDue', fallback: true))
                    PreviewTotalLine(
                      label: _label('customBalanceDueLabel', 'Balance due'),
                      value: formatMoney(invoice.balanceDue, invoice.currencySymbol),
                      bold: true,
                      color: const Color(0xFFDC2626),
                      fontSize: 16,
                    ),
                ],
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // ROW: BANK & PAYMENT DETAILS + QR CODE (LEFT) & SIGNATURE / STAMP (RIGHT)
          // -------------------------------------------------------------------
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT HALF: BANK & PAYMENT DETAILS WITH QR CODE (SCAN TO PAY)
              Expanded(
                flex: 6,
                child: (showBank &&
                        (bankName.isNotEmpty ||
                            accountNumber.isNotEmpty ||
                            upiId.isNotEmpty ||
                            paymentLink.isNotEmpty))
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Bank Details Text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.account_balance_rounded,
                                        size: 15,
                                        color: templateColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'BANK & PAYMENT DETAILS',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: templateColor,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (bankName.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 3),
                                      child: Text(
                                        'Bank: $bankName',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                  if (accountHolder.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 3),
                                      child: Text(
                                        'A/C Name: $accountHolder',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                  if (accountNumber.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 3),
                                      child: Text(
                                        'A/C No: $accountNumber',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                  if (ifscCode.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 3),
                                      child: Text(
                                        'IFSC / SWIFT: $ifscCode',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                    ),
                                  if (upiId.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 3),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDCFCE7),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'UPI: $upiId',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF166534),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (paymentLink.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Pay Link: $paymentLink',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: Color(0xFF2563EB),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // QR Code with Scan to Pay badge (Optional: only if upiId or paymentLink is provided)
                            if ((template?.showQrCode ?? true) &&
                                (localSettings['showQrCode'] != false) &&
                                (upiId.isNotEmpty || paymentLink.isNotEmpty)) ...[
                              const SizedBox(width: 10),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InvoiceQrCodeWidget(
                                    data: upiId.isNotEmpty
                                        ? 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(bizName.isNotEmpty ? bizName : "Merchant")}&am=${(invoice.balanceDue > 0 ? invoice.balanceDue : invoice.total).toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent("Invoice ${invoice.invoiceNumber}")}'
                                        : paymentLink,
                                    size: 92,
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: const Text(
                                      'SCAN TO PAY',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(width: 20),

              // RIGHT HALF: SIGNATURE & STAMP SECTION (Ample Space for Sign/Stamp)
              Expanded(
                flex: 5,
                child: ((_show('showSignature') && (template?.showSignature ?? true)) || _show('showStamp'))
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (bizName.isNotEmpty)
                            Text(
                              'For $bizName',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                              textAlign: TextAlign.end,
                            ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (stampImage != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: stampImage,
                                ),
                              InkWell(
                                onTap: onSignTap,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 165,
                                  constraints: const BoxConstraints(minHeight: 75),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: signatureImage != null
                                          ? Colors.transparent
                                          : const Color(0xFF93C5FD).withAlpha(120),
                                      style: signatureImage != null
                                          ? BorderStyle.none
                                          : BorderStyle.solid,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    color: signatureImage == null
                                        ? const Color(0xFFF8FAFC)
                                        : Colors.transparent,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (signatureImage != null) ...[
                                        signatureImage,
                                        const SizedBox(height: 4),
                                      ] else ...[
                                        const SizedBox(height: 10),
                                        const Icon(
                                          Icons.draw_rounded,
                                          size: 28,
                                          color: Color(0xFF2563EB),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'Tap to Sign',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF2563EB),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                      Container(
                                        width: 145,
                                        height: 1,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            signeeTitle,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                            textAlign: TextAlign.end,
                          ),
                          if (signeeName.isNotEmpty)
                            Text(
                              signeeName,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF64748B),
                              ),
                              textAlign: TextAlign.end,
                            ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),

          // -------------------------------------------------------------------
          // FULL WIDTH (TOTAL DOWN): NOTES, TERMS & CONDITIONS, PAYMENT INSTRUCTIONS
          // -------------------------------------------------------------------
          if ((_show('showNotes') && (template?.showNotes ?? true) && invoice.notes.isNotEmpty) ||
              (_show('showTerms') && (template?.showTerms ?? true) && invoice.terms.isNotEmpty) ||
              (_show('showPaymentInstructions') &&
                  (template?.showPaymentInstructions ?? true) &&
                  invoice.paymentInstructions.isNotEmpty) ||
              customFooter.any((f) => f['isVisible'] != false)) ...[
            const Divider(height: 32),
            if (_show('showNotes') && (template?.showNotes ?? true) && invoice.notes.isNotEmpty) ...[
              Text(
                notesLabel.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: templateColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                invoice.notes,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 10),
            ],
            if (_show('showTerms') && (template?.showTerms ?? true) && invoice.terms.isNotEmpty) ...[
              Text(
                termsLabel.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: templateColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                invoice.terms,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 10),
            ],
            if (_show('showPaymentInstructions') &&
                (template?.showPaymentInstructions ?? true) &&
                invoice.paymentInstructions.isNotEmpty) ...[
              Text(
                _label('customPaymentInstructionsLabel', 'PAYMENT INSTRUCTIONS'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: templateColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                invoice.paymentInstructions,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
              ),
            ],
            for (final foot in customFooter)
              if (foot['isVisible'] != false && foot['label']?.toString().isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  foot['label'].toString().toUpperCase(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: templateColor),
                ),
                if (foot['value']?.toString().isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(foot['value'].toString(), style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569))),
                ],
              ],
          ],
          if (template?.footer.isNotEmpty == true) ...[
            const SizedBox(height: 20),
            Center(
              child: Text(
                template!.footer,
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
