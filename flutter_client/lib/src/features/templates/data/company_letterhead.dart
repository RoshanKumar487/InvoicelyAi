import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class LetterheadPreset {
  const LetterheadPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.accentColor,
    required this.secondaryColor,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String description;
  final Color accentColor;
  final Color secondaryColor;
  final bool isDefault;
}

const List<LetterheadPreset> kLetterheadPresets = [
  LetterheadPreset(
    id: 'royal_security_crest',
    name: 'Royal Sovereign Crest (Security & Corporate)',
    description:
        'Linen geometric pattern, heraldic monogram crest, antique bronze serif title, midnight navy specialist banner & metallic bronze bottom bar.',
    accentColor: Color(0xFF7C6842),
    secondaryColor: Color(0xFF1B2A4A),
    isDefault: true,
  ),
  LetterheadPreset(
    id: 'modern_ribbon',
    name: 'Modern Geometric Ribbon',
    description:
        'Logo | Company + Tagline | Contact Column | Address Column with angled blue-cyan corner ribbons & matching footer.',
    accentColor: Color(0xFF1E3A8A),
    secondaryColor: Color(0xFF06B6D4),
    isDefault: false,
  ),
  LetterheadPreset(
    id: 'executive_navy_bar',
    name: 'Executive Navy Corporate Banner',
    description:
        'Full-bleed deep navy top bar with gold/cyan accent rule, split contact blocks & official footer bar.',
    accentColor: Color(0xFF0F172A),
    secondaryColor: Color(0xFF38BDF8),
  ),
  LetterheadPreset(
    id: 'emerald_corporate',
    name: 'Emerald Shield & Crest',
    description:
        'Clean emerald & slate split header with vertical dividers, GST/CIN badges & structured footer.',
    accentColor: Color(0xFF065F46),
    secondaryColor: Color(0xFF10B981),
  ),
  LetterheadPreset(
    id: 'royal_minimal_split',
    name: 'Minimalist Split Line',
    description:
        'High-contrast white letterhead with thin precision dividers, website & social footer icons.',
    accentColor: Color(0xFF1E293B),
    secondaryColor: Color(0xFF2563EB),
  ),
  LetterheadPreset(
    id: 'tech_gradient_wave',
    name: 'Tech Electric Gradient Wave',
    description:
        'Vibrant indigo & violet flowing gradient wave, illuminated monogram badge & tech contact matrix.',
    accentColor: Color(0xFF4338CA),
    secondaryColor: Color(0xFF8B5CF6),
  ),
  LetterheadPreset(
    id: 'luxury_gold_crest',
    name: 'Prestige Onyx & Champagne Gold',
    description:
        'Luxurious obsidian dark slate background with champagne gold framing, serif crest & regal divider.',
    accentColor: Color(0xFF18181B),
    secondaryColor: Color(0xFFF59E0B),
  ),
  LetterheadPreset(
    id: 'industrial_blueprint',
    name: 'Industrial Blueprint & Technical Grid',
    description:
        'Precision steel blue blueprint grid, safety amber accent bar, ISO compliance stamp box.',
    accentColor: Color(0xFF0369A1),
    secondaryColor: Color(0xFFF97316),
  ),
  LetterheadPreset(
    id: 'crimson_chevron',
    name: 'Crimson Dynamic Chevron (Logistics)',
    description:
        'High-energy crimson red & graphite dual diagonal chevrons, speed badge & quick dispatch contacts.',
    accentColor: Color(0xFFBE123C),
    secondaryColor: Color(0xFFEF4444),
  ),
  LetterheadPreset(
    id: 'nordic_sidebar_accent',
    name: 'Nordic Clean Asymmetric Stripe',
    description:
        'Clean Scandinavian layout with a bold vertical primary color bar, airy layout & modern sans-serif typography.',
    accentColor: Color(0xFF0284C7),
    secondaryColor: Color(0xFF0EA5E9),
  ),
  LetterheadPreset(
    id: 'botanical_sage_eco',
    name: 'Botanical Sage & Forest (Eco/Wellness)',
    description:
        'Organic pine green & soft sage duo-tone header with leaf badge, sustainability footer.',
    accentColor: Color(0xFF14532D),
    secondaryColor: Color(0xFF22C55E),
  ),
  LetterheadPreset(
    id: 'monochrome_bauhaus',
    name: 'Bauhaus Modernist Monogram',
    description:
        'Swiss high-contrast black & white geometric frame with punchy typography, boxed metadata grid.',
    accentColor: Color(0xFF09090B),
    secondaryColor: Color(0xFF71717A),
  ),
  LetterheadPreset(
    id: 'classic_traditional',
    name: 'Classic Invoice Header',
    description:
        'Standard top-left company details without full-width letterhead banner.',
    accentColor: Color(0xFF334155),
    secondaryColor: Color(0xFF64748B),
  ),
];

class CompanyLetterheadConfig {
  const CompanyLetterheadConfig({
    this.enabledForAllDocuments = true,
    this.styleId = 'royal_security_crest',
    this.companyName = 'ROYAL',
    this.tagline = 'SECURITY FORCE',
    this.specialistServices =
        'SPECIALIST IN : Industrial Protective, Detective, Investigating in the Administration of all Essential Supervisors through Perfectly Trained Security Staff.',
    this.phone = '+91 8247369182, 6305422632',
    this.email = 'royalsecuritiesforce@gmail.com',
    this.website = 'www.royalsecurityforce.com',
    this.address =
        'Plot No. 43E, Sy. No. 50, Aditya Dental Hospital, Raghavendra Nagar Colony, Shivrampally, Hyderabad - 500 052. (T.S.)',
    this.gstin = '36AABCR1234F1Z9',
    this.pan = 'AABCR1234F',
    this.cinOrLicense = 'PSARA/TS/2022/451',
    this.showSocialIcons = true,
    this.logoBase64,
    this.primaryColorHex = '#7C6842',
    this.isColorless = false,
  });

  final bool enabledForAllDocuments;
  final String styleId;
  final String companyName;
  final String tagline;
  final String specialistServices;
  final String phone;
  final String email;
  final String website;
  final String address;
  final String gstin;
  final String pan;
  final String cinOrLicense;
  final bool showSocialIcons;
  final String? logoBase64;
  final String primaryColorHex;
  final bool isColorless;

  bool get isLetterheadActive =>
      enabledForAllDocuments && styleId != 'classic_traditional' && styleId != 'none';

  CompanyLetterheadConfig copyWith({
    bool? enabledForAllDocuments,
    String? styleId,
    String? companyName,
    String? tagline,
    String? specialistServices,
    String? phone,
    String? email,
    String? website,
    String? address,
    String? gstin,
    String? pan,
    String? cinOrLicense,
    bool? showSocialIcons,
    String? logoBase64,
    String? primaryColorHex,
    bool? isColorless,
  }) {
    return CompanyLetterheadConfig(
      enabledForAllDocuments: enabledForAllDocuments ?? this.enabledForAllDocuments,
      styleId: styleId ?? this.styleId,
      companyName: companyName ?? this.companyName,
      tagline: tagline ?? this.tagline,
      specialistServices: specialistServices ?? this.specialistServices,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      address: address ?? this.address,
      gstin: gstin ?? this.gstin,
      pan: pan ?? this.pan,
      cinOrLicense: cinOrLicense ?? this.cinOrLicense,
      showSocialIcons: showSocialIcons ?? this.showSocialIcons,
      logoBase64: logoBase64 ?? this.logoBase64,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      isColorless: isColorless ?? this.isColorless,
    );
  }

