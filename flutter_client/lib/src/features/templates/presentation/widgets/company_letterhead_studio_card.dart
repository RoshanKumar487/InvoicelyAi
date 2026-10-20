import 'package:flutter/material.dart';

import '../../data/company_letterhead.dart';

class CompanyLetterheadStudioCard extends StatelessWidget {
  const CompanyLetterheadStudioCard({
    required this.config,
    required this.letterheadEnabled,
    required this.letterheadStyleId,
    required this.primaryColor,
    required this.letterheadCompanyName,
    required this.letterheadTagline,
    required this.letterheadPhone,
    required this.letterheadEmail,
    required this.letterheadWebsite,
    required this.letterheadAddress,
    this.letterheadSpecialistServices,
    required this.onEnabledChanged,
    required this.onStyleChanged,
    required this.onCompanyNameChanged,
    required this.onTaglineChanged,
    required this.onPhoneChanged,
    required this.onEmailChanged,
    required this.onWebsiteChanged,
    required this.onAddressChanged,
    this.onSpecialistServicesChanged,
    super.key,
  });

  final CompanyLetterheadConfig config;
  final bool letterheadEnabled;
  final String letterheadStyleId;
  final Color primaryColor;
  final String letterheadCompanyName;
  final String letterheadTagline;
  final String? letterheadSpecialistServices;
  final String letterheadPhone;
  final String letterheadEmail;
  final String letterheadWebsite;
  final String letterheadAddress;

  final ValueChanged<bool> onEnabledChanged;
  final void Function(String styleId, bool enabled) onStyleChanged;
  final ValueChanged<String> onCompanyNameChanged;
  final ValueChanged<String> onTaglineChanged;
  final ValueChanged<String>? onSpecialistServicesChanged;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onWebsiteChanged;
  final ValueChanged<String> onAddressChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: letterheadEnabled ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
          width: letterheadEnabled ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF06B6D4)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.branding_watermark_rounded, color: Colors.white, size: 18),
          ),
          title: Row(
            children: [
              const Expanded(
                child: Text(
                  'Company Letterhead (Header & Footer)',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: letterheadEnabled ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  letterheadEnabled ? 'DIGITAL BANNER' : 'PRE-PRINTED PAPER',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: letterheadEnabled ? const Color(0xFF15803D) : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            letterheadEnabled
                ? 'Auto-applies header banner & footer to Invoices, Biodata, & PDFs'
                : 'Leaves blank margins for companies printing directly onto pre-printed letterhead paper',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          children: [
            // Master Toggle: Default for All Documents
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                letterheadEnabled
                    ? 'Digital Company Letterhead Banner Active'
                    : 'Pre-Printed Stationery Paper Mode (Letterhead Unselected)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              subtitle: Text(
                letterheadEnabled
                    ? 'Prints digital company banner, GSTIN, and footer directly onto plain paper.'
                    : 'Unselected: Hides all Billed-From company details and reserves blank top/bottom margins so you can print directly into your own pre-printed letterhead paper.',
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
              ),
              value: letterheadEnabled,
              activeColor: const Color(0xFF2563EB),
              onChanged: onEnabledChanged,
            ),
            const SizedBox(height: 8),

            // Layout Design Picker
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select Letterhead Layout Design:',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kLetterheadPresets.map((preset) {
                final isSelected = letterheadStyleId == preset.id;
                return InkWell(
                  onTap: () {
                    final shouldEnable = preset.id != 'classic_traditional';
                    onStyleChanged(preset.id, shouldEnable);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                        width: isSelected ? 1.8 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [preset.accentColor, preset.secondaryColor],
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          preset.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Live Mini Preview of Header + Footer
            if (config.isLetterheadActive) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: 680,
                        child: CompanyLetterheadWidgets.buildHeaderBanner(
                          config: config,
                          overridePrimaryColor: primaryColor,
                          showGstBadges: false,
                        ),
                      ),
                    ),
                    const Text(
                      'Header (for all documents)',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: 680,
                        child: CompanyLetterheadWidgets.buildFooterBanner(
                          config: config,
                          overridePrimaryColor: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Footer (for all documents)',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Editable Letterhead Details (Responsive layout for mobile & desktop)
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 500;

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        initialValue: letterheadCompanyName,
                        decoration: InputDecoration(
                          labelText: 'Company Name on Letterhead',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: onCompanyNameChanged,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: letterheadTagline,
                        decoration: InputDecoration(
                          labelText: 'Company Tagline / Slogan',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: onTaglineChanged,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: letterheadPhone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: onPhoneChanged,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: letterheadEmail,
                        decoration: InputDecoration(
                          labelText: 'Official Email',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: onEmailChanged,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: letterheadWebsite,
                        decoration: InputDecoration(
                          labelText: 'Website URL',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: onWebsiteChanged,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: letterheadAddress,
                        decoration: InputDecoration(
                          labelText: 'Registered Office Address (Header & Footer)',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: onAddressChanged,
                      ),
                      if (letterheadSpecialistServices != null || onSpecialistServicesChanged != null) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: letterheadSpecialistServices ?? '',
                          decoration: InputDecoration(
                            labelText: 'Specialist Services (Navy Blue Banner)',
                            hintText: 'SPECIALIST IN : Industrial Protective, Detective...',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          maxLines: 2,
                          onChanged: onSpecialistServicesChanged,
                        ),
                      ],
                    ],
                  );
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: letterheadCompanyName,
                            decoration: InputDecoration(
                              labelText: 'Company Name on Letterhead',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onChanged: onCompanyNameChanged,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: letterheadTagline,
                            decoration: InputDecoration(
                              labelText: 'Company Tagline / Slogan',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onChanged: onTaglineChanged,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: letterheadPhone,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onChanged: onPhoneChanged,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: letterheadEmail,
                            decoration: InputDecoration(
                              labelText: 'Official Email',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onChanged: onEmailChanged,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: letterheadWebsite,
                            decoration: InputDecoration(
                              labelText: 'Website URL',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onChanged: onWebsiteChanged,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: letterheadAddress,
                      decoration: InputDecoration(
                        labelText: 'Registered Office Address (Header & Footer)',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: onAddressChanged,
                    ),
                    if (letterheadSpecialistServices != null || onSpecialistServicesChanged != null) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: letterheadSpecialistServices ?? '',
                        decoration: InputDecoration(
                          labelText: 'Specialist Services (Navy Blue Banner)',
                          hintText: 'SPECIALIST IN : Industrial Protective, Detective...',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        maxLines: 2,
                        onChanged: onSpecialistServicesChanged,
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
