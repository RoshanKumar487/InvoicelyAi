import 'dart:math';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_card.dart';
import 'report_types.dart';

class ReportTabs extends StatelessWidget {
  const ReportTabs({
    required this.selected,
    required this.counts,
    required this.onSelected,
    super.key,
  });

  final ReportType selected;
  final Map<ReportType, int> counts;
  final ValueChanged<ReportType> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final type in ReportType.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ReportTab(
                    type: type,
                    count: counts[type] ?? 0,
                    selected: selected == type,
                    compact: constraints.maxWidth < 420,
                    onTap: () => onSelected(type),
                  ),
                ),
            ],
          ),
        ),
      );
}

class ReportTab extends StatelessWidget {
  const ReportTab({
    required this.type,
    required this.count,
    required this.selected,
    required this.compact,
    required this.onTap,
    super.key,
  });

  final ReportType type;
  final int count;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF0284C7) : const Color(0xFF64748B);
    return Material(
      color: selected ? const Color(0xFFE0F2FE) : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(type.icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                type.label,
                style: TextStyle(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF0284C7).withValues(alpha: 0.15)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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

class ReportActiveFiltersBar extends StatelessWidget {
  const ReportActiveFiltersBar({
    super.key,
    required this.activeFilterCount,
    required this.dateRange,
    required this.datePreset,
    required this.statusFilter,
    required this.creatorFilter,
    required this.onClearDate,
    required this.onClearStatus,
    required this.onClearCreator,
    required this.onClearAll,
  });

  final int activeFilterCount;
  final DateTimeRange? dateRange;
  final String datePreset;
  final String statusFilter;
  final String creatorFilter;
  final VoidCallback onClearDate;
  final VoidCallback onClearStatus;
  final VoidCallback onClearCreator;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    if (activeFilterCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (dateRange != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InputChip(
                  avatar: const Icon(Icons.date_range, size: 14),
                  label: Text(
                    datePreset != 'Custom' && datePreset != 'All time'
                        ? datePreset
                        : '${formatReportDate(dateRange!.start)} - ${formatReportDate(dateRange!.end)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  onDeleted: onClearDate,
                ),
              ),
            if (statusFilter != 'All statuses')
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InputChip(
                  avatar: const Icon(Icons.flag_outlined, size: 14),
                  label: Text(
                    statusFilter,
                    style: const TextStyle(fontSize: 11),
                  ),
                  onDeleted: onClearStatus,
                ),
              ),
            if (creatorFilter != 'All creators')
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InputChip(
                  avatar: const Icon(Icons.person_outline, size: 14),
                  label: Text(
                    creatorFilter,
                    style: const TextStyle(fontSize: 11),
                  ),
                  onDeleted: onClearCreator,
                ),
              ),
            ActionChip(
              avatar: const Icon(Icons.close, size: 14),
              label: const Text('Clear all', style: TextStyle(fontSize: 11)),
              onPressed: onClearAll,
            ),
          ],
        ),
      ),
    );
  }
}

class ReportColumn {
  const ReportColumn({
    required this.id,
    required this.title,
    required this.width,
    this.alignRight = false,
  });

  final String id;
  final String title;
  final double width;
  final bool alignRight;
}

class ReportEnterpriseDataGrid extends StatefulWidget {
  const ReportEnterpriseDataGrid({
    super.key,
    required this.reportType,
    required this.rows,
    required this.selectedIds,
    required this.onToggleSelect,
    required this.onSelectAll,
    required this.onDeselectAll,
    required this.onExportSelected,
    required this.onEditRow,
    required this.onDeleteRow,
    required this.onShareRow,
    required this.onChangeStatus,
    required this.onViewDetails,
    required this.formatCurrency,
    this.initialIsGrouped = false, // Classical flat table view by default
    this.pageSize = 20,
  });

  final ReportType reportType;
  final List<Map<String, dynamic>> rows;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggleSelect;
  final ValueChanged<List<String>> onSelectAll;
  final VoidCallback onDeselectAll;
  final VoidCallback onExportSelected;
  final ValueChanged<Map<String, dynamic>> onEditRow;
  final ValueChanged<Map<String, dynamic>> onDeleteRow;
  final ValueChanged<Map<String, dynamic>> onShareRow;
  final void Function(Map<String, dynamic> row, String newStatus) onChangeStatus;
  final ValueChanged<Map<String, dynamic>> onViewDetails;
  final String Function(double) formatCurrency;
  final bool initialIsGrouped;
  final int pageSize;

