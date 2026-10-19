import 'package:flutter/material.dart';

class StudioTemplateOption {
  const StudioTemplateOption({
    required this.id,
    required this.name,
    required this.presetKey,
    required this.description,
    required this.primaryColor,
    this.layoutStyle = 'modern_split',
    this.isWasm = false,
  });

  final String id;
  final String name;
  final String presetKey;
  final String description;
  final Color primaryColor;
  final String layoutStyle;
  final bool isWasm;
}

class StudioTemplateSelectorDialog extends StatelessWidget {
  const StudioTemplateSelectorDialog({
    required this.availableTemplates,
    required this.activePreset,
    required this.companyDefaultTemplateId,
    required this.onSelectTemplate,
    required this.onSetAsCompanyDefault,
    super.key,
  });

  final List<StudioTemplateOption> availableTemplates;
  final String activePreset;
  final String companyDefaultTemplateId;
  final ValueChanged<StudioTemplateOption> onSelectTemplate;
  final ValueChanged<StudioTemplateOption> onSetAsCompanyDefault;

  static void show(
    BuildContext context, {
    required List<StudioTemplateOption> availableTemplates,
    required String activePreset,
    required String companyDefaultTemplateId,
    required ValueChanged<StudioTemplateOption> onSelectTemplate,
    required ValueChanged<StudioTemplateOption> onSetAsCompanyDefault,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => StudioTemplateSelectorDialog(
        availableTemplates: availableTemplates,
        activePreset: activePreset,
        companyDefaultTemplateId: companyDefaultTemplateId,
        onSelectTemplate: onSelectTemplate,
        onSetAsCompanyDefault: onSetAsCompanyDefault,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_mosaic_rounded,
              color: Color(0xFF2563EB),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Select Invoice Template',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              for (final t in availableTemplates) ...[
                _buildTemplateOptionCard(context, t),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildTemplateOptionCard(BuildContext ctx, StudioTemplateOption t) {
    final isCurrent = activePreset == t.presetKey;
    final isDefault = companyDefaultTemplateId == t.id;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
          width: isCurrent ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: t.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                t.isWasm
                    ? Icons.view_compact_rounded
                    : Icons.description_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.name,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isCurrent
                              ? const Color(0xFF1E3A8A)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded,
                                size: 12, color: Color(0xFFD97706)),
                            SizedBox(width: 3),
                            Text(
                              'Default',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (t.isWasm) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'WASM Engine',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  t.description,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCurrent
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () {
                        onSelectTemplate(t);
                        Navigator.of(ctx).pop();
                      },
                      child: Text(
                        isCurrent ? 'Active & Editing' : 'Select & Edit',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!isDefault)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () {
                          onSelectTemplate(t);
                          onSetAsCompanyDefault(t);
                          Navigator.of(ctx).pop();
                        },
                        child: const Text(
                          'Set as Default',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
