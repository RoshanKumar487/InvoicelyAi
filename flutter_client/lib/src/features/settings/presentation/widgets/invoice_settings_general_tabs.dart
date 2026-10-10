import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_card.dart';

Widget buildSettingsInfoBanner(String title, String subtitle) {
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

Widget buildSettingsPresetsCard(BuildContext context, ValueChanged<String> onApplyPreset) {
  return AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('1-Click Industry Presets', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        const Text(
          'Instantly populate standard labels & columns for your trade',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.receipt_long, size: 16),
              label: const Text('Indian GST Bill'),
              onPressed: () => onApplyPreset('gst'),
            ),
            ActionChip(
              avatar: const Icon(Icons.code, size: 16),
              label: const Text('IT & Consulting'),
              onPressed: () => onApplyPreset('it'),
            ),
            ActionChip(
              avatar: const Icon(Icons.storefront, size: 16),
              label: const Text('Retail Store'),
              onPressed: () => onApplyPreset('retail'),
            ),
            ActionChip(
              avatar: const Icon(Icons.local_shipping, size: 16),
              label: const Text('Wholesale & Logistics'),
              onPressed: () => onApplyPreset('wholesale'),
            ),
            ActionChip(
              avatar: const Icon(Icons.palette, size: 16),
              label: const Text('Freelancer / Creative'),
              onPressed: () => onApplyPreset('freelance'),
            ),
          ],
        ),
      ],
    ),
  );
}

class InvoiceSettingsDetailsTab extends StatelessWidget {
  const InvoiceSettingsDetailsTab({
    super.key,
    required this.fieldTileBuilder,
    required this.customFieldsCardBuilder,
    required this.onApplyPreset,
    required this.onSave,
  });

  final Widget Function({
    required String title,
    required String description,
    required String toggleKey,
    required bool defaultToggle,
    required String labelKey,
    required String fallbackLabel,
    required String hint,
  }) fieldTileBuilder;
  final Widget Function({
    required String key,
    required String title,
    required String itemType,
    required String hintText,
  }) customFieldsCardBuilder;
  final ValueChanged<String> onApplyPreset;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        buildSettingsInfoBanner(
          'Invoice Details Section',
          'Configure document title, invoice number, creation dates, and add custom metadata like Order ID or Project Code.',
        ),
        const SizedBox(height: 12),

