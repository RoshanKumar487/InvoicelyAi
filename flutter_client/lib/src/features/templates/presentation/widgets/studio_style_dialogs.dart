import 'package:flutter/material.dart';

class StudioStyleConfig {
  const StudioStyleConfig({
    required this.fontFamily,
    required this.fontScale,
    required this.uppercaseHeadings,
    required this.documentTitle,
    required this.primaryColor,
    required this.tableHeaderTextColor,
    required this.tableBorderStyle,
    this.isColorless = false,
    this.tableHeaderStyle = 'solid',
    this.tableDensity = 'standard',
    this.cornerRadius = 'subtle',
    this.watermark = 'None',
  });

  final String fontFamily;
  final double fontScale;
  final bool uppercaseHeadings;
  final String documentTitle;
  final Color primaryColor;
  final Color tableHeaderTextColor;
  final String tableBorderStyle;
  final bool isColorless;
  final String tableHeaderStyle;
  final String tableDensity;
  final String cornerRadius;
  final String watermark;
}

class StudioStyleDialog extends StatelessWidget {
  const StudioStyleDialog({
    required this.initialConfig,
    required this.onApplyStyle,
    super.key,
  });

  final StudioStyleConfig initialConfig;
  final ValueChanged<StudioStyleConfig> onApplyStyle;

  static void show(
    BuildContext context, {
    required StudioStyleConfig initialConfig,
    required ValueChanged<StudioStyleConfig> onApplyStyle,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => StudioStyleDialog(
        initialConfig: initialConfig,
        onApplyStyle: onApplyStyle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String tempFont = initialConfig.fontFamily;
    double tempScale = initialConfig.fontScale;
    bool tempUppercase = initialConfig.uppercaseHeadings;
    String tempTitle = initialConfig.documentTitle;
    Color tempPrimary = initialConfig.primaryColor;
    Color tempHeaderText = initialConfig.tableHeaderTextColor;
    String tempBorderStyle = initialConfig.tableBorderStyle;
    bool tempColorless = initialConfig.isColorless;
    String tempHeaderStyle = initialConfig.tableHeaderStyle;
    String tempDensity = initialConfig.tableDensity;
    String tempCornerRadius = initialConfig.cornerRadius;
    String tempWatermark = initialConfig.watermark;
    final titleCtrl = TextEditingController(text: tempTitle);

    return StatefulBuilder(
      builder: (ctx, setDlgState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.palette_outlined,
                  color: Color(0xFF2563EB), size: 18),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Document Style & Typography',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A)),
              ),
            ),
            if (tempColorless)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF94A3B8)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.print_outlined, size: 12, color: Color(0xFF334155)),
                    SizedBox(width: 4),
                    Text(
                      'B&W MONO',
                      style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),

