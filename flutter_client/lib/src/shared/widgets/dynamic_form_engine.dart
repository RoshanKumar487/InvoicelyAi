import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'app_card.dart';

/// Supported low-code field types.
enum DynamicFormFieldType {
  text,
  number,
  currency,
  date,
  select,
  checkbox,
  switchType,
  textarea,
  email,
  phone;

  static DynamicFormFieldType fromString(String val) {
    switch (val.toLowerCase().trim()) {
      case 'number':
        return DynamicFormFieldType.number;
      case 'currency':
        return DynamicFormFieldType.currency;
      case 'date':
        return DynamicFormFieldType.date;
      case 'select':
      case 'dropdown':
        return DynamicFormFieldType.select;
      case 'checkbox':
        return DynamicFormFieldType.checkbox;
      case 'switch':
        return DynamicFormFieldType.switchType;
      case 'textarea':
        return DynamicFormFieldType.textarea;
      case 'email':
        return DynamicFormFieldType.email;
      case 'phone':
        return DynamicFormFieldType.phone;
      case 'text':
      default:
        return DynamicFormFieldType.text;
    }
  }
}

/// Select dropdown option.
class DynamicFieldOption {
  const DynamicFieldOption({required this.label, required this.value});

  final String label;
  final dynamic value;

  factory DynamicFieldOption.fromJson(Map<String, dynamic> json) {
    return DynamicFieldOption(
      label: json['label']?.toString() ?? '',
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() => {'label': label, 'value': value};
}

/// Configuration for an individual field in the low-code form.
class DynamicFormFieldConfig {
  const DynamicFormFieldConfig({
    required this.name,
    required this.label,
    this.type = DynamicFormFieldType.text,
    this.initialValue,
    this.placeholder,
    this.helperText,
    this.required = false,
    this.readOnly = false,
    this.prefixIcon,
    this.currencySymbol = '₹',
    this.options = const [],
    this.colSpan = 1, // 1: half width on >=600px screen, 2: full width
    this.min,
    this.max,
    this.regexPattern,
    this.regexError,
    this.dependsOn,
    this.dependsOnValue,
  });

  final String name;
  final String label;
  final DynamicFormFieldType type;
  final dynamic initialValue;
  final String? placeholder;
  final String? helperText;
  final bool required;
  final bool readOnly;
  final IconData? prefixIcon;
  final String currencySymbol;
  final List<DynamicFieldOption> options;
  final int colSpan;
  final num? min;
  final num? max;
  final String? regexPattern;
  final String? regexError;
  final String? dependsOn;
  final dynamic dependsOnValue;

  factory DynamicFormFieldConfig.fromJson(Map<String, dynamic> json) {
    return DynamicFormFieldConfig(
      name: json['name']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      type: DynamicFormFieldType.fromString(json['type']?.toString() ?? 'text'),
      initialValue: json['initialValue'],
      placeholder: json['placeholder']?.toString(),
      helperText: json['helperText']?.toString(),
      required: json['required'] == true,
      readOnly: json['readOnly'] == true,
      currencySymbol: json['currencySymbol']?.toString() ?? '₹',
      options: (json['options'] as List<dynamic>?)
              ?.map((o) => DynamicFieldOption.fromJson(o as Map<String, dynamic>))
              .toList() ??
          const [],
      colSpan: json['colSpan'] is int ? json['colSpan'] as int : 1,
      min: json['min'] as num?,
      max: json['max'] as num?,
      regexPattern: json['regexPattern']?.toString(),
      regexError: json['regexError']?.toString(),
      dependsOn: json['dependsOn']?.toString(),
      dependsOnValue: json['dependsOnValue'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'label': label,
        'type': type.name,
        'initialValue': initialValue,
        'placeholder': placeholder,
        'helperText': helperText,
        'required': required,
        'readOnly': readOnly,
        'currencySymbol': currencySymbol,
        'options': options.map((o) => o.toJson()).toList(),
        'colSpan': colSpan,
        'min': min,
        'max': max,
        'regexPattern': regexPattern,
        'regexError': regexError,
        'dependsOn': dependsOn,
        'dependsOnValue': dependsOnValue,
      };
}

/// Logical grouping of fields.
class DynamicFormSection {
  const DynamicFormSection({
    required this.title,
    this.description,
    this.icon,
    required this.fields,
  });

  final String title;
  final String? description;
  final IconData? icon;
  final List<DynamicFormFieldConfig> fields;

  factory DynamicFormSection.fromJson(Map<String, dynamic> json) {
    return DynamicFormSection(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      fields: (json['fields'] as List<dynamic>?)
              ?.map((f) => DynamicFormFieldConfig.fromJson(f as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'fields': fields.map((f) => f.toJson()).toList(),
      };
}

/// Root schema for the entire dynamic form.
class DynamicFormSchema {
  const DynamicFormSchema({
    required this.title,
    this.subtitle,
    required this.sections,
    this.submitLabel = 'Save Changes',
    this.cancelLabel = 'Cancel',
  });

  final String title;
  final String? subtitle;
  final List<DynamicFormSection> sections;
  final String submitLabel;
  final String cancelLabel;

  factory DynamicFormSchema.fromJson(Map<String, dynamic> json) {
    return DynamicFormSchema(
      title: json['title']?.toString() ?? 'Dynamic Form',
      subtitle: json['subtitle']?.toString(),
      submitLabel: json['submitLabel']?.toString() ?? 'Save Changes',
      cancelLabel: json['cancelLabel']?.toString() ?? 'Cancel',
      sections: (json['sections'] as List<dynamic>?)
              ?.map((s) => DynamicFormSection.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'submitLabel': submitLabel,
        'cancelLabel': cancelLabel,
        'sections': sections.map((s) => s.toJson()).toList(),
      };
}

/// The Dynamic Form Engine widget.
class DynamicFormEngine extends StatefulWidget {
  const DynamicFormEngine({
    required this.schema,
    this.initialValues,
    required this.onSubmit,
    this.onCancel,
    this.onValuesChanged,
    super.key,
  });

  final DynamicFormSchema schema;
  final Map<String, dynamic>? initialValues;
  final Future<void> Function(Map<String, dynamic> formJson) onSubmit;
  final VoidCallback? onCancel;
  final ValueChanged<Map<String, dynamic>>? onValuesChanged;

  @override
  State<DynamicFormEngine> createState() => _DynamicFormEngineState();
}

class _DynamicFormEngineState extends State<DynamicFormEngine> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formValues = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeFormValues();
  }

  void _initializeFormValues() {
    if (widget.initialValues != null) {
      _formValues.addAll(widget.initialValues!);
    }

    for (final section in widget.schema.sections) {
      for (final field in section.fields) {
        if (!_formValues.containsKey(field.name)) {
          if (field.initialValue != null) {
            _formValues[field.name] = field.initialValue;
          } else {
            switch (field.type) {
              case DynamicFormFieldType.checkbox:
              case DynamicFormFieldType.switchType:
                _formValues[field.name] = false;
                break;
              default:
                _formValues[field.name] = '';
            }
          }
        }

        // Initialize text controller for text-based inputs
        if (_isTextType(field.type)) {
          final initialText = _formValues[field.name]?.toString() ?? '';
          _controllers[field.name] = TextEditingController(text: initialText);
        }
      }
    }
  }

  bool _isTextType(DynamicFormFieldType type) {
    return type == DynamicFormFieldType.text ||
        type == DynamicFormFieldType.number ||
        type == DynamicFormFieldType.currency ||
        type == DynamicFormFieldType.textarea ||
        type == DynamicFormFieldType.email ||
        type == DynamicFormFieldType.phone;
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _shouldShowField(DynamicFormFieldConfig field) {
    if (field.dependsOn == null) return true;
    final parentVal = _formValues[field.dependsOn];
    if (field.dependsOnValue == null) {
      return parentVal != null && parentVal != false && parentVal != '';
    }
    return parentVal == field.dependsOnValue;
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    // Sync all text controllers into values map
    for (final entry in _controllers.entries) {
      final field = _findFieldConfig(entry.key);
      if (field != null) {
        if (field.type == DynamicFormFieldType.number || field.type == DynamicFormFieldType.currency) {
          final numVal = num.tryParse(entry.value.text.trim());
          _formValues[entry.key] = numVal ?? entry.value.text.trim();
        } else {
          _formValues[entry.key] = entry.value.text.trim();
        }
      }
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.onSubmit(Map<String, dynamic>.from(_formValues));
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  DynamicFormFieldConfig? _findFieldConfig(String name) {
    for (final sec in widget.schema.sections) {
      for (final f in sec.fields) {
        if (f.name == name) return f;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF87171)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              for (final section in widget.schema.sections) ...[
                _buildSection(section, isWide),
                const SizedBox(height: 18),
              ],
              const SizedBox(height: 8),
              _buildActionFooter(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(DynamicFormSection section, bool isWide) {
    final visibleFields = section.fields.where(_shouldShowField).toList();
    if (visibleFields.isEmpty) return const SizedBox.shrink();

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (section.icon != null) ...[
                Icon(section.icon, size: 20, color: const Color(0xFF0284C7)),
                const SizedBox(width: 8),
              ],
              Text(
                section.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          if (section.description != null) ...[
            const SizedBox(height: 4),
            Text(
              section.description!,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 14,
            children: visibleFields.map((field) {
              final double width = (!isWide || field.colSpan == 2)
                  ? double.infinity
                  : (MediaQuery.sizeOf(context).width > 700 ? 320 : double.infinity);

              return SizedBox(
                width: width,
                child: _buildFieldWidget(field),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldWidget(DynamicFormFieldConfig field) {
    switch (field.type) {
      case DynamicFormFieldType.select:
        return _buildDropdownField(field);
      case DynamicFormFieldType.checkbox:
        return _buildCheckboxField(field);
      case DynamicFormFieldType.switchType:
        return _buildSwitchField(field);
      case DynamicFormFieldType.date:
        return _buildDateField(field);
      case DynamicFormFieldType.text:
      case DynamicFormFieldType.number:
      case DynamicFormFieldType.currency:
      case DynamicFormFieldType.textarea:
      case DynamicFormFieldType.email:
      case DynamicFormFieldType.phone:
        return _buildTextualField(field);
    }
  }

  Widget _buildTextualField(DynamicFormFieldConfig field) {
    final controller = _controllers[field.name];

    TextInputType keyboardType = TextInputType.text;
    if (field.type == DynamicFormFieldType.number || field.type == DynamicFormFieldType.currency) {
      keyboardType = const TextInputType.numberWithOptions(decimal: true);
    } else if (field.type == DynamicFormFieldType.email) {
      keyboardType = TextInputType.emailAddress;
    } else if (field.type == DynamicFormFieldType.phone) {
      keyboardType = TextInputType.phone;
    } else if (field.type == DynamicFormFieldType.textarea) {
      keyboardType = TextInputType.multiline;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(field),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: field.readOnly,
          keyboardType: keyboardType,
          maxLines: field.type == DynamicFormFieldType.textarea ? 3 : 1,
          decoration: InputDecoration(
            hintText: field.placeholder ?? 'Enter ${field.label.toLowerCase()}',
            helperText: field.helperText,
            helperMaxLines: 2,
            prefixIcon: field.prefixIcon != null
                ? Icon(field.prefixIcon, size: 18)
                : (field.type == DynamicFormFieldType.currency
                    ? Padding(
                        padding: const EdgeInsets.only(left: 12, right: 6),
                        child: Text(
                          field.currencySymbol,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      )
                    : null),
            prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 0),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (val) => _validateFieldValue(field, val),
          onChanged: (val) {
            _formValues[field.name] = val;
            widget.onValuesChanged?.call(Map<String, dynamic>.from(_formValues));
          },
        ),
      ],
    );
  }

  Widget _buildDropdownField(DynamicFormFieldConfig field) {
    final currentVal = _formValues[field.name];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(field),
        const SizedBox(height: 6),
        DropdownButtonFormField<dynamic>(
          initialValue: field.options.any((o) => o.value == currentVal) ? currentVal : null,
          items: field.options.map((opt) {
            return DropdownMenuItem<dynamic>(
              value: opt.value,
              child: Text(opt.label, style: const TextStyle(fontSize: 13)),
            );
          }).toList(),
          decoration: InputDecoration(
            hintText: field.placeholder ?? 'Select ${field.label.toLowerCase()}',
            helperText: field.helperText,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (val) {
            if (field.required && (val == null || val == '')) {
              return '${field.label} is required';
            }
            return null;
          },
          onChanged: field.readOnly
              ? null
              : (val) {
                  setState(() {
                    _formValues[field.name] = val;
                  });
                  widget.onValuesChanged?.call(Map<String, dynamic>.from(_formValues));
                },
        ),
      ],
    );
  }

  Widget _buildDateField(DynamicFormFieldConfig field) {
    final currentVal = _formValues[field.name]?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(field),
        const SizedBox(height: 6),
        InkWell(
          onTap: field.readOnly
              ? null
              : () async {
                  final initial = DateTime.tryParse(currentVal) ?? DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    final dateStr =
                        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                    setState(() {
                      _formValues[field.name] = dateStr;
                    });
                    widget.onValuesChanged?.call(Map<String, dynamic>.from(_formValues));
                  }
                },
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: field.placeholder ?? 'YYYY-MM-DD',
              helperText: field.helperText,
              prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              currentVal.isNotEmpty ? currentVal : (field.placeholder ?? 'Select date'),
              style: TextStyle(
                fontSize: 13,
                color: currentVal.isNotEmpty ? const Color(0xFF0F172A) : AppColors.muted,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxField(DynamicFormFieldConfig field) {
    final bool checked = _formValues[field.name] == true;

    return Row(
      children: [
        Checkbox(
          value: checked,
          onChanged: field.readOnly
              ? null
              : (val) {
                  setState(() {
                    _formValues[field.name] = val == true;
                  });
                  widget.onValuesChanged?.call(Map<String, dynamic>.from(_formValues));
                },
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                field.label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              if (field.helperText != null)
                Text(
                  field.helperText!,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchField(DynamicFormFieldConfig field) {
    final bool switched = _formValues[field.name] == true;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                field.label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              if (field.helperText != null)
                Text(
                  field.helperText!,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
            ],
          ),
        ),
        Switch(
          value: switched,
          onChanged: field.readOnly
              ? null
              : (val) {
                  setState(() {
                    _formValues[field.name] = val;
                  });
                  widget.onValuesChanged?.call(Map<String, dynamic>.from(_formValues));
                },
        ),
      ],
    );
  }

  Widget _buildFieldLabel(DynamicFormFieldConfig field) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          field.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        if (field.required)
          const Text(
            ' *',
            style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  String? _validateFieldValue(DynamicFormFieldConfig field, String? val) {
    final text = val?.trim() ?? '';
    if (field.required && text.isEmpty) {
      return '${field.label} is required';
    }

    if (text.isNotEmpty) {
      if (field.type == DynamicFormFieldType.number || field.type == DynamicFormFieldType.currency) {
        final parsed = num.tryParse(text);
        if (parsed == null) {
          return 'Please enter a valid numeric value';
        }
        if (field.min != null && parsed < field.min!) {
          return 'Value must be at least ${field.min}';
        }
        if (field.max != null && parsed > field.max!) {
          return 'Value must be at most ${field.max}';
        }
      }

      if (field.type == DynamicFormFieldType.email) {
        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
        if (!emailRegex.hasMatch(text)) {
          return 'Please enter a valid email address';
        }
      }

      if (field.regexPattern != null) {
        final reg = RegExp(field.regexPattern!);
        if (!reg.hasMatch(text)) {
          return field.regexError ?? 'Invalid format';
        }
      }
    }

    return null;
  }

  Widget _buildActionFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.onCancel != null) ...[
          OutlinedButton(
            onPressed: _isSubmitting ? null : widget.onCancel,
            child: Text(widget.schema.cancelLabel),
          ),
          const SizedBox(width: 12),
        ],
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _handleSubmit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_circle_outline, size: 18),
          label: Text(widget.schema.submitLabel),
        ),
      ],
    );
  }
}

/// Dialog wrapper to pop open any dynamic schema-driven form.
class DynamicFormDialog extends StatelessWidget {
  const DynamicFormDialog({
    required this.schema,
    this.initialValues,
    super.key,
  });

  final DynamicFormSchema schema;
  final Map<String, dynamic>? initialValues;

  static Future<Map<String, dynamic>?> show({
    required BuildContext context,
    required DynamicFormSchema schema,
    Map<String, dynamic>? initialValues,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DynamicFormDialog(
        schema: schema,
        initialValues: initialValues,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 850),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schema.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (schema.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            schema.subtitle!,
                            style: const TextStyle(fontSize: 12, color: AppColors.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: DynamicFormEngine(
                    schema: schema,
                    initialValues: initialValues,
                    onCancel: () => Navigator.pop(context),
                    onSubmit: (formJson) async {
                      Navigator.pop(context, formJson);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
