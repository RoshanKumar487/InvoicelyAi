import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/signature_pad_dialog.dart';

class InvoiceSettingsBrandTermsTab extends StatefulWidget {
  const InvoiceSettingsBrandTermsTab({
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

  @override
  State<InvoiceSettingsBrandTermsTab> createState() =>
      _InvoiceSettingsBrandTermsTabState();
}

class _InvoiceSettingsBrandTermsTabState
    extends State<InvoiceSettingsBrandTermsTab> {
  final _picker = ImagePicker();

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

  Image? _getBrandImage(String key, {double height = 50}) {
    final encoded = widget.localSettings[key]?.toString() ?? '';
    if (encoded.isEmpty) return null;
    try {
      return Image.memory(
        base64Decode(encoded),
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickImageFor(String settingKey, ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, maxWidth: 800);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          widget.localSettings[settingKey] = base64Encode(bytes);
        });
        widget.onChanged();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load image: $e')),
        );
      }
    }
  }

  Future<void> _openDocuHubSigner() async {
    final result = await SignaturePadDialog.show(
      context,
      initialSigneeName: widget.localSettings['signeeName']?.toString() ??
          widget.profile['signeeName']?.toString(),
      initialSigneeTitle: widget.localSettings['signeeTitle']?.toString() ??
          widget.profile['signeeTitle']?.toString(),
    );
    if (result == null) return;
    if (mounted) {
      setState(() {
        widget.localSettings['invoiceSignature'] = result.base64Png;
        widget.localSettings['showSignature'] = true;
        if (result.signeeName != null) {
          widget.localSettings['signeeName'] = result.signeeName;
          widget.profile['signeeName'] = result.signeeName;
        }
        if (result.signeeTitle != null) {
          widget.localSettings['signeeTitle'] = result.signeeTitle;
          widget.profile['signeeTitle'] = result.signeeTitle;
        }
      });
      widget.onChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signature captured via DocuHub Studio! Tap Save to apply.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoBanner(
          'Branding, Digital Signatures & Terms',
          'Upload your company logo (enabled by default), capture your digital signature via DocuHub, and customize footer terms and bank payment instructions.',
        ),
        const SizedBox(height: 14),

        // LOGO CARD
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Company Logo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Switch(
                    value: widget.localSettings['showLogo'] != false,
                    onChanged: (val) {
                      setState(() => widget.localSettings['showLogo'] = val);
                      widget.onChanged();
                    },
                  ),
                ],
              ),
              const Text(
                'Displayed at the top of all templates (Enabled by default)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 100,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _getBrandImage('invoiceLogo', height: 60) ??
                        const Center(
                          child: Icon(Icons.business_outlined, color: Colors.grey, size: 32),
                        ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _pickImageFor('invoiceLogo', ImageSource.gallery),
                              icon: const Icon(Icons.photo_library, size: 16),
                              label: const Text('Gallery'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _pickImageFor('invoiceLogo', ImageSource.camera),
                              icon: const Icon(Icons.camera_alt, size: 16),
                              label: const Text('Camera'),
                            ),
                          ],
                        ),
                        if (widget.localSettings['invoiceLogo'] != null)
                          TextButton.icon(
                            onPressed: () {
                              setState(() => widget.localSettings.remove('invoiceLogo'));
                              widget.onChanged();
                            },
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                            label: const Text('Remove Logo', style: TextStyle(color: Colors.red)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // DOCUHUB SIGNATURE CARD
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DocuHub Digital Signature',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Switch(
                    value: widget.localSettings['showSignature'] != false,
                    onChanged: (val) {
                      setState(() => widget.localSettings['showSignature'] = val);
                      widget.onChanged();
                    },
                  ),
                ],
              ),
              const Text(
                'Draw with smooth Bezier ink, type in cursive, or photograph ink on paper',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 130,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _getBrandImage('invoiceSignature', height: 60) ??
                        const Center(
                          child: Icon(Icons.draw_outlined, color: Colors.grey, size: 30),
                        ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _openDocuHubSigner,
                          icon: const Icon(Icons.edit_note, size: 18),
                          label: Text(
                            widget.localSettings['invoiceSignature'] != null
                                ? 'Edit Signature'
                                : 'Capture Signature',
                          ),
                        ),
                        if (widget.localSettings['invoiceSignature'] != null)
                          TextButton.icon(
                            onPressed: () {
                              setState(() => widget.localSettings.remove('invoiceSignature'));
                              widget.onChanged();
                            },
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                            label: const Text('Remove', style: TextStyle(color: Colors.red)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: widget.localSettings['signeeTitle']?.toString() ??
                          widget.profile['signeeTitle']?.toString() ??
                          'Authorized Signatory',
                      decoration: const InputDecoration(
                        labelText: 'Signatory Title',
                        isDense: true,
                        hintText: 'e.g. Managing Director, Founder',
                      ),
                      onChanged: (val) {
                        widget.localSettings['signeeTitle'] = val;
                        widget.profile['signeeTitle'] = val;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      initialValue: widget.localSettings['signeeName']?.toString() ??
                          widget.profile['signeeName']?.toString() ??
                          '',
                      decoration: const InputDecoration(
                        labelText: 'Signatory Name',
                        isDense: true,
                        hintText: 'e.g. John Doe',
                      ),
                      onChanged: (val) {
                        widget.localSettings['signeeName'] = val;
                        widget.profile['signeeName'] = val;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // DIGITAL STAMP CARD
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Digital Rubber Stamp / Seal',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              const Text(
                'Upload your circular or rectangular official company seal to overlay next to signature',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 90,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _getBrandImage('invoiceStamp', height: 60) ??
                        const Center(
                          child: Icon(Icons.verified_outlined, color: Colors.grey, size: 30),
                        ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _pickImageFor('invoiceStamp', ImageSource.gallery),
                              icon: const Icon(Icons.photo_library, size: 16),
                              label: const Text('Gallery'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _pickImageFor('invoiceStamp', ImageSource.camera),
                              icon: const Icon(Icons.camera_alt, size: 16),
                              label: const Text('Camera'),
                            ),
                          ],
                        ),
                        if (widget.localSettings['invoiceStamp'] != null)
                          TextButton.icon(
                            onPressed: () {
                              setState(() => widget.localSettings.remove('invoiceStamp'));
                              widget.onChanged();
                            },
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                            label: const Text('Remove Stamp', style: TextStyle(color: Colors.red)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // DEFAULT INVOICE CONTENT
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.feed_outlined, color: Color(0xFF2563EB), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Default Invoice Content & Defaults',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'These texts are automatically pre-filled into all new invoices, saving you repetitive typing:',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: widget.profile['defaultNotes']?.toString() ??
                    widget.localSettings['defaultNotes']?.toString() ??
                    '',
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Default Notes & Remarks',
                  hintText:
                      'e.g. Thank you for your business. Security attendance verified by site supervisor.',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_rounded, size: 18),
                ),
                onChanged: (val) {
                  widget.profile['defaultNotes'] = val;
                  widget.localSettings['defaultNotes'] = val;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: widget.profile['defaultTerms']?.toString() ??
                    widget.localSettings['defaultTerms']?.toString() ??
                    '',
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Default Terms & Conditions',
                  hintText:
                      'e.g. Payment due within 15 days of bill submission. Interest @ 18% p.a. on overdue bills.',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.gavel_rounded, size: 18),
                ),
                onChanged: (val) {
                  widget.profile['defaultTerms'] = val;
                  widget.localSettings['defaultTerms'] = val;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: widget.localSettings['defaultPaymentInstructions']?.toString() ?? '',
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Default Payment Instructions',
                  hintText:
                      'e.g. Please mention Invoice # in NEFT narration. Cheques payable to Acme Security.',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.payments_outlined, size: 18),
                ),
                onChanged: (val) {
                  widget.localSettings['defaultPaymentInstructions'] = val;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: widget.localSettings['defaultShippingDetails']?.toString() ?? '',
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Default Delivery / Shipping Notes',
                  hintText:
                      'e.g. Dispatch via Blue Dart / Safe Express. Contact warehouse manager at +91 98765 43210.',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.local_shipping_outlined, size: 18),
                ),
                onChanged: (val) {
                  widget.localSettings['defaultShippingDetails'] = val;
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: widget.onSave,
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
