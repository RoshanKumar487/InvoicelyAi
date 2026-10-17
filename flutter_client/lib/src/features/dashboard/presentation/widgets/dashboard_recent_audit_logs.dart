import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_card.dart';
import '../../../../theme/app_theme.dart';
import '../../../audit/data/audit_log.dart';

class DashboardRecentAuditLogs extends StatelessWidget {
  const DashboardRecentAuditLogs({
    required this.logs,
    required this.onOpenAuditLogs,
    super.key,
  });

  final List<AuditLog> logs;
  final VoidCallback? onOpenAuditLogs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.history_edu_rounded,
                    size: 18,
                    color: Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Recent Audit & Activity Logs',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (onOpenAuditLogs != null)
              TextButton.icon(
                onPressed: onOpenAuditLogs,
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: const Text('View All', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            children: [
              for (int i = 0; i < logs.length; i++) ...[
                _buildLogItem(context, logs[i]),
                if (i < logs.length - 1)
                  const Divider(height: 16, thickness: 0.5),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogItem(BuildContext context, AuditLog log) {
    final (icon, color) = _getModuleIconAndColor(log.module);
    final timeStr = _formatRelativeTime(log.createdAt);

    return InkWell(
      onTap: onOpenAuditLogs,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          log.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log.userName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          log.description.isNotEmpty
                              ? log.description
                              : log.action,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _getModuleIconAndColor(String module) {
    switch (module.toUpperCase()) {
      case 'INVOICE':
        return (Icons.receipt_long_rounded, const Color(0xFF2563EB));
      case 'EXPENSE':
        return (Icons.account_balance_wallet_rounded, const Color(0xFFD97706));
      case 'CLIENT':
        return (Icons.people_alt_rounded, const Color(0xFF059669));
      case 'EMPLOYEE':
        return (Icons.badge_rounded, const Color(0xFF7C3AED));
      case 'TEAM':
        return (Icons.manage_accounts_rounded, const Color(0xFFDC2626));
      default:
        return (Icons.history_rounded, const Color(0xFF0284C7));
    }
  }

  String _formatRelativeTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
