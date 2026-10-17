import 'package:flutter/material.dart';

import '../../../employees/data/employee.dart';
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
  final bool isEmployee;

  const ItemSuggestion({
    required this.title,
    required this.subtitle,
    required this.defaultDetails,
    this.defaultRate,
    this.defaultUnit,
    this.defaultDuty,
    this.icon = Icons.shield_outlined,
    this.isEmployee = false,
  });
}

const securitySuggestions = <ItemSuggestion>[
  ItemSuggestion(
    title: 'Security Guard (12 Hrs Shift)',
    subtitle: '12-Hour Shift • Unarmed Uniformed Guard',
    defaultDetails:
        'Deployment of uniformed security guard for 12 hours shift. Access control, gatekeeping, and premise surveillance.',
    defaultUnit: 'Duty',
    defaultDuty: 30,
    defaultRate: 30000,
    icon: Icons.security,
  ),
  ItemSuggestion(
    title: 'Security Guard (8 Hrs Shift)',
    subtitle: '8-Hour Shift • Commercial / Corporate Guard',
    defaultDetails:
        'Deployment of trained security guard for 8 hours shift. Visitor monitoring and perimeter patrolling.',
    defaultUnit: 'Duty',
    defaultDuty: 30,
    defaultRate: 18500,
    icon: Icons.shield_outlined,
  ),
  ItemSuggestion(
    title: 'Security Supervisor',
    subtitle: 'Post In-Charge • Shift Operations & Briefing',
    defaultDetails:
        'Overall supervision of security personnel, deployment management, incident escalation, and daily report log.',
    defaultUnit: 'Duty',
    defaultDuty: 30,
    defaultRate: 28000,
    icon: Icons.local_police_outlined,
  ),
  ItemSuggestion(
    title: 'Gunman / Armed Guard',
    subtitle: 'Armed Security • Vault & Cash Escort',
    defaultDetails:
        'Deployment of licensed armed gunman with weapon for high-security areas, cash transport, or executive protection.',
    defaultUnit: 'Duty',
    defaultDuty: 30,
    defaultRate: 32000,
    icon: Icons.verified_user_outlined,
  ),
  ItemSuggestion(
    title: 'Head Guard / Chief Guard',
    subtitle: 'Site Leadership • Shift Coordination',
    defaultDetails:
        'Site head guard responsible for main gate registers, key management, and shift roster execution.',
    defaultUnit: 'Duty',
    defaultDuty: 30,
    defaultRate: 24000,
    icon: Icons.person_pin_outlined,
  ),
  ItemSuggestion(
    title: 'Lady Security Guard',
    subtitle: 'Female Screening • Reception / Staff Gate',
    defaultDetails:
        'Deployment of female security guard for female staff/visitor frisking, reception assistance, and women safety.',
    defaultUnit: 'Duty',
    defaultDuty: 30,
    defaultRate: 21000,
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
    defaultDuty: 30,
    defaultRate: 30000,
    icon: Icons.directions_walk_outlined,
  ),
  ItemSuggestion(
    title: 'CCTV Operator / Control Room',
    subtitle: 'Surveillance Tech • Electronic Monitoring',
    defaultDetails:
        'Continuous monitoring of CCTV camera feeds, alarm acknowledgement, incident timestamping, and reporting.',
    defaultUnit: 'Duty',
    defaultDuty: 30,
    defaultRate: 22000,
    icon: Icons.videocam_outlined,
  ),
  ItemSuggestion(
    title: 'Housekeeping Staff / Janitor',
    subtitle: 'Facility Cleaning • Daily Upkeep',
    defaultDetails:
        'Daily cleaning of common areas, restroom hygiene, waste disposal, and maintenance of clean premises.',
    defaultUnit: 'Duty',
    defaultDuty: 30,
    defaultRate: 15000,
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

class DesktopLineItemsTableHeader extends StatelessWidget {
  const DesktopLineItemsTableHeader({
    required this.localSettings,
    required this.currencySymbol,
    super.key,
  });

  final Map<String, Object?> localSettings;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final ls = localSettings;
    final itemLabel =
        ls['customItemHeader']?.toString().trim().isNotEmpty == true
            ? ls['customItemHeader']!.toString().trim()
            : 'Particulars / Service Description';
    final qtyLabel =
        ls['customQtyHeader']?.toString().trim().isNotEmpty == true
            ? ls['customQtyHeader']!.toString().trim()
            : 'Qty / Staff';
    final dutyLabel =
        ls['customDutyHeader']?.toString().trim().isNotEmpty == true
            ? ls['customDutyHeader']!.toString().trim()
            : 'Duty / Days';
    final unitLabel =
        ls['customUnitHeader']?.toString().trim().isNotEmpty == true
            ? ls['customUnitHeader']!.toString().trim()
            : 'Unit';
    final rateLabel =
        ls['customRateHeader']?.toString().trim().isNotEmpty == true
            ? ls['customRateHeader']!.toString().trim()
            : 'Rate ($currencySymbol)';
    final discountLabel =
        ls['customDiscountHeader']?.toString().trim().isNotEmpty == true
            ? ls['customDiscountHeader']!.toString().trim()
            : 'Disc %';

    final isSecurityOrStaffing = ls['industryPresetId'] == 'security' ||
        ls['businessType'] == 'security' ||
        ls['industryPresetId'] == 'hr_staffing' ||
        itemLabel.toLowerCase().contains('guard') ||
        itemLabel.toLowerCase().contains('designation');

    final showDuty = ls['showItemDuty'] == true || isSecurityOrStaffing;
    final showUnit = ls['showItemUnit'] != false;
    final showDiscount = ls['showItemDiscount'] == true;

    const headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: Colors.white,
      letterSpacing: 0.4,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 34,
            child: Text('#', style: headerStyle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(itemLabel.toUpperCase(), style: headerStyle),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 84,
            child: Text(qtyLabel.toUpperCase(), style: headerStyle, textAlign: TextAlign.center),
          ),
          if (showDuty) ...[
            const SizedBox(width: 10),
            SizedBox(
              width: 96,
              child: Text(dutyLabel.toUpperCase(), style: headerStyle, textAlign: TextAlign.center),
            ),
          ],
          if (showUnit) ...[
            const SizedBox(width: 10),
            SizedBox(
              width: 98,
              child: Text(unitLabel.toUpperCase(), style: headerStyle, textAlign: TextAlign.center),
            ),
          ],
          const SizedBox(width: 10),
          SizedBox(
            width: 122,
            child: Text(rateLabel.toUpperCase(), style: headerStyle, textAlign: TextAlign.right),
          ),
          if (showDiscount) ...[
            const SizedBox(width: 10),
            SizedBox(
              width: 76,
              child: Text(discountLabel.toUpperCase(), style: headerStyle, textAlign: TextAlign.center),
            ),
          ],
          const SizedBox(width: 12),
          SizedBox(
            width: 142,
            child: Text('AMOUNT ($currencySymbol)', style: headerStyle, textAlign: TextAlign.right),
          ),
          const SizedBox(width: 8),
          const SizedBox(
            width: 66,
            child: Text('ACTION', style: headerStyle, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

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
    this.onDuplicate,
    this.issueDate,
    this.forceDesktopRow,
    this.employees = const <Employee>[],
    this.onOpenFormulaSettings,
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
  final VoidCallback? onDuplicate;
  final String? issueDate;
  final bool? forceDesktopRow;
  final List<Employee> employees;
  final VoidCallback? onOpenFormulaSettings;

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

  int get _calendarDays {
    final parsed = DateTime.tryParse(widget.issueDate ?? '') ?? DateTime.now();
    return DateTime(parsed.year, parsed.month + 1, 0).day;
  }

  double get _preferredStandardDutyDays {
    final ls = widget.localSettings;
    final formula = ls['itemCalculationFormula']?.toString() ?? 'monthly_salary_30';
    if (formula == 'calendar_month' || formula == 'monthly_salary_calendar') {
      return _calendarDays.toDouble();
    }
    if (formula == 'monthly_salary_30') return 30.0;
    if (formula == 'monthly_salary_26') return 26.0;
    return double.tryParse(ls['standardDutyDays']?.toString() ?? '30') ?? 30.0;
  }

  void _notify() {
    final ls = widget.localSettings;
    final isSecurity = ls['industryPresetId'] == 'security' ||
        ls['businessType'] == 'security' ||
        ls['showItemDuty'] == true;
    final dutyValue = double.tryParse(_duty.text) ?? 0;
    final formula = ls['itemCalculationFormula']?.toString() ??
        widget.item.calculationFormula ??
        (isSecurity ? 'monthly_salary_30' : (dutyValue > 0 ? 'monthly_salary_30' : 'standard'));
    final double standardDays = (formula == 'calendar_month' || formula == 'monthly_salary_calendar')
        ? _calendarDays.toDouble()
        : (formula == 'monthly_salary_30'
            ? 30.0
            : (formula == 'monthly_salary_26'
                ? 26.0
                : (double.tryParse(ls['standardDutyDays']?.toString() ?? '30') ?? 30.0)));

    widget.onChanged(InvoiceItem(
      id: widget.item.id,
      description: _description.text,
      itemDetails: _itemDetails.text,
      quantity: double.tryParse(_quantity.text) ?? 0,
      dutyCount: double.tryParse(_duty.text) ?? 0,
      unitPrice: double.tryParse(_unitPrice.text) ?? 0,
      unit: _unit.text.trim().isEmpty ? 'pcs' : _unit.text.trim(),
      taxRate: widget.item.taxRate,
      discountRate: (ls['showItemDiscount'] == true)
          ? (double.tryParse(_discount.text) ?? 0)
          : 0,
      calculationFormula: formula,
      standardDutyDays: standardDays,
    ));
  }

  void _applySuggestion(ItemSuggestion s) {
    setState(() {
      _description.text = s.title;
      _description.selection = TextSelection.collapsed(offset: _description.text.length);
      if (s.defaultUnit != null && s.defaultUnit!.isNotEmpty) {
        _unit.text = s.defaultUnit!;
      }
      if (s.defaultDuty != null &&
          (_duty.text.trim().isEmpty || _duty.text == '0')) {
        _duty.text = _num(s.defaultDuty!);
      }
      if (s.defaultRate != null && s.defaultRate! > 0) {
        _unitPrice.text = _num(s.defaultRate!);
      }
      if (s.isEmployee && s.defaultDetails.isNotEmpty && _itemDetails.text.trim().isEmpty) {
        _itemDetails.text = s.defaultDetails;
      }
      _showSuggestions = false;
    });
    _notify();
  }

  void _tryAutoFetchFromTypedInput(String rawInput) {
    final query = rawInput.trim().toLowerCase();
    if (query.length < 2) return;

    // 1. Check exact match against Workforce Employees (by full name or employee code)
    for (final emp in widget.employees) {
      final fullName = emp.fullName.trim();
      final code = emp.employeeCode.trim();
      if (fullName.isEmpty) continue;
      if (fullName.toLowerCase() == query ||
          (code.isNotEmpty && code.toLowerCase() == query)) {
        final fullLabel = emp.designation.trim().isNotEmpty
            ? '$fullName — ${emp.designation.trim()}'
            : fullName;
        setState(() {
          _description.text = fullLabel;
          _description.selection =
              TextSelection.collapsed(offset: _description.text.length);
          if (emp.monthlySalary > 0) {
            _unitPrice.text = _num(emp.monthlySalary);
          }
          if (_duty.text.trim().isEmpty || _duty.text.trim() == '0') {
            _duty.text = _num(_preferredStandardDutyDays);
          }
          if (_unit.text.trim().isEmpty || _unit.text.trim() == 'pcs') {
            _unit.text = 'Duty';
          }
          if (_itemDetails.text.trim().isEmpty) {
            _itemDetails.text =
                'Employee: $fullName${code.isNotEmpty ? " ($code)" : ""} • Designation: ${emp.designation}';
          }
          _showSuggestions = false;
        });
        return;
      }
    }

    // 2. Check exact match against preset items (only autofetch rate if currently 0/empty so custom rates stay intact)
    final allPresets = <ItemSuggestion>[...securitySuggestions, ...generalSuggestions];
    for (final preset in allPresets) {
      if (preset.title.trim().toLowerCase() == query) {
        final currentRate = double.tryParse(_unitPrice.text.trim()) ?? 0;
        if (currentRate == 0 && preset.defaultRate != null) {
          setState(() {
            _unitPrice.text = _num(preset.defaultRate!);
            if (preset.defaultDuty != null &&
                (_duty.text.trim().isEmpty || _duty.text.trim() == '0')) {
              _duty.text = _num(preset.defaultDuty!);
            }
            if (preset.defaultUnit != null &&
                (_unit.text.trim().isEmpty || _unit.text.trim() == 'pcs')) {
              _unit.text = preset.defaultUnit!;
            }
          });
        }
        return;
      }
    }
  }

  List<ItemSuggestion> _employeeSuggestions() {
    final defaultDuty = _preferredStandardDutyDays;
    return [
      for (final emp in widget.employees)
        if (emp.fullName.trim().isNotEmpty)
          ItemSuggestion(
            title: emp.designation.trim().isNotEmpty
                ? '${emp.fullName.trim()} — ${emp.designation.trim()}'
                : emp.fullName.trim(),
            subtitle:
                '${emp.employeeCode.trim().isNotEmpty ? "${emp.employeeCode.trim()} • " : ""}'
                '${emp.designation.trim().isNotEmpty ? "${emp.designation.trim()} • " : ""}'
                'Monthly Rate: ${widget.currencySymbol}${_num(emp.monthlySalary > 0 ? emp.monthlySalary : 30000)}',
            defaultDetails:
                'Employee: ${emp.fullName.trim()}${emp.employeeCode.trim().isNotEmpty ? " (${emp.employeeCode.trim()})" : ""} • Post: ${emp.designation.trim()}',
            defaultRate: emp.monthlySalary > 0 ? emp.monthlySalary : 30000,
            defaultDuty: defaultDuty,
            defaultUnit: 'Duty',
            icon: Icons.badge_outlined,
            isEmployee: true,
          ),
    ];
  }

  List<ItemSuggestion> _matchingSuggestions(bool isSecurity) {
    final query = _description.text.trim().toLowerCase();
    final empPool = _employeeSuggestions();
    final itemPool = isSecurity
        ? <ItemSuggestion>[...securitySuggestions, ...generalSuggestions]
        : <ItemSuggestion>[...securitySuggestions, ...generalSuggestions];
    final combinedPool = <ItemSuggestion>[...empPool, ...itemPool];

    if (query.isEmpty) {
      return combinedPool.take(8).toList(growable: false);
    }
    return combinedPool
        .where((s) =>
            s.title.toLowerCase().contains(query) ||
            s.subtitle.toLowerCase().contains(query) ||
            s.defaultDetails.toLowerCase().contains(query))
        .take(8)
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

  Widget _dutyQuickChip(String label, double days) {
    final currentDuty = double.tryParse(_duty.text.trim()) ?? 0;
    final isSelected = (currentDuty - days).abs() < 0.01;
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
        ),
      ),
      backgroundColor: isSelected ? const Color(0xFFDBEAFE) : const Color(0xFFF8FAFC),
      side: BorderSide(
        color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1),
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      onPressed: () {
        setState(() {
          _duty.text = _num(days);
          if (_unit.text.trim().isEmpty || _unit.text == 'pcs') {
            _unit.text = 'Duty';
          }
        });
        _notify();
      },
    );
  }

  InputDecoration _desktopCellDecoration({
    required String hint,
    Widget? suffixIcon,
    Widget? prefixIcon,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
  }) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      contentPadding: contentPadding,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
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
        ls['businessType'] == 'security' ||
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
    final discVal = showDiscount ? (double.tryParse(_discount.text) ?? 0) : 0.0;

    final formula = ls['itemCalculationFormula']?.toString() ??
        widget.item.calculationFormula ??
        (isSecurityOrStaffing ? 'monthly_salary_30' : (dutyVal > 0 ? 'monthly_salary_30' : 'standard'));
    final int calendarDays = _calendarDays;
    final standardDays = (formula == 'calendar_month' || formula == 'monthly_salary_calendar')
        ? calendarDays.toDouble()
        : (formula == 'monthly_salary_30'
            ? 30.0
            : (formula == 'monthly_salary_26'
                ? 26.0
                : (double.tryParse(ls['standardDutyDays']?.toString() ?? '30') ?? 30.0)));

    double gross;
    if (dutyVal <= 0) {
      gross = qtyVal * rateVal;
    } else {
      switch (formula) {
        case 'calendar_month':
        case 'monthly_salary_calendar':
          gross = (qtyVal * dutyVal * rateVal) / (calendarDays > 0 ? calendarDays : 30.0);
          break;
        case 'monthly_salary_30':
          gross = (qtyVal * dutyVal * rateVal) / 30.0;
          break;
        case 'flat_monthly':
          gross = qtyVal * rateVal;
          break;
        case 'per_duty':
        case 'daily_duty':
          gross = qtyVal * dutyVal * rateVal;
          break;
        case 'standard':
          gross = qtyVal * rateVal;
          break;
        case 'monthly_salary':
        case 'monthly_salary_26':
        default:
          final div = standardDays > 0 ? standardDays : 30.0;
          gross = (qtyVal * dutyVal * rateVal) / div;
          break;
      }
    }
    final discAmt = gross * (discVal / 100);
    final lineTotal = gross - discAmt;

    final isDescOpen = _isDescriptionCollapsed != null
        ? !_isDescriptionCollapsed!
        : (widget.showDescriptionField || _itemDetails.text.trim().isNotEmpty);
    final suggestions = _matchingSuggestions(isSecurityOrStaffing);

    final useDesktopSingleLine =
        widget.forceDesktopRow ?? (MediaQuery.sizeOf(context).width >= 900);

    if (useDesktopSingleLine) {
      return _buildDesktopSingleLineRow(
        context: context,
        itemLabel: itemLabel,
        qtyLabel: qtyLabel,
        dutyLabel: dutyLabel,
        unitLabel: unitLabel,
        rateLabel: rateLabel,
        discountLabel: discountLabel,
        isSecurityOrStaffing: isSecurityOrStaffing,
        showDuty: showDuty,
        showUnit: showUnit,
        showDiscount: showDiscount,
        qtyVal: qtyVal,
        dutyVal: dutyVal,
        rateVal: rateVal,
        discVal: discVal,
        formula: formula,
        calendarDays: calendarDays,
        standardDays: standardDays,
        lineTotal: lineTotal,
        isDescOpen: isDescOpen,
        suggestions: suggestions,
      );
    }

    // Mobile & Compact Screen Layout (Preserved intact!)
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
            if (widget.onOpenFormulaSettings != null)
              IconButton(
                tooltip: 'Daily Wage & Formula Setup',
                onPressed: widget.onOpenFormulaSettings,
                icon: const Icon(
                  Icons.functions_rounded,
                  size: 18,
                  color: Color(0xFF4F46E5),
                ),
              ),
            if (widget.onDuplicate != null)
              IconButton(
                tooltip: 'Duplicate line item',
                onPressed: widget.onDuplicate,
                icon: const Icon(Icons.copy_rounded, size: 18),
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
                ? 'Type Employee Name or Designation (autofetches rate)...'
                : 'Type Employee Name or Item to autofetch rate...',
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
            setState(() => _showSuggestions = true);
          },
          onChanged: (val) {
            setState(() => _showSuggestions = val.trim().isNotEmpty);
            _tryAutoFetchFromTypedInput(val);
            _notify();
          },
        ),
        if (_showSuggestions && suggestions.isNotEmpty) ...[
          const SizedBox(height: 6),
          _buildSuggestionsDropdown(suggestions),
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
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (showDuty) ...[
              const Text(
                'Worked Days:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
              _dutyQuickChip('30d', 30),
              _dutyQuickChip('26d', 26),
              _dutyQuickChip('22d', 22),
              _dutyQuickChip('15d', 15),
              if (calendarDays != 30 && calendarDays != 26)
                _dutyQuickChip('${calendarDays}d', calendarDays.toDouble()),
              const SizedBox(width: 4),
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
        () {
          final dailyRate = standardDays > 0 ? (rateVal / standardDays) : (rateVal / 30.0);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.onOpenFormulaSettings != null) ...[
                  InkWell(
                    onTap: widget.onOpenFormulaSettings,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.functions_rounded, size: 13, color: Color(0xFF4F46E5)),
                          SizedBox(width: 2),
                          Text(
                            'fx',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF4338CA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    dutyVal > 0
                        ? ((formula == 'calendar_month' || formula == 'monthly_salary_calendar')
                            ? 'Daily Wage (${calendarDays}d): ${widget.currencySymbol}${dailyRate.toStringAsFixed(2)}/day (${widget.currencySymbol}${_num(rateVal)} ÷ $calendarDays) × ${_num(qtyVal)} Staff × ${_num(dutyVal)} Days'
                            : formula == 'monthly_salary_30'
                                ? 'Daily Wage (30d): ${widget.currencySymbol}${(rateVal / 30.0).toStringAsFixed(2)}/day (${widget.currencySymbol}${_num(rateVal)} ÷ 30) × ${_num(qtyVal)} Staff × ${_num(dutyVal)} Days'
                                : formula == 'flat_monthly'
                                    ? 'Monthly Flat Rate: ${_num(qtyVal)} Staff × ${widget.currencySymbol}${_num(rateVal)} / Month'
                                    : (formula == 'per_duty' || formula == 'daily_duty')
                                        ? 'Per Duty: ${_num(qtyVal)} Staff × ${_num(dutyVal)} Duties × ${widget.currencySymbol}${_num(rateVal)}/Duty'
                                        : 'Daily Wage (${_num(standardDays)}d): ${widget.currencySymbol}${dailyRate.toStringAsFixed(2)}/day (${widget.currencySymbol}${_num(rateVal)} ÷ ${_num(standardDays)}) × ${_num(qtyVal)} Staff × ${_num(dutyVal)} Days')
                        : 'Auto Calculation: ${_num(qtyVal)} × ${widget.currencySymbol}${_num(rateVal)}${showDiscount && discVal > 0 ? " (−$discVal%)" : ""}',
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
          );
        }(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // DESKTOP / LAPTOP SINGLE-LINE DOCUMENT ROW EDITOR
  // ---------------------------------------------------------------------------
  Widget _buildDesktopSingleLineRow({
    required BuildContext context,
    required String itemLabel,
    required String qtyLabel,
    required String dutyLabel,
    required String unitLabel,
    required String rateLabel,
    required String discountLabel,
    required bool isSecurityOrStaffing,
    required bool showDuty,
    required bool showUnit,
    required bool showDiscount,
    required double qtyVal,
    required double dutyVal,
    required double rateVal,
    required double discVal,
    required String formula,
    required int calendarDays,
    required double standardDays,
    required double lineTotal,
    required bool isDescOpen,
    required List<ItemSuggestion> suggestions,
  }) {
    final isEven = widget.index.isEven;
    final formulaBadge = dutyVal > 0
        ? ((formula == 'calendar_month' || formula == 'monthly_salary_calendar')
            ? '÷${calendarDays}d'
            : formula == 'monthly_salary_30'
                ? '÷30d'
                : formula == 'flat_monthly'
                    ? 'Flat'
                    : (formula == 'per_duty' || formula == 'daily_duty')
                        ? '×Duty'
                        : '÷${_num(standardDays)}d')
        : '×Qty';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : const Color(0xFFF8FAFC),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Index Badge (#)
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                alignment: Alignment.center,
                child: Text(
                  (widget.index + 1).toString().padLeft(2, '0'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 2. Particulars / Service Description (Single-line with quick note toggle & preset menu)
              Expanded(
                child: TextFormField(
                  controller: _description,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: _desktopCellDecoration(
                    hint: isSecurityOrStaffing
                        ? 'Select or type Employee Name / Designation (autofetches rate)...'
                        : 'Enter Employee Name, item, or service description...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: isDescOpen
                              ? 'Hide scope / item details'
                              : 'Add scope / item details note',
                          child: InkWell(
                            onTap: () {
                              setState(() => _isDescriptionCollapsed = isDescOpen);
                              widget.onToggleDescription(!isDescOpen);
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: isDescOpen || _itemDetails.text.trim().isNotEmpty
                                    ? const Color(0xFFDBEAFE)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.notes_rounded,
                                    size: 13,
                                    color: isDescOpen || _itemDetails.text.trim().isNotEmpty
                                        ? const Color(0xFF1D4ED8)
                                        : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Note',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isDescOpen || _itemDetails.text.trim().isNotEmpty
                                          ? const Color(0xFF1D4ED8)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: _showSuggestions ? 'Close suggestions' : 'Browse employees & service presets',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                          icon: Icon(
                            _showSuggestions
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.arrow_drop_down_circle_outlined,
                            size: 17,
                            color: const Color(0xFF2563EB),
                          ),
                          onPressed: () {
                            setState(() => _showSuggestions = !_showSuggestions);
                          },
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                  onTap: () {
                    setState(() => _showSuggestions = true);
                  },
                  onChanged: (val) {
                    setState(() => _showSuggestions = val.trim().isNotEmpty);
                    _tryAutoFetchFromTypedInput(val);
                    _notify();
                  },
                ),
              ),
              const SizedBox(width: 10),

              // 3. Quantity / Staff
              SizedBox(
                width: 84,
                child: TextFormField(
                  controller: _quantity,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: _desktopCellDecoration(hint: '1'),
                  onChanged: (_) => _notify(),
                ),
              ),

              // 4. Duty / Days (if enabled)
              if (showDuty) ...[
                const SizedBox(width: 10),
                SizedBox(
                  width: 96,
                  child: TextFormField(
                    controller: _duty,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E3A8A),
                    ),
                    decoration: _desktopCellDecoration(
                      hint: '30',
                      suffixIcon: InkWell(
                        onTap: widget.onOpenFormulaSettings,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              formulaBadge,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    onChanged: (_) => _notify(),
                  ),
                ),
              ],

              // 5. Unit with quick popup menu
              if (showUnit) ...[
                const SizedBox(width: 10),
                SizedBox(
                  width: 98,
                  child: TextFormField(
                    controller: _unit,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                    decoration: _desktopCellDecoration(
                      hint: 'Duty',
                      contentPadding: const EdgeInsets.only(left: 8, top: 10, bottom: 10),
                      suffixIcon: PopupMenuButton<String>(
                        tooltip: 'Select unit',
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        onSelected: (val) {
                          setState(() => _unit.text = val);
                          _notify();
                        },
                        itemBuilder: (ctx) => const [
                          PopupMenuItem(value: 'Duty', child: Text('Duty')),
                          PopupMenuItem(value: 'Shift', child: Text('Shift')),
                          PopupMenuItem(value: 'Days', child: Text('Days')),
                          PopupMenuItem(value: 'Month', child: Text('Month')),
                          PopupMenuItem(value: 'hrs', child: Text('hrs')),
                          PopupMenuItem(value: 'pcs', child: Text('pcs')),
                        ],
                      ),
                    ),
                    onChanged: (_) => _notify(),
                  ),
                ),
              ],

              // 6. Rate / Unit Price
              const SizedBox(width: 10),
              SizedBox(
                width: 122,
                child: TextFormField(
                  controller: _unitPrice,
                  textAlign: TextAlign.right,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: _desktopCellDecoration(
                    hint: '0.00',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 8, right: 2),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          widget.currencySymbol,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                  onChanged: (_) => _notify(),
                ),
              ),

              // 7. Discount %
              if (showDiscount) ...[
                const SizedBox(width: 10),
                SizedBox(
                  width: 76,
                  child: TextFormField(
                    controller: _discount,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF059669),
                    ),
                    decoration: _desktopCellDecoration(hint: '0%'),
                    onChanged: (_) => _notify(),
                  ),
                ),
              ],

              // 8. Live Line Amount Box (clickable to open formula builder)
              const SizedBox(width: 12),
              InkWell(
                onTap: widget.onOpenFormulaSettings,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 142,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFEFF6FF), Color(0xFFE0E7FF)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${widget.currencySymbol}${lineTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ),
                      Text(
                        dutyVal > 0
                            ? '${_num(qtyVal)}×${_num(dutyVal)}d ($formulaBadge)'
                            : '${_num(qtyVal)} × ${widget.currencySymbol}${_num(rateVal)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 9. Row Actions (Duplicate + Remove)
              const SizedBox(width: 8),
              SizedBox(
                width: 66,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (widget.onDuplicate != null)
                      Tooltip(
                        message: 'Duplicate row',
                        child: InkWell(
                          onTap: widget.onDuplicate,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Icon(
                              Icons.copy_rounded,
                              size: 14,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Remove row',
                      child: InkWell(
                        onTap: widget.onRemove,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Expandable Inline Scope of Work / Item Note Row (only when toggled open)
          if (isDescOpen)
            Padding(
              padding: const EdgeInsets.only(left: 42, top: 8, right: 74),
              child: TextFormField(
                controller: _itemDetails,
                maxLines: 2,
                minLines: 1,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  hintText: 'Scope of work, shift timings, deployment post location, or HSN/SAC notes...',
                  hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.subdirectory_arrow_right_rounded, size: 16, color: Color(0xFF2563EB)),
                  suffixIcon: IconButton(
                    tooltip: 'Hide note',
                    icon: const Icon(Icons.close_rounded, size: 15),
                    onPressed: () {
                      setState(() => _isDescriptionCollapsed = true);
                      widget.onToggleDescription(false);
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                ),
                onChanged: (_) => _notify(),
              ),
            ),

          // Autocomplete Suggestions Dropdown
          if (_showSuggestions && suggestions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 42, right: 74),
              child: _buildSuggestionsDropdown(suggestions),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionsDropdown(List<ItemSuggestion> suggestions) {
    return Material(
      elevation: 4,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Autofetch Employees & Service Presets (${suggestions.length})',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _showSuggestions = false),
                    child: const Icon(Icons.close, size: 16, color: Color(0xFF94A3B8)),
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
                  backgroundColor: s.isEmployee
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFEFF6FF),
                  child: Icon(
                    s.icon,
                    size: 16,
                    color: s.isEmployee
                        ? const Color(0xFF059669)
                        : const Color(0xFF2563EB),
                  ),
                ),
                title: Row(
                  children: [
                    if (s.isEmployee) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'EMPLOYEE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ),
                    ],
                    Expanded(
                      child: Text(
                        s.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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
                trailing: s.defaultRate != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: s.isEmployee
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${widget.currencySymbol}${_num(s.defaultRate!)}/mo',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: s.isEmployee
                                ? const Color(0xFF047857)
                                : const Color(0xFF1E3A8A),
                          ),
                        ),
                      )
                    : null,
                onTap: () => _applySuggestion(s),
              ),
          ],
        ),
      ),
    );
  }
}