        buildSettingsPresetsCard(context, onApplyPreset),
        const SizedBox(height: 14),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Document Style & Core Fields',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'By default, only Invoice Number, Creation Date, and Invoice Style are shown on your invoice.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),

              fieldTileBuilder(
                title: 'Invoice Style / Title',
                description: 'Main letterhead document title',
                toggleKey: 'showDocumentTitle',
                defaultToggle: true,
                labelKey: 'customTitle',
                fallbackLabel: 'Tax Invoice',
                hint: 'e.g. Tax Invoice, Bill of Supply',
              ),
              const Divider(height: 24),

              fieldTileBuilder(
                title: 'Invoice Number',
                description: 'Unique invoice identifier',
                toggleKey: 'showInvoiceNumber',
                defaultToggle: true,
                labelKey: 'customInvoiceNoLabel',
                fallbackLabel: 'Invoice #',
                hint: 'e.g. Bill No., Ref #',
              ),
              const Divider(height: 24),

              fieldTileBuilder(
                title: 'Creation Date (Issue Date)',
                description: 'Date invoice was created',
                toggleKey: 'showIssueDate',
                defaultToggle: true,
                labelKey: 'customDateLabel',
                fallbackLabel: 'Creation Date',
                hint: 'e.g. Invoice Date, Date',
              ),
              const Divider(height: 24),

              fieldTileBuilder(
                title: 'Due Date',
                description: 'Payment due deadline (Default: Hidden)',
                toggleKey: 'showDueDate',
                defaultToggle: false,
                labelKey: 'customDueDateLabel',
                fallbackLabel: 'Due Date',
                hint: 'e.g. Payment Due',
              ),
              const Divider(height: 24),

              fieldTileBuilder(
                title: 'Purchase Order (PO) Number',
                description: 'Client purchase order reference (Default: Hidden)',
                toggleKey: 'showPoNumber',
                defaultToggle: false,
                labelKey: 'customPoLabel',
                fallbackLabel: 'PO Number',
                hint: 'e.g. Customer PO #',
              ),
              const Divider(height: 24),

              fieldTileBuilder(
                title: 'Payment Terms',
                description: 'e.g. Net 30, Due on Receipt (Default: Hidden)',
                toggleKey: 'showPaymentTerms',
                defaultToggle: false,
                labelKey: 'customTermsLabel',
                fallbackLabel: 'Payment Terms',
                hint: 'e.g. Terms',
              ),
              const Divider(height: 24),

              fieldTileBuilder(
                title: 'Invoice Status Badge',
                description: 'Paid, Sent, Draft pill (Default: Hidden)',
                toggleKey: 'showStatus',
                defaultToggle: false,
                labelKey: 'customStatusLabel',
                fallbackLabel: 'Status',
                hint: 'e.g. State',
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        customFieldsCardBuilder(
          key: 'customFields_details',
          title: 'Invoice Details',
          itemType: 'Field',
          hintText: 'e.g. Order ID, Project Name, Delivery Challan #, Sales Rep',
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

class InvoiceSettingsBillingTab extends StatelessWidget {
  const InvoiceSettingsBillingTab({
    super.key,
    required this.fieldTileBuilder,
    required this.customFieldsCardBuilder,
    required this.onSave,
  });

  final Widget Function({
    required String title,
    required String description,
    required String toggleKey,
    required bool defaultToggle,
    required String labelKey,
    required String fallbackLabel,
    required String hint,
  }) fieldTileBuilder;
  final Widget Function({
    required String key,
    required String title,
    required String itemType,
    required String hintText,
  }) customFieldsCardBuilder;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        buildSettingsInfoBanner(
          'Bills & Client Section',
          'Rename billing headers, toggle client details, shipping sections, and add custom fields like PAN Number or Place of Supply.',
        ),
        const SizedBox(height: 14),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Billing & Shipping Section Labels',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),

              fieldTileBuilder(
                title: 'Bill To Section Header',
                description: 'Section heading above customer address',
                toggleKey: 'showBillToSection',
                defaultToggle: true,
                labelKey: 'customBillToLabel',
                fallbackLabel: 'BILL TO',
                hint: 'e.g. Invoiced To, Customer Details',
              ),
              const Divider(height: 24),

              fieldTileBuilder(
                title: 'Ship To / Delivery Section',
                description: 'Separate shipping recipient details (Default: Hidden)',
                toggleKey: 'showShippingSection',
                defaultToggle: false,
                labelKey: 'customShipToLabel',
                fallbackLabel: 'SHIPPING DETAILS',
                hint: 'e.g. Shipped To, Delivery Address',
              ),
              const Divider(height: 24),

              fieldTileBuilder(
                title: 'Client / Customer Name',
                description: 'Primary customer name line',
                toggleKey: 'showClientName',
                defaultToggle: true,
                labelKey: 'customClientNameLabel',
                fallbackLabel: 'Client Name',
                hint: 'e.g. Customer Name, M/s',
              ),
              const Divider(height: 24),

              fieldTileBuilder(
                title: 'Company Name',
                description: 'Customer company or legal entity',
                toggleKey: 'showClientCompany',
                defaultToggle: true,
                labelKey: 'customClientCompanyLabel',
                fallbackLabel: 'Company Name',
                hint: 'e.g. Business Name',
              ),
              const Divider(height: 24),

              fieldTileBuilder(
                title: 'Email Address',
                description: 'Billing email line',
                toggleKey: 'showClientEmail',
                defaultToggle: true,
                labelKey: 'customClientEmailLabel',
                fallbackLabel: 'Email',
                hint: 'e.g. Billing Email',
              ),
              const Divider(height: 24),

              fieldTileBuilder(
                title: 'Phone Number',
                description: 'Contact phone line',
                toggleKey: 'showClientPhone',
                defaultToggle: true,
                labelKey: 'customClientPhoneLabel',
                fallbackLabel: 'Phone',
                hint: 'e.g. Mobile, Contact',
              ),
              const Divider(height: 24),

              fieldTileBuilder(
                title: 'Billing Address',
                description: 'Street, city, postal code',
                toggleKey: 'showClientAddress',
                defaultToggle: true,
                labelKey: 'customClientAddressLabel',
                fallbackLabel: 'Billing Address',
                hint: 'e.g. Address',
              ),
              const Divider(height: 24),

              fieldTileBuilder(
                title: 'Tax ID / GSTIN',
                description: 'Customer tax registration',
                toggleKey: 'showClientTaxId',
                defaultToggle: true,
                labelKey: 'customClientTaxIdLabel',
                fallbackLabel: 'GSTIN / Tax ID',
                hint: 'e.g. GSTIN, VAT No., Tax ID',
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        customFieldsCardBuilder(
          key: 'customFields_billing',
          title: 'Bills & Client',
          itemType: 'Field',
          hintText: 'e.g. PAN Number, Place of Supply, Customer Code, State Code',
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

class InvoiceSettingsAdjustmentsTab extends StatelessWidget {
  const InvoiceSettingsAdjustmentsTab({
    super.key,
    required this.fieldTileBuilder,
    required this.customFieldsCardBuilder,
    required this.onSave,
  });

  final Widget Function({
    required String title,
    required String description,
    required String toggleKey,
    required bool defaultToggle,
    required String labelKey,
    required String fallbackLabel,
    required String hint,
  }) fieldTileBuilder;
  final Widget Function({
    required String key,
    required String title,
    required String itemType,
    required String hintText,
  }) customFieldsCardBuilder;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        buildSettingsInfoBanner(
          'Invoice Adjustments & Summary Totals',
          'Rename calculation rows, show/hide discounts, shipping fees, round offs, and add custom adjustment charges like Packaging & Handling.',
        ),
        const SizedBox(height: 14),

        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Financial Summary Labels',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),

              fieldTileBuilder(
                title: 'Subtotal Row',
                description: 'Gross sum of all line items',
                toggleKey: 'showSubtotal',
                defaultToggle: true,
                labelKey: 'customSubtotalLabel',
                fallbackLabel: 'Subtotal',
                hint: 'e.g. Gross Total',
              ),
              const Divider(height: 24),

              fieldTileBuilder(
                title: 'Discount Adjustment',
                description: 'Invoice-level or item discount deduction',
                toggleKey: 'showDiscount',
                defaultToggle: true,
                labelKey: 'customDiscountLabel',
                fallbackLabel: 'Discount',
                hint: 'e.g. Special Discount, Promo',
              ),
              const Divider(height: 24),

              fieldTileBuilder(
                title: 'Tax Breakdown Row',
                description: 'Tax rate & total calculated tax',
                toggleKey: 'showTax',
                defaultToggle: true,
                labelKey: 'customTaxLabel',
                fallbackLabel: 'Tax',
                hint: 'e.g. GST, VAT, Sales Tax',
              ),
              const Divider(height: 24),

              fieldTileBuilder(
                title: 'Shipping & Delivery Fee',
                description: 'Freight / courier charge (Default: Hidden)',
                toggleKey: 'showShippingFee',
                defaultToggle: false,
                labelKey: 'customShippingLabel',
                fallbackLabel: 'Shipping',
                hint: 'e.g. Delivery & Handling, Freight',
              ),
              const Divider(height: 24),

              fieldTileBuilder(
                title: 'Additional Charges / Adjustments',
                description: 'Misc adjustments (Default: Hidden)',
                toggleKey: 'showAdditionalCharges',
                defaultToggle: false,
                labelKey: 'customAdjustmentsLabel',
                fallbackLabel: 'Adjustments',
                hint: 'e.g. Other Charges, Surcharge',
              ),
              const Divider(height: 24),

              fieldTileBuilder(
                title: 'Round Off',
                description: 'Decimal rounding adjustment (Default: Hidden)',
                toggleKey: 'showRoundOff',
                defaultToggle: false,
                labelKey: 'customRoundOffLabel',
                fallbackLabel: 'Round off',
                hint: 'e.g. Rounding (+/-)',
              ),
              const Divider(height: 24),

              fieldTileBuilder(
                title: 'Total Amount Row',
                description: 'Final payable invoice balance',
                toggleKey: 'showTotal',
                defaultToggle: true,
                labelKey: 'customTotalLabel',
                fallbackLabel: 'Total',
                hint: 'e.g. Grand Total, Invoice Total',
              ),
              const Divider(height: 24),

              fieldTileBuilder(
                title: 'Amount Paid Row',
                description: 'Advance or payments received',
                toggleKey: 'showAmountPaid',
                defaultToggle: true,
                labelKey: 'customAmountPaidLabel',
                fallbackLabel: 'Amount paid',
                hint: 'e.g. Paid, Advance Received',
              ),
              const Divider(height: 24),

              fieldTileBuilder(
                title: 'Balance Due Row',
                description: 'Remaining outstanding amount',
                toggleKey: 'showBalanceDue',
                defaultToggle: true,
                labelKey: 'customBalanceDueLabel',
                fallbackLabel: 'Balance due',
                hint: 'e.g. Net Payable, Amount Due',
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        customFieldsCardBuilder(
          key: 'customFields_adjustments',
          title: 'Invoice Adjustments',
          itemType: 'Fee / Charge',
          hintText: 'e.g. Packaging Fee, Insurance, Cess, Service Fee',
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
