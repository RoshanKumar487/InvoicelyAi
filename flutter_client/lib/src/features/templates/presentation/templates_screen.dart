import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../data/template_config.dart';
import 'invoice_template_studio_screen.dart';

/// Production NY Invoice & Template Studio Screen.
/// Combines accordion block customization, industry presets, live A4 preview, and PDF generation.
class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({
    this.apiClient,
    this.initialConfig,
    this.initialLocalSettings = const <String, Object?>{},
    this.onSaveLocalSettings,
    this.onBack,
    this.onSave,
    super.key,
  });

  final ApiClient? apiClient;
  final TemplateConfig? initialConfig;
  final Map<String, Object?> initialLocalSettings;
  final ValueChanged<Map<String, Object?>>? onSaveLocalSettings;
  final VoidCallback? onBack;
  final ValueChanged<TemplateConfig>? onSave;

  @override
  Widget build(BuildContext context) {
    if (apiClient == null) {
      return const Scaffold(
        body: Center(child: Text('API client is required.')),
      );
    }

    return InvoiceTemplateStudioScreen(
      apiClient: apiClient!,
      initialConfig: initialConfig,
      initialLocalSettings: initialLocalSettings,
      onSaveLocalSettings: onSaveLocalSettings,
      onSaveTemplate: onSave,
      onBack: onBack,
    );
  }
}
