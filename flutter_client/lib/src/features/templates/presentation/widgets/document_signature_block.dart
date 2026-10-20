import 'dart:convert';
import 'package:flutter/material.dart';

/// Reusable invisible Document Signature & Stamp section widget for invoices,
/// templates studio preview, and A4 paper render.
///
/// Features:
/// - Seamless "invisible" container that blends naturally into document paper
/// - Centers or right-aligns without RenderFlex overflow
/// - Full captured stamp and signature rendered side-by-side or auto-wrapping cleanly
/// - Full signer name (bold) + designation title + company legal heading
/// - Tap-to-sign interactive support for digital capture
class DocumentSignatureBlock extends StatelessWidget {
  const DocumentSignatureBlock({
    super.key,
    required this.companyLegalName,
    this.stampBase64,
    this.signatureBase64,
    this.signeeName,
    this.signeeTitle = 'Authorized Signatory',
    this.isAutoStampDisclaimer = false,
    this.fontScale = 1.0,
    this.fontFamily = 'Inter',
    this.isColorless = false,
    this.showCompanyHeading = true,
    this.onSignTap,
    this.alignment = CrossAxisAlignment.end,
  });

  final String companyLegalName;
  final String? stampBase64;
  final String? signatureBase64;
  final String? signeeName;
  final String signeeTitle;
  final bool isAutoStampDisclaimer;
  final double fontScale;
  final String fontFamily;
  final bool isColorless;
  final bool showCompanyHeading;
  final VoidCallback? onSignTap;
  final CrossAxisAlignment alignment;

  TextStyle _docStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color color = const Color(0xFF1E293B),
    FontStyle fontStyle = FontStyle.normal,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize * fontScale,
      fontWeight: fontWeight,
      color: color,
      fontStyle: fontStyle,
    );
  }

  Widget _safeBase64Image(
    String encoded, {
    double? width,
    double? height,
  }) {
    try {
      final clean = _stripDataPrefix(encoded);
      if (clean == null || clean.isEmpty) return const SizedBox.shrink();
      return Image.memory(
        base64Decode(clean),
        width: width,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  static String? _stripDataPrefix(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim();
    if (trimmed.startsWith('data:')) {
      final idx = trimmed.indexOf(',');
      if (idx != -1) return trimmed.substring(idx + 1);
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final hasStamp = stampBase64 != null && stampBase64!.trim().isNotEmpty;
    final hasSig = signatureBase64 != null && signatureBase64!.trim().isNotEmpty;
    final cleanSignerName = signeeName?.trim();
    final cleanTitle = signeeTitle.trim().isNotEmpty ? signeeTitle.trim() : 'Authorized Signatory';
    final effectiveCompany = companyLegalName.trim().isNotEmpty
        ? companyLegalName.trim()
        : 'Authorized Signatory Company';

    final textAlignment = alignment == CrossAxisAlignment.center
        ? TextAlign.center
        : (alignment == CrossAxisAlignment.start ? TextAlign.left : TextAlign.right);

    final wrapAlignment = alignment == CrossAxisAlignment.center
        ? WrapAlignment.center
        : (alignment == CrossAxisAlignment.start ? WrapAlignment.start : WrapAlignment.end);

    return Container(
      // Invisible section: transparent, non-intrusive container
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: alignment,
        children: [
          // 1. Company Legal Heading
          if (showCompanyHeading) ...[
            Text(
              'For $effectiveCompany',
              textAlign: textAlignment,
              style: _docStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: isColorless ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 6 * fontScale),
          ],

          // 2. Stamp & Signature Inks (Flexible Wrap to prevent ANY RenderFlex overflow)
          InkWell(
            onTap: onSignTap,
            borderRadius: BorderRadius.circular(6),
            child: Wrap(
              alignment: wrapAlignment,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 8 * fontScale,
              runSpacing: 6 * fontScale,
              children: [
                // Stamp
                if (hasStamp)
                  Container(
                    width: 60 * fontScale,
                    height: 60 * fontScale,
                    alignment: Alignment.center,
                    child: _safeBase64Image(
                      stampBase64!,
                      width: 60 * fontScale,
                      height: 60 * fontScale,
                    ),
                  ),

                // Signature
                if (hasSig)
                  Container(
                    height: 48 * fontScale,
                    constraints: BoxConstraints(
                      maxWidth: 160 * fontScale,
                      minWidth: 80 * fontScale,
                    ),
                    alignment: alignment == CrossAxisAlignment.center
                        ? Alignment.center
                        : Alignment.bottomRight,
                    child: _safeBase64Image(
                      signatureBase64!,
                      height: 48 * fontScale,
                    ),
                  )
                else if (onSignTap != null)
                  Container(
                    height: 30 * fontScale,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isColorless ? const Color(0xFF94A3B8) : const Color(0xFF93C5FD),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.draw_rounded,
                          size: 13 * fontScale,
                          color: isColorless ? const Color(0xFF0F172A) : const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tap to Sign',
                          style: _docStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                            color: isColorless ? const Color(0xFF0F172A) : const Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    height: 34 * fontScale,
                    width: 110 * fontScale,
                  ),
              ],
            ),
          ),

          SizedBox(height: 4 * fontScale),

          // 3. Crisp Signature Divider Line
          Container(
            width: 140 * fontScale,
            height: 1.2,
            color: isColorless ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
          ),

          SizedBox(height: 4 * fontScale),

          // 4. Full Captured Signatory Name (Bold)
          if (cleanSignerName != null && cleanSignerName.isNotEmpty) ...[
            Text(
              cleanSignerName,
              textAlign: textAlignment,
              style: _docStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: isColorless ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 1),
          ],

          // 5. Signatory Designation / Title
          Text(
            cleanTitle,
            textAlign: textAlignment,
            style: _docStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),

          // 6. System Generated Disclaimer (if enabled)
          if (isAutoStampDisclaimer) ...[
            const SizedBox(height: 2),
            Text(
              '(This is a system generated invoice)',
              textAlign: textAlignment,
              style: _docStyle(
                fontSize: 7.5,
                color: const Color(0xFF94A3B8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
