import 'package:flutter/material.dart';

import '../../data/invoice.dart';
import 'invoice_editor_components.dart';

String _num(double value) =>
    value == value.truncateToDouble() ? value.toInt().toString() : '$value';

class ItemSuggestion {
  final String title;
  final String subtitle;
  final String defaultDetails;
  final double? defaultRate;
  final String? defaultUnit;
  final double? defaultDuty;
  final IconData icon;

  const ItemSuggestion({
    required this.title,
    required this.subtitle,
    required this.defaultDetails,
    this.defaultRate,
    this.defaultUnit,
    this.defaultDuty,
    this.icon = Icons.shield_outlined,
  });
}

const securitySuggestions = <ItemSuggestion>[
  ItemSuggestion(
    title: 'Security Guard (12 Hrs Shift)',
    subtitle: '12-Hour Shift • Unarmed Uniformed Guard',
    defaultDetails:
        'Deployment of uniformed security guard for 12 hours shift. Access control, gatekeeping, and premise surveillance.',
    defaultUnit: 'Duty',
    defaultDuty: 26,
    defaultRate: 18500,
    icon: Icons.security,
  ),
  ItemSuggestion(
    title: 'Security Guard (8 Hrs Shift)',
    subtitle: '8-Hour Shift • Commercial / Corporate Guard',
    defaultDetails:
        'Deployment of trained security guard for 8 hours shift. Visitor monitoring and perimeter patrolling.',
    defaultUnit: 'Duty',
    defaultDuty: 26,
    defaultRate: 15000,
    icon: Icons.shield_outlined,
  ),
  ItemSuggestion(
    title: 'Security Supervisor',
    subtitle: 'Post In-Charge • Shift Operations & Briefing',
    defaultDetails:
        'Overall supervision of security personnel, deployment management, incident escalation, and daily report log.',
    defaultUnit: 'Duty',
    defaultDuty: 26,
    defaultRate: 24000,
    icon: Icons.local_police_outlined,
  ),
  ItemSuggestion(
    title: 'Gunman / Armed Guard',
    subtitle: 'Armed Security • Vault & Cash Escort',
    defaultDetails:
        'Deployment of licensed armed gunman with weapon for high-security areas, cash transport, or executive protection.',
    defaultUnit: 'Duty',
    defaultDuty: 26,
    defaultRate: 28000,
    icon: Icons.verified_user_outlined,
  ),
  ItemSuggestion(
    title: 'Head Guard / Chief Guard',
    subtitle: 'Site Leadership • Shift Coordination',
    defaultDetails:
        'Site head guard responsible for main gate registers, key management, and shift roster execution.',
    defaultUnit: 'Duty',
    defaultDuty: 26,
    defaultRate: 21000,
    icon: Icons.person_pin_outlined,
  ),
  ItemSuggestion(
    title: 'Lady Security Guard',
    subtitle: 'Female Screening • Reception / Staff Gate',
    defaultDetails:
        'Deployment of female security guard for female staff/visitor frisking, reception assistance, and women safety.',
    defaultUnit: 'Duty',
    defaultDuty: 26,
    defaultRate: 17500,
    icon: Icons.female_outlined,
  ),
  ItemSuggestion(
    title: 'Bouncer / Event Security',
    subtitle: 'Physical Security • Crowd Control & VIP',
    defaultDetails:
        'Heavy physical security bouncer for crowd management, VIP escort, event access, and conflict mitigation.',
    defaultUnit: 'Duty',
    defaultDuty: 1,
    defaultRate: 2500,
    icon: Icons.sports_mma_outlined,
  ),
  ItemSuggestion(
    title: 'Field Officer / Inspector',
    subtitle: 'Operations Officer • Night Patrol & Audit',
    defaultDetails:
        'Mobile inspection officer conducting surprise night rounds, guard muster verification, and client feedback.',
    defaultUnit: 'Duty',
    defaultDuty: 26,
    defaultRate: 26000,
    icon: Icons.directions_walk_outlined,
  ),
  ItemSuggestion(
    title: 'CCTV Operator / Control Room',
    subtitle: 'Surveillance Tech • Electronic Monitoring',
    defaultDetails:
        'Continuous monitoring of CCTV camera feeds, alarm acknowledgement, incident timestamping, and reporting.',
    defaultUnit: 'Duty',
    defaultDuty: 26,
    defaultRate: 19500,
    icon: Icons.videocam_outlined,
  ),
  ItemSuggestion(
    title: 'Housekeeping Staff / Janitor',
    subtitle: 'Facility Cleaning • Daily Upkeep',
    defaultDetails:
        'Daily cleaning of common areas, restroom hygiene, waste disposal, and maintenance of clean premises.',
    defaultUnit: 'Duty',
    defaultDuty: 26,
    defaultRate: 12500,
    icon: Icons.cleaning_services_outlined,
  ),
];

