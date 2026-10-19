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
    id: 'modern_ribbon',
    name: 'Modern Geometric Ribbon (Default)',
    description:
        'Logo | Company + Tagline | Contact Column | Address Column with angled blue-cyan corner ribbons & matching footer.',
    accentColor: Color(0xFF1E3A8A),
    secondaryColor: Color(0xFF06B6D4),
    isDefault: true,
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
    this.styleId = 'modern_ribbon',
    this.companyName = 'NORTHSTAR SECURITY SERVICES PVT. LTD.',
    this.tagline = 'Smart Solutions for a Better Tomorrow',
    this.phone = '+91 98765 43210',
    this.email = 'billing@northstarsecurity.in',
    this.website = 'www.northstarsecurity.in',
    this.address = 'Plot 42, Sector 18, Cyber Park, Gurugram, Haryana - 122015',
    this.gstin = '06AABCN1234F1Z5',
    this.pan = 'AABCN1234F',
    this.cinOrLicense = 'PSARA/HR/2021/889',
    this.showSocialIcons = true,
    this.logoBase64,
    this.primaryColorHex = '#1E3A8A',
  });

  final bool enabledForAllDocuments;
  final String styleId;
  final String companyName;
  final String tagline;
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

  bool get isLetterheadActive =>
      enabledForAllDocuments && styleId != 'classic_traditional' && styleId != 'none';

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
    ], 'modern_ribbon');

    final companyName = pickStr([
      profile['businessName'],
      profile['companyName'],
      localSettings['businessName'],
      localSettings['companyName'],
      localSettings['letterhead_company_name'],
      fallbackCompanyName,
    ], 'NORTHSTAR SECURITY SERVICES PVT. LTD.');

    final tagline = pickStr([
      localSettings['letterhead_tagline'],
      profile['tagline'],
      localSettings['companyTagline'],
    ], 'Smart Solutions for a Better Tomorrow');

    final phone = pickStr([
      profile['phone'],
      profile['companyPhone'],
      localSettings['businessPhone'],
      localSettings['companyPhone'],
      localSettings['letterhead_phone'],
      fallbackPhone,
    ], '+91 98765 43210');

    final email = pickStr([
      profile['email'],
      profile['companyEmail'],
      localSettings['businessEmail'],
      localSettings['companyEmail'],
      localSettings['letterhead_email'],
      fallbackEmail,
    ], 'billing@northstarsecurity.in');

    final website = pickStr([
      profile['website'],
      localSettings['businessWebsite'],
      localSettings['companyWebsite'],
      localSettings['letterhead_website'],
      fallbackWebsite,
    ], 'www.northstarsecurity.in');

    final address = pickStr([
      profile['address'],
      profile['companyAddress'],
      localSettings['businessAddress'],
      localSettings['companyAddress'],
      localSettings['letterhead_address'],
      fallbackAddress,
    ], 'Plot 42, Sector 18, Cyber Park, Gurugram, Haryana - 122015');

    final gstin = pickStr([
      profile['gstin'],
      profile['gstNumber'],
      localSettings['businessGstin'],
      localSettings['companyGstin'],
      localSettings['letterhead_gstin'],
      fallbackGstin,
    ], '06AABCN1234F1Z5');

    final pan = pickStr([
      profile['panNumber'],
      profile['pan'],
      localSettings['businessPan'],
      localSettings['companyPan'],
      localSettings['letterhead_pan'],
      fallbackPan,
    ], 'AABCN1234F');

    final cin = pickStr([
      localSettings['letterhead_cin'],
      profile['cin'],
      profile['taxId'],
      localSettings['companyCin'],
      fallbackCin,
    ], 'PSARA/HR/2021/889');

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
    ], '#1E3A8A');

    return CompanyLetterheadConfig(
      enabledForAllDocuments: enabled,
      styleId: styleId,
      companyName: companyName,
      tagline: tagline,
      phone: phone,
      email: email,
      website: website,
      address: address,
      gstin: gstin,
      pan: pan,
      cinOrLicense: cin,
      logoBase64: logo.isNotEmpty ? logo : null,
      primaryColorHex: primaryHex,
    );
  }
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

  /// Renders the top Company Letterhead Banner matching the selected style.
  static Widget buildHeaderBanner({
    required CompanyLetterheadConfig config,
    Color? overridePrimaryColor,
    double fontScale = 1.0,
    String fontFamily = 'Inter',
    bool showGstBadges = true,
  }) {
    final preset = kLetterheadPresets.firstWhere(
      (p) => p.id == config.styleId,
      orElse: () => kLetterheadPresets.first,
    );
    final primary = (config.styleId == 'modern_ribbon' ||
            config.styleId == 'executive_navy_bar' ||
            config.styleId == 'royal_minimal_split')
        ? (overridePrimaryColor ?? _parseHex(config.primaryColorHex, preset.accentColor))
        : preset.accentColor;
    final secondary = preset.secondaryColor;
    final isDarkBanner = config.styleId == 'executive_navy_bar' ||
        config.styleId == 'tech_gradient_wave' ||
        config.styleId == 'luxury_gold_crest' ||
        config.styleId == 'monochrome_bauhaus';

    Color bgColor = Colors.white;
    BoxBorder customBorder = Border.all(
      color: isDarkBanner ? primary : const Color(0xFFE2E8F0),
      width: 1,
    );

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

    Color titleColor = isDarkBanner ? Colors.white : const Color(0xFF0F2942);
    Color subColor = isDarkBanner ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
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

  /// Renders the bottom Company Letterhead Footer Banner matching the selected style.
  static Widget buildFooterBanner({
    required CompanyLetterheadConfig config,
    Color? overridePrimaryColor,
    double fontScale = 1.0,
    String fontFamily = 'Inter',
    String pageLabel = 'Page 1 of 1',
  }) {
    final preset = kLetterheadPresets.firstWhere(
      (p) => p.id == config.styleId,
      orElse: () => kLetterheadPresets.first,
    );
    final primary = (config.styleId == 'modern_ribbon' ||
            config.styleId == 'executive_navy_bar' ||
            config.styleId == 'royal_minimal_split')
        ? (overridePrimaryColor ?? _parseHex(config.primaryColorHex, preset.accentColor))
        : preset.accentColor;
    final secondary = preset.secondaryColor;
    final isDarkBanner = config.styleId == 'executive_navy_bar' ||
        config.styleId == 'tech_gradient_wave' ||
        config.styleId == 'luxury_gold_crest' ||
        config.styleId == 'monochrome_bauhaus';

    Color bgColor = Colors.white;
    BoxBorder customBorder = Border.all(
      color: isDarkBanner ? primary : const Color(0xFFE2E8F0),
    );

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

    Color textColor = isDarkBanner ? Colors.white : const Color(0xFF1E293B);
    if (config.styleId == 'monochrome_bauhaus') {
      textColor = Colors.black;
    } else if (config.styleId == 'luxury_gold_crest') {
      textColor = const Color(0xFFFEF3C7);
    } else if (config.styleId == 'botanical_sage_eco') {
      textColor = const Color(0xFF14532D);
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

  static pw.Widget buildPdfHeader({
    required CompanyLetterheadConfig config,
    PdfColor? overridePrimary,
    double scale = 1.0,
    bool showGstBadges = true,
  }) {
    final isDarkBanner = config.styleId == 'executive_navy_bar' ||
        config.styleId == 'tech_gradient_wave' ||
        config.styleId == 'luxury_gold_crest' ||
        config.styleId == 'monochrome_bauhaus';
    final primary = (config.styleId == 'modern_ribbon' ||
            config.styleId == 'executive_navy_bar' ||
            config.styleId == 'royal_minimal_split')
        ? (overridePrimary ?? _parsePdfHex(config.primaryColorHex, 0xFF1E3A8A))
        : (config.styleId == 'emerald_corporate'
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
                                            _parsePdfHex(config.primaryColorHex, 0xFF1E3A8A)));
    PdfColor secondary = const PdfColor.fromInt(0xFF06B6D4);
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

    PdfColor bgColor = PdfColors.white;
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

    PdfColor titleColor = isDarkBanner ? PdfColors.white : const PdfColor.fromInt(0xFF0F2942);
    PdfColor subColor = isDarkBanner
        ? const PdfColor.fromInt(0xFFCBD5E1)
        : const PdfColor.fromInt(0xFF475569);
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
              : const PdfColor.fromInt(0xFFCBD5E1),
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

  static pw.Widget buildPdfFooter({
    required CompanyLetterheadConfig config,
    PdfColor? overridePrimary,
    double scale = 1.0,
    String pageLabel = 'Page 1 of 1',
  }) {
    final isDarkBanner = config.styleId == 'executive_navy_bar' ||
        config.styleId == 'tech_gradient_wave' ||
        config.styleId == 'luxury_gold_crest' ||
        config.styleId == 'monochrome_bauhaus';
    final primary = (config.styleId == 'modern_ribbon' ||
            config.styleId == 'executive_navy_bar' ||
            config.styleId == 'royal_minimal_split')
        ? (overridePrimary ?? _parsePdfHex(config.primaryColorHex, 0xFF1E3A8A))
        : (config.styleId == 'emerald_corporate'
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
                                            _parsePdfHex(config.primaryColorHex, 0xFF1E3A8A)));
    PdfColor secondary = const PdfColor.fromInt(0xFF06B6D4);
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

    PdfColor bgColor = PdfColors.white;
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

    PdfColor textColor = isDarkBanner ? PdfColors.white : const PdfColor.fromInt(0xFF1E293B);
    if (config.styleId == 'monochrome_bauhaus') {
      textColor = PdfColors.black;
    } else if (config.styleId == 'luxury_gold_crest') {
      textColor = const PdfColor.fromInt(0xFFFEF3C7);
    } else if (config.styleId == 'botanical_sage_eco') {
      textColor = const PdfColor.fromInt(0xFF14532D);
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
              : const PdfColor.fromInt(0xFFCBD5E1),
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
