import 'dart:math';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'app_card.dart';

/// Interactive KPI summary card item matching Invoices design
class EnterpriseMetricCardItem {
  const EnterpriseMetricCardItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.filterKey,
    this.count,
    this.isSelected = false,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? filterKey;
  final String? count;
  final bool isSelected;
  final VoidCallback? onTap;
}

/// Unified 4-KPI metrics strip with Neumorphic sculpted card styling and interactive filter-on-click
class EnterpriseMetricsStrip extends StatelessWidget {
  const EnterpriseMetricsStrip({
    required this.metrics,
    super.key,
  });

  final List<EnterpriseMetricCardItem> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final cardWidth = isWide
            ? (constraints.maxWidth - (metrics.length - 1) * 14) / metrics.length
            : (constraints.maxWidth - 14) / 2;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: metrics.map((m) {
            return SizedBox(
              width: cardWidth,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: m.onTap,
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: AppTheme.neuCardDecoration(
                      radius: 20,
                      selected: m.isSelected,
                      accentColor: m.color,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: AppTheme.neuOrbDecoration(
                            active: m.isSelected,
                            activeColor: m.color,
                            shape: BoxShape.rectangle,
                            radius: 13,
                          ),
                          child: Icon(
                            m.icon,
                            color: m.isSelected ? Colors.white : m.color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                m.value,
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                m.label,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (m.isSelected)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: m.color,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, size: 10, color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Column definition for [EnterpriseDataView] table view with sorting support.
class EnterpriseTableColumn<T> {
  const EnterpriseTableColumn({
    required this.title,
    required this.cellBuilder,
    this.width = 150,
    this.alignRight = false,
    this.sortKey,
  });

  final String title;
  final Widget Function(BuildContext context, T item) cellBuilder;
  final double width;
  final bool alignRight;
  final Comparable<dynamic>? Function(T item)? sortKey;
}

/// Generic, highly reusable enterprise data view supporting:
/// 1. 3 View Modes: **Table** (classical zebra table), **Grouped** (collapsible category accordion), and **Cards** (mobile list show).
/// 2. **Adaptive Defaults**: Defaults to `Cards` on mobile (< 700px) and `Table` on desktop/tablet (>= 700px), with user mode override.
/// 3. Search & Filter Bar with horizontal choice chips.
/// 4. Multi-item selection & pagination footer.
/// 5. Column sorting (ascending/descending toggle with indicator).
/// 6. Directory toolbar with Date Range picker & Download Report icons.
class EnterpriseDataView<T> extends StatefulWidget {
  const EnterpriseDataView({
    required this.items,
    required this.cardBuilder,
    required this.columns,
    this.groupBy,
    this.groupLabelBuilder,
    this.idGetter,
    this.selectedIds,
    this.onToggleSelect,
    this.onSelectAll,
    this.onDeselectAll,
    this.batchActions,
    this.onRowTap,
    this.searchHint = 'Search records...',
    this.searchController,
    this.onSearchChanged,
    this.searchFilter,
    this.showSearchBar = true,
    this.filterChips,
    this.selectedFilterChip,
    this.onFilterChipSelected,
    this.filterWidget,
    this.topTrailing,
    this.headerTitle,
    this.metrics,
    this.metricsStrip,
    this.dateRange,
    this.onDateRangeChanged,
    this.onDownloadReport,
    this.directoryActions,
    this.emptyWidget,
    this.emptyMessage = 'No records found matching current criteria.',
    this.pageSize = 20,
    this.initialMode, // 'table', 'grouped', 'cards'
    super.key,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item) cardBuilder;
  final List<EnterpriseTableColumn<T>> columns;
  final String Function(T item)? groupBy;
  final String Function(String groupKey, List<T> groupItems)? groupLabelBuilder;
  final String Function(T item)? idGetter;
  final Set<String>? selectedIds;
  final ValueChanged<String>? onToggleSelect;
  final ValueChanged<List<String>>? onSelectAll;
  final VoidCallback? onDeselectAll;
  final List<Widget>? batchActions;
  final ValueChanged<T>? onRowTap;

  final String searchHint;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final bool Function(T item, String query)? searchFilter;
  final bool showSearchBar;

  final List<String>? filterChips;
  final String? selectedFilterChip;
  final ValueChanged<String>? onFilterChipSelected;
  final Widget? filterWidget;

  final Widget? topTrailing;
  final String? headerTitle;
  final List<EnterpriseMetricCardItem>? metrics;
  final Widget? metricsStrip;
  final DateTimeRange? dateRange;
  final ValueChanged<DateTimeRange?>? onDateRangeChanged;
  final VoidCallback? onDownloadReport;
  final List<Widget>? directoryActions;

  final Widget? emptyWidget;
  final String emptyMessage;
  final int pageSize;
  final String? initialMode; // 'table', 'grouped', 'cards'

  @override
  State<EnterpriseDataView<T>> createState() => _EnterpriseDataViewState<T>();
}

class _EnterpriseDataViewState<T> extends State<EnterpriseDataView<T>> {
  late final TextEditingController _internalSearchController;
  TextEditingController get _searchController => widget.searchController ?? _internalSearchController;

  String? _userSelectedMode; // 'table', 'grouped', 'cards'
  late int _pageSize;
  int _currentPage = 0;
  final Map<String, bool> _expandedGroups = {};

  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _internalSearchController = TextEditingController();
    _pageSize = widget.pageSize;
    if (widget.initialMode != null) {
      _userSelectedMode = widget.initialMode;
    }
  }

  @override
  void dispose() {
    if (widget.searchController == null) {
      _internalSearchController.dispose();
    }
    super.dispose();
  }

  String _resolveActiveMode(double screenWidth) {
    if (_userSelectedMode != null) return _userSelectedMode!;
    // Default to Cards view on mobile (< 700px), Table on desktop (>= 700px)
    return screenWidth < 700 ? 'cards' : 'table';
  }

  List<T> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();
    var list = widget.items;
    if (query.isNotEmpty && widget.searchFilter != null) {
      list = list.where((item) => widget.searchFilter!(item, query)).toList();
    }
    if (_sortColumnIndex != null &&
        _sortColumnIndex! >= 0 &&
        _sortColumnIndex! < widget.columns.length) {
      final col = widget.columns[_sortColumnIndex!];
      if (col.sortKey != null) {
        list = List<T>.from(list)..sort((a, b) {
          final aVal = col.sortKey!(a);
          final bVal = col.sortKey!(b);
          if (aVal == null && bVal == null) return 0;
          if (aVal == null) return _sortAscending ? -1 : 1;
          if (bVal == null) return _sortAscending ? 1 : -1;
          final cmp = aVal.compareTo(bVal);
          return _sortAscending ? cmp : -cmp;
        });
      }
    }
    return list;
  }

  void _toggleGroup(String key) {
    setState(() {
      final current = _expandedGroups[key] ?? true;
      _expandedGroups[key] = !current;
    });
  }

  void _expandAll(List<String> keys) {
    setState(() {
      for (final k in keys) {
        _expandedGroups[k] = true;
      }
    });
  }

  void _collapseAll(List<String> keys) {
    setState(() {
      for (final k in keys) {
        _expandedGroups[k] = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final activeMode = _resolveActiveMode(screenWidth);
    final filtered = _filteredItems;

    // Grouping
    final Map<String, List<T>> grouped = {};
    if (widget.groupBy != null) {
      for (final item in filtered) {
        final key = widget.groupBy!(item);
        grouped.putIfAbsent(key.isNotEmpty ? key : 'General', () => []).add(item);
      }
    }

    // Pagination
    final totalCount = filtered.length;
    final totalPages = max(1, (totalCount / _pageSize).ceil());
    if (_currentPage >= totalPages) {
      _currentPage = max(0, totalPages - 1);
    }
    final startIndex = _currentPage * _pageSize;
    final endIndex = min(startIndex + _pageSize, totalCount);
    final pageItems = totalCount > 0 ? filtered.sublist(startIndex, endIndex) : <T>[];

    final pageGrouped = <String, List<T>>{};
    if (widget.groupBy != null) {
      for (final item in pageItems) {
        final key = widget.groupBy!(item);
        pageGrouped.putIfAbsent(key.isNotEmpty ? key : 'General', () => []).add(item);
      }
    }

    final hasSelection = widget.selectedIds != null && widget.idGetter != null;
    final pageIds = hasSelection ? pageItems.map(widget.idGetter!).toList() : <String>[];
    final allPageSelected = pageIds.isNotEmpty && pageIds.every((id) => widget.selectedIds!.contains(id));
    final somePageSelected = pageIds.any((id) => widget.selectedIds!.contains(id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Optional top metrics strip
        if (widget.metrics != null && widget.metricsStrip == null) ...[
          EnterpriseMetricsStrip(metrics: widget.metrics!),
          const SizedBox(height: 14),
        ] else if (widget.metricsStrip != null) ...[
          widget.metricsStrip!,
          const SizedBox(height: 14),
        ],

        // Unified Search & Filter Bar
        if (widget.showSearchBar || (widget.filterChips != null && widget.filterChips!.isNotEmpty) || widget.filterWidget != null) ...[
          _buildFilterSearchBar(screenWidth),
          const SizedBox(height: 10),
        ],

        // Controls bar: 3-way View Mode Switcher (Table, Grouped, Cards), Count, Group actions, Trailing
        _buildControlsBar(
          activeMode: activeMode,
          totalCount: totalCount,
          groupedKeys: grouped.keys.toList(),
          screenWidth: screenWidth,
        ),
        const SizedBox(height: 10),

        // Selection Action Bar (if items selected)
        if (hasSelection && widget.selectedIds!.isNotEmpty) ...[
          _buildSelectionActionBar(totalCount),
          const SizedBox(height: 10),
        ],

        // Main Content Area
        if (filtered.isEmpty)
          widget.emptyWidget ?? _buildDefaultEmptyWidget()
        else if (activeMode == 'cards')
          _buildCardsView(pageItems, screenWidth)
        else if (activeMode == 'grouped' && widget.groupBy != null)
          _buildGroupedView(pageGrouped, screenWidth)
        else
          _buildTableView(pageItems, allPageSelected, somePageSelected, pageIds),

        // Pagination Footer
        if (filtered.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildPaginationFooter(
            totalCount: totalCount,
            startIndex: startIndex,
            endIndex: endIndex,
            totalPages: totalPages,
          ),
        ],
      ],
    );
  }

  Widget _buildFilterSearchBar(double screenWidth) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showSearchBar)
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 500;
                if (isNarrow && widget.topTrailing != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSearchField(),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: widget.topTrailing!,
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: _buildSearchField()),
                    if (widget.topTrailing != null) ...[
                      const SizedBox(width: 10),
                      widget.topTrailing!,
                    ],
                  ],
                );
              },
            ),

          // Custom Filter Widget (if provided)
          if (widget.filterWidget != null) ...[
            if (widget.showSearchBar) const SizedBox(height: 10),
            widget.filterWidget!,
          ],

          // Horizontal Filter ChoiceChips
          if (widget.filterChips != null && widget.filterChips!.isNotEmpty) ...[
            if (widget.showSearchBar || widget.filterWidget != null) const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final chip in widget.filterChips!)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          chip,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: widget.selectedFilterChip == chip ? FontWeight.w800 : FontWeight.w600,
                            color: widget.selectedFilterChip == chip ? const Color(0xFF0F172A) : const Color(0xFF475569),
                          ),
                        ),
                        selected: widget.selectedFilterChip == chip,
                        selectedColor: const Color(0xFFE2E8F0),
                        backgroundColor: AppColors.neuSurface,
                        side: BorderSide(
                          color: widget.selectedFilterChip == chip ? const Color(0xFFCBD5E1) : Colors.white.withValues(alpha: 0.85),
                        ),
                        onSelected: (selected) {
                          if (selected && widget.onFilterChipSelected != null) {
                            setState(() => _currentPage = 0);
                            widget.onFilterChipSelected!(chip);
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (val) {
        setState(() => _currentPage = 0);
        widget.onSearchChanged?.call(val);
      },
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.searchHint,
        prefixIcon: const Icon(Icons.search, size: 18),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 16),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _currentPage = 0);
                  widget.onSearchChanged?.call('');
                },
              )
            : null,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
      ),
    );
  }

  Future<void> _openFilterDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => EnterpriseFilterDialog(
        currentRange: widget.dateRange,
        onApplyDateRange: (range) => widget.onDateRangeChanged?.call(range),
        statusOptions: widget.filterChips,
        selectedStatus: widget.selectedFilterChip,
        onStatusSelected: (status) => widget.onFilterChipSelected?.call(status),
      ),
    );
  }

  Widget _buildControlsBar({
    required String activeMode,
    required int totalCount,
    required List<String> groupedKeys,
    required double screenWidth,
  }) {
    final hasGrouping = widget.groupBy != null;
    final isCompact = screenWidth < 500;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppTheme.neuCardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dedicated Header Title Row with auto-truncation and record badge
          if (widget.headerTitle != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.headerTitle!,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.dateRange != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.date_range_rounded, size: 12, color: Color(0xFF0284C7)),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.dateRange!.start.toIso8601String().substring(0, 10)} - ${widget.dateRange!.end.toIso8601String().substring(0, 10)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => widget.onDateRangeChanged?.call(null),
                          child: const Icon(Icons.close_rounded, size: 12, color: Color(0xFF0284C7)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (widget.onDateRangeChanged != null || (widget.filterChips != null && widget.filterChips!.isNotEmpty)) ...[
                  IconButton(
                    icon: Icon(
                      (widget.dateRange != null || (widget.selectedFilterChip != null && widget.selectedFilterChip != 'All'))
                          ? Icons.filter_alt_rounded
                          : Icons.filter_alt_outlined,
                      size: 18,
                      color: (widget.dateRange != null || (widget.selectedFilterChip != null && widget.selectedFilterChip != 'All'))
                          ? const Color(0xFF0284C7)
                          : const Color(0xFF64748B),
                    ),
                    tooltip: 'Filter records',
                    visualDensity: VisualDensity.compact,
                    onPressed: _openFilterDialog,
                  ),
                  const SizedBox(width: 2),
                ],
                if (widget.onDownloadReport != null) ...[
                  IconButton(
                    icon: const Icon(Icons.file_download_outlined, size: 18, color: Color(0xFF0284C7)),
                    tooltip: 'Download report',
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.onDownloadReport,
                  ),
                  const SizedBox(width: 2),
                ],
                if (widget.directoryActions != null) ...[
                  ...widget.directoryActions!,
                  const SizedBox(width: 2),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: AppTheme.neuRecessedDecoration(radius: 12),
                  child: Text(
                    '$totalCount ${totalCount == 1 ? 'record' : 'records'}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Controls Row: Mode Switcher + Grouping Actions + optional record count
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              // 3-way Segmented Mode Switcher
              Container(
                decoration: AppTheme.neuRecessedDecoration(radius: 12),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModeChip(
                      icon: Icons.table_chart_rounded,
                      label: 'Table',
                      selected: activeMode == 'table',
                      isCompact: isCompact,
                      onTap: () => setState(() => _userSelectedMode = 'table'),
                    ),
                    if (hasGrouping)
                      _buildModeChip(
                        icon: Icons.folder_copy_rounded,
                        label: 'Grouped',
                        selected: activeMode == 'grouped',
                        isCompact: isCompact,
                        onTap: () => setState(() => _userSelectedMode = 'grouped'),
                      ),
                    _buildModeChip(
                      icon: Icons.grid_view_rounded,
                      label: 'Cards',
                      selected: activeMode == 'cards',
                      isCompact: isCompact,
                      onTap: () => setState(() => _userSelectedMode = 'cards'),
                    ),
                  ],
                ),
              ),

              // Expand / Collapse quick actions in grouped mode
              if (activeMode == 'grouped' && groupedKeys.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _expandAll(groupedKeys),
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text(
                          'Expand All',
                          style: TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _collapseAll(groupedKeys),
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text(
                          'Collapse All',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),

              // If no headerTitle, show count & action icons here
              if (widget.headerTitle == null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onDateRangeChanged != null)
                      IconButton(
                        icon: const Icon(Icons.filter_alt_outlined, size: 18, color: Color(0xFF64748B)),
                        tooltip: 'Filter date range',
                        visualDensity: VisualDensity.compact,
                        onPressed: _openFilterDialog,
                      ),
                    if (widget.onDownloadReport != null)
                      IconButton(
                        icon: const Icon(Icons.file_download_outlined, size: 18, color: Color(0xFF0284C7)),
                        tooltip: 'Download report',
                        visualDensity: VisualDensity.compact,
                        onPressed: widget.onDownloadReport,
                      ),
                    Text(
                      '$totalCount ${totalCount == 1 ? 'record' : 'records'}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip({
    required IconData icon,
    required String label,
    required bool selected,
    required bool isCompact,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 9 : 11,
          vertical: isCompact ? 5 : 6,
        ),
        decoration: selected
            ? BoxDecoration(
                color: AppColors.neuSurface,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.neuShadowDark,
                    offset: Offset(2, 2),
                    blurRadius: 5,
                  ),
                  BoxShadow(
                    color: AppColors.neuShadowLight,
                    offset: Offset(-2, -2),
                    blurRadius: 5,
                  ),
                ],
              )
            : const BoxDecoration(color: Colors.transparent),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isCompact ? 13 : 15,
              color: selected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
            ),
            SizedBox(width: isCompact ? 4 : 5),
            Text(
              label,
              style: TextStyle(
                fontSize: isCompact ? 11 : 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? const Color(0xFF1E293B) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionActionBar(int totalCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0284C7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_box_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            '${widget.selectedIds!.length} of $totalCount selected',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          if (widget.batchActions != null && widget.batchActions!.isNotEmpty) ...[
            const SizedBox(width: 16),
            ...widget.batchActions!,
          ],
          const Spacer(),
          TextButton(
            onPressed: widget.onDeselectAll,
            child: const Text('Deselect All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 1. Cards View (Dense mobile card show, multi-column desktop grid via LayoutBuilder)
  Widget _buildCardsView(List<T> items, double screenWidth) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final columnsCount = availableWidth >= 1200
            ? 4
            : (availableWidth >= 800
                ? 3
                : (availableWidth >= 550 ? 2 : 1));

        if (columnsCount > 1) {
          const spacing = 12.0;
          final totalSpacing = spacing * (columnsCount - 1);
          final cardWidth = (availableWidth - totalSpacing) / columnsCount;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: items.map((item) {
              return SizedBox(
                width: cardWidth,
                child: widget.cardBuilder(context, item),
              );
            }).toList(),
          );
        }

        return Column(
          children: [
            for (final item in items) ...[
              widget.cardBuilder(context, item),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  // 2. Grouped View (Collapsible Accordion containing Cards or Table)
  Widget _buildGroupedView(Map<String, List<T>> groupedMap, double screenWidth) {
    return Column(
      children: groupedMap.entries.map((entry) {
        final groupKey = entry.key;
        final groupItems = entry.value;
        final isExpanded = _expandedGroups[groupKey] ?? true;

        final label = widget.groupLabelBuilder != null
            ? widget.groupLabelBuilder!(groupKey, groupItems)
            : '$groupKey (${groupItems.length})';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () => _toggleGroup(groupKey),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  color: const Color(0xFFF8FAFC),
                  child: Row(
                    children: [
                      Icon(
                        isExpanded ? Icons.folder_open_rounded : Icons.folder_rounded,
                        size: 20,
                        color: const Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        color: const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buildCardsView(groupItems, screenWidth),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 3. Table View (Classical alternating row zebra enterprise table with column sorting)
  Widget _buildTableView(
    List<T> items,
    bool allPageSelected,
    bool somePageSelected,
    List<String> pageIds,
  ) {
    final hasSelection = widget.selectedIds != null && widget.idGetter != null;

    return AppCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sortedColIdx = _sortColumnIndex == null
              ? null
              : (hasSelection ? _sortColumnIndex! + 1 : _sortColumnIndex!);

          return SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  showCheckboxColumn: false,
                  sortColumnIndex: sortedColIdx,
                  sortAscending: _sortAscending,
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  columnSpacing: 20,
                  horizontalMargin: 16,
                  columns: [
                    if (hasSelection)
                      DataColumn(
                        label: Checkbox(
                          tristate: true,
                          value: allPageSelected ? true : (somePageSelected ? null : false),
                          onChanged: (val) {
                            if (val == true) {
                              widget.onSelectAll?.call(pageIds);
                            } else {
                              widget.onDeselectAll?.call();
                            }
                          },
                        ),
                      ),
                    for (var i = 0; i < widget.columns.length; i++)
                      DataColumn(
                        label: Text(
                          widget.columns[i].title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        numeric: widget.columns[i].alignRight,
                        tooltip: widget.columns[i].sortKey != null
                            ? 'Sort by ${widget.columns[i].title}'
                            : null,
                        onSort: widget.columns[i].sortKey == null
                            ? null
                            : (columnIndex, ascending) {
                                setState(() {
                                  _sortColumnIndex = i;
                                  _sortAscending = ascending;
                                });
                              },
                      ),
                  ],
                  rows: items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isEven = index.isEven;
                    final id = hasSelection ? widget.idGetter!(item) : '';
                    final isSelected = hasSelection && widget.selectedIds!.contains(id);

                    return DataRow(
                      color: WidgetStateProperty.resolveWith((states) {
                        if (isSelected) return const Color(0xFFF0F9FF);
                        if (states.contains(WidgetState.hovered)) return const Color(0xFFF1F5F9);
                        return isEven ? Colors.transparent : const Color(0xFFFBFDFF);
                      }),
                      onSelectChanged: widget.onRowTap != null
                          ? (_) => widget.onRowTap!(item)
                          : (hasSelection
                              ? (_) => widget.onToggleSelect?.call(id)
                              : null),
                      cells: [
                        if (hasSelection)
                          DataCell(
                            Checkbox(
                              value: isSelected,
                              onChanged: (_) => widget.onToggleSelect?.call(id),
                            ),
                          ),
                        for (final col in widget.columns)
                          DataCell(
                            col.alignRight
                                ? Align(
                                    alignment: Alignment.centerRight,
                                    child: col.cellBuilder(context, item),
                                  )
                                : col.cellBuilder(context, item),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Reports-grade pagination footer with rows-per-page dropdown & numbered buttons
  Widget _buildPaginationFooter({
    required int totalCount,
    required int startIndex,
    required int endIndex,
    required int totalPages,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 14,
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
                'Showing ${totalCount == 0 ? 0 : startIndex + 1} to $endIndex of $totalCount records',
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
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 20),
                  tooltip: 'Previous page',
                  onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                  visualDensity: VisualDensity.compact,
                ),
                for (var i = max(0, _currentPage - 2); i <= min(totalPages - 1, _currentPage + 2); i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentPage = i),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _currentPage == i ? const Color(0xFF0284C7) : Colors.white,
                        foregroundColor: _currentPage == i ? Colors.white : const Color(0xFF475569),
                        side: BorderSide(
                          color: _currentPage == i ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
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
                  onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.last_page_rounded, size: 18),
                  tooltip: 'Last page',
                  onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage = totalPages - 1) : null,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultEmptyWidget() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.search_off_rounded, size: 44, color: Color(0xFF94A3B8)),
              const SizedBox(height: 12),
              Text(
                widget.emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Interactive status badge that opens an inline dropdown to change status on the fly.
class EnterpriseStatusDropdown extends StatelessWidget {
  const EnterpriseStatusDropdown({
    required this.currentStatus,
    required this.options,
    required this.onChanged,
    this.statusColors,
    super.key,
  });

  final String currentStatus;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final Map<String, ({Color color, Color bg})>? statusColors;

  static ({Color color, Color bg}) defaultColors(String status) {
    final s = status.toUpperCase().trim();
    if (s == 'PAID' || s == 'ACTIVE' || s == 'SETTLED') {
      return (color: const Color(0xFF16A34A), bg: const Color(0xFFDCFCE7));
    }
    if (s == 'PENDING' || s == 'DRAFT' || s == 'ON_LEAVE' || s == 'ON LEAVE' || s == 'NET 30') {
      return (color: const Color(0xFFD97706), bg: const Color(0xFFFEF3C7));
    }
    if (s == 'OVERDUE' || s == 'INACTIVE' || s == 'REJECTED' || s == 'CANCELLED') {
      return (color: const Color(0xFFDC2626), bg: const Color(0xFFFEE2E2));
    }
    if (s == 'SENT' || s == 'TAX DEDUCTIBLE' || s == 'CORPORATE' || s == 'ON_HOLD' || s == 'ON HOLD' || s == 'IMMEDIATE') {
      return (color: const Color(0xFF0284C7), bg: const Color(0xFFE0F2FE));
    }
    return (color: const Color(0xFF64748B), bg: const Color(0xFFF1F5F9));
  }

  @override
  Widget build(BuildContext context) {
    final colors = statusColors?[currentStatus] ?? defaultColors(currentStatus);

    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: Colors.transparent,
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Click to change status',
        offset: const Offset(0, 26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        color: Colors.white,
        elevation: 6,
        onSelected: onChanged,
        itemBuilder: (ctx) {
          return options.map((opt) {
            final optColors = statusColors?[opt] ?? defaultColors(opt);
            final isCurrent = opt.toLowerCase().trim() == currentStatus.toLowerCase().trim();
            return PopupMenuItem<String>(
              value: opt,
              height: 36,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: optColors.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    opt,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent ? const Color(0xFF0F172A) : const Color(0xFF475569),
                    ),
                  ),
                  if (isCurrent) ...[
                    const Spacer(),
                    Icon(Icons.check, size: 14, color: optColors.color),
                  ],
                ],
              ),
            );
          }).toList();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colors.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: colors.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                currentStatus,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.color,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.arrow_drop_down, size: 14, color: colors.color),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact enterprise filter dialog with presets (Today, Week, Month, Year, All Time),
/// custom date calendar range, and status options.
class EnterpriseFilterDialog extends StatefulWidget {
  const EnterpriseFilterDialog({
    this.currentRange,
    this.onApplyDateRange,
    this.statusOptions,
    this.selectedStatus,
    this.onStatusSelected,
    super.key,
  });

  final DateTimeRange? currentRange;
  final ValueChanged<DateTimeRange?>? onApplyDateRange;
  final List<String>? statusOptions;
  final String? selectedStatus;
  final ValueChanged<String>? onStatusSelected;

  @override
  State<EnterpriseFilterDialog> createState() => _EnterpriseFilterDialogState();
}

class _EnterpriseFilterDialogState extends State<EnterpriseFilterDialog> {
  DateTimeRange? _range;
  String? _selectedStatus;
  String _activePreset = '';

  @override
  void initState() {
    super.initState();
    _range = widget.currentRange;
    _selectedStatus = widget.selectedStatus;
  }

  void _applyPreset(String preset) {
    final now = DateTime.now();
    setState(() {
      _activePreset = preset;
      switch (preset) {
        case 'Today':
          _range = DateTimeRange(
            start: DateTime(now.year, now.month, now.day),
            end: DateTime(now.year, now.month, now.day, 23, 59, 59),
          );
          break;
        case 'This Week':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          _range = DateTimeRange(
            start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
            end: DateTime(now.year, now.month, now.day, 23, 59, 59),
          );
          break;
        case 'This Month':
          _range = DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
          );
          break;
        case 'This Year':
          _range = DateTimeRange(
            start: DateTime(now.year, 1, 1),
            end: DateTime(now.year, 12, 31, 23, 59, 59),
          );
          break;
        case 'All Time':
          _range = null;
          break;
      }
    });
  }

  Future<void> _pickCustomDate({required bool isStart}) async {
    final initial = isStart
        ? (_range?.start ?? DateTime.now())
        : (_range?.end ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      _activePreset = 'Custom';
      if (isStart) {
        final end = _range?.end ?? picked.add(const Duration(days: 30));
        _range = DateTimeRange(
          start: picked,
          end: end.isBefore(picked) ? picked : end,
        );
      } else {
        final start = _range?.start ?? picked.subtract(const Duration(days: 30));
        _range = DateTimeRange(
          start: start.isAfter(picked) ? picked : start,
          end: picked,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String dateFormat(DateTime dt) => dt.toIso8601String().substring(0, 10);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Color(0xFF0284C7), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filter Records',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Quick date presets and status options',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Date Range Presets
              const Text(
                'DATE RANGE PRESETS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PresetChip(
                    label: 'Today',
                    icon: Icons.today_rounded,
                    isSelected: _activePreset == 'Today',
                    onTap: () => _applyPreset('Today'),
                  ),
                  _PresetChip(
                    label: 'This Week',
                    icon: Icons.view_week_outlined,
                    isSelected: _activePreset == 'This Week',
                    onTap: () => _applyPreset('This Week'),
                  ),
                  _PresetChip(
                    label: 'This Month',
                    icon: Icons.calendar_month_outlined,
                    isSelected: _activePreset == 'This Month',
                    onTap: () => _applyPreset('This Month'),
                  ),
                  _PresetChip(
                    label: 'This Year',
                    icon: Icons.date_range_outlined,
                    isSelected: _activePreset == 'This Year',
                    onTap: () => _applyPreset('This Year'),
                  ),
                  _PresetChip(
                    label: 'All Time',
                    icon: Icons.all_inclusive_rounded,
                    isSelected: _activePreset == 'All Time' || (_range == null && _activePreset.isEmpty),
                    onTap: () => _applyPreset('All Time'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Custom Range Date Pickers
              const Text(
                'CUSTOM CALENDAR RANGE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickCustomDate(isStart: true),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFFF8FAFC),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF0284C7)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _range != null ? dateFormat(_range!.start) : 'Start date',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _range != null ? FontWeight.bold : FontWeight.normal,
                                  color: _range != null ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('to', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickCustomDate(isStart: false),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFFF8FAFC),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF0284C7)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _range != null ? dateFormat(_range!.end) : 'End date',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _range != null ? FontWeight.bold : FontWeight.normal,
                                  color: _range != null ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Status Options
              if (widget.statusOptions != null && widget.statusOptions!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'STATUS FILTER',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.statusOptions!.map((status) {
                    final cleanStatus = status.split(' ').first;
                    final isSelected = (_selectedStatus ?? 'All').toLowerCase().startsWith(cleanStatus.toLowerCase());
                    return ChoiceChip(
                      label: Text(status, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _selectedStatus = cleanStatus);
                      },
                      selectedColor: const Color(0xFF0284C7).withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF475569),
                      ),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _range = null;
                        _selectedStatus = 'All';
                        _activePreset = 'All Time';
                      });
                      widget.onApplyDateRange?.call(null);
                      widget.onStatusSelected?.call('All');
                      Navigator.pop(context);
                    },
                    child: const Text('Reset All'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: () {
                      widget.onApplyDateRange?.call(_range);
                      if (_selectedStatus != null) {
                        widget.onStatusSelected?.call(_selectedStatus!);
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('Apply Filters'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
