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
          title: const Text('DOCX Templates & Editor'),
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
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Choose a template',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _presetId,
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
                        childAspectRatio: 1.5,
                        children: templatePresets.map((preset) {
                          final color = _parseColor(preset.color);
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
                                  Container(
                                    width: 30,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  Text(
                                    preset.name,
                                    maxLines: 2,
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
                    value: _config.font,
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
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.description_outlined,
                          color: AppColors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Live preview',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (_saved)
                        const Chip(
                          label: Text('Applied'),
                          avatar: Icon(Icons.check, size: 16),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (_config.showLogo)
                              CircleAvatar(
                                backgroundColor: _parseColor(_config.color),
                                child: const Icon(Icons.business,
                                    color: Colors.white, size: 18),
                              ),
                            const Spacer(),
                            Text(
                              _config.title.isEmpty ? 'INVOICE' : _config.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: _parseColor(_config.color),
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const Divider(height: 28),
                        Text(_config.itemHeader),
                        const SizedBox(height: 6),
                        const Divider(),
                        const Text('Sample service                   1 × 100.00'),
                        if (_config.showTaxBreakdown)
                          const Text('Tax                                     10.00'),
                        if (_config.showPaymentInstructions)
                          const Text('Payment instructions appear here.'),
                        if (_config.showSignature)
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text('Authorized signature'),
                          ),
                        const SizedBox(height: 12),
                        Text(_config.footer,
                            style: const TextStyle(color: AppColors.muted)),
                      ],
                    ),
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
              label: const Text('Apply & Save'),
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

Color _parseColor(String hex) {
  final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
  return value == null ? AppColors.primary : Color(0xFF000000 | value);
}