const generalSuggestions = <ItemSuggestion>[
  ItemSuggestion(
    title: 'Consulting Services',
    subtitle: 'Professional Advisory & Planning',
    defaultDetails:
        'Strategic consulting and expert advisory services per agreement scope.',
    defaultUnit: 'hrs',
    defaultRate: 120,
    icon: Icons.business_center_outlined,
  ),
  ItemSuggestion(
    title: 'Maintenance & Support',
    subtitle: 'Monthly AMC & SLA Support',
    defaultDetails:
        'Ongoing maintenance, support services, and issue resolution under SLA.',
    defaultUnit: 'Month',
    defaultRate: 500,
    icon: Icons.build_outlined,
  ),
  ItemSuggestion(
    title: 'Software Development',
    subtitle: 'Custom Software & Feature Engineering',
    defaultDetails:
        'Software design, feature coding, QA testing, and release delivery.',
    defaultUnit: 'hrs',
    defaultRate: 75,
    icon: Icons.code_outlined,
  ),
  ItemSuggestion(
    title: 'UI/UX Design Services',
    subtitle: 'Interface Prototyping & Wireframing',
    defaultDetails:
        'User interface design, mobile/web mockups, design tokens, and prototypes.',
    defaultUnit: 'hrs',
    defaultRate: 60,
    icon: Icons.design_services_outlined,
  ),
  ItemSuggestion(
    title: 'Digital Marketing & SEO',
    subtitle: 'Search Ranking & Campaign Strategy',
    defaultDetails:
        'Search engine optimization, targeted ad management, and monthly performance reporting.',
    defaultUnit: 'Month',
    defaultRate: 400,
    icon: Icons.campaign_outlined,
  ),
  ItemSuggestion(
    title: 'Technical Audit & Inspection',
    subtitle: 'Infrastructure Review & Report',
    defaultDetails:
        'Full system security and operational compliance audit with detailed recommendation findings.',
    defaultUnit: 'pcs',
    defaultRate: 850,
    icon: Icons.checklist_outlined,
  ),
];