                // 1. Color Mode / Printer Readiness
                Row(
                  children: [
                    const Text('Color Mode & Printer Option',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155))),
                    const Spacer(),
                    if (tempColorless)
                      const Text(
                        'Zero Color Ink Mode',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF059669)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setDlgState(() {
                            tempColorless = false;
                            if (tempPrimary == const Color(0xFF0F172A) ||
                                tempPrimary == Colors.black) {
                              tempPrimary = const Color(0xFF1E3A8A);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                          decoration: BoxDecoration(
                            color: !tempColorless
                                ? const Color(0xFF2563EB).withValues(alpha: 0.1)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: !tempColorless
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFE2E8F0),
                              width: !tempColorless ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.palette_outlined,
                                size: 14,
                                color: !tempColorless
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Vibrant Colors',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: !tempColorless
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: !tempColorless
                                      ? const Color(0xFF1E40AF)
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setDlgState(() {
                            tempColorless = true;
                            tempPrimary = const Color(0xFF0F172A);
                            tempHeaderText = Colors.white;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                          decoration: BoxDecoration(
                            color: tempColorless
                                ? const Color(0xFF0F172A).withValues(alpha: 0.08)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: tempColorless
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFE2E8F0),
                              width: tempColorless ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.print_outlined,
                                size: 14,
                                color: tempColorless
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'No Color (B&W Mono)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: tempColorless
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: tempColorless
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (tempColorless) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 15, color: Color(0xFF334155)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Printer-Friendly Monochrome Active: Suppresses all color backgrounds, gradients, and saturated ribbons across Letterhead banners and sections. Renders in crisp black, clean white, and sharp line dividers for dot-matrix and B&W laser printers.',
                            style: TextStyle(
                                fontSize: 10.2,
                                height: 1.35,
                                color: Color(0xFF334155)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 20),

                // 2. Primary Brand / Table Header Color
                Row(
                  children: [
                    const Text('Brand & Table Header Color',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155))),
                    const Spacer(),
                    if (!tempColorless)
                      Text(
                        '#${tempPrimary.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                        style: const TextStyle(
                            fontSize: 10.5,
                            fontFamily: 'monospace',
                            color: Color(0xFF64748B)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Special No-Color / B&W swatch
                    InkWell(
                      onTap: () {
                        setDlgState(() {
                          tempColorless = true;
                          tempPrimary = const Color(0xFF0F172A);
                          tempHeaderText = Colors.white;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: tempColorless
                                ? const Color(0xFF0F172A)
                                : const Color(0xFF94A3B8),
                            width: tempColorless ? 2.5 : 1.2,
                          ),
                          boxShadow: [
                            if (tempColorless)
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  spreadRadius: 1),
                          ],
                        ),
                        child: const Icon(
                          Icons.format_color_reset_outlined,
                          size: 15,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    ...const [
                      Color(0xFF0F172A), // Slate Dark
                      Color(0xFF000000), // Pure Black
                      Color(0xFF1E3A8A), // Navy Corporate
                      Color(0xFF2563EB), // Royal Blue
                      Color(0xFF0284C7), // Sky Tech
                      Color(0xFF0D9488), // Teal Cyan
                      Color(0xFF059669), // Emerald
                      Color(0xFF15803D), // Forest Pine
                      Color(0xFFD97706), // Amber
                      Color(0xFFEA580C), // Rust Orange
                      Color(0xFF991B1B), // Crimson Red
                      Color(0xFF831843), // Wine
                      Color(0xFF7C3AED), // Purple
                      Color(0xFF78592B), // Antique Bronze
                      Color(0xFF475569), // Graphite Steel
                    ].map((col) {
                      final isSel = !tempColorless && tempPrimary == col;
                      return InkWell(
                        onTap: () {
                          setDlgState(() {
                            tempColorless = false;
                            tempPrimary = col;
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: col,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: isSel ? Colors.white : Colors.transparent,
                                width: 2),
                            boxShadow: [
                              if (isSel)
                                BoxShadow(
                                    color: col.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                    spreadRadius: 2),
                            ],
                          ),
                          child: isSel
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                      );
                    }),
                  ],
                ),
                const Divider(height: 20),

                // 3. Table Header Fill Style (Solid vs Light Tint vs Clean Outline)
                const Text('Table Header Fill Style',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildOptionBtn(
                      label: 'Solid Fill',
                      key: 'solid',
                      current: tempHeaderStyle,
                      icon: Icons.rectangle,
                      onSelect: (k) => setDlgState(() => tempHeaderStyle = k),
                    ),
                    const SizedBox(width: 8),
                    _buildOptionBtn(
                      label: 'Light Tint (8%)',
                      key: 'tint',
                      current: tempHeaderStyle,
                      icon: Icons.opacity,
                      onSelect: (k) => setDlgState(() => tempHeaderStyle = k),
                    ),
                    const SizedBox(width: 8),
                    _buildOptionBtn(
                      label: 'Clean Outline',
                      key: 'outline',
                      current: tempHeaderStyle,
                      icon: Icons.border_all_outlined,
                      onSelect: (k) => setDlgState(() {
                        tempHeaderStyle = k;
                        if (tempHeaderText == Colors.white) {
                          tempHeaderText = const Color(0xFF1E293B);
                        }
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Table Header Text Color
                Row(
                  children: [
                    const Text('Header Text:',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B))),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('White Text',
                          style: TextStyle(fontSize: 11)),
                      selected: tempHeaderText == Colors.white,
                      selectedColor: const Color(0xFF0F172A),
                      labelStyle: TextStyle(
                          color: tempHeaderText == Colors.white
                              ? Colors.white
                              : const Color(0xFF334155)),
                      onSelected: (_) =>
                          setDlgState(() => tempHeaderText = Colors.white),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Dark Text',
                          style: TextStyle(fontSize: 11)),
                      selected: tempHeaderText == const Color(0xFF1E293B),
                      selectedColor: const Color(0xFF0F172A),
                      labelStyle: TextStyle(
                          color: tempHeaderText == const Color(0xFF1E293B)
                              ? Colors.white
                              : const Color(0xFF334155)),
                      onSelected: (_) => setDlgState(
                          () => tempHeaderText = const Color(0xFF1E293B)),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // 4. Line Items Grid & Border Style
                const Text('Line Items Border Style',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildOptionBtn(
                      label: 'Boxed Borders',
                      key: 'boxed',
                      current: tempBorderStyle,
                      icon: Icons.grid_on_sharp,
                      onSelect: (b) => setDlgState(() => tempBorderStyle = b),
                    ),
                    const SizedBox(width: 8),
                    _buildOptionBtn(
                      label: 'Clean Dividers',
                      key: 'lines',
                      current: tempBorderStyle,
                      icon: Icons.table_rows_outlined,
                      onSelect: (b) => setDlgState(() => tempBorderStyle = b),
                    ),
                    const SizedBox(width: 8),
                    _buildOptionBtn(
                      label: 'Striped Rows',
                      key: 'striped',
                      current: tempBorderStyle,
                      icon: Icons.view_headline_rounded,
                      onSelect: (b) => setDlgState(() => tempBorderStyle = b),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Table Row Density & Height
                const Text('Table Row Spacing & Density',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildOptionBtn(
                      label: 'Compact (88%)',
                      key: 'compact',
                      current: tempDensity,
                      icon: Icons.density_small,
                      onSelect: (d) => setDlgState(() => tempDensity = d),
                    ),
                    const SizedBox(width: 8),
                    _buildOptionBtn(
                      label: 'Standard (100%)',
                      key: 'standard',
                      current: tempDensity,
                      icon: Icons.density_medium,
                      onSelect: (d) => setDlgState(() => tempDensity = d),
                    ),
                    const SizedBox(width: 8),
                    _buildOptionBtn(
                      label: 'Spacious (115%)',
                      key: 'spacious',
                      current: tempDensity,
                      icon: Icons.density_large,
                      onSelect: (d) => setDlgState(() => tempDensity = d),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // 5. Corner Rounding & Card Radius
                const Text('Cards & Table Corner Shape',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildOptionBtn(
                      label: 'Sharp (0px)',
                      key: 'sharp',
                      current: tempCornerRadius,
                      icon: Icons.crop_square,
                      onSelect: (r) => setDlgState(() => tempCornerRadius = r),
                    ),
                    const SizedBox(width: 8),
                    _buildOptionBtn(
                      label: 'Subtle (4px)',
                      key: 'subtle',
                      current: tempCornerRadius,
                      icon: Icons.rounded_corner,
                      onSelect: (r) => setDlgState(() => tempCornerRadius = r),
                    ),
                    const SizedBox(width: 8),
                    _buildOptionBtn(
                      label: 'Rounded (8px)',
                      key: 'rounded',
                      current: tempCornerRadius,
                      icon: Icons.circle_outlined,
                      onSelect: (r) => setDlgState(() => tempCornerRadius = r),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // 6. Document Title & Quick Presets
                Row(
                  children: [
                    const Text('Document Title',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155))),
                    const Spacer(),
                    Wrap(
                      spacing: 4,
                      children: ['TAX INVOICE', 'BILL OF SUPPLY', 'PROFORMA', 'ESTIMATE'].map((t) {
                        return InkWell(
                          onTap: () {
                            setDlgState(() {
                              tempTitle = t;
                              titleCtrl.text = t;
                            });
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Text(
                              t,
                              style: const TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. TAX INVOICE',
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (v) => tempTitle = v,
                ),
                const SizedBox(height: 6),

                // Uppercase headings toggle
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Uppercase Headings',
                      style: TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                      'Display titles in capital letters (TAX INVOICE)',
                      style:
                          TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  value: tempUppercase,
                  activeColor: const Color(0xFF2563EB),
                  onChanged: (v) => setDlgState(() => tempUppercase = v),
                ),
                const Divider(height: 20),

                // 7. Font Family
                const Text('Font Family',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155))),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: ['Inter', 'Roboto', 'Poppins', 'Merriweather', 'Courier']
                      .map((font) {
                    final isSel = tempFont == font;
                    return ChoiceChip(
                      label: Text(font,
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSel
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                      selected: isSel,
                      selectedColor: const Color(0xFF2563EB),
                      labelStyle: TextStyle(
                          color: isSel
                              ? Colors.white
                              : const Color(0xFF334155)),
                      onSelected: (_) => setDlgState(() => tempFont = font),
                    );
                  }).toList(),
                ),
                const Divider(height: 20),

                // 8. Text Size Scale
                const Text('Font Size Scaling',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildScaleBtn('Compact (88%)', 0.88, tempScale,
                        (s) => setDlgState(() => tempScale = s)),
                    const SizedBox(width: 8),
                    _buildScaleBtn('Standard (100%)', 1.0, tempScale,
                        (s) => setDlgState(() => tempScale = s)),
                    const SizedBox(width: 8),
                    _buildScaleBtn('Large (112%)', 1.12, tempScale,
                        (s) => setDlgState(() => tempScale = s)),
                  ],
                ),
                const Divider(height: 20),

                // 9. Document Watermark Preset
                const Text('Document Background Watermark',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155))),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ['None', 'ORIGINAL', 'DUPLICATE', 'PAID', 'TAX INVOICE', 'DRAFT']
                      .map((w) {
                    final isSel = tempWatermark == w;
                    return ChoiceChip(
                      label: Text(w, style: const TextStyle(fontSize: 10.5)),
                      selected: isSel,
                      selectedColor: const Color(0xFF0F172A),
                      labelStyle: TextStyle(
                          color: isSel ? Colors.white : const Color(0xFF334155),
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
                      onSelected: (_) => setDlgState(() => tempWatermark = w),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final finalTitle = titleCtrl.text.trim().isNotEmpty
                  ? titleCtrl.text.trim()
                  : tempTitle;
              onApplyStyle(
                StudioStyleConfig(
                  fontFamily: tempFont,
                  fontScale: tempScale,
                  uppercaseHeadings: tempUppercase,
                  documentTitle: finalTitle,
                  primaryColor: tempColorless ? const Color(0xFF0F172A) : tempPrimary,
                  tableHeaderTextColor: tempHeaderText,
                  tableBorderStyle: tempBorderStyle,
                  isColorless: tempColorless,
                  tableHeaderStyle: tempHeaderStyle,
                  tableDensity: tempDensity,
                  cornerRadius: tempCornerRadius,
                  watermark: tempWatermark,
                ),
              );
              Navigator.of(ctx).pop();
            },
            child:
                const Text('Apply Style', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionBtn({
    required String label,
    required String key,
    required String current,
    required IconData icon,
    required ValueChanged<String> onSelect,
  }) {
    final isSel = current == key;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(key),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSel ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
              width: isSel ? 1.4 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isSel ? Colors.white : const Color(0xFF64748B)),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                  color: isSel ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScaleBtn(String label, double scale, double current,
      ValueChanged<double> onSelect) {
    final isSel = (current - scale).abs() < 0.01;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(scale),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSel ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
              color: isSel ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }
}

class StudioPageSettingsDialog extends StatelessWidget {
  const StudioPageSettingsDialog({
    required this.showQrCode,
    required this.watermark,
    required this.pageMargin,
    required this.onSaveSettings,
    super.key,
  });

  final bool showQrCode;
  final String watermark;
  final String pageMargin;
  final void Function(bool showQr, String watermark, String pageMargin)
      onSaveSettings;

  static void show(
    BuildContext context, {
    required bool showQrCode,
    required String watermark,
    required String pageMargin,
    required void Function(bool showQr, String watermark, String pageMargin)
        onSaveSettings,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => StudioPageSettingsDialog(
        showQrCode: showQrCode,
        watermark: watermark,
        pageMargin: pageMargin,
        onSaveSettings: onSaveSettings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool tempQr = showQrCode;
    String tempWatermark = watermark;
    String tempMargin = pageMargin;

    return StatefulBuilder(
      builder: (ctx, setDlgState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.tune_rounded, color: Color(0xFF2563EB), size: 18),
            SizedBox(width: 8),
            Text('Page & Document Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paper Format',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155))),
            const SizedBox(height: 6),
            Row(
              children: const [
                Chip(
                    label: Text('A4 (210 × 297 mm)',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB)))),
                SizedBox(width: 8),
                Chip(
                    label: Text('Letter (8.5 × 11 in)',
                        style: TextStyle(fontSize: 11))),
              ],
            ),
            const Divider(height: 20),
            const Text('Page Margins',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155))),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: ['Compact (10mm)', 'Standard (16mm)', 'Spacious (24mm)']
                  .map((m) {
                final isSel = tempMargin == m;
                return ChoiceChip(
                  label: Text(m, style: const TextStyle(fontSize: 11)),
                  selected: isSel,
                  selectedColor: const Color(0xFF2563EB),
                  labelStyle: TextStyle(
                      color: isSel ? Colors.white : const Color(0xFF334155)),
                  onSelected: (_) => setDlgState(() => tempMargin = m),
                );
              }).toList(),
            ),
            const Divider(height: 20),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Show UPI Scan & Pay QR Code',
                  style:
                      TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              value: tempQr,
              activeColor: const Color(0xFF2563EB),
              onChanged: (v) => setDlgState(() => tempQr = v),
            ),
            const Divider(height: 20),
            const Text('Watermark',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155))),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: ['None', 'DRAFT', 'ORIGINAL FOR RECIPIENT'].map((w) {
                final isSel = tempWatermark == w;
                return ChoiceChip(
                  label: Text(w, style: const TextStyle(fontSize: 11)),
                  selected: isSel,
                  selectedColor: const Color(0xFF2563EB),
                  labelStyle: TextStyle(
                      color: isSel ? Colors.white : const Color(0xFF334155)),
                  onSelected: (_) => setDlgState(() => tempWatermark = w),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              onSaveSettings(tempQr, tempWatermark, tempMargin);
              Navigator.of(ctx).pop();
            },
            child: const Text('Save Settings',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
