import 'package:flutter/material.dart';

import '../../../shared/widgets/app_card.dart';
import '../../../theme/app_theme.dart';
import '../data/template_config.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({
    this.initialConfig,
    this.onBack,
    this.onSave,
    super.key,
  });

  final TemplateConfig? initialConfig;
  final VoidCallback? onBack;
  final ValueChanged<TemplateConfig>? onSave;

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  late TemplateConfig _config;
  String _presetId = 'gst_tax';
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig ??
        templatePresets.firstWhere((preset) => preset.id == 'gst_tax');
    _presetId = templatePresets.any((preset) => preset.id == _config.id)
        ? _config.id
        : 'gst_tax';
  }

  void _selectPreset(String? id) {
    if (id == null) return;
    final preset = templatePresets.firstWhere((template) => template.id == id);
    setState(() {
      _presetId = id;
      _config = preset;
      _saved = false;
    });
  }

  void _save() {
    if (_colorError(_config.color) != null ||
        _colorError(_config.secondaryColor) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid six-digit primary brand color.'),
        ),
      );
      return;
    }
    widget.onSave?.call(_config);
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.onSave == null
            ? 'Template updated for this screen session only.'
            : 'Template configuration applied.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: widget.onBack == null
              ? null
              : IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
          title: const Text('Invoice templates'),
          actions: [
            IconButton(
              onPressed: _save,
              tooltip: 'Apply template',
              icon: const Icon(Icons.check),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _samplePreview(context),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Choose your default template',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Preview the sample above, then select the style you want on new invoices.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey<String>(_presetId),
                    initialValue: _presetId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Preset'),
                    items: templatePresets
                        .map(
                          (template) => DropdownMenuItem<String>(
                            value: template.id,
                            child: Text(
                              '${template.name} • ${template.category}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _selectPreset,
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final count = constraints.maxWidth > 620 ? 4 : 2;
                      return GridView.count(
                        crossAxisCount: count,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.35,
                        children: templatePresets.map((preset) {
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _selectPreset(preset.id),
                            child: AppCard(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _TemplateThumbnail(
                                    template: preset,
                                    selected: preset.id == _presetId,
                                  ),
                                  Text(
                                    '${preset.name}\n${preset.category}',
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                  if (preset.id == _presetId)
                                    const Align(
                                      alignment: Alignment.centerRight,
                                      child: Icon(
                                        Icons.check_circle,
                                        size: 18,
                                        color: AppColors.paid,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Document details',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _textField(
                    label: 'Invoice document title',
                    value: _config.title,
                    onChanged: (value) => _update(_config.copyWith(title: value)),
                  ),
                  const SizedBox(height: 10),
                  _textField(
                    label: 'Description header',
                    value: _config.itemHeader,
                    onChanged: (value) =>
                        _update(_config.copyWith(itemHeader: value)),
                  ),
                  const SizedBox(height: 10),
                  _textField(
                    label: 'Quantity header',
                    value: _config.quantityHeader,
                    onChanged: (value) => _update(
                      _config.copyWith(quantityHeader: value),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _textField(
                    label: 'Rate header',
                    value: _config.rateHeader,
                    onChanged: (value) =>
                        _update(_config.copyWith(rateHeader: value)),
                  ),
                  const SizedBox(height: 10),
                  _textField(
                    label: 'Amount header',
                    value: _config.amountHeader,
                    onChanged: (value) =>
                        _update(_config.copyWith(amountHeader: value)),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    key: ValueKey<String>('font-${_config.font}'),
                    initialValue: _config.font,
                    decoration: const InputDecoration(labelText: 'Font'),
                    items: const [
                      DropdownMenuItem(value: 'Calibri', child: Text('Calibri')),
                      DropdownMenuItem(value: 'Arial', child: Text('Arial')),
                      DropdownMenuItem(
                        value: 'Times New Roman',
                        child: Text('Times New Roman'),
                      ),
                      DropdownMenuItem(
                        value: 'Consolas',
                        child: Text('Consolas'),
                      ),
                    ],
                    onChanged: (font) {
                      if (font != null) {
                        _update(_config.copyWith(font: font));
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _textField(
                    label: 'Primary brand color',
                    value: _config.color,
                    onChanged: (value) => _update(_config.copyWith(color: value)),
                    validator: _colorError,
                  ),
                  const SizedBox(height: 10),
                  _textField(
                    label: 'Secondary brand color',
                    value: _config.secondaryColor,
                    onChanged: (value) => _update(
                      _config.copyWith(secondaryColor: value),
                    ),
                    validator: _colorError,
                  ),
                  const SizedBox(height: 10),
                  _textField(
                    label: 'Custom footer note',
                    value: _config.footer,
                    maxLines: 3,
                    onChanged: (value) => _update(_config.copyWith(footer: value)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show logo'),
                    value: _config.showLogo,
                    onChanged: (value) =>
                        _update(_config.copyWith(showLogo: value)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show tax rate breakdown'),
                    value: _config.showTaxBreakdown,
                    onChanged: (value) =>
                        _update(_config.copyWith(showTaxBreakdown: value)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show payment instructions'),
                    value: _config.showPaymentInstructions,
                    onChanged: (value) => _update(
                      _config.copyWith(showPaymentInstructions: value),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show authorized signature block'),
                    value: _config.showSignature,
                    onChanged: (value) =>
                        _update(_config.copyWith(showSignature: value)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Templates are client-side presets. The backend has no template storage or DOCX export endpoint; pass onSave to connect this editor to your app’s local state.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(_saved ? 'Default template saved' : 'Set as default'),
            ),
          ],
        ),
      );

  Widget _samplePreview(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.preview_outlined, color: AppColors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Template sample',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (_saved)
                  const Chip(
                    label: Text('Default'),
                    avatar: Icon(Icons.check, size: 16),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_config.name} · ${_config.category}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A0F172A),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_config.showLogo)
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: _parseColor(_config.color),
                          child: const Icon(
                            Icons.business,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                      const Spacer(),
                      Text(
                        _config.title.isEmpty ? 'INVOICE' : _config.title,
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: _parseColor(_config.color),
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: _parseColor(_config.secondaryColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'BILL TO  ·  ACME STUDIO',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 7),
                    color: _parseColor(_config.color).withValues(alpha: 0.08),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            _config.itemHeader,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          '${_config.quantityHeader}     ${_config.amountHeader}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _PreviewLine(label: 'Professional services'),
                  const _PreviewLine(label: 'Project delivery'),
                  const Divider(height: 18),
                  if (_config.showTaxBreakdown)
                    const _PreviewLine(label: 'Tax 10%', amount: '10.00'),
                  const _PreviewLine(
                    label: 'TOTAL',
                    amount: '110.00',
                    bold: true,
                  ),
                  if (_config.showPaymentInstructions) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Payment instructions appear here',
                      style: TextStyle(fontSize: 9, color: AppColors.muted),
                    ),
                  ],
                  if (_config.showSignature) ...[
                    const SizedBox(height: 14),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Authorized signature',
                        style: TextStyle(
                          fontSize: 9,
                          fontStyle: FontStyle.italic,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Review this sample first. Choosing a card below updates the sample; save to make that template the default.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );

  Widget _textField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        key: ValueKey<String>('$_presetId:$label'),
        initialValue: value,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        validator: validator,
        onChanged: onChanged,
      );

  void _update(TemplateConfig config) {
    setState(() {
      _config = config;
      _saved = false;
    });
  }

  String? _colorError(String? value) {
    return RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value?.trim() ?? '')
        ? null
        : 'Enter a six-digit color such as #1E3A8A.';
  }
}

class _TemplateThumbnail extends StatelessWidget {
  const _TemplateThumbnail({
    required this.template,
    required this.selected,
  });

  final TemplateConfig template;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(template.color);
    return Container(
      height: 66,
      width: double.infinity,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: selected ? color : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (template.showLogo)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              const Spacer(),
              Container(
                width: 38,
                height: 5,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Container(height: 4, color: color.withValues(alpha: 0.14)),
          const SizedBox(height: 5),
          for (var index = 0; index < 3; index++) ...[
            Row(
              children: [
                Expanded(
                  flex: index == 0 ? 3 : 2,
                  child: Container(
                    height: 3,
                    color: const Color(0xFFCBD5E1),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 18,
                  height: 3,
                  color: const Color(0xFFE2E8F0),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({
    required this.label,
    this.amount = '100.00',
    this.bold = false,
  });

  final String label;
  final String amount;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
                ),
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontSize: 10,
                fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
}

Color _parseColor(String hex) {
  final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
  return value == null ? AppColors.primary : Color(0xFF000000 | value);
}