  @override
  State<ReportEnterpriseDataGrid> createState() => _ReportEnterpriseDataGridState();
}

class _ReportEnterpriseDataGridState extends State<ReportEnterpriseDataGrid> {
  bool? _userSelectedGrouped;
  bool? _userSelectedGridView;
  late int _pageSize;
  int _currentPage = 0;
  final Map<String, bool> _expandedCompanies = {};

  bool get _isGridView => _userSelectedGridView ?? (MediaQuery.sizeOf(context).width < 700);
  bool get _isGrouped => _userSelectedGrouped ?? widget.initialIsGrouped;

  @override
  void initState() {
    super.initState();
    _pageSize = widget.pageSize;
  }

  void _toggleGroup(String company) {
    setState(() {
      final current = _expandedCompanies[company] ?? true;
      _expandedCompanies[company] = !current;
    });
  }

  void _expandAll(List<String> companies) {
    setState(() {
      for (final c in companies) {
        _expandedCompanies[c] = true;
      }
    });
  }

  void _collapseAll(List<String> companies) {
    setState(() {
      for (final c in companies) {
        _expandedCompanies[c] = false;
      }
    });
  }

  List<String> _extractRowIds(List<Map<String, dynamic>> rows) {
    return rows.map(rowRecordId).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Column(
              children: [
                const Icon(
                  Icons.search_off_rounded,
                  size: 40,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(height: 12),
                Text(
                  'No ${widget.reportType.label.toLowerCase()} found matching current filters.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Grouping
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final row in widget.rows) {
      final comp = companyNameFromRow(row);
      grouped.putIfAbsent(comp, () => []).add(row);
    }

    final totalRowsCount = widget.rows.length;
    final totalPages = max(1, (totalRowsCount / _pageSize).ceil());
    if (_currentPage >= totalPages) {
      _currentPage = max(0, totalPages - 1);
    }

    final startIndex = _currentPage * _pageSize;
    final endIndex = min(startIndex + _pageSize, totalRowsCount);
    final pageRows = widget.rows.sublist(startIndex, endIndex);

    final pageGrouped = <String, List<Map<String, dynamic>>>{};
    for (final row in pageRows) {
      final comp = companyNameFromRow(row);
      pageGrouped.putIfAbsent(comp, () => []).add(row);
    }

    final allPageIds = _extractRowIds(pageRows);
    final allPageSelected = allPageIds.isNotEmpty &&
        allPageIds.every((id) => widget.selectedIds.contains(id));
    final somePageSelected =
        allPageIds.any((id) => widget.selectedIds.contains(id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Controls bar above table (Customize View, Group By, Table/Grid, Expand/Collapse)
        _buildControlsBar(
          grouped.keys.toList(growable: false),
          totalRowsCount,
          pageRows.length,
        ),
        const SizedBox(height: 10),

        // Multi-selection floating banner if items are selected
        if (widget.selectedIds.isNotEmpty) ...[
          _buildSelectionActionBar(totalRowsCount),
          const SizedBox(height: 10),
        ],

        // Main table or grid
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isGridView)
                _buildGridView(pageRows)
              else
                _buildTableView(
                  pageGrouped,
                  pageRows,
                  allPageSelected,
                  somePageSelected,
                  allPageIds,
                ),
              // Pagination Footer
              _buildPaginationFooter(
                totalRowsCount: totalRowsCount,
                startIndex: startIndex,
                endIndex: endIndex,
                totalPages: totalPages,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlsBar(
    List<String> allCompanies,
    int totalCount,
    int currentCount,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // 3-way Segmented View Mode Switcher
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModeChip(
                      icon: Icons.table_chart_rounded,
                      label: 'Table',
                      selected: !_isGridView && !_isGrouped,
                      onTap: () {
                        setState(() {
                          _userSelectedGridView = false;
                          _userSelectedGrouped = false;
                        });
                      },
                    ),
                    _buildModeChip(
                      icon: Icons.folder_copy_rounded,
                      label: 'Grouped',
                      selected: !_isGridView && _isGrouped,
                      onTap: () {
                        setState(() {
                          _userSelectedGridView = false;
                          _userSelectedGrouped = true;
                        });
                      },
                    ),
                    _buildModeChip(
                      icon: Icons.grid_view_rounded,
                      label: 'Cards',
                      selected: _isGridView,
                      onTap: () {
                        setState(() {
                          _userSelectedGridView = true;
                        });
                      },
                    ),
                  ],
                ),
              ),
              if (_isGrouped && !_isGridView) ...[
                TextButton.icon(
                  onPressed: () => _expandAll(allCompanies),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 30),
                  ),
                  icon: const Icon(Icons.unfold_more_rounded, size: 15),
                  label: const Text('Expand all', style: TextStyle(fontSize: 11)),
                ),
                TextButton.icon(
                  onPressed: () => _collapseAll(allCompanies),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 30),
                  ),
                  icon: const Icon(Icons.unfold_less_rounded, size: 15),
                  label: const Text('Collapse all', style: TextStyle(fontSize: 11)),
                ),
              ],
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Text(
              'Showing $currentCount of $totalCount',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionActionBar(int totalCount) {
    final count = widget.selectedIds.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count selected',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () {
              final allIds = _extractRowIds(widget.rows);
              widget.onSelectAll(allIds);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              'Select all $totalCount records',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: widget.onDeselectAll,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Clear', style: TextStyle(fontSize: 12)),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: widget.onExportSelected,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: const Size(0, 34),
            ),
            icon: const Icon(Icons.download_rounded, size: 16),
            label: Text(
              'Export ($count)',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  static const double _colCheckboxWidth = 44.0;

  static const List<ReportColumn> _invoiceColumns = [
    ReportColumn(id: 'invoiceNum', title: 'Invoice #', width: 130),
    ReportColumn(id: 'client', title: 'Client / Company', width: 220),
    ReportColumn(id: 'issueDate', title: 'Issue Date', width: 120),
    ReportColumn(id: 'dueDate', title: 'Due Date', width: 120),
    ReportColumn(id: 'amount', title: 'Total Amount', width: 130, alignRight: true),
    ReportColumn(id: 'balance', title: 'Paid / Balance', width: 140),
    ReportColumn(id: 'status', title: 'Status', width: 130),
    ReportColumn(id: 'action', title: 'Action', width: 70, alignRight: true),
  ];

  static const List<ReportColumn> _expenseColumns = [
    ReportColumn(id: 'title', title: 'Expense Title', width: 200),
    ReportColumn(id: 'vendor', title: 'Vendor / Merchant', width: 190),
    ReportColumn(id: 'category', title: 'Category', width: 140),
    ReportColumn(id: 'date', title: 'Date', width: 120),
    ReportColumn(id: 'amount', title: 'Amount', width: 130, alignRight: true),
    ReportColumn(id: 'tax', title: 'Tax Amount', width: 110),
    ReportColumn(id: 'status', title: 'Status', width: 130),
    ReportColumn(id: 'action', title: 'Action', width: 70, alignRight: true),
  ];

  static const List<ReportColumn> _clientColumns = [
    ReportColumn(id: 'name', title: 'Client Name', width: 190),
    ReportColumn(id: 'company', title: 'Company Name', width: 190),
    ReportColumn(id: 'email', title: 'Email Address', width: 210),
    ReportColumn(id: 'phone', title: 'Phone', width: 140),
    ReportColumn(id: 'paymentTerms', title: 'Payment Terms', width: 130),
    ReportColumn(id: 'addedDate', title: 'Added Date', width: 120),
    ReportColumn(id: 'status', title: 'Status', width: 130),
    ReportColumn(id: 'action', title: 'Action', width: 70, alignRight: true),
  ];

  static const List<ReportColumn> _allColumns = [
    ReportColumn(id: 'date', title: 'Record Date', width: 110),
    ReportColumn(id: 'ref', title: 'Reference / Voucher', width: 150),
    ReportColumn(id: 'party', title: 'Particulars / Account', width: 200),
    ReportColumn(id: 'type', title: 'Type', width: 95),
    ReportColumn(id: 'debit', title: 'Debit (Dr)', width: 120, alignRight: true),
    ReportColumn(id: 'credit', title: 'Credit (Cr)', width: 120, alignRight: true),
    ReportColumn(id: 'amount', title: 'Net Value', width: 125, alignRight: true),
    ReportColumn(id: 'status', title: 'Status', width: 120),
    ReportColumn(id: 'action', title: 'Action', width: 65, alignRight: true),
  ];

  List<ReportColumn> get _columns => switch (widget.reportType) {
        ReportType.invoices => _invoiceColumns,
        ReportType.expenses => _expenseColumns,
        ReportType.clients => _clientColumns,
        ReportType.all => _allColumns,
      };

  double get _tableTotalWidth {
    final sumCols = _columns.fold<double>(0.0, (sum, col) => sum + col.width);
    return _colCheckboxWidth + sumCols + 28.0; // 28 is horizontal padding (14 + 14)
  }

  Widget _buildTableView(
    Map<String, List<Map<String, dynamic>>> pageGrouped,
    List<Map<String, dynamic>> pageRows,
    bool allPageSelected,
    bool somePageSelected,
    List<String> allPageIds,
  ) {
    final columns = _columns;
    final totalWidth = _tableTotalWidth;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: SizedBox(
        width: totalWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Table Header Row dynamically built from record columns
            _buildHeaderRow(columns, allPageSelected, somePageSelected, allPageIds),

            // Rows (Grouped or Flat with classical zebra striping!)
            if (_isGrouped) ...[
              for (final entry in pageGrouped.entries)
                _buildCompanyGroupSection(entry.key, entry.value, columns),
            ] else ...[
              for (var i = 0; i < pageRows.length; i++)
                _buildDataTableRow(pageRows[i], columns, isNested: false, rowIndex: i),
            ],

            // Classical Ledger Totals Summary Row at the bottom
            _buildTableTotalsRow(columns, pageRows),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(
    List<ReportColumn> columns,
    bool allPageSelected,
    bool somePageSelected,
    List<String> allPageIds,
  ) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        border: Border(
          bottom: BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _colCheckboxWidth,
            child: Checkbox(
              value: allPageSelected
                  ? true
                  : (somePageSelected ? null : false),
              tristate: true,
              onChanged: (val) {
                if (val == true) {
                  widget.onSelectAll(allPageIds);
                } else {
                  widget.onDeselectAll();
                }
              },
            ),
          ),
          for (final col in columns)
            _buildHeaderCell(col.title, width: col.width, alignRight: col.alignRight),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, {required double width, bool alignRight = false}) {
    return SizedBox(
      width: width,
      child: Text(
        title.toUpperCase(),
        textAlign: alignRight ? TextAlign.end : TextAlign.start,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF334155),
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildTableTotalsRow(
    List<ReportColumn> columns,
    List<Map<String, dynamic>> rows,
  ) {
    var totalDr = 0.0;
    var totalCr = 0.0;
    var totalNet = 0.0;
    var totalTax = 0.0;

    for (final r in rows) {
      final type = rowRecordType(r);
      final eff = rowEffectiveAmount(r);
      totalTax += reportNumber(r['taxAmount']);
      if (type == 'EXPENSE') {
        totalDr += eff;
        totalNet -= eff;
      } else if (type == 'INVOICE') {
        totalCr += eff;
        totalNet += eff;
      }
    }

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
          bottom: BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: _colCheckboxWidth,
            child: Icon(Icons.calculate_outlined, size: 16, color: Color(0xFF64748B)),
          ),
          for (final col in columns)
            SizedBox(
              width: col.width,
              child: _buildTotalsCell(col, totalDr, totalCr, totalNet, totalTax, rows.length),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalsCell(
    ReportColumn col,
    double totalDr,
    double totalCr,
    double totalNet,
    double totalTax,
    int count,
  ) {
    switch (col.id) {
      case 'date':
      case 'invoiceNum':
      case 'title':
      case 'name':
      case 'ref':
        return Text(
          'TOTALS ($count items)',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: 0.2,
          ),
        );
      case 'debit':
        return totalDr > 0
            ? Text(
                widget.formatCurrency(totalDr),
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFDC2626),
                ),
              )
            : const Text('—', textAlign: TextAlign.end, style: TextStyle(color: Color(0xFF94A3B8)));
      case 'credit':
        return totalCr > 0
            ? Text(
                widget.formatCurrency(totalCr),
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF16A34A),
                ),
              )
            : const Text('—', textAlign: TextAlign.end, style: TextStyle(color: Color(0xFF94A3B8)));
      case 'amount':
        return Text(
          widget.formatCurrency(totalNet),
          textAlign: TextAlign.end,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: totalNet >= 0 ? const Color(0xFF0F172A) : const Color(0xFFDC2626),
          ),
        );
      case 'tax':
        return totalTax > 0
            ? Text(
                widget.formatCurrency(totalTax),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
              )
            : const Text('—', style: TextStyle(color: Color(0xFF94A3B8)));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCompanyGroupSection(
    String company,
    List<Map<String, dynamic>> items,
    List<ReportColumn> columns,
  ) {
    final isExpanded = _expandedCompanies[company] ?? true;
    final itemIds = _extractRowIds(items);
    final allSelected = itemIds.isNotEmpty &&
        itemIds.every((id) => widget.selectedIds.contains(id));
    final someSelected = itemIds.any((id) => widget.selectedIds.contains(id));
    final groupTotal = items.fold<double>(0, (sum, item) => sum + calculateInvoiceTotal(item));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Company Group Header Bar - Clean White/Light Neutral
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0)),
              top: BorderSide(color: Color(0xFFE2E8F0), width: 0.5),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: _colCheckboxWidth,
                child: Checkbox(
                  value: allSelected ? true : (someSelected ? null : false),
                  tristate: true,
                  onChanged: (val) {
                    if (val == true) {
                      final updated = Set<String>.from(widget.selectedIds)..addAll(itemIds);
                      widget.onSelectAll(updated.toList(growable: false));
                    } else {
                      final updated = Set<String>.from(widget.selectedIds)..removeAll(itemIds);
                      widget.onSelectAll(updated.toList(growable: false));
                    }
                  },
                ),
              ),
              InkWell(
                onTap: () => _toggleGroup(company),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_right_rounded,
                        size: 20,
                        color: const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color(0xFFF1F5F9),
                        child: Text(
                          company.isNotEmpty ? company[0].toUpperCase() : 'C',
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        company,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Text(
                  '${items.length} ${items.length == 1 ? "record" : "records"}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              if (groupTotal > 0) ...[
                const SizedBox(width: 10),
                Text(
                  widget.formatCurrency(groupTotal),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
              const Spacer(),
              TextButton.icon(
                onPressed: () => _toggleGroup(company),
                icon: Icon(
                  isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 16,
                  color: const Color(0xFF64748B),
                ),
                label: Text(
                  isExpanded ? 'Collapse' : 'Expand',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ),

        // Child Rows
        if (isExpanded)
          for (var i = 0; i < items.length; i++)
            _buildDataTableRow(items[i], columns, isNested: true, rowIndex: i),
      ],
    );
  }

  Widget _buildDataTableRow(
    Map<String, dynamic> row,
    List<ReportColumn> columns, {
    required bool isNested,
    int rowIndex = 0,
  }) {
    final id = rowRecordId(row);
    final isSelected = widget.selectedIds.contains(id);
    final isEven = (rowIndex % 2 == 0);

    final rowColor = isSelected
        ? const Color(0xFFEFF6FF)
        : (isNested
            ? (isEven ? const Color(0xFFFAFAFA) : const Color(0xFFF1F5F9))
            : (isEven ? Colors.white : const Color(0xFFF8FAFC)));

    return Material(
      color: rowColor,
      child: InkWell(
        onTap: () => widget.onToggleSelect(id),
        hoverColor: const Color(0xFFF1F5F9),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: const BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
              left: isSelected
                  ? const BorderSide(color: Color(0xFF0284C7), width: 3.5)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: _colCheckboxWidth,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => widget.onToggleSelect(id),
                ),
              ),
              for (final col in columns)
                SizedBox(
                  width: col.width,
                  child: _buildCellContent(row, col),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCellContent(Map<String, dynamic> row, ReportColumn col) {
    final company = companyNameFromRow(row);
    final clientSubtitle = reportText(row['clientName'] ?? row['name'], fallback: 'Client');
    final invoiceNum = rowInvoiceNumber(row);
    final total = calculateInvoiceTotal(row);
    final paid = reportNumber(row['amountPaid']);
    final balance = (total - paid).clamp(0.0, double.infinity);
    final issueDate = rowCreatedDateTime(row);
    final dueDate = rowUpdatedDateTime(row);

    switch (col.id) {
      case 'invoiceNum':
        return Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: () => widget.onViewDetails(row),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      invoiceNum,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      case 'client':
        return Row(
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: const Color(0xFFF1F5F9),
              child: Text(
                company.isNotEmpty ? company[0].toUpperCase() : 'C',
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    clientSubtitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case 'issueDate':
        return Text(
          formatReportDate(issueDate),
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
        );

      case 'dueDate':
        return Text(
          formatReportDate(dueDate),
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
        );

      case 'amount':
        final effAmount = rowEffectiveAmount(row);
        final isExp = rowRecordType(row) == 'EXPENSE';
        return Text(
          '${isExp ? '-' : ''}${widget.formatCurrency(effAmount)}',
          textAlign: TextAlign.end,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isExp ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
          ),
        );

      case 'balance':
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bal: ${widget.formatCurrency(balance)}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            Text(
              'Paid: ${widget.formatCurrency(paid)}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        );

      case 'title':
        final title = reportText(row['title'], fallback: 'Expense Item');
        final category = rowCategory(row);
        return Row(
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: const Color(0xFFF1F5F9),
              child: Text(
                title.isNotEmpty ? title[0].toUpperCase() : 'E',
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    category,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case 'vendor':
        final vendor = rowVendorName(row);
        return Text(
          vendor,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w500),
        );

      case 'category':
        final cat = rowCategory(row);
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              cat,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );

      case 'date':
        return Text(
          formatReportDate(rowCreatedDateTime(row)),
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
        );

      case 'tax':
        final taxAmount = reportNumber(row['taxAmount']);
        final taxStr = taxAmount > 0 ? widget.formatCurrency(taxAmount) : '—';
        return Text(
          taxStr,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        );

      case 'name':
        final name = rowClientName(row);
        return Row(
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: const Color(0xFFF1F5F9),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        );

      case 'company':
        return Text(
          company,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
        );

      case 'email':
        return Text(
          rowEmail(row),
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
        );

      case 'phone':
        return Text(
          rowPhone(row),
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        );

      case 'paymentTerms':
        return Text(
          rowPaymentTerms(row),
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
        );

      case 'addedDate':
        return Text(
          formatReportDate(rowCreatedDateTime(row)),
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
        );

      case 'debit':
        final isExp = rowRecordType(row) == 'EXPENSE';
        final effAmount = rowEffectiveAmount(row);
        return Align(
          alignment: Alignment.centerRight,
          child: Text(
            isExp ? widget.formatCurrency(effAmount) : '—',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isExp ? FontWeight.w700 : FontWeight.normal,
              color: isExp ? const Color(0xFFDC2626) : const Color(0xFF94A3B8),
            ),
          ),
        );

      case 'credit':
        final isInv = rowRecordType(row) == 'INVOICE';
        final effAmount = rowEffectiveAmount(row);
        return Align(
          alignment: Alignment.centerRight,
          child: Text(
            isInv ? widget.formatCurrency(effAmount) : '—',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isInv ? FontWeight.w700 : FontWeight.normal,
              color: isInv ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
            ),
          ),
        );

      case 'type':
        final type = rowRecordType(row);
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              type,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
          ),
        );

      case 'ref':
        final ref = reportText(row['invoiceNumber'] ?? row['title'] ?? row['name'], fallback: '—');
        return Text(
          ref,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        );

      case 'party':
        return Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: const Color(0xFFF1F5F9),
              child: Text(
                company.isNotEmpty ? company[0].toUpperCase() : 'P',
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                company,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        );

      case 'status':
        return Align(
          alignment: Alignment.centerLeft,
          child: _buildStatusDropdown(row),
        );

      case 'action':
        return Align(
          alignment: Alignment.centerRight,
          child: _buildRowPopupMenu(row),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStatusDropdown(Map<String, dynamic> row) {
    final status = statusLabelFromRow(row);
    final fg = statusColor(status);
    final bg = statusBgColor(status);
    final border = statusBorderColor(status);

    final statusOptions = switch (widget.reportType) {
      ReportType.invoices => const [
          'Paid',
          'Sent',
          'Pending',
          'Draft',
          'Overdue',
          'Cancelled',
        ],
      ReportType.expenses => const [
          'Paid',
          'Approved',
          'Pending',
          'Draft',
          'Rejected',
        ],
      ReportType.clients => const [
          'Active',
          'Inactive',
        ],
      ReportType.all => const [
          'Paid',
          'Active',
          'Pending',
          'Draft',
          'Overdue',
          'Cancelled',
        ],
    };

    return PopupMenuButton<String>(
      tooltip: 'Change Status',
      initialValue: status,
      onSelected: (newStatus) {
        if (newStatus != status) {
          widget.onChangeStatus(row, newStatus);
        }
      },
      itemBuilder: (context) => [
        for (final s in statusOptions)
          PopupMenuItem<String>(
            value: s,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 4,
                  backgroundColor: statusColor(s),
                ),
                const SizedBox(width: 8),
                Text(
                  s,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: s == status ? FontWeight.w800 : FontWeight.w500,
                    color: s == status ? statusColor(s) : const Color(0xFF0F172A),
                  ),
                ),
                if (s == status) ...[
                  const Spacer(),
                  Icon(Icons.check_rounded, size: 16, color: statusColor(s)),
                ],
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: fg,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                status,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down_rounded, size: 14, color: fg),
          ],
        ),
      ),
    );
  }

  Widget _buildRowPopupMenu(Map<String, dynamic> row) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF64748B)),
      tooltip: 'Actions',
      onSelected: (action) {
        switch (action) {
          case 'preview':
            widget.onViewDetails(row);
            break;
          case 'edit':
            widget.onEditRow(row);
            break;
          case 'share':
            widget.onShareRow(row);
            break;
          case 'status':
            _showQuickStatusPicker(row);
            break;
          case 'delete':
            widget.onDeleteRow(row);
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'preview',
          child: ListTile(
            leading: Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF475569)),
            title: Text('Preview', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit_outlined, size: 18, color: Color(0xFF475569)),
            title: Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'share',
          child: ListTile(
            leading: Icon(Icons.share_outlined, size: 18, color: Color(0xFF475569)),
            title: Text('Share / PDF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'status',
          child: ListTile(
            leading: Icon(Icons.published_with_changes_outlined, size: 18, color: Color(0xFF475569)),
            title: Text('Change Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
            title: Text('Delete', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  void _showQuickStatusPicker(Map<String, dynamic> row) {
    final currentStatus = statusLabelFromRow(row);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Change Status for ${companyNameFromRow(row)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Current: $currentStatus',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusOptionPill(ctx, row, 'Paid', const Color(0xFF059669)),
                _buildStatusOptionPill(ctx, row, 'Sent', const Color(0xFFD97706)),
                _buildStatusOptionPill(ctx, row, 'Pending', const Color(0xFFD97706)),
                _buildStatusOptionPill(ctx, row, 'Draft', const Color(0xFF475569)),
                _buildStatusOptionPill(ctx, row, 'Overdue', const Color(0xFFDC2626)),
                _buildStatusOptionPill(ctx, row, 'Cancelled', const Color(0xFFDC2626)),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOptionPill(
    BuildContext ctx,
    Map<String, dynamic> row,
    String status,
    Color color,
  ) {
    return ActionChip(
      avatar: CircleAvatar(radius: 4, backgroundColor: color),
      label: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      onPressed: () {
        Navigator.pop(ctx);
        widget.onChangeStatus(row, status);
      },
    );
  }

  Widget _buildGridView(List<Map<String, dynamic>> pageRows) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 900
              ? 3
              : (constraints.maxWidth > 600 ? 2 : 1);

          return Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final row in pageRows)
                SizedBox(
                  width: (constraints.maxWidth - (crossAxisCount - 1) * 14) /
                      crossAxisCount,
                  child: _buildGridCard(row),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGridCard(Map<String, dynamic> row) {
    final id = rowRecordId(row);
    final isSelected = widget.selectedIds.contains(id);
    final company = companyNameFromRow(row);
    final total = calculateInvoiceTotal(row);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header: Checkbox + Monogram + Title + Action Menu
          Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (_) => widget.onToggleSelect(id),
              ),
              CircleAvatar(
                radius: 13,
                backgroundColor: const Color(0xFFF1F5F9),
                child: Text(
                  company.isNotEmpty ? company[0].toUpperCase() : 'R',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  company,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              _buildRowPopupMenu(row),
            ],
          ),
          const SizedBox(height: 10),

          // Content body tailored dynamically based on record type
          _buildGridCardBody(row, total),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Bottom Bar: ONLY the Status badge has color! Quick actions are neutral.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusDropdown(row),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => widget.onViewDetails(row),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 28),
                    ),
                    child: const Text('View', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  TextButton(
                    onPressed: () => widget.onEditRow(row),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 28),
                    ),
                    child: const Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridCardBody(Map<String, dynamic> row, double total) {
    switch (widget.reportType) {
      case ReportType.invoices:
        final invoiceNum = rowInvoiceNumber(row);
        final paid = reportNumber(row['amountPaid']);
        final balance = (total - paid).clamp(0.0, double.infinity);
        final dueDate = rowUpdatedDateTime(row);
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  invoiceNum,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                Text(
                  widget.formatCurrency(total),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Due: ${formatReportDate(dueDate)}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                Text(
                  'Bal: ${widget.formatCurrency(balance)}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
              ],
            ),
          ],
        );

      case ReportType.expenses:
        final title = reportText(row['title'], fallback: 'Expense Item');
        final category = rowCategory(row);
        final date = rowCreatedDateTime(row);
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                ),
                Text(
                  widget.formatCurrency(total),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(category, style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
                ),
                Text(
                  formatReportDate(date),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        );

      case ReportType.clients:
        final email = rowEmail(row);
        final phone = rowPhone(row);
        final terms = rowPaymentTerms(row);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email, style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(phone, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                Text(terms, style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        );

      case ReportType.all:
        final type = rowRecordType(row);
        final ref = reportText(row['invoiceNumber'] ?? row['title'] ?? row['name'], fallback: '—');
        final date = rowCreatedDateTime(row);
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(type, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                ),
                if (total > 0)
                  Text(
                    widget.formatCurrency(total),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(ref, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                Text(formatReportDate(date), style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ],
        );
    }
  }

  Widget _buildPaginationFooter({
    required int totalRowsCount,
    required int startIndex,
    required int endIndex,
    required int totalPages,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 10,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Rows per page:',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _pageSize,
                    isDense: true,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 10, child: Text('10', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 20, child: Text('20', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 50, child: Text('50', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 100, child: Text('100', style: TextStyle(fontSize: 12))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _pageSize = val;
                          _currentPage = 0;
                        });
                      }
                    },
                  ),
                ],
              ),
              Text(
                'Showing ${startIndex + 1} to $endIndex of $totalRowsCount records',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // Page Buttons (Horizontally scrollable for small screens / tablets)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.first_page_rounded, size: 18),
                  tooltip: 'First page',
                  onPressed: _currentPage > 0 ? () => setState(() => _currentPage = 0) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 20),
                  tooltip: 'Previous page',
                  onPressed:
                      _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                ),
                for (var i = max(0, _currentPage - 2);
                    i <= min(totalPages - 1, _currentPage + 2);
                    i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentPage = i),
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                            _currentPage == i ? const Color(0xFF0284C7) : Colors.white,
                        foregroundColor:
                            _currentPage == i ? Colors.white : const Color(0xFF475569),
                        side: BorderSide(
                          color: _currentPage == i
                              ? const Color(0xFF0284C7)
                              : const Color(0xFFCBD5E1),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: const Size(32, 32),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 20),
                  tooltip: 'Next page',
                  onPressed: _currentPage < totalPages - 1
                      ? () => setState(() => _currentPage++)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.last_page_rounded, size: 18),
                  tooltip: 'Last page',
                  onPressed: _currentPage < totalPages - 1
                      ? () => setState(() => _currentPage = totalPages - 1)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReportErrorState extends StatelessWidget {
  const ReportErrorState({required this.message, required this.onRetry, super.key});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 40, color: Color(0xFFEF4444)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}