  factory CompanyLetterheadConfig.fromSettings({
    Map<String, Object?> localSettings = const {},
    Map<String, dynamic> profile = const {},
    String? fallbackCompanyName,
    String? fallbackAddress,
    String? fallbackPhone,
    String? fallbackEmail,
    String? fallbackWebsite,
    String? fallbackGstin,
    String? fallbackPan,
    String? fallbackCin,
    String? fallbackLogoBase64,
  }) {
    const samplePlaceholders = <String>{
      'northstar security services pvt. ltd.',
      'northstar security services ltd.',
      'apex nova dynamics',
      'apex nova dynamics llc',
      '+91 98765 43210',
      'info@northstarsecurity.in',
      'billing@northstarsecurity.in',
      'billing@apexnova.io',
      'www.northstarsecurity.in',
      '#12, 3rd floor, green park, bengaluru, karnataka - 560076',
      'plot 42, sector 18, cyber park, gurugram, haryana - 122015',
      '29abcde1234f1z5',
      '06aabcn1234f1z5',
      'abcde1234f',
      'aabcn1234f',
    };

    String pickStr(List<Object?> candidates, String fallback) {
      // First pass: prefer non-sample, real organization values
      for (final c in candidates) {
        final s = c?.toString().trim() ?? '';
        if (s.isNotEmpty &&
            s != 'null' &&
            !samplePlaceholders.contains(s.toLowerCase())) {
          return s;
        }
      }
      // Second pass: allow any non-empty candidate
      for (final c in candidates) {
        final s = c?.toString().trim() ?? '';
        if (s.isNotEmpty && s != 'null') return s;
      }
      return fallback;
    }

    final enabledRaw = localSettings['letterhead_enabled'];
    final enabled = enabledRaw == null
        ? true
        : (enabledRaw == true || enabledRaw.toString().toLowerCase() == 'true');

    final styleId = pickStr([
      localSettings['letterhead_style_id'],
      profile['letterheadStyleId'],
    ], 'royal_security_crest');

    final companyName = pickStr([
      profile['businessName'],
      profile['companyName'],
      localSettings['businessName'],
      localSettings['companyName'],
      localSettings['letterhead_company_name'],
      fallbackCompanyName,
    ], 'ROYAL');

    final tagline = pickStr([
      localSettings['letterhead_tagline'],
      profile['tagline'],
      localSettings['companyTagline'],
    ], 'SECURITY FORCE');

    final specialistServices = pickStr([
      localSettings['letterhead_specialist_services'],
      profile['specialistServices'],
      profile['specialization'],
      localSettings['companySpecialistServices'],
    ], 'SPECIALIST IN : Industrial Protective, Detective, Investigating in the Administration of all Essential Supervisors through Perfectly Trained Security Staff.');

    final phone = pickStr([
      profile['phone'],
      profile['companyPhone'],
      localSettings['businessPhone'],
      localSettings['companyPhone'],
      localSettings['letterhead_phone'],
      fallbackPhone,
    ], '+91 8247369182, 6305422632');

    final email = pickStr([
      profile['email'],
      profile['companyEmail'],
      localSettings['businessEmail'],
      localSettings['companyEmail'],
      localSettings['letterhead_email'],
      fallbackEmail,
    ], 'royalsecuritiesforce@gmail.com');

    final website = pickStr([
      profile['website'],
      localSettings['businessWebsite'],
      localSettings['companyWebsite'],
      localSettings['letterhead_website'],
      fallbackWebsite,
    ], 'www.royalsecurityforce.com');

    final address = pickStr([
      profile['address'],
      profile['companyAddress'],
      localSettings['businessAddress'],
      localSettings['companyAddress'],
      localSettings['letterhead_address'],
      fallbackAddress,
    ], 'Plot No. 43E, Sy. No. 50, Aditya Dental Hospital, Raghavendra Nagar Colony, Shivrampally, Hyderabad - 500 052. (T.S.)');

    final gstin = pickStr([
      profile['gstin'],
      profile['gstNumber'],
      localSettings['businessGstin'],
      localSettings['companyGstin'],
      localSettings['letterhead_gstin'],
      fallbackGstin,
    ], '36AABCR1234F1Z9');

    final pan = pickStr([
      profile['panNumber'],
      profile['pan'],
      localSettings['businessPan'],
      localSettings['companyPan'],
      localSettings['letterhead_pan'],
      fallbackPan,
    ], 'AABCR1234F');

    final cin = pickStr([
      localSettings['letterhead_cin'],
      profile['cin'],
      profile['taxId'],
      localSettings['companyCin'],
      fallbackCin,
    ], 'PSARA/TS/2022/451');

    final logo = pickStr([
      localSettings['invoiceLogo'],
      profile['logoUrl'],
      profile['logoBase64'],
      fallbackLogoBase64,
    ], '');

    final primaryHex = pickStr([
      localSettings['studio_primary_color'],
      localSettings['letterhead_color'],
      profile['brandColorHex'],
    ], '#7C6842');

    final isColorless = localSettings['studio_is_colorless'] == true ||
        localSettings['studio_is_colorless'] == 'true' ||
        localSettings['is_colorless'] == true ||
        localSettings['studio_color_mode'] == 'monochrome';

    return CompanyLetterheadConfig(
      enabledForAllDocuments: enabled,
      styleId: styleId,
      companyName: companyName,
      tagline: tagline,
      specialistServices: specialistServices,
      phone: phone,
      email: email,
      website: website,
      address: address,
      gstin: gstin,
      pan: pan,
      cinOrLicense: cin,
      logoBase64: logo.isNotEmpty ? logo : null,
      primaryColorHex: isColorless ? '#0F172A' : primaryHex,
      isColorless: isColorless,
    );
  }
}

class _HeraldicCrestPainter extends CustomPainter {
  const _HeraldicCrestPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..isAntiAlias = true;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final rx = size.width * 0.30;
    final ry = size.height * 0.40;

