import 'dart:math';
import 'package:flutter/material.dart';

import 'app_card.dart';

/// Column definition for [EnterpriseDataView] table view.
class EnterpriseTableColumn<T> {
  const EnterpriseTableColumn({
    required this.title,
    required this.cellBuilder,
    this.width = 150,
    this.alignRight = false,
  });

  final String title;
  final Widget Function(BuildContext context, T item) cellBuilder;
  final double width;
  final bool alignRight;
}

/// Generic, highly reusable enterprise data view supporting:
/// 1. 3 View Modes: **Table** (classical zebra table), **Grouped** (collapsible category accordion), and **Cards** (mobile list show).
/// 2. **Adaptive Defaults**: Defaults to `Cards` on mobile (< 700px) and `Table` on desktop/tablet (>= 700px), with user mode override.
/// 3. Search & Filter Bar with horizontal choice chips.
/// 4. Multi-item selection & pagination footer.
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
    this.metricsStrip,
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
  final Widget? metricsStrip;
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
    if (query.isEmpty || widget.searchFilter == null) {
      return widget.items;
    }
    return widget.items.where((item) => widget.searchFilter!(item, query)).toList();
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
        if (widget.metricsStrip != null) ...[
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
                        label: Text(chip, style: const TextStyle(fontSize: 12)),
                        selected: widget.selectedFilterChip == chip,
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

  Widget _buildControlsBar({
    required String activeMode,
    required int totalCount,
    required List<String> groupedKeys,
    required double screenWidth,
  }) {
    final hasGrouping = widget.groupBy != null;
    final isCompact = screenWidth < 500;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalCount ${totalCount == 1 ? 'record' : 'records'}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w600,
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

              // If no headerTitle, show count here
              if (widget.headerTitle == null)
                Text(
                  '$totalCount ${totalCount == 1 ? 'record' : 'records'}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
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
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 10,
          vertical: isCompact ? 5 : 6,
        ),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x10000000), blurRadius: 2, offset: Offset(0, 1))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isCompact ? 13 : 15,
              color: selected ? const Color(0xFF0284C7) : const Color(0xFF64748B),
            ),
            SizedBox(width: isCompact ? 4 : 5),
            Text(
              label,
              style: TextStyle(
                fontSize: isCompact ? 11 : 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
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

  // 3. Table View (Classical alternating row zebra enterprise table)
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
          return SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
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
                    for (final col in widget.columns)
                      DataColumn(
                        label: Text(
                          col.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        numeric: col.alignRight,
                      ),
                  ],
                  rows: items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isEven = index.isEven;
                    final id = hasSelection ? widget.idGetter!(item) : '';
                    final isSelected = hasSelection && widget.selectedIds!.contains(id);

                    return DataRow(
                      color: WidgetStateProperty.all(
                        isSelected
                            ? const Color(0xFFF0F9FF)
                            : isEven
                                ? Colors.transparent
                                : const Color(0xFFFBFDFF),
                      ),
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
                            col.cellBuilder(context, item),
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
