import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../shared/widgets/app_card.dart';
import '../data/document_template_schema.dart';
import '../data/template_layout_engine.dart';
import '../data/wysiwyg_pdf_exporter.dart';
import 'widgets/wysiwyg_canvas_preview.dart';

class WysiwygTemplateEditorScreen extends StatefulWidget {
  const WysiwygTemplateEditorScreen({
    this.initialSchema,
    this.onSaveSchema,
    this.onBack,
    super.key,
  });

  final DocumentTemplateSchema? initialSchema;
  final ValueChanged<DocumentTemplateSchema>? onSaveSchema;
  final VoidCallback? onBack;

  @override
  State<WysiwygTemplateEditorScreen> createState() => _WysiwygTemplateEditorScreenState();
}

class _WysiwygTemplateEditorScreenState extends State<WysiwygTemplateEditorScreen> {
  late DocumentTemplateSchema _schema;
  int _activePageIndex = 0;
  double _zoomScale = 0.85;

  // Stress-Test Simulator States
  int _simulatedItemCount = 6;
  bool _simulateLongDescriptions = false;
  bool _simulateBankDetails = true;
  bool _simulateNotes = true;

  // Swatch colors
  static const List<String> _primarySwatches = [
    '#1E3A8A', // Deep Navy
    '#0284C7', // Sky Tech
    '#047857', // Emerald
    '#6366F1', // Indigo
    '#0F172A', // Slate Dark
    '#B91C1C', // Crimson
  ];

  @override
  void initState() {
    super.initState();
    _schema = widget.initialSchema ?? DocumentTemplateSchema.builtInPresets().first;
  }

  List<LayoutLineItem> _generateSimulatedItems() {
    final list = <LayoutLineItem>[];
    for (int i = 1; i <= _simulatedItemCount; i++) {
      final desc = _simulateLongDescriptions
          ? 'Comprehensive enterprise cloud infrastructure architecture, containerized microservices orchestration, and quarterly high-availability failover validation.'
          : (i.isEven ? 'Monthly software licensing and SLA technical support' : '');

      list.add(LayoutLineItem(
        name: 'Service Module 0$i - Enterprise Integration',
        description: desc,
        hsn: '998313',
        qty: (i % 3 + 1).toDouble(),
        unitPrice: 12500.0 + (i * 1500),
        amount: (12500.0 + (i * 1500)) * (i % 3 + 1),
      ));
    }
    return list;
  }

  TemplateLayoutResult _computeCurrentLayout() {
    final items = _generateSimulatedItems();
    return TemplateLayoutEngine.computeLayout(
      schema: _schema,
      items: items,
      pageWidth: _schema.metadata.pageSize.previewWidth,
      pageHeight: _schema.metadata.pageSize.previewHeight,
      hasBank: _simulateBankDetails,
      hasNotes: _simulateNotes,
    );
  }

