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
  });

  final String fontFamily;
  final double fontScale;
  final bool uppercaseHeadings;
  final String documentTitle;
  final Color primaryColor;
  final Color tableHeaderTextColor;
  final String tableBorderStyle;
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
            const Text(
              'Document Style & Typography',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A)),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // 1. Document Title Text
                const Text('Document Title',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155))),
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
                const SizedBox(height: 12),

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

                // 2. Font Family
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

                // 3. Text Size Scale
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

                // 4. Primary Brand / Table Header Color
                const Text('Brand & Table Header Color',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: const [
                    Color(0xFF1E3A8A), // Navy
                    Color(0xFF2563EB), // Royal Blue
                    Color(0xFF0284C7), // Sky Tech
                    Color(0xFF0F172A), // Slate Dark
                    Color(0xFF059669), // Emerald
                    Color(0xFF991B1B), // Crimson
                    Color(0xFFD97706), // Amber
                    Color(0xFF7C3AED), // Purple
                    Color(0xFF0D9488), // Teal
                  ].map((col) {
                    final isSel = tempPrimary == col;
                    return InkWell(
                      onTap: () => setDlgState(() => tempPrimary = col),
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
                  }).toList(),
                ),
                const Divider(height: 20),

                // 5. Table Header Text Color
                const Text('Table Header Text Color',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155))),
                const SizedBox(height: 6),
                Row(
                  children: [
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

                // 6. Table Border Style (Boxed vs Lines vs Striped)
                const Text('Line Items Border Style',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildBorderBtn('Boxed Borders', 'boxed', tempBorderStyle,
                        (b) => setDlgState(() => tempBorderStyle = b)),
                    const SizedBox(width: 8),
                    _buildBorderBtn('Clean Dividers', 'lines', tempBorderStyle,
                        (b) => setDlgState(() => tempBorderStyle = b)),
                    const SizedBox(width: 8),
                    _buildBorderBtn('Striped Rows', 'striped', tempBorderStyle,
                        (b) => setDlgState(() => tempBorderStyle = b)),
                  ],
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
                  primaryColor: tempPrimary,
                  tableHeaderTextColor: tempHeaderText,
                  tableBorderStyle: tempBorderStyle,
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

  Widget _buildBorderBtn(String label, String key, String current,
      ValueChanged<String> onSelect) {
    final isSel = current == key;
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(key),
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
              fontSize: 11,
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
