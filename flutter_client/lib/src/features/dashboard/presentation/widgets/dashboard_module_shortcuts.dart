import 'package:flutter/material.dart';

import '../../../../data/models/auth_models.dart';

class ModuleCardData {
  const ModuleCardData({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.onTap,
    this.isStandout = false,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final VoidCallback onTap;
  final bool isStandout;
}

class DashboardModuleShortcuts extends StatelessWidget {
  const DashboardModuleShortcuts({
    required this.user,
    required this.onViewInvoices,
    required this.onViewExpenses,
    required this.onViewClients,
    required this.onOpenTemplates,
    this.onOpenPayroll,
    super.key,
  });

  final UserSummary user;
  final VoidCallback onViewInvoices;
  final VoidCallback onViewExpenses;
  final VoidCallback onViewClients;
  final VoidCallback onOpenTemplates;
  final VoidCallback? onOpenPayroll;

  @override
  Widget build(BuildContext context) {
    final items = [
      if (user.hasPermission('INVOICES'))
        ModuleCardData(
          label: 'Invoices',
          subtitle: 'Create & manage invoices',
          icon: Icons.description_rounded,
          iconBg: const Color(0xFF1D68F0),
          onTap: onViewInvoices,
          isStandout: true,
        ),
      if (user.hasPermission('EXPENSES'))
        ModuleCardData(
          label: 'Expenses',
          subtitle: 'Track your expenses',
          icon: Icons.currency_rupee_rounded,
          iconBg: const Color(0xFF10B981),
          onTap: onViewExpenses,
        ),
      if (onOpenPayroll != null)
        ModuleCardData(
          label: 'Payroll',
          subtitle: 'Manage staff & salary',
          icon: Icons.groups_rounded,
          iconBg: const Color(0xFF8B5CF6),
          onTap: onOpenPayroll!,
        ),
      if (user.hasPermission('CLIENTS'))
        ModuleCardData(
          label: 'Clients',
          subtitle: 'Customer management',
          icon: Icons.people_alt_rounded,
          iconBg: const Color(0xFFF97316),
          onTap: onViewClients,
        ),
      if (user.hasPermission('INVOICES'))
        ModuleCardData(
          label: 'Templates',
          subtitle: 'Invoice templates',
          icon: Icons.tune_rounded,
          iconBg: const Color(0xFF06B6D4),
          onTap: onOpenTemplates,
        ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;

        if (!isDesktop) {
          // On mobile & tablets (Android / compact screens): smooth horizontal scroll
          return SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 215,
                  child: ShortcutCardTile(item: items[index]),
                );
              },
            ),
          );
        }

        // On desktop screen: expand evenly across the row
        return Row(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              Expanded(
                child: ShortcutCardTile(item: items[i]),
              ),
              if (i < items.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class ShortcutCardTile extends StatefulWidget {
  const ShortcutCardTile({
    required this.item,
    super.key,
  });

  final ModuleCardData item;

  @override
  State<ShortcutCardTile> createState() => _ShortcutCardTileState();
}

class _ShortcutCardTileState extends State<ShortcutCardTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = item.isStandout;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: item.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: _hovered
              ? Matrix4.translationValues(0, -3, 0)
              : Matrix4.identity(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F3277) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF1E40AF) : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? const Color(0x280F3277)
                    : const Color(0x080F172A),
                offset: const Offset(0, 3),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              // Colored rounded square icon box
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.icon,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.75)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: isDark ? Colors.white60 : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