class LineItemEditor extends StatefulWidget {
  const LineItemEditor({
    required this.index,
    required this.item,
    required this.currencySymbol,
    required this.localSettings,
    required this.showDescriptionField,
    required this.onToggleDescription,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final int index;
  final InvoiceItem item;
  final String currencySymbol;
  final Map<String, Object?> localSettings;
  final bool showDescriptionField;
  final ValueChanged<bool> onToggleDescription;
  final ValueChanged<InvoiceItem> onChanged;
  final VoidCallback onRemove;

  @override
  State<LineItemEditor> createState() => _LineItemEditorState();
}

class _LineItemEditorState extends State<LineItemEditor> {
  late final TextEditingController _description;
  late final TextEditingController _itemDetails;
  late final TextEditingController _quantity;
  late final TextEditingController _duty;
  late final TextEditingController _unitPrice;
  late final TextEditingController _unit;
  late final TextEditingController _discount;
  bool _showSuggestions = false;
  bool? _isDescriptionCollapsed;

  @override
  void initState() {
    super.initState();
    _description = TextEditingController(text: widget.item.description);
    _itemDetails = TextEditingController(text: widget.item.itemDetails);
    _quantity = TextEditingController(text: _num(widget.item.quantity));
    _duty = TextEditingController(
      text: widget.item.dutyCount > 0 ? _num(widget.item.dutyCount) : '',
    );
    _unitPrice = TextEditingController(text: _num(widget.item.unitPrice));
    _unit = TextEditingController(text: widget.item.unit);
    _discount = TextEditingController(text: _num(widget.item.discountRate));
  }

  @override
  void dispose() {
    _description.dispose();
    _itemDetails.dispose();
    _quantity.dispose();
    _duty.dispose();
    _unitPrice.dispose();
    _unit.dispose();
    _discount.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged(InvoiceItem(
      id: widget.item.id,
      description: _description.text,
      itemDetails: _itemDetails.text,
      quantity: double.tryParse(_quantity.text) ?? 0,
      dutyCount: double.tryParse(_duty.text) ?? 0,
      unitPrice: double.tryParse(_unitPrice.text) ?? 0,
      unit: _unit.text.trim().isEmpty ? 'pcs' : _unit.text.trim(),
      taxRate: widget.item.taxRate,
      discountRate: double.tryParse(_discount.text) ?? 0,
    ));
  }

  void _applySuggestion(ItemSuggestion s) {
    setState(() {
      _description.text = s.title;
      // Keep description empty as default per requirement; only display if user enters text
      if (s.defaultUnit != null &&
          (_unit.text.trim().isEmpty || _unit.text == 'pcs')) {
        _unit.text = s.defaultUnit!;
      }
      if (s.defaultDuty != null &&
          (_duty.text.trim().isEmpty || _duty.text == '0')) {
        _duty.text = _num(s.defaultDuty!);
      }
      if (s.defaultRate != null &&
          (_unitPrice.text.trim().isEmpty || _unitPrice.text == '0')) {
        _unitPrice.text = _num(s.defaultRate!);
      }
      _showSuggestions = false;
    });
    _notify();
  }

  List<ItemSuggestion> _matchingSuggestions(bool isSecurity) {
    final query = _description.text.trim().toLowerCase();
    if (query.isEmpty) return const [];
    final pool = isSecurity
        ? securitySuggestions
        : <ItemSuggestion>[...securitySuggestions, ...generalSuggestions];
    return pool
        .where((s) =>
            s.title.toLowerCase().contains(query) ||
            s.subtitle.toLowerCase().contains(query) ||
            s.defaultDetails.toLowerCase().contains(query))
        .take(6)
        .toList(growable: false);
  }

  Widget _unitChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 11)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      onPressed: () {
        setState(() => _unit.text = text);
        _notify();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ls = widget.localSettings;
    final itemLabel =
        ls['customItemHeader']?.toString().trim().isNotEmpty == true
            ? ls['customItemHeader']!.toString().trim()
            : 'Description';
    final qtyLabel =
        ls['customQtyHeader']?.toString().trim().isNotEmpty == true
            ? ls['customQtyHeader']!.toString().trim()
            : 'Quantity';
    final dutyLabel =
        ls['customDutyHeader']?.toString().trim().isNotEmpty == true
            ? ls['customDutyHeader']!.toString().trim()
            : 'No. of Duty / Days';
    final unitLabel =
        ls['customUnitHeader']?.toString().trim().isNotEmpty == true
            ? ls['customUnitHeader']!.toString().trim()
            : 'Unit';
    final rateLabel =
        ls['customRateHeader']?.toString().trim().isNotEmpty == true
            ? ls['customRateHeader']!.toString().trim()
            : 'Unit price';
    final discountLabel =
        ls['customDiscountHeader']?.toString().trim().isNotEmpty == true
            ? ls['customDiscountHeader']!.toString().trim()
            : 'Discount (%)';

    final isSecurityOrStaffing = ls['industryPresetId'] == 'security' ||
        ls['industryPresetId'] == 'hr_staffing' ||
        itemLabel.toLowerCase().contains('guard') ||
        itemLabel.toLowerCase().contains('designation');

    final showDuty = ls['showItemDuty'] == true ||
        isSecurityOrStaffing ||
        widget.item.dutyCount > 0;
    final showUnit = ls['showItemUnit'] != false;
    final showDiscount = ls['showItemDiscount'] == true;

    final qtyVal = double.tryParse(_quantity.text) ?? 0;
    final dutyVal = double.tryParse(_duty.text) ?? 0;
    final rateVal = double.tryParse(_unitPrice.text) ?? 0;
    final discVal = double.tryParse(_discount.text) ?? 0;

    final gross =
        dutyVal > 0 ? (qtyVal * dutyVal * rateVal) : (qtyVal * rateVal);
    final discAmt = gross * (discVal / 100);
    final lineTotal = gross - discAmt;

    final isDescOpen = _isDescriptionCollapsed != null
        ? !_isDescriptionCollapsed!
        : (widget.showDescriptionField || _itemDetails.text.trim().isNotEmpty);
    final suggestions = _matchingSuggestions(isSecurityOrStaffing);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Item ${widget.index + 1}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            IconButton(
              tooltip: 'Remove line item',
              onPressed: widget.onRemove,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        TextFormField(
          controller: _description,
          decoration: InputDecoration(
            labelText: itemLabel,
            hintText: isSecurityOrStaffing
                ? 'Type to search (e.g. Guard, Supervisor...)'
                : 'What are you billing for? (Type to search)',
            suffixIcon: _description.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      setState(() {
                        _description.clear();
                        _showSuggestions = false;
                      });
                      _notify();
                    },
                  )
                : const Icon(Icons.search, size: 18),
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Add a $itemLabel'
              : null,
          onTap: () {
            if (_description.text.trim().isNotEmpty) {
              setState(() => _showSuggestions = true);
            }
          },
          onChanged: (_) {
            setState(() => _showSuggestions = _description.text.trim().isNotEmpty);
            _notify();
          },
        ),
        if (_showSuggestions && suggestions.isNotEmpty) ...[
          const SizedBox(height: 6),
          Material(
            elevation: 3,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    color: const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Suggested designations & services (${suggestions.length})',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                        InkWell(
                          onTap: () =>
                              setState(() => _showSuggestions = false),
                          child: const Icon(Icons.close,
                              size: 16, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  for (final s in suggestions)
                    ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 15,
                        backgroundColor: const Color(0xFFEFF6FF),
                        child: Icon(s.icon,
                            size: 16, color: const Color(0xFF2563EB)),
                      ),
                      title: Text(
                        s.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        s.subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _applySuggestion(s),
                    ),
                ],
              ),
            ),
          ),
        ],
        if (!isDescOpen)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: InkWell(
              onTap: () {
                setState(() => _isDescriptionCollapsed = false);
                widget.onToggleDescription(true);
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_circle_outline, size: 15, color: Color(0xFF2563EB)),
                    const SizedBox(width: 5),
                    Text(
                      _itemDetails.text.trim().isNotEmpty
                          ? '+ Description: "${_itemDetails.text.trim().split('\n').first}" (Expand)'
                          : '+ Description / Scope of Work',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    if (_itemDetails.text.trim().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Clear description',
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _itemDetails.clear();
                              _isDescriptionCollapsed = true;
                            });
                            _notify();
                          },
                          child: const Icon(Icons.close, size: 14, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Description / Scope of Work',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() => _isDescriptionCollapsed = true);
                        widget.onToggleDescription(false);
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.unfold_less, size: 14, color: Color(0xFF64748B)),
                            SizedBox(width: 3),
                            Text(
                              'Collapse',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _itemDetails,
                  maxLines: 2,
                  minLines: 1,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText:
                        'Specifications, post location, shift hours, duties...',
                    prefixIcon: const Icon(Icons.notes_rounded, size: 18),
                    suffixIcon: _itemDetails.text.isNotEmpty
                        ? IconButton(
                            tooltip: 'Clear description',
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _itemDetails.clear();
                              _notify();
                            },
                          )
                        : null,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (_) => _notify(),
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        ResponsiveFields(
          children: [
            appItemNumberField(
              controller: _quantity,
              label: qtyLabel,
              min: 0.000001,
              onChanged: _notify,
            ),
            if (showDuty)
              appItemNumberField(
                controller: _duty,
                label: dutyLabel,
                min: 0,
                onChanged: _notify,
              ),
            appItemNumberField(
              controller: _unitPrice,
              label: '$rateLabel (${widget.currencySymbol})',
              min: 0,
              onChanged: _notify,
            ),
            if (showUnit)
              TextField(
                controller: _unit,
                decoration: InputDecoration(
                  labelText: unitLabel,
                  hintText: 'Duty, Days, Shift, hrs, pcs',
                ),
                onChanged: (_) => _notify(),
              ),
            if (showDiscount)
              appItemNumberField(
                controller: _discount,
                label: discountLabel,
                min: 0,
                max: 100,
                onChanged: _notify,
              ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            if (showDuty) ...[
              _unitChip('Duty'),
              _unitChip('Shift'),
            ],
            _unitChip('Days'),
            _unitChip('Month'),
            _unitChip('hrs'),
            _unitChip('pcs'),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  dutyVal > 0
                      ? 'Auto Calculation: ${_num(qtyVal)} Staff × ${_num(dutyVal)} Duties × ${widget.currencySymbol}${_num(rateVal)}${discVal > 0 ? " (−$discVal%)" : ""}'
                      : 'Auto Calculation: ${_num(qtyVal)} × ${widget.currencySymbol}${_num(rateVal)}${discVal > 0 ? " (−$discVal%)" : ""}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Total: ${widget.currencySymbol}${lineTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
