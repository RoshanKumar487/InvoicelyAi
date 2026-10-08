import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/storage/local_preferences.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../theme/app_theme.dart';
import '../data/settings_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.apiClient,
    this.localPreferences,
    this.initialLocalSettings = const <String, Object?>{},
    this.onSaveLocalSettings,
    this.onBack,
    super.key,
  });

  final ApiClient apiClient;
  final LocalPreferences? localPreferences;
  final Map<String, Object?> initialLocalSettings;
  final ValueChanged<Map<String, Object?>>? onSaveLocalSettings;
  final VoidCallback? onBack;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final SettingsRepository _repository;
  Map<String, dynamic> _profile = <String, dynamic>{};
  bool _loading = true;
  bool _saving = false;
  bool _savingBranding = false;
  String? _error;
  late Map<String, Object?> _localSettings;

  static const _editableStringFields = <String, String>{
    'businessName': 'Business name',
    'legalName': 'Legal name',
    'email': 'Business email',
    'phone': 'Phone',
    'website': 'Website',
    'address': 'Business address',
    'taxId': 'Tax ID',
    'gstin': 'GSTIN',
    'panNumber': 'PAN number',
    'placeOfSupply': 'Place of supply',
    'upiId': 'UPI ID',
    'bankName': 'Bank name',
    'accountHolder': 'Account holder',
    'accountNumber': 'Account number',
    'ifscCode': 'IFSC code',
    'routingNumber': 'Routing number',
    'swiftBic': 'SWIFT / BIC',
    'paymentLink': 'Payment link',
    'defaultNotes': 'Default invoice notes',
    'defaultTerms': 'Default invoice terms',
    'signeeName': 'Authorized signatory',
    'signeeTitle': 'Signatory title',
  };

  @override
  void initState() {
    super.initState();
    _localSettings = Map<String, Object?>.from(widget.initialLocalSettings);
    _repository = SettingsRepository(apiClient: widget.apiClient);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _repository.loadProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load business settings: $error';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final result = await _repository.saveProfile(_profile);
      if (!mounted) return;
      setState(() => _profile = result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business settings saved.')),
      );
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } catch (error) {
      if (mounted) _showError('Could not save settings: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveBranding() async {
    final preferences = widget.localPreferences;
    if (preferences == null) {
      _showError('Local settings are unavailable on this device.');
      return;
    }
    setState(() => _savingBranding = true);
    try {
      await preferences.writeMap('invoice_settings', _localSettings);
      widget.onSaveLocalSettings?.call(
        Map<String, Object?>.from(_localSettings),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice branding saved on this device.')),
        );
      }
    } catch (error) {
      if (mounted) _showError('Could not save invoice branding: $error');
    } finally {
      if (mounted) setState(() => _savingBranding = false);
    }
  }

  Future<void> _pickBrandImage(String key, String label) async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        imageQuality: 70,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() => _localSettings[key] = base64Encode(bytes));
    } catch (error) {
      if (mounted) _showError('Could not select $label: $error');
    }
  }

  Future<void> _captureSignature() async {
    final points = await showDialog<List<Offset?>>(
      context: context,
      builder: (context) => const _SignatureDialog(),
    );
    if (points == null || points.isEmpty) return;
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(Colors.white, BlendMode.src);
      const size = Size(700, 220);
      _SignaturePainter(points).paint(canvas, size);
      final picture = recorder.endRecording();
      final image = await picture.toImage(size.width.toInt(), size.height.toInt());
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      picture.dispose();
      if (data == null) throw StateError('Could not render the signature.');
      if (mounted) {
        setState(() => _localSettings['invoiceSignature'] =
            base64Encode(data.buffer.asUint8List()));
      }
    } catch (error) {
      if (mounted) _showError('Could not save signature: $error');
    }
  }

  void _removeBrandingAsset(String key) {
    setState(() => _localSettings.remove(key));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
          title: const Text('Business Settings'),
          actions: [
            IconButton(
              onPressed: _loading || _saving ? null : _save,
              tooltip: 'Save settings',
              icon: const Icon(Icons.save_outlined),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _SettingsError(message: _error!, onRetry: _load)
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Business profile',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 12),
                              ..._editableStringFields.entries.map(
                                (field) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TextFormField(
                                    initialValue:
                                        _profile[field.key]?.toString() ?? '',
                                    decoration: InputDecoration(
                                      labelText: field.value,
                                    ),
                                    keyboardType: field.key == 'email'
                                        ? TextInputType.emailAddress
                                        : field.key == 'address' ||
                                                field.key == 'defaultNotes' ||
                                                field.key == 'defaultTerms'
                                            ? TextInputType.multiline
                                            : TextInputType.text,
                                    maxLines: field.key == 'address' ||
                                            field.key == 'defaultNotes' ||
                                            field.key == 'defaultTerms'
                                        ? 3
                                        : 1,
                                    validator: field.key == 'email'
                                        ? _validateEmail
                                        : null,
                                    onChanged: (value) =>
                                        _profile[field.key] = value,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Invoice branding',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Assets are stored on this device and included in invoice previews and PDFs.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 16),
                              _BrandingAssetTile(
                                label: 'Company logo',
                                base64:
                                    _localSettings['invoiceLogo']?.toString(),
                                onPick: () =>
                                    _pickBrandImage('invoiceLogo', 'logo'),
                                onRemove: () =>
                                    _removeBrandingAsset('invoiceLogo'),
                              ),
                              const SizedBox(height: 10),
                              _BrandingAssetTile(
                                label: 'Company stamp',
                                base64:
                                    _localSettings['invoiceStamp']?.toString(),
                                onPick: () =>
                                    _pickBrandImage('invoiceStamp', 'stamp'),
                                onRemove: () =>
                                    _removeBrandingAsset('invoiceStamp'),
                              ),
                              const SizedBox(height: 10),
                              _BrandingAssetTile(
                                label: 'Authorized signature',
                                base64: _localSettings['invoiceSignature']
                                    ?.toString(),
                                onPick: _captureSignature,
                                onRemove: () =>
                                    _removeBrandingAsset('invoiceSignature'),
                                pickLabel: 'Draw',
                              ),
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton.icon(
                                  onPressed: _savingBranding
                                      ? null
                                      : _saveBranding,
                                  icon: _savingBranding
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.save_outlined),
                                  label: const Text('Save branding'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Currency & invoice defaults',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: _currencyCode,
                                decoration: const InputDecoration(
                                  labelText: 'Default currency',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'INR', child: Text('INR — ₹')),
                                  DropdownMenuItem(
                                      value: 'USD', child: Text('USD — \$')),
                                  DropdownMenuItem(
                                      value: 'EUR', child: Text('EUR — €')),
                                  DropdownMenuItem(
                                      value: 'GBP', child: Text('GBP — £')),
                                  DropdownMenuItem(
                                      value: 'AED', child: Text('AED')),
                                  DropdownMenuItem(
                                      value: 'CAD', child: Text('CAD — C\$')),
                                  DropdownMenuItem(
                                      value: 'AUD', child: Text('AUD — A\$')),
                                  DropdownMenuItem(
                                      value: 'JPY', child: Text('JPY — ¥')),
                                  DropdownMenuItem(
                                      value: 'SGD', child: Text('SGD — S\$')),
                                  DropdownMenuItem(
                                      value: 'SAR', child: Text('SAR')),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _profile['defaultCurrency'] = value;
                                    _profile['defaultCurrencySymbol'] =
                                        _currencySymbols[value] ?? value;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: _currencyFormat,
                                decoration: const InputDecoration(
                                  labelText: 'Currency symbol position',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'before',
                                    child: Text('Prefix (₹ 1,500.00)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'after',
                                    child: Text('Suffix (1,500.00 ₹)'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() =>
                                        _profile['defaultCurrencyFormat'] =
                                            value);
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                initialValue:
                                    _profile['defaultTaxLabel']?.toString() ??
                                        'Tax',
                                decoration: const InputDecoration(
                                  labelText: 'Default tax label',
                                ),
                                onChanged: (value) =>
                                    _profile['defaultTaxLabel'] = value,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                initialValue: _profile['defaultTaxRate']
                                        ?.toString() ??
                                    '0',
                                decoration: const InputDecoration(
                                  labelText: 'Default tax rate (%)',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: _validateRate,
                                onChanged: (value) {
                                  final rate = double.tryParse(value);
                                  if (rate != null) {
                                    _profile['defaultTaxRate'] = rate;
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                initialValue:
                                    _profile['defaultPaymentTerms']?.toString() ??
                                        'Net 30',
                                decoration: const InputDecoration(
                                  labelText: 'Default payment terms',
                                ),
                                onChanged: (value) =>
                                    _profile['defaultPaymentTerms'] = value,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Brand color',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue:
                                    _profile['brandColorHex']?.toString() ??
                                        '#1E3A8A',
                                decoration: const InputDecoration(
                                  labelText: 'Hex color (for example #1E3A8A)',
                                ),
                                validator: _validateHexColor,
                                onChanged: (value) =>
                                    _profile['brandColorHex'] = value,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(_saving ? 'Saving…' : 'Save settings'),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Server URL, account sync controls, invoice deletion and local reset actions are not exposed by the Flutter backend API.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
      );

  String get _currencyCode =>
      _profile['defaultCurrency']?.toString() ?? 'INR';

  String get _currencyFormat =>
      _profile['defaultCurrencyFormat']?.toString() ?? 'before';

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validateRate(String? value) {
    final rate = double.tryParse(value ?? '');
    if (rate == null || rate < 0 || rate > 100) {
      return 'Enter a rate from 0 to 100.';
    }
    return null;
  }

  String? _validateHexColor(String? value) {
    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value?.trim() ?? '')) {
      return 'Use a six-digit hex color such as #1E3A8A.';
    }
    return null;
  }
}

const _currencySymbols = <String, String>{
  'INR': '₹',
  'USD': r'$',
  'EUR': '€',
  'GBP': '£',
  'AED': 'AED',
  'CAD': 'C\$',
  'AUD': 'A\$',
  'JPY': '¥',
  'SGD': 'S\$',
  'SAR': 'SAR',
};

class _BrandingAssetTile extends StatelessWidget {
  const _BrandingAssetTile({
    required this.label,
    required this.base64,
    required this.onPick,
    required this.onRemove,
    this.pickLabel = 'Choose',
  });

  final String label;
  final String? base64;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final String pickLabel;

  @override
  Widget build(BuildContext context) {
    Uint8List? bytes;
    try {
      if (base64 != null && base64!.isNotEmpty) {
        bytes = base64Decode(base64!);
      }
    } on FormatException {
      bytes = null;
    }
    return Row(
      children: [
        Container(
          width: 64,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: bytes == null
              ? const Icon(Icons.image_outlined)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    bytes,
                    width: 62,
                    height: 52,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (bytes != null)
          IconButton(
            tooltip: 'Remove $label',
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
          ),
        OutlinedButton(
          onPressed: onPick,
          child: Text(pickLabel),
        ),
      ],
    );
  }
}

class _SignatureDialog extends StatefulWidget {
  const _SignatureDialog();

  @override
  State<_SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<_SignatureDialog> {
  final List<Offset?> _points = [];

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Draw your signature'),
        content: SizedBox(
          width: (MediaQuery.sizeOf(context).width - 80).clamp(280, 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Sign using your finger or mouse.'),
                  ),
                  IconButton(
                    tooltip: 'Undo last stroke',
                    onPressed: _points.whereType<Offset>().isEmpty
                        ? null
                        : () => setState(_undoStroke),
                    icon: const Icon(Icons.undo),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 3.2,
                child: LayoutBuilder(
                  builder: (context, constraints) => GestureDetector(
                    onPanStart: (event) => setState(
                      () => _points.add(_normalize(
                        event.localPosition,
                        constraints.biggest,
                      )),
                    ),
                    onPanUpdate: (event) => setState(
                      () => _points.add(_normalize(
                        event.localPosition,
                        constraints.biggest,
                      )),
                    ),
                    onPanEnd: (_) => setState(() => _points.add(null)),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: CustomPaint(
                        foregroundPainter: _SignaturePainter(_points),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(_points.clear),
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _points.whereType<Offset>().isEmpty
                ? null
                : () => Navigator.of(context).pop(_points),
            child: const Text('Use signature'),
          ),
        ],
      );

  Offset _normalize(Offset point, Size size) => Offset(
        point.dx / size.width * 700,
        point.dy / size.height * 220,
      );

  void _undoStroke() {
    if (_points.isEmpty) return;
    if (_points.last == null) _points.removeLast();
    while (_points.isNotEmpty && _points.last != null) {
      _points.removeLast();
    }
    if (_points.isNotEmpty) _points.removeLast();
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter(this.points);

  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF172554)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    var drawing = false;
    for (final point in points) {
      if (point == null) {
        drawing = false;
        continue;
      }
      final scaled = Offset(
        point.dx * size.width / 700,
        point.dy * size.height / 220,
      );
      if (!drawing) {
        path.moveTo(scaled.dx, scaled.dy);
        drawing = true;
      } else {
        path.lineTo(scaled.dx, scaled.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) =>
      !identical(points, oldDelegate.points);
}

class _SettingsError extends StatelessWidget {
  const _SettingsError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}