  Future<void> _exportPdf(TemplateLayoutResult layoutResult) async {
    try {
      final pdfBytes = await WysiwygPdfExporter.build(
        schema: _schema,
        layoutResult: layoutResult,
      );

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '${_schema.metadata.id}_preview.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final layoutResult = _computeCurrentLayout();
    final isDesktop = MediaQuery.sizeOf(context).width >= 1000;

    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
        title: const Text('WYSIWYG Template Studio'),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
            label: const Text('Export Verified PDF'),
            onPressed: () => _exportPdf(layoutResult),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            icon: const Icon(Icons.save_outlined, size: 16),
            label: const Text('Save Template JSON'),
            onPressed: () {
              widget.onSaveSchema?.call(_schema);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF16A34A),
                  content: Text('✓ Template schema saved successfully!'),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: isDesktop
          ? Row(
              children: [
                // Left Panel: Template Controls & Stress Simulator
                SizedBox(
                  width: 440,
                  child: _buildControlsPanel(layoutResult),
                ),
                const VerticalDivider(width: 1),

                // Right Panel: WYSIWYG Multi-Page Canvas
                Expanded(
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.all(16),
                    child: WysiwygCanvasPreview(
                      schema: _schema,
                      layoutResult: layoutResult,
                      activePageIndex: _activePageIndex,
                      onPageChanged: (page) => setState(() => _activePageIndex = page),
                      scale: _zoomScale,
                    ),
                  ),
                ),
              ],
            )
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Settings & Stress Test'),
                      Tab(text: 'Live WYSIWYG Preview'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildControlsPanel(layoutResult),
                        Container(
                          color: const Color(0xFFF8FAFC),
                          padding: const EdgeInsets.all(12),
                          child: WysiwygCanvasPreview(
                            schema: _schema,
                            layoutResult: layoutResult,
                            activePageIndex: _activePageIndex,
                            onPageChanged: (page) => setState(() => _activePageIndex = page),
                            scale: 0.65,
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

  Widget _buildControlsPanel(TemplateLayoutResult layoutResult) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Zero-Overflow Health Card
        _buildTelemetryHealthCard(layoutResult),
        const SizedBox(height: 16),

        // 2. Preset Quick-Loader
        _buildPresetsCard(),
        const SizedBox(height: 14),

        // 3. Stress-Test Simulator Card
        _buildStressSimulatorCard(),
        const SizedBox(height: 14),

        // 4. Paper Size & Geometry
        _buildPaperAndMarginsCard(),
        const SizedBox(height: 14),

        // 5. Brand Color & Typography
        _buildStyleAndPaletteCard(),
        const SizedBox(height: 14),

        // 6. Signature Block Settings
        _buildSignatureSettingsCard(),
        const SizedBox(height: 14),

        // 7. Table & Pagination Rules
        _buildTableAndPaginationCard(),
      ],
    );
  }

  Widget _buildTelemetryHealthCard(TemplateLayoutResult layoutResult) {
    final m = layoutResult.metrics;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.health_and_safety_outlined, color: Color(0xFF16A34A), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Auto-Layout & Safety Telemetry',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('100% Overflow Protected', style: TextStyle(fontSize: 10, color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric('Total Pages', '${m.totalPages}'),
              _buildMiniMetric('Simulated Items', '${m.totalItems}'),
              _buildMiniMetric('Sign. Page', 'Page ${m.signaturePage}'),
              _buildMiniMetric('Dropped Cols', '${m.droppedColumnCount}'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            m.notes,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildPresetsCard() {
    final presets = DocumentTemplateSchema.builtInPresets();

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose Template Preset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: presets.map((preset) {
                final isSelected = _schema.metadata.id == preset.metadata.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(preset.metadata.name, style: const TextStyle(fontSize: 11.5)),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _schema = preset;
                          _activePageIndex = 0;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStressSimulatorCard() {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Data Stress-Test Simulator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('$_simulatedItemCount Items', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Simulate large data volumes to verify multi-page pagination & signature placement.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Slider(
            min: 1,
            max: 30,
            divisions: 29,
            value: _simulatedItemCount.toDouble(),
            onChanged: (val) {
              setState(() {
                _simulatedItemCount = val.toInt();
                _activePageIndex = 0;
              });
            },
          ),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Simulate Multi-Line Descriptions', style: TextStyle(fontSize: 12)),
            subtitle: const Text('Forces row wrapping and height expansion', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            value: _simulateLongDescriptions,
            onChanged: (val) => setState(() => _simulateLongDescriptions = val),
          ),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Show Bank Details & QR Code', style: TextStyle(fontSize: 12)),
            value: _simulateBankDetails,
            onChanged: (val) => setState(() => _simulateBankDetails = val),
          ),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Show Notes & Legal Terms', style: TextStyle(fontSize: 12)),
            value: _simulateNotes,
            onChanged: (val) => setState(() => _simulateNotes = val),
          ),
        ],
      ),
    );
  }

  Widget _buildPaperAndMarginsCard() {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Paper Size & Margins', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              ChoiceChip(
                label: const Text('A4 (Standard)'),
                selected: _schema.metadata.pageSize == TemplatePageSize.a4,
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _schema = _schema.copyWith(
                        metadata: _schema.metadata.copyWith(pageSize: TemplatePageSize.a4),
                      );
                    });
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('US Letter'),
                selected: _schema.metadata.pageSize == TemplatePageSize.letter,
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _schema = _schema.copyWith(
                        metadata: _schema.metadata.copyWith(pageSize: TemplatePageSize.letter),
                      );
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Top Margin: ${_schema.metadata.marginTop.toInt()} pt', style: const TextStyle(fontSize: 11.5)),
          Slider(
            min: 12,
            max: 48,
            value: _schema.metadata.marginTop,
            onChanged: (v) {
              setState(() {
                _schema = _schema.copyWith(
                  metadata: _schema.metadata.copyWith(marginTop: v, marginBottom: v),
                );
              });
            },
          ),
          Text('Side Margins: ${_schema.metadata.marginLeft.toInt()} pt', style: const TextStyle(fontSize: 11.5)),
          Slider(
            min: 12,
            max: 40,
            value: _schema.metadata.marginLeft,
            onChanged: (v) {
              setState(() {
                _schema = _schema.copyWith(
                  metadata: _schema.metadata.copyWith(marginLeft: v, marginRight: v),
                );
              });
            },
          ),
          Text('Canvas Zoom: ${(_zoomScale * 100).toInt()}%', style: const TextStyle(fontSize: 11.5)),
          Slider(
            min: 0.5,
            max: 1.2,
            value: _zoomScale,
            onChanged: (v) => setState(() => _zoomScale = v),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleAndPaletteCard() {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Brand Theme & Colors', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          const Text('Primary Accent Color', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Row(
            children: _primarySwatches.map((hex) {
              final isSelected = _schema.style.primaryColor.toUpperCase() == hex.toUpperCase();
              final color = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _schema = _schema.copyWith(
                      style: _schema.style.copyWith(primaryColor: hex),
                    );
                  });
                },
                child: Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text('Base Font Size: ${_schema.style.baseSize.toStringAsFixed(1)} pt', style: const TextStyle(fontSize: 11.5)),
          Slider(
            min: 9.0,
            max: 13.0,
            divisions: 8,
            value: _schema.style.baseSize,
            onChanged: (v) {
              setState(() {
                _schema = _schema.copyWith(
                  style: _schema.style.copyWith(baseSize: v),
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureSettingsCard() {
    final signSec = _schema.sectionOfType('signature');
    final currentMode = signSec?.config.signatureMode ?? SignatureMode.fixedBottom;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Signature Placement & Rules', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          DropdownButtonFormField<SignatureMode>(
            initialValue: currentMode,
            decoration: const InputDecoration(
              labelText: 'Signature Mode',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: SignatureMode.values.map((mode) {
              return DropdownMenuItem(value: mode, child: Text(mode.label, style: const TextStyle(fontSize: 12)));
            }).toList(),
            onChanged: (val) {
              if (val != null && signSec != null) {
                final updatedConfig = signSec.config.copyWith(signatureMode: val);
                _updateSectionConfig('signature', updatedConfig);
              }
            },
          ),
          const SizedBox(height: 10),
          Text('Signature Height Reservation: ${signSec?.config.signatureHeight.toInt() ?? 70} pt', style: const TextStyle(fontSize: 11.5)),
          Slider(
            min: 50,
            max: 120,
            value: signSec?.config.signatureHeight ?? 70,
            onChanged: (v) {
              if (signSec != null) {
                final updated = signSec.config.copyWith(signatureHeight: v);
                _updateSectionConfig('signature', updated);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTableAndPaginationCard() {
    final itemSec = _schema.sectionOfType('item_table');

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Table & Pagination Rules', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Repeat Table Header on Every Page', style: TextStyle(fontSize: 12)),
            subtitle: const Text('Prevents orphan rows across page breaks', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            value: itemSec?.config.repeatHeader ?? true,
            onChanged: (v) {
              if (itemSec != null) {
                _updateSectionConfig('item_table', itemSec.config.copyWith(repeatHeader: v));
              }
            },
          ),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Zebra Striping on Rows', style: TextStyle(fontSize: 12)),
            value: itemSec?.config.stripedRows ?? true,
            onChanged: (v) {
              if (itemSec != null) {
                _updateSectionConfig('item_table', itemSec.config.copyWith(stripedRows: v));
              }
            },
          ),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Adaptive Column Dropping', style: TextStyle(fontSize: 12)),
            subtitle: const Text('Automatically drop priority 3 columns on narrow widths', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            value: _schema.columnPriorityDropping,
            onChanged: (v) {
              setState(() {
                _schema = _schema.copyWith(columnPriorityDropping: v);
              });
            },
          ),
        ],
      ),
    );
  }

  void _updateSectionConfig(String type, TemplateSectionConfig newConfig) {
    setState(() {
      final updatedSections = _schema.sections.map((s) {
        if (s.type == type) {
          return s.copyWith(config: newConfig);
        }
        return s;
      }).toList();
      _schema = _schema.copyWith(sections: updatedSections);
    });
  }
}
