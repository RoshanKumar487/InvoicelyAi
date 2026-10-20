import 'dart:convert';
import 'package:flutter/material.dart';

/// Unified Studio Stamp & Signature Card for configuring official company seal,
/// authorized DocuHub digital signature, and legal signer identity metadata in one place.
class StudioStampSignatureCard extends StatelessWidget {
  const StudioStampSignatureCard({
    super.key,
    required this.stampBase64,
    required this.signatureBase64,
    required this.signeeName,
    required this.signeeTitle,
    required this.companyLegalName,
    required this.onPickStamp,
    required this.onRemoveStamp,
    required this.onCaptureSignature,
    required this.onRemoveSignature,
    required this.onSigneeNameChanged,
    required this.onSigneeTitleChanged,
    this.isColorless = false,
  });

  final String? stampBase64;
  final String? signatureBase64;
  final String? signeeName;
  final String? signeeTitle;
  final String companyLegalName;
  final VoidCallback onPickStamp;
  final VoidCallback onRemoveStamp;
  final VoidCallback onCaptureSignature;
  final VoidCallback onRemoveSignature;
  final ValueChanged<String> onSigneeNameChanged;
  final ValueChanged<String> onSigneeTitleChanged;
  final bool isColorless;

  static String? _stripDataPrefix(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim();
    if (trimmed.startsWith('data:')) {
      final idx = trimmed.indexOf(',');
      if (idx != -1) return trimmed.substring(idx + 1);
    }
    return trimmed;
  }

  Widget _safeBase64Image(String encoded, {double? width, double? height}) {
    try {
      final clean = _stripDataPrefix(encoded);
      if (clean == null || clean.isEmpty) return const SizedBox.shrink();
      return Image.memory(
        base64Decode(clean),
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 460;
        final hasStamp = stampBase64 != null && stampBase64!.trim().isNotEmpty;
        final hasSig = signatureBase64 != null && signatureBase64!.trim().isNotEmpty;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      color: Color(0xFF2563EB),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Official Stamp & Authorized Digital Signature',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Combine rubber seal and legal signatory into one unified verification block.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Text(
                      'Legal Block',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 1. Official Company Stamp Block
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hasStamp ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
                          width: hasStamp ? 1.5 : 1.0,
                        ),
                      ),
                      child: hasStamp
                          ? ClipOval(
                              child: _safeBase64Image(stampBase64!, width: 50, height: 50),
                            )
                          : const Icon(Icons.verified_outlined, color: Color(0xFF94A3B8), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Official Rubber Stamp / Seal',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            hasStamp
                                ? '✓ Seal uploaded & active on invoices'
                                : 'Upload transparent PNG seal (round or rectangular)',
                            style: TextStyle(
                              fontSize: 11,
                              color: hasStamp ? const Color(0xFF059669) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (hasStamp) ...[
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                        tooltip: 'Remove Stamp',
                        onPressed: onRemoveStamp,
                      ),
                      OutlinedButton(
                        onPressed: onPickStamp,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Replace', style: TextStyle(fontSize: 11)),
                      ),
                    ] else ...[
                      FilledButton.icon(
                        icon: const Icon(Icons.upload_file_outlined, size: 14),
                        label: const Text('Upload Stamp', style: TextStyle(fontSize: 11)),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: onPickStamp,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 2. Authorized Signature Block (DocuHub Signer)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 130,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: hasSig ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: hasSig
                              ? Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: _safeBase64Image(signatureBase64!, height: 40),
                                )
                              : const Text(
                                  'No Signature',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF94A3B8),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Authorized Signatory Ink (DocuHub)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                hasSig
                                    ? '✓ Signature captured & active'
                                    : 'Draw ink signature or create styled typography',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: hasSig ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (hasSig) ...[
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                            tooltip: 'Clear Signature',
                            onPressed: onRemoveSignature,
                          ),
                          OutlinedButton(
                            onPressed: onCaptureSignature,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Redraw', style: TextStyle(fontSize: 11)),
                          ),
                        ] else ...[
                          FilledButton.icon(
                            icon: const Icon(Icons.draw_outlined, size: 14),
                            label: const Text('Capture Sign', style: TextStyle(fontSize: 11)),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: onCaptureSignature,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 3. Legal Signer Identity Fields (Signatory Name & Designation Title)
              if (isNarrow) ...[
                TextFormField(
                  initialValue: signeeName ?? '',
                  decoration: InputDecoration(
                    labelText: 'Signatory Full Name',
                    hintText: 'e.g. Rajesh K. Sharma',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  onChanged: onSigneeNameChanged,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: signeeTitle ?? 'Authorized Signatory',
                  decoration: InputDecoration(
                    labelText: 'Signatory Title / Designation',
                    hintText: 'e.g. Director / Authorized Signatory',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  onChanged: onSigneeTitleChanged,
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: signeeName ?? '',
                        decoration: InputDecoration(
                          labelText: 'Signatory Full Name',
                          hintText: 'e.g. Rajesh K. Sharma',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        onChanged: onSigneeNameChanged,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: signeeTitle ?? 'Authorized Signatory',
                        decoration: InputDecoration(
                          labelText: 'Signatory Title / Designation',
                          hintText: 'e.g. Director / Authorized Signatory',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        onChanged: onSigneeTitleChanged,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