    // Outer double oval
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
      strokePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: (rx - 3) * 2, height: (ry - 3) * 2),
      strokePaint..strokeWidth = 0.8,
    );

    // Left and Right heraldic cross wings ☩
    for (final dir in [-1.0, 1.0]) {
      final wingX = cx + dir * (rx + 8);
      // horizontal arm
      canvas.drawLine(
        Offset(wingX - 4, cy),
        Offset(wingX + 4, cy),
        strokePaint..strokeWidth = 1.2,
      );
      // vertical cross arm
      canvas.drawLine(
        Offset(wingX, cy - 6),
        Offset(wingX, cy + 6),
        strokePaint..strokeWidth = 1.2,
      );
      // cross finials (small balls)
      canvas.drawCircle(Offset(wingX, cy - 6), 1.2, fillPaint);
      canvas.drawCircle(Offset(wingX, cy + 6), 1.2, fillPaint);
      canvas.drawCircle(Offset(wingX - 4, cy), 1.2, fillPaint);
      canvas.drawCircle(Offset(wingX + 4, cy), 1.2, fillPaint);
    }

    // Bottom flourish curl / ribbon wings
    final curlPath = Path();
    curlPath.moveTo(cx - 14, cy + ry + 3);
    curlPath.quadraticBezierTo(cx - 7, cy + ry + 8, cx, cy + ry + 4);
    curlPath.quadraticBezierTo(cx + 7, cy + ry + 8, cx + 14, cy + ry + 3);
    canvas.drawPath(curlPath, strokePaint..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(covariant _HeraldicCrestPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _RoyalLinenGeometricPainter extends CustomPainter {
  const _RoyalLinenGeometricPainter({required this.lineColor});
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.75
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    const step = 20.0;
    // Diagonal lines forming diamond isometric lattice
    for (double x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoyalLinenGeometricPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}

// =============================================================================
// 1. FLUTTER WIDGET RENDERER FOR COMPANY LETTERHEAD HEADER & FOOTER
// =============================================================================

class CompanyLetterheadWidgets {
  CompanyLetterheadWidgets._();

  static Color _parseHex(String hex, Color fallback) {
    final cleaned = hex.replaceFirst('#', '').trim();
    final val = int.tryParse(cleaned, radix: 16);
    if (val != null) {
      return Color(cleaned.length <= 6 ? (0xFF000000 | val) : val);
    }
    return fallback;
  }

  static Uint8List? _decodeLogo(String? b64) {
    if (b64 == null || b64.trim().isEmpty) return null;
    try {
      final cleaned = b64.contains(',') ? b64.split(',').last : b64;
      return base64Decode(cleaned.trim());
    } catch (_) {
      return null;
    }
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'NY';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length.clamp(1, 2)).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static String _extractMonogram(String companyName, String tagline) {
    final comp = companyName.trim();
    final tag = tagline.trim();
    final combined = '$comp $tag'.toUpperCase();
    if (combined.contains('ROYAL') &&
        (combined.contains('SECURITY') || combined.contains('FORCE'))) {
      return '(SRF)';
    }

    final words = comp.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length >= 3) {
      return '(${words[0][0]}${words[1][0]}${words[2][0]})'.toUpperCase();
    } else if (words.length == 2) {
      if (tag.isNotEmpty) {
        final tw = tag.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        if (tw.isNotEmpty) {
          return '(${words[0][0]}${words[1][0]}${tw[0][0]})'.toUpperCase();
        }
      }
      return '(${words[0][0]}${words[1][0]})'.toUpperCase();
    } else if (words.length == 1) {
      if (tag.isNotEmpty) {
        final tw = tag.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        if (tw.length >= 2) {
          return '(${words[0][0]}${tw[0][0]}${tw[1][0]})'.toUpperCase();
        } else if (tw.length == 1) {
          return '(${words[0][0]}${tw[0][0]})'.toUpperCase();
        }
      }
      final single = words.first;
      return '(${single.substring(0, single.length.clamp(1, 3)).toUpperCase()})';
    }
    return '(SRF)';
  }

  static Widget _buildRoyalHeraldicCrest({
    required CompanyLetterheadConfig config,
    required Color bronzeColor,
    required double scale,
    required String fontFamily,
    Uint8List? logoBytes,
  }) {
    if (logoBytes != null) {
      return Container(
        width: 58 * scale,
        height: 58 * scale,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: bronzeColor, width: 1.5),
        ),
        child: Image.memory(logoBytes, fit: BoxFit.contain),
      );
    }

    final monogram = _extractMonogram(config.companyName, config.tagline);

    return SizedBox(
      width: 76 * scale,
      height: 64 * scale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(76 * scale, 64 * scale),
            painter: _HeraldicCrestPainter(color: bronzeColor),
          ),
          Center(
            child: Text(
              monogram,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 13.5 * scale,
                fontWeight: FontWeight.w900,
                color: bronzeColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _royalContactRow({
    required IconData icon,
    required String text,
    required Color bronzeColor,
    required double scale,
    required String fontFamily,
    int maxLines = 2,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 13 * scale,
          height: 13 * scale,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: bronzeColor, width: 1.1),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 8 * scale, color: bronzeColor),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 8.4 * scale,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4A453E),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildRoyalSecurityCrestHeader({
    required CompanyLetterheadConfig config,
    required Color bronzeColor,
    required double fontScale,
    required String fontFamily,
    required bool showGstBadges,
    Uint8List? logoBytes,
    bool isColorless = false,
  }) {
    final effectiveBronze = isColorless ? const Color(0xFF0F172A) : bronzeColor;
    final navyColor = isColorless ? const Color(0xFF1E293B) : const Color(0xFF1B2A4A);
    final scale = fontScale.clamp(0.7, 1.4);
    final bgColor = isColorless ? Colors.white : const Color(0xFFFBF9F4);
    final borderColor = isColorless ? const Color(0xFFCBD5E1) : const Color(0xFFDCD2BD);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Section with Subtle Geometric Linen Background
            CustomPaint(
              painter: const _RoyalLinenGeometricPainter(
                lineColor: Color(0x2BD4C5A8),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. Left: Royal Heraldic Crest Badge
                    _buildRoyalHeraldicCrest(
                      config: config,
                      bronzeColor: effectiveBronze,
                      scale: scale,
                      fontFamily: fontFamily,
                      logoBytes: logoBytes,
                    ),

                    const SizedBox(width: 14),

                    // 2. Center: Company Name, Flourish Divider, and Tagline
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            config.companyName.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 22 * scale,
                              fontWeight: FontWeight.w900,
                              color: effectiveBronze,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Decorative flourish divider: ── ∿ ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 26 * scale,
                                height: 1.1,
                                color: effectiveBronze.withValues(alpha: 0.65),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 5),
                                child: Text(
                                  '∿',
                                  style: TextStyle(
                                    fontSize: 12 * scale,
                                    color: effectiveBronze,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                width: 26 * scale,
                                height: 1.1,
                                color: effectiveBronze.withValues(alpha: 0.65),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            config.tagline.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 9.5 * scale,
                              fontWeight: FontWeight.w700,
                              color: effectiveBronze,
                              letterSpacing: 3.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 14),

                    // 3. Right: Contact Information (Location, Phone, Email)
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (config.address.isNotEmpty)
                            _royalContactRow(
                              icon: Icons.location_on_rounded,
                              text: config.address,
                              bronzeColor: effectiveBronze,
                              scale: scale,
                              fontFamily: fontFamily,
                              maxLines: 3,
                            ),
                          if (config.phone.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            _royalContactRow(
                              icon: Icons.call_rounded,
                              text: config.phone,
                              bronzeColor: effectiveBronze,
                              scale: scale,
                              fontFamily: fontFamily,
                              maxLines: 1,
                            ),
                          ],
                          if (config.email.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            _royalContactRow(
                              icon: Icons.mail_rounded,
                              text: config.email,
                              bronzeColor: effectiveBronze,
                              scale: scale,
                              fontFamily: fontFamily,
                              maxLines: 1,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Optional GSTIN / PAN / License sub-strip if present
            if (showGstBadges &&
                (config.gstin.isNotEmpty ||
                    config.pan.isNotEmpty ||
                    config.cinOrLicense.isNotEmpty))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                color: isColorless ? const Color(0xFFF8FAFC) : const Color(0xFFF3EEE3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (config.gstin.isNotEmpty)
                      Text(
                        'GSTIN: ${config.gstin}   ',
                        style: TextStyle(
                          fontSize: 8.2 * scale,
                          fontWeight: FontWeight.w700,
                          color: isColorless ? const Color(0xFF1E293B) : const Color(0xFF5A4D33),
                        ),
                      ),
                    if (config.pan.isNotEmpty)
                      Text(
                        'PAN: ${config.pan}   ',
                        style: TextStyle(
                          fontSize: 8.2 * scale,
                          fontWeight: FontWeight.w600,
                          color: isColorless ? const Color(0xFF334155) : const Color(0xFF5A4D33),
                        ),
                      ),
                    if (config.cinOrLicense.isNotEmpty)
                      Text(
                        'License: ${config.cinOrLicense}',
                        style: TextStyle(
                          fontSize: 8.2 * scale,
                          fontWeight: FontWeight.w600,
                          color: isColorless ? const Color(0xFF334155) : const Color(0xFF5A4D33),
                        ),
                      ),
                  ],
                ),
              ),

            // 4. Bottom Horizontal Specialist Bar
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6.5 * scale),
              decoration: BoxDecoration(
                color: isColorless ? const Color(0xFFF1F5F9) : navyColor,
                border: isColorless ? const Border(top: BorderSide(color: Color(0xFFCBD5E1))) : null,
              ),
              alignment: Alignment.center,
              child: Text(
                config.specialistServices.isNotEmpty
                    ? config.specialistServices
                    : 'SPECIALIST IN : Industrial Protective, Detective, Investigating in the Administration of all Essential Supervisors through Perfectly Trained Security Staff.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 8.2 * scale,
                  fontWeight: FontWeight.w700,
                  color: isColorless ? const Color(0xFF1E293B) : Colors.white,
                  letterSpacing: 0.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Renders the top Company Letterhead Banner matching the selected style.
  static Widget buildHeaderBanner({
    required CompanyLetterheadConfig config,
    Color? overridePrimaryColor,
    double fontScale = 1.0,
    String fontFamily = 'Inter',
    bool showGstBadges = true,
    bool isColorless = false,
  }) {
    final effectiveColorless = isColorless || config.isColorless;
    if (config.styleId == 'royal_security_crest') {
      final bronzeColor = overridePrimaryColor ??
          _parseHex(config.primaryColorHex, const Color(0xFF7C6842));
      return _buildRoyalSecurityCrestHeader(
        config: config,
        bronzeColor: bronzeColor,
        fontScale: fontScale,
        fontFamily: fontFamily,
        showGstBadges: showGstBadges,
        logoBytes: _decodeLogo(config.logoBase64),
        isColorless: effectiveColorless,
      );
    }
    final preset = kLetterheadPresets.firstWhere(
      (p) => p.id == config.styleId,
      orElse: () => kLetterheadPresets.first,
    );
    final primary = effectiveColorless
        ? const Color(0xFF0F172A)
        : ((config.styleId == 'modern_ribbon' ||
                config.styleId == 'executive_navy_bar' ||
                config.styleId == 'royal_minimal_split')
            ? (overridePrimaryColor ?? _parseHex(config.primaryColorHex, preset.accentColor))
            : preset.accentColor);
    final secondary = effectiveColorless ? const Color(0xFF475569) : preset.secondaryColor;
    final isDarkBanner = !effectiveColorless &&
        (config.styleId == 'executive_navy_bar' ||
            config.styleId == 'tech_gradient_wave' ||
            config.styleId == 'luxury_gold_crest' ||
            config.styleId == 'monochrome_bauhaus');

    Color bgColor = Colors.white;
    BoxBorder customBorder = Border.all(
      color: isDarkBanner
          ? primary
          : (effectiveColorless ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      width: 1,
    );

    if (!effectiveColorless) {
      if (config.styleId == 'executive_navy_bar') {
        bgColor = primary;
        customBorder = Border.all(color: primary, width: 1);
      } else if (config.styleId == 'tech_gradient_wave') {
        bgColor = const Color(0xFF1E1B4B);
        customBorder = Border.all(color: const Color(0xFF6366F1), width: 1.2);
      } else if (config.styleId == 'luxury_gold_crest') {
        bgColor = const Color(0xFF18181B);
        customBorder = Border.all(color: const Color(0xFFF59E0B), width: 1.5);
      } else if (config.styleId == 'industrial_blueprint') {
        bgColor = const Color(0xFFF0F9FF);
        customBorder = Border.all(color: const Color(0xFF0284C7), width: 1.2);
      } else if (config.styleId == 'nordic_sidebar_accent') {
        bgColor = Colors.white;
        customBorder = Border(
          left: BorderSide(color: primary, width: 6),
          top: const BorderSide(color: Color(0xFFE2E8F0)),
          right: const BorderSide(color: Color(0xFFE2E8F0)),
          bottom: const BorderSide(color: Color(0xFFE2E8F0)),
        );
      } else if (config.styleId == 'botanical_sage_eco') {
        bgColor = const Color(0xFFF0FDF4);
        customBorder = Border.all(color: const Color(0xFF86EFAC), width: 1.2);
      } else if (config.styleId == 'monochrome_bauhaus') {
        bgColor = Colors.white;
        customBorder = Border.all(color: Colors.black, width: 2.0);
      }
    }

    Color titleColor = effectiveColorless
        ? const Color(0xFF0F172A)
        : (isDarkBanner ? Colors.white : const Color(0xFF0F2942));
    Color subColor = effectiveColorless
        ? const Color(0xFF334155)
        : (isDarkBanner ? const Color(0xFFCBD5E1) : const Color(0xFF475569));
    if (!effectiveColorless) {
      if (config.styleId == 'monochrome_bauhaus') {
        titleColor = Colors.black;
        subColor = const Color(0xFF333333);
      } else if (config.styleId == 'luxury_gold_crest') {
        titleColor = const Color(0xFFFEF3C7);
        subColor = const Color(0xFFFDE68A);
      } else if (config.styleId == 'botanical_sage_eco') {
        titleColor = const Color(0xFF14532D);
        subColor = const Color(0xFF166534);
      } else if (config.styleId == 'industrial_blueprint') {
        titleColor = const Color(0xFF0C4A6E);
        subColor = const Color(0xFF0369A1);
      }
    }

    final dividerColor = isDarkBanner
        ? Colors.white.withValues(alpha: 0.22)
        : (config.styleId == 'industrial_blueprint'
            ? const Color(0xFFBAE6FD)
            : const Color(0xFFCBD5E1));
    final logoBytes = _decodeLogo(config.logoBase64);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: customBorder,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          children: [
            // Decorative left & right geometric ribbons
            if (config.styleId == 'modern_ribbon' || config.styleId == 'emerald_corporate') ...[
              Positioned(
                left: -26,
                top: -18,
                bottom: -18,
                child: Transform.rotate(
                  angle: -0.35,
                  child: Container(
                    width: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          secondary.withValues(alpha: 0.22),
                          primary.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -18,
                bottom: -24,
                child: Transform.rotate(
                  angle: -0.65,
                  child: Container(
                    width: 82,
                    height: 68,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [secondary, primary],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 14,
                bottom: -28,
                child: Transform.rotate(
                  angle: -0.65,
                  child: Container(
                    width: 24,
                    height: 58,
                    decoration: BoxDecoration(
                      color: secondary.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ] else if (config.styleId == 'tech_gradient_wave') ...[
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 3,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [secondary, primary, const Color(0xFF06B6D4)],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [secondary.withValues(alpha: 0.35), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ] else if (config.styleId == 'luxury_gold_crest') ...[
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 2.5,
                child: Container(color: const Color(0xFFF59E0B)),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 1,
                child: Container(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
              ),
            ] else if (config.styleId == 'industrial_blueprint') ...[
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 4,
                child: Container(color: const Color(0xFFF97316)),
              ),
            ] else if (config.styleId == 'crimson_chevron') ...[
              Positioned(
                right: -20,
                top: -15,
                bottom: -15,
                child: Transform.rotate(
                  angle: -0.4,
                  child: Row(
                    children: [
                      Container(width: 14, color: const Color(0xFFBE123C).withValues(alpha: 0.3)),
                      const SizedBox(width: 6),
                      Container(width: 24, color: const Color(0xFFBE123C)),
                      const SizedBox(width: 6),
                      Container(width: 8, color: const Color(0xFFEF4444)),
                    ],
                  ),
                ),
              ),
            ] else if (config.styleId == 'botanical_sage_eco') ...[
              Positioned(
                left: -20,
                bottom: -20,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(35),
                  ),
                ),
              ),
            ],

            // Main 3-Column Letterhead Content
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 34, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. Logo Monogram or Image
                      if (logoBytes != null)
                        Container(
                          width: 54,
                          height: 54,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Image.memory(logoBytes, fit: BoxFit.contain),
                        )
                      else
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primary, secondary],
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _initials(config.companyName),
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 20 * fontScale,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),

                      // Vertical Divider after Logo
                      Container(
                        height: 44,
                        width: 1.2,
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        color: dividerColor,
                      ),

                      // 2. Company Name & Tagline
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              config.companyName,
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 15.5 * fontScale,
                                fontWeight: FontWeight.w900,
                                color: titleColor,
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (config.tagline.trim().isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                config.tagline,
                                style: TextStyle(
                                  fontFamily: fontFamily,
                                  fontSize: 9.5 * fontScale,
                                  fontWeight: FontWeight.w500,
                                  color: subColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Vertical Divider before Contact Column
                      Container(
                        height: 52,
                        width: 1.2,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        color: dividerColor,
                      ),

                      // 3. Contact Column (Phone, Email, Web)
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (config.phone.isNotEmpty)
                              _contactRow(
                                Icons.call_rounded,
                                config.phone,
                                isDarkBanner ? secondary : const Color(0xFF2563EB),
                                titleColor,
                                fontScale,
                                fontFamily,
                              ),
                            if (config.email.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              _contactRow(
                                Icons.mail_rounded,
                                config.email,
                                isDarkBanner ? secondary : const Color(0xFF2563EB),
                                titleColor,
                                fontScale,
                                fontFamily,
                              ),
                            ],
                            if (config.website.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              _contactRow(
                                Icons.language_rounded,
                                config.website,
                                isDarkBanner ? secondary : const Color(0xFF0D9488),
                                titleColor,
                                fontScale,
                                fontFamily,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Vertical Divider before Address Column
                      Container(
                        height: 52,
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        color: dividerColor.withValues(alpha: 0.6),
                      ),

                      // 4. Address Column
                      Expanded(
                        flex: 3,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 13 * fontScale,
                              color: isDarkBanner ? secondary : const Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                config.address,
                                style: TextStyle(
                                  fontFamily: fontFamily,
                                  fontSize: 8.8 * fontScale,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                  color: titleColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Statutory Registration Strip (GSTIN / PAN / CIN)
                  if (showGstBadges &&
                      (config.gstin.isNotEmpty ||
                          config.pan.isNotEmpty ||
                          config.cinOrLicense.isNotEmpty)) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDarkBanner
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: isDarkBanner
                              ? Colors.white.withValues(alpha: 0.15)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Wrap(
                        spacing: 18,
                        runSpacing: 4,
                        children: [
                          if (config.gstin.isNotEmpty)
                            Text(
                              'GSTIN: ${config.gstin}',
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 8.5 * fontScale,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                          if (config.pan.isNotEmpty)
                            Text(
                              'PAN: ${config.pan}',
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 8.5 * fontScale,
                                fontWeight: FontWeight.w600,
                                color: subColor,
                              ),
                            ),
                          if (config.cinOrLicense.isNotEmpty)
                            Text(
                              'License / CIN: ${config.cinOrLicense}',
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 8.5 * fontScale,
                                fontWeight: FontWeight.w600,
                                color: subColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildRoyalSecurityCrestFooter({
    required CompanyLetterheadConfig config,
    required Color bronzeColor,
    required double fontScale,
    required String fontFamily,
    String pageLabel = 'Page 1 of 1',
    bool isColorless = false,
  }) {
    final scale = fontScale.clamp(0.7, 1.4);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (config.website.isNotEmpty || pageLabel.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (config.website.isNotEmpty)
                    Text(
                      config.website,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 7.8 * scale,
                        fontWeight: FontWeight.w600,
                        color: isColorless ? const Color(0xFF334155) : const Color(0xFF7C6842),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Text(
                    pageLabel,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 7.5 * scale,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Container(
            height: isColorless ? 2.5 : 13 * scale,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isColorless ? const Color(0xFF0F172A) : null,
              gradient: isColorless
                  ? null
                  : const LinearGradient(
                      colors: [
                        Color(0xFFBFA054),
                        Color(0xFF9E7D3B),
                        Color(0xFFC5A560),
                        Color(0xFF9E7D3B),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
              boxShadow: isColorless
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildWatermark({
    required CompanyLetterheadConfig config,
    double size = 260,
  }) {
    final monogram = _extractMonogram(config.companyName, config.tagline);
    const bronzeColor = Color(0xFF7C6842);

    return Center(
      child: Opacity(
        opacity: 0.055,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size * 0.85),
                painter: const _HeraldicCrestPainter(color: bronzeColor),
              ),
              Center(
                child: Text(
                  monogram,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: bronzeColor,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Renders the bottom Company Letterhead Footer Banner matching the selected style.
  static Widget buildFooterBanner({
    required CompanyLetterheadConfig config,
    Color? overridePrimaryColor,
    double fontScale = 1.0,
    String fontFamily = 'Inter',
    String pageLabel = 'Page 1 of 1',
    bool isColorless = false,
  }) {
    final effectiveColorless = isColorless || config.isColorless;
    if (config.styleId == 'royal_security_crest') {
      final bronzeColor = overridePrimaryColor ??
          _parseHex(config.primaryColorHex, const Color(0xFF7C6842));
      return _buildRoyalSecurityCrestFooter(
        config: config,
        bronzeColor: bronzeColor,
        fontScale: fontScale,
        fontFamily: fontFamily,
        pageLabel: pageLabel,
        isColorless: effectiveColorless,
      );
    }
    final preset = kLetterheadPresets.firstWhere(
      (p) => p.id == config.styleId,
      orElse: () => kLetterheadPresets.first,
    );
    final primary = effectiveColorless
        ? const Color(0xFF0F172A)
        : ((config.styleId == 'modern_ribbon' ||
                config.styleId == 'executive_navy_bar' ||
                config.styleId == 'royal_minimal_split')
            ? (overridePrimaryColor ?? _parseHex(config.primaryColorHex, preset.accentColor))
            : preset.accentColor);
    final secondary = effectiveColorless ? const Color(0xFF475569) : preset.secondaryColor;
    final isDarkBanner = !effectiveColorless &&
        (config.styleId == 'executive_navy_bar' ||
            config.styleId == 'tech_gradient_wave' ||
            config.styleId == 'luxury_gold_crest' ||
            config.styleId == 'monochrome_bauhaus');

    Color bgColor = Colors.white;
    BoxBorder customBorder = Border.all(
      color: isDarkBanner
          ? primary
          : (effectiveColorless ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
    );

    if (!effectiveColorless) {
      if (config.styleId == 'executive_navy_bar') {
        bgColor = primary;
        customBorder = Border.all(color: primary);
      } else if (config.styleId == 'tech_gradient_wave') {
        bgColor = const Color(0xFF1E1B4B);
        customBorder = Border.all(color: const Color(0xFF6366F1));
      } else if (config.styleId == 'luxury_gold_crest') {
        bgColor = const Color(0xFF18181B);
        customBorder = Border.all(color: const Color(0xFFF59E0B));
      } else if (config.styleId == 'industrial_blueprint') {
        bgColor = const Color(0xFFF0F9FF);
        customBorder = Border.all(color: const Color(0xFF0284C7));
      } else if (config.styleId == 'nordic_sidebar_accent') {
        bgColor = Colors.white;
        customBorder = Border(
          left: BorderSide(color: primary, width: 6),
          top: const BorderSide(color: Color(0xFFE2E8F0)),
          right: const BorderSide(color: Color(0xFFE2E8F0)),
          bottom: const BorderSide(color: Color(0xFFE2E8F0)),
        );
      } else if (config.styleId == 'botanical_sage_eco') {
        bgColor = const Color(0xFFF0FDF4);
        customBorder = Border.all(color: const Color(0xFF86EFAC));
      } else if (config.styleId == 'monochrome_bauhaus') {
        bgColor = Colors.white;
        customBorder = Border.all(color: Colors.black, width: 2.0);
      }
    }

    Color textColor = effectiveColorless
        ? const Color(0xFF1E293B)
        : (isDarkBanner ? Colors.white : const Color(0xFF1E293B));
    if (!effectiveColorless) {
      if (config.styleId == 'monochrome_bauhaus') {
        textColor = Colors.black;
      } else if (config.styleId == 'luxury_gold_crest') {
        textColor = const Color(0xFFFEF3C7);
      } else if (config.styleId == 'botanical_sage_eco') {
        textColor = const Color(0xFF14532D);
      }
    }

    final dividerColor = isDarkBanner
        ? Colors.white.withValues(alpha: 0.25)
        : (config.styleId == 'industrial_blueprint'
            ? const Color(0xFFBAE6FD)
            : const Color(0xFFCBD5E1));

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: customBorder,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          children: [
            if (config.styleId == 'modern_ribbon' || config.styleId == 'emerald_corporate') ...[
              Positioned(
                left: -24,
                top: -18,
                bottom: -18,
                child: Transform.rotate(
                  angle: 0.45,
                  child: Container(
                    width: 48,
                    decoration: BoxDecoration(
                      color: secondary.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -16,
                bottom: -20,
                child: Transform.rotate(
                  angle: -0.65,
                  child: Container(
                    width: 68,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [secondary, primary],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ] else if (config.styleId == 'tech_gradient_wave') ...[
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [secondary, primary]),
                  ),
                ),
              ),
            ] else if (config.styleId == 'luxury_gold_crest') ...[
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 1.5,
                child: Container(color: const Color(0xFFF59E0B)),
              ),
            ] else if (config.styleId == 'industrial_blueprint') ...[
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 2.5,
                child: Container(color: const Color(0xFFF97316)),
              ),
            ] else if (config.styleId == 'crimson_chevron') ...[
              Positioned(
                right: -10,
                top: -10,
                bottom: -10,
                child: Transform.rotate(
                  angle: -0.4,
                  child: Row(
                    children: [
                      Container(width: 8, color: const Color(0xFFBE123C)),
                      const SizedBox(width: 4),
                      Container(width: 5, color: const Color(0xFFEF4444)),
                    ],
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 11, 34, 11),
              child: Row(
                children: [
                  // 1. Address with Pin Icon
                  Icon(
                    Icons.location_on_rounded,
                    size: 14 * fontScale,
                    color: isDarkBanner ? secondary : const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 5,
                    child: Text(
                      config.address,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 8.8 * fontScale,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  Container(
                    height: 24,
                    width: 1.2,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    color: dividerColor,
                  ),

                  // 2. Website with Globe Icon
                  Icon(
                    Icons.language_rounded,
                    size: 14 * fontScale,
                    color: isDarkBanner ? secondary : const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 3,
                    child: Text(
                      config.website.isNotEmpty ? config.website : config.email,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 9 * fontScale,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // 3. Social Badges + Page Number
                  if (config.showSocialIcons) ...[
                    _socialCircle('in', primary, isDarkBanner, fontScale),
                    const SizedBox(width: 5),
                    _socialCircle('𝕏', primary, isDarkBanner, fontScale),
                    const SizedBox(width: 5),
                    _socialCircle('f', primary, isDarkBanner, fontScale),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    pageLabel,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 8.2 * fontScale,
                      color: isDarkBanner ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _contactRow(
    IconData icon,
    String text,
    Color iconColor,
    Color textColor,
    double scale,
    String fontFamily,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12 * scale, color: iconColor),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 8.8 * scale,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  static Widget _socialCircle(
    String label,
    Color primary,
    bool isDarkBanner,
    double scale,
  ) {
    return Container(
      width: 18 * scale,
      height: 18 * scale,
      decoration: BoxDecoration(
        color: isDarkBanner ? Colors.white.withValues(alpha: 0.18) : primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.5 * scale,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

// =============================================================================
// 2. VECTOR PDF RENDERER FOR COMPANY LETTERHEAD HEADER & FOOTER (package:pdf)
// =============================================================================

class CompanyLetterheadPdf {
  CompanyLetterheadPdf._();

  static PdfColor _parsePdfHex(String hex, int fallbackInt) {
    final cleaned = hex.replaceFirst('#', '').trim();
    final val = int.tryParse(cleaned, radix: 16);
    if (val != null) {
      return PdfColor.fromInt(cleaned.length <= 6 ? (0xFF000000 | val) : val);
    }
    return PdfColor.fromInt(fallbackInt);
  }

  static Uint8List? _decodeLogo(String? b64) {
    if (b64 == null || b64.trim().isEmpty) return null;
    try {
      final cleaned = b64.contains(',') ? b64.split(',').last : b64;
      return base64Decode(cleaned.trim());
    } catch (_) {
      return null;
    }
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'NY';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length.clamp(1, 2)).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static pw.Widget _buildPdfRoyalSecurityCrestHeader({
    required CompanyLetterheadConfig config,
    required PdfColor bronzeColor,
    required double scale,
    required bool showGstBadges,
    Uint8List? logoBytes,
    bool isColorless = false,
  }) {
    final effectiveBronze = isColorless ? PdfColors.black : bronzeColor;
    final navyColor = isColorless ? const PdfColor.fromInt(0xFF1E293B) : const PdfColor.fromInt(0xFF1B2A4A);
    final ivoryBg = isColorless ? PdfColors.white : const PdfColor.fromInt(0xFFFBF9F4);
    final borderGold = isColorless ? const PdfColor.fromInt(0xFFCBD5E1) : const PdfColor.fromInt(0xFFDCD2BD);

    final monogram = CompanyLetterheadWidgets._extractMonogram(config.companyName, config.tagline);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        color: ivoryBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: borderGold, width: 1.0),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // 1. Left: Crest / Logo
                if (logoBytes != null)
                  pw.Container(
                    width: 44,
                    height: 44,
                    padding: const pw.EdgeInsets.all(2),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(color: effectiveBronze, width: 1.2),
                    ),
                    child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
                  )
                else
                  pw.Container(
                    width: 48,
                    height: 48,
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(color: effectiveBronze, width: 1.5),
                    ),
                    child: pw.Text(
                      monogram,
                      style: pw.TextStyle(
                        fontSize: 12 * scale,
                        fontWeight: pw.FontWeight.bold,
                        color: effectiveBronze,
                      ),
                    ),
                  ),

                pw.SizedBox(width: 10),

                // 2. Center: Company Name & Tagline
                pw.Expanded(
                  flex: 5,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        config.companyName.toUpperCase(),
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 18 * scale,
                          fontWeight: pw.FontWeight.bold,
                          color: effectiveBronze,
                          letterSpacing: 1.5,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Container(width: 24, height: 0.8, color: effectiveBronze),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                            child: pw.Text('~', style: pw.TextStyle(fontSize: 10, color: effectiveBronze)),
                          ),
                          pw.Container(width: 24, height: 0.8, color: effectiveBronze),
                        ],
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        config.tagline.toUpperCase(),
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 8.5 * scale,
                          fontWeight: pw.FontWeight.bold,
                          color: effectiveBronze,
                          letterSpacing: 2.8,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(width: 10),

                // 3. Right: Contact Info
                pw.Expanded(
                  flex: 4,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (config.address.isNotEmpty)
                        pw.Text(
                          config.address,
                          style: pw.TextStyle(
                            fontSize: 7.2 * scale,
                            color: const PdfColor.fromInt(0xFF4A453E),
                            lineSpacing: 1.15,
                          ),
                        ),
                      if (config.phone.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Tel: ${config.phone}',
                          style: pw.TextStyle(
                            fontSize: 7.2 * scale,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF4A453E),
                          ),
                        ),
                      ],
                      if (config.email.isNotEmpty) ...[
                        pw.SizedBox(height: 1.5),
                        pw.Text(
                          'Email: ${config.email}',
                          style: pw.TextStyle(
                            fontSize: 7.2 * scale,
                            color: const PdfColor.fromInt(0xFF4A453E),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. Specialist Ribbon
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: pw.BoxDecoration(
              color: isColorless ? const PdfColor.fromInt(0xFFF1F5F9) : navyColor,
              border: isColorless
                  ? const pw.Border(top: pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 0.8))
                  : null,
            ),
            alignment: pw.Alignment.center,
            child: pw.Text(
              config.specialistServices.isNotEmpty
                  ? config.specialistServices
                  : 'SPECIALIST IN : Industrial Protective, Detective, Investigating in the Administration of all Essential Supervisors through Perfectly Trained Security Staff.',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 7.2 * scale,
                fontWeight: pw.FontWeight.bold,
                color: isColorless ? const PdfColor.fromInt(0xFF1E293B) : PdfColors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget buildPdfHeader({
    required CompanyLetterheadConfig config,
    PdfColor? overridePrimary,
    double scale = 1.0,
    bool showGstBadges = true,
    bool isColorless = false,
  }) {
    final effectiveColorless = isColorless || config.isColorless;
    if (config.styleId == 'royal_security_crest') {
      final bronzePdf = overridePrimary ?? _parsePdfHex(config.primaryColorHex, 0xFF7C6842);
      return _buildPdfRoyalSecurityCrestHeader(
        config: config,
        bronzeColor: bronzePdf,
        scale: scale,
        showGstBadges: showGstBadges,
        logoBytes: _decodeLogo(config.logoBase64),
        isColorless: effectiveColorless,
      );
    }
    final isDarkBanner = !effectiveColorless &&
        (config.styleId == 'executive_navy_bar' ||
            config.styleId == 'tech_gradient_wave' ||
            config.styleId == 'luxury_gold_crest' ||
            config.styleId == 'monochrome_bauhaus');
    final primary = effectiveColorless
        ? PdfColors.black
        : (config.styleId == 'modern_ribbon' ||
                config.styleId == 'executive_navy_bar' ||
                config.styleId == 'royal_minimal_split')
            ? (overridePrimary ?? _parsePdfHex(config.primaryColorHex, 0xFF1E3A8A))
            : config.styleId == 'emerald_corporate'
                ? const PdfColor.fromInt(0xFF047857)
                : config.styleId == 'tech_gradient_wave'
                    ? const PdfColor.fromInt(0xFF4F46E5)
                    : config.styleId == 'luxury_gold_crest'
                        ? const PdfColor.fromInt(0xFFD97706)
                        : config.styleId == 'industrial_blueprint'
                            ? const PdfColor.fromInt(0xFF0284C7)
                            : config.styleId == 'crimson_chevron'
                                ? const PdfColor.fromInt(0xFFDC2626)
                                : config.styleId == 'nordic_sidebar_accent'
                                    ? const PdfColor.fromInt(0xFF0F766E)
                                    : config.styleId == 'botanical_sage_eco'
                                        ? const PdfColor.fromInt(0xFF16A34A)
                                        : config.styleId == 'monochrome_bauhaus'
                                            ? const PdfColor.fromInt(0xFF18181B)
                                            : (overridePrimary ??
                                                _parsePdfHex(config.primaryColorHex, 0xFF1E3A8A));
    PdfColor secondary = effectiveColorless ? const PdfColor.fromInt(0xFF475569) : const PdfColor.fromInt(0xFF06B6D4);
    if (!effectiveColorless) {
      if (config.styleId == 'emerald_corporate') {
        secondary = const PdfColor.fromInt(0xFF10B981);
      } else if (config.styleId == 'tech_gradient_wave') {
        secondary = const PdfColor.fromInt(0xFF8B5CF6);
      } else if (config.styleId == 'luxury_gold_crest') {
        secondary = const PdfColor.fromInt(0xFFF59E0B);
      } else if (config.styleId == 'industrial_blueprint') {
        secondary = const PdfColor.fromInt(0xFFF97316);
      } else if (config.styleId == 'crimson_chevron') {
        secondary = const PdfColor.fromInt(0xFFEF4444);
      } else if (config.styleId == 'botanical_sage_eco') {
        secondary = const PdfColor.fromInt(0xFF22C55E);
      } else if (config.styleId == 'monochrome_bauhaus') {
        secondary = const PdfColor.fromInt(0xFF71717A);
      }
    }

    PdfColor bgColor = PdfColors.white;
    if (!effectiveColorless) {
      if (config.styleId == 'executive_navy_bar') {
        bgColor = primary;
      } else if (config.styleId == 'tech_gradient_wave') {
        bgColor = const PdfColor.fromInt(0xFF1E1B4B);
      } else if (config.styleId == 'luxury_gold_crest') {
        bgColor = const PdfColor.fromInt(0xFF18181B);
      } else if (config.styleId == 'industrial_blueprint') {
        bgColor = const PdfColor.fromInt(0xFFF0F9FF);
      } else if (config.styleId == 'botanical_sage_eco') {
        bgColor = const PdfColor.fromInt(0xFFF0FDF4);
      }
    }

    PdfColor titleColor = effectiveColorless
        ? PdfColors.black
        : (isDarkBanner ? PdfColors.white : const PdfColor.fromInt(0xFF0F2942));
    PdfColor subColor = effectiveColorless
        ? const PdfColor.fromInt(0xFF334155)
        : (isDarkBanner
            ? const PdfColor.fromInt(0xFFCBD5E1)
            : const PdfColor.fromInt(0xFF475569));
    if (!effectiveColorless) {
      if (config.styleId == 'monochrome_bauhaus') {
        titleColor = PdfColors.black;
        subColor = const PdfColor.fromInt(0xFF333333);
      } else if (config.styleId == 'luxury_gold_crest') {
        titleColor = const PdfColor.fromInt(0xFFFEF3C7);
        subColor = const PdfColor.fromInt(0xFFFDE68A);
      } else if (config.styleId == 'botanical_sage_eco') {
        titleColor = const PdfColor.fromInt(0xFF14532D);
        subColor = const PdfColor.fromInt(0xFF166534);
      } else if (config.styleId == 'industrial_blueprint') {
        titleColor = const PdfColor.fromInt(0xFF0C4A6E);
        subColor = const PdfColor.fromInt(0xFF0369A1);
      }
    }

    final dividerColor = isDarkBanner
        ? const PdfColor.fromInt(0xFF334155)
        : const PdfColor.fromInt(0xFFCBD5E1);
    final logoBytes = _decodeLogo(config.logoBase64);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(
          color: isDarkBanner
              ? (config.styleId == 'luxury_gold_crest'
                  ? const PdfColor.fromInt(0xFFF59E0B)
                  : primary)
              : (effectiveColorless ? PdfColors.black : const PdfColor.fromInt(0xFFCBD5E1)),
          width: config.styleId == 'luxury_gold_crest' || config.styleId == 'monochrome_bauhaus'
              ? 1.5
              : 0.8,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Top Accent Strip
          pw.Container(
            height: 4,
            decoration: pw.BoxDecoration(
              color: secondary,
              borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(5)),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // 1. Logo
                    if (logoBytes != null)
                      pw.Container(
                        width: 42,
                        height: 42,
                        padding: const pw.EdgeInsets.all(2),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                          border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
                        ),
                        child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
                      )
                    else
                      pw.Container(
                        width: 42,
                        height: 42,
                        alignment: pw.Alignment.center,
                        decoration: pw.BoxDecoration(
                          color: isDarkBanner ? secondary : primary,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
                        ),
                        child: pw.Text(
                          _initials(config.companyName),
                          style: pw.TextStyle(
                            fontSize: 15 * scale,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),

                    pw.Container(
                      height: 36,
                      width: 1,
                      margin: const pw.EdgeInsets.symmetric(horizontal: 10),
                      color: dividerColor,
                    ),

                    // 2. Company Name & Tagline
                    pw.Expanded(
                      flex: 5,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            config.companyName,
                            style: pw.TextStyle(
                              fontSize: 12.5 * scale,
                              fontWeight: pw.FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                          if (config.tagline.trim().isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              config.tagline,
                              style: pw.TextStyle(
                                fontSize: 8 * scale,
                                color: subColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    pw.Container(
                      height: 38,
                      width: 1,
                      margin: const pw.EdgeInsets.symmetric(horizontal: 8),
                      color: dividerColor,
                    ),

                    // 3. Contact Column
                    pw.Expanded(
                      flex: 3,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (config.phone.isNotEmpty)
                            pw.Text(
                              'Tel: ${config.phone}',
                              style: pw.TextStyle(
                                fontSize: 7.8 * scale,
                                fontWeight: pw.FontWeight.bold,
                                color: titleColor,
                              ),
                            ),
                          if (config.email.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Mail: ${config.email}',
                              style: pw.TextStyle(fontSize: 7.5 * scale, color: titleColor),
                            ),
                          ],
                          if (config.website.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Web: ${config.website}',
                              style: pw.TextStyle(fontSize: 7.5 * scale, color: titleColor),
                            ),
                          ],
                        ],
                      ),
                    ),

                    pw.Container(
                      height: 38,
                      width: 0.8,
                      margin: const pw.EdgeInsets.symmetric(horizontal: 8),
                      color: dividerColor,
                    ),

                    // 4. Address Column
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        config.address,
                        style: pw.TextStyle(
                          fontSize: 7.5 * scale,
                          color: titleColor,
                          lineSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                if (showGstBadges &&
                    (config.gstin.isNotEmpty ||
                        config.pan.isNotEmpty ||
                        config.cinOrLicense.isNotEmpty)) ...[
                  pw.SizedBox(height: 7),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: pw.BoxDecoration(
                      color: isDarkBanner
                          ? const PdfColor.fromInt(0xFF1E293B)
                          : const PdfColor.fromInt(0xFFF8FAFC),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        if (config.gstin.isNotEmpty)
                          pw.Text(
                            'GSTIN: ${config.gstin}',
                            style: pw.TextStyle(
                              fontSize: 7.5 * scale,
                              fontWeight: pw.FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                        if (config.pan.isNotEmpty)
                          pw.Text(
                            'PAN: ${config.pan}',
                            style: pw.TextStyle(fontSize: 7.5 * scale, color: subColor),
                          ),
                        if (config.cinOrLicense.isNotEmpty)
                          pw.Text(
                            'License / CIN: ${config.cinOrLicense}',
                            style: pw.TextStyle(fontSize: 7.5 * scale, color: subColor),
                          ),
                      ],
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

  static pw.Widget _buildPdfRoyalSecurityCrestFooter({
    required CompanyLetterheadConfig config,
    required PdfColor bronzeColor,
    required double scale,
    String pageLabel = 'Page 1 of 1',
    bool isColorless = false,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 6),
      child: pw.Column(
        children: [
          if (config.website.isNotEmpty || pageLabel.isNotEmpty) ...[
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    config.website,
                    style: pw.TextStyle(
                      fontSize: 7.2 * scale,
                      color: isColorless ? const PdfColor.fromInt(0xFF334155) : bronzeColor,
                    ),
                  ),
                  pw.Text(
                    pageLabel,
                    style: pw.TextStyle(
                      fontSize: 7.0 * scale,
                      color: const PdfColor.fromInt(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Metallic Gold/Bronze bar (Image 1 & 3) or thin black rule for colorless
          pw.Container(
            height: isColorless ? 1.5 : 11 * scale,
            decoration: pw.BoxDecoration(
              color: isColorless ? PdfColors.black : const PdfColor.fromInt(0xFFBFA054),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget buildPdfWatermark({
    required CompanyLetterheadConfig config,
    double size = 260,
  }) {
    final monogram = CompanyLetterheadWidgets._extractMonogram(config.companyName, config.tagline);
    const bronzeColor = PdfColor.fromInt(0xFF7C6842);

    return pw.Center(
      child: pw.Opacity(
        opacity: 0.05,
        child: pw.Container(
          width: size,
          height: size,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            border: pw.Border.all(color: bronzeColor, width: 3.5),
          ),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                monogram,
                style: pw.TextStyle(
                  fontSize: 42,
                  fontWeight: pw.FontWeight.bold,
                  color: bronzeColor,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                '~ ~ ~',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: bronzeColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static pw.Widget buildPdfFooter({
    required CompanyLetterheadConfig config,
    PdfColor? overridePrimary,
    double scale = 1.0,
    String pageLabel = 'Page 1 of 1',
    bool isColorless = false,
  }) {
    final effectiveColorless = isColorless || config.isColorless;
    if (config.styleId == 'royal_security_crest') {
      final bronzePdf = overridePrimary ?? _parsePdfHex(config.primaryColorHex, 0xFF7C6842);
      return _buildPdfRoyalSecurityCrestFooter(
        config: config,
        bronzeColor: bronzePdf,
        scale: scale,
        pageLabel: pageLabel,
        isColorless: effectiveColorless,
      );
    }
    final isDarkBanner = !effectiveColorless &&
        (config.styleId == 'executive_navy_bar' ||
            config.styleId == 'tech_gradient_wave' ||
            config.styleId == 'luxury_gold_crest' ||
            config.styleId == 'monochrome_bauhaus');
    final primary = effectiveColorless
        ? PdfColors.black
        : (config.styleId == 'modern_ribbon' ||
                config.styleId == 'executive_navy_bar' ||
                config.styleId == 'royal_minimal_split')
            ? (overridePrimary ?? _parsePdfHex(config.primaryColorHex, 0xFF1E3A8A))
            : config.styleId == 'emerald_corporate'
                ? const PdfColor.fromInt(0xFF047857)
                : config.styleId == 'tech_gradient_wave'
                    ? const PdfColor.fromInt(0xFF4F46E5)
                    : config.styleId == 'luxury_gold_crest'
                        ? const PdfColor.fromInt(0xFFD97706)
                        : config.styleId == 'industrial_blueprint'
                            ? const PdfColor.fromInt(0xFF0284C7)
                            : config.styleId == 'crimson_chevron'
                                ? const PdfColor.fromInt(0xFFDC2626)
                                : config.styleId == 'nordic_sidebar_accent'
                                    ? const PdfColor.fromInt(0xFF0F766E)
                                    : config.styleId == 'botanical_sage_eco'
                                        ? const PdfColor.fromInt(0xFF16A34A)
                                        : config.styleId == 'monochrome_bauhaus'
                                            ? const PdfColor.fromInt(0xFF18181B)
                                            : (overridePrimary ??
                                                _parsePdfHex(config.primaryColorHex, 0xFF1E3A8A));
    PdfColor secondary = effectiveColorless ? const PdfColor.fromInt(0xFF475569) : const PdfColor.fromInt(0xFF06B6D4);
    if (!effectiveColorless) {
      if (config.styleId == 'emerald_corporate') {
        secondary = const PdfColor.fromInt(0xFF10B981);
      } else if (config.styleId == 'tech_gradient_wave') {
        secondary = const PdfColor.fromInt(0xFF8B5CF6);
      } else if (config.styleId == 'luxury_gold_crest') {
        secondary = const PdfColor.fromInt(0xFFF59E0B);
      } else if (config.styleId == 'industrial_blueprint') {
        secondary = const PdfColor.fromInt(0xFFF97316);
      } else if (config.styleId == 'crimson_chevron') {
        secondary = const PdfColor.fromInt(0xFFEF4444);
      } else if (config.styleId == 'botanical_sage_eco') {
        secondary = const PdfColor.fromInt(0xFF22C55E);
      } else if (config.styleId == 'monochrome_bauhaus') {
        secondary = const PdfColor.fromInt(0xFF71717A);
      }
    }

    PdfColor bgColor = PdfColors.white;
    if (!effectiveColorless) {
      if (config.styleId == 'executive_navy_bar') {
        bgColor = primary;
      } else if (config.styleId == 'tech_gradient_wave') {
        bgColor = const PdfColor.fromInt(0xFF1E1B4B);
      } else if (config.styleId == 'luxury_gold_crest') {
        bgColor = const PdfColor.fromInt(0xFF18181B);
      } else if (config.styleId == 'industrial_blueprint') {
        bgColor = const PdfColor.fromInt(0xFFF0F9FF);
      } else if (config.styleId == 'botanical_sage_eco') {
        bgColor = const PdfColor.fromInt(0xFFF0FDF4);
      }
    }

    PdfColor textColor = effectiveColorless
        ? const PdfColor.fromInt(0xFF1E293B)
        : (isDarkBanner ? PdfColors.white : const PdfColor.fromInt(0xFF1E293B));
    if (!effectiveColorless) {
      if (config.styleId == 'monochrome_bauhaus') {
        textColor = PdfColors.black;
      } else if (config.styleId == 'luxury_gold_crest') {
        textColor = const PdfColor.fromInt(0xFFFEF3C7);
      } else if (config.styleId == 'botanical_sage_eco') {
        textColor = const PdfColor.fromInt(0xFF14532D);
      }
    }

    final dividerColor = isDarkBanner
        ? const PdfColor.fromInt(0xFF334155)
        : const PdfColor.fromInt(0xFFCBD5E1);

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 6),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
        border: pw.Border.all(
          color: isDarkBanner
              ? (config.styleId == 'luxury_gold_crest'
                  ? const PdfColor.fromInt(0xFFF59E0B)
                  : primary)
              : (effectiveColorless ? const PdfColor.fromInt(0xFFCBD5E1) : const PdfColor.fromInt(0xFFCBD5E1)),
          width: 0.8,
        ),
      ),
      child: pw.Column(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 5,
                  child: pw.Text(
                    config.address,
                    style: pw.TextStyle(fontSize: 7.5 * scale, color: textColor),
                  ),
                ),
                pw.Container(
                  height: 16,
                  width: 1,
                  margin: const pw.EdgeInsets.symmetric(horizontal: 10),
                  color: dividerColor,
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    config.website.isNotEmpty ? config.website : config.email,
                    style: pw.TextStyle(
                      fontSize: 7.8 * scale,
                      fontWeight: pw.FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                if (config.showSocialIcons) ...[
                  _pdfSocialBadge('in', primary),
                  pw.SizedBox(width: 4),
                  _pdfSocialBadge('X', primary),
                  pw.SizedBox(width: 4),
                  _pdfSocialBadge('f', primary),
                  pw.SizedBox(width: 8),
                ],
                pw.Text(
                  pageLabel,
                  style: pw.TextStyle(
                    fontSize: 7.2 * scale,
                    color: isDarkBanner ? PdfColors.grey300 : const PdfColor.fromInt(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          pw.Container(
            height: 3,
            decoration: pw.BoxDecoration(
              color: secondary,
              borderRadius: const pw.BorderRadius.vertical(bottom: pw.Radius.circular(4)),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfSocialBadge(String label, PdfColor color) {
    return pw.Container(
      width: 13,
      height: 13,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: color,
        shape: pw.BoxShape.circle,
      ),
      child: pw.Text(
        label,
        style: pw.TextStyle(
          fontSize: 6.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }
}
