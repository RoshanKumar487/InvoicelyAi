import 'package:flutter/material.dart';

import '../../../../data/models/auth_models.dart';
import '../../../../theme/app_theme.dart';

class ModuleCardData {
  const ModuleCardData({
    required this.label,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;
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
          icon: Icons.receipt_long_rounded,
          iconBg: const Color(0xFF2B3548),
          iconColor: const Color(0xFF2B3548),
          onTap: onViewInvoices,
        ),
      if (user.hasPermission('EXPENSES'))
        ModuleCardData(
          label: 'Expenses',
          icon: Icons.account_balance_wallet_rounded,
          iconBg: const Color(0xFFEAEEF5),
          iconColor: const Color(0xFF334155),
          onTap: onViewExpenses,
        ),
      if (onOpenPayroll != null)
        ModuleCardData(
          label: 'Payroll',
          icon: Icons.groups_rounded,
          iconBg: const Color(0xFFEAEEF5),
          iconColor: const Color(0xFF334155),
          onTap: onOpenPayroll!,
        ),
      if (user.hasPermission('CLIENTS'))
        ModuleCardData(
          label: 'Clients',
          icon: Icons.people_alt_rounded,
          iconBg: const Color(0xFFEAEEF5),
          iconColor: const Color(0xFF334155),
          onTap: onViewClients,
        ),
      if (user.hasPermission('INVOICES'))
        ModuleCardData(
          label: 'Templates',
          icon: Icons.tune_rounded,
          iconBg: const Color(0xFFEAEEF5),
          iconColor: const Color(0xFF334155),
          onTap: onOpenTemplates,
        ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // If narrow screen (mobile < 520px), use horizontal scroll list to prevent cramped buttons or overflow
        if (constraints.maxWidth < 520) {
          return SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 100,
                  child: ClayModuleTile(
                    item: items[index],
                    isHighlighted: index == 0,
                  ),
                );
              },
            ),
          );
        }

        // On tablet / desktop, expand evenly across row
        return Row(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              Expanded(
                child: ClayModuleTile(
                  item: items[i],
                  isHighlighted: i == 0,
                ),
              ),
              if (i < items.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }
}

class ClayModuleTile extends StatefulWidget {
  const ClayModuleTile({
    required this.item,
    this.isHighlighted = false,
    super.key,
  });

  final ModuleCardData item;
  final bool isHighlighted;

  @override
  State<ClayModuleTile> createState() => _ClayModuleTileState();
}

class _ClayModuleTileState extends State<ClayModuleTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final activeDark = widget.isHighlighted || _hovered;

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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: activeDark
              ? AppTheme.neuPillDecoration(
                  radius: 22,
                  active: true,
                  activeColor: const Color(0xFF2B3548),
                )
              : AppTheme.neuCardDecoration(radius: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: activeDark
                    ? BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25)),
                      )
                    : AppTheme.neuOrbDecoration(),
                child: Icon(
                  item.icon,
                  color: activeDark ? Colors.white : item.iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: activeDark ? Colors.white : const Color(0xFF1E293B),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
