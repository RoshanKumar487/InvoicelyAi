import 'package:flutter/material.dart';

import '../../../../data/models/auth_models.dart';
import '../../../../theme/app_theme.dart';

/// Clean, responsive modal dialog for user profile details, roles, permissions,
/// company info, settings redirection, and logout.
class UserProfileDialog extends StatelessWidget {
  const UserProfileDialog({
    required this.session,
    this.onOpenBusinessSettings,
    required this.onLogout,
    super.key,
  });

  final AuthSession session;
  final VoidCallback? onOpenBusinessSettings;
  final Future<void> Function() onLogout;

  static void show(
    BuildContext context, {
    required AuthSession session,
    VoidCallback? onOpenBusinessSettings,
    required Future<void> Function() onLogout,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => UserProfileDialog(
        session: session,
        onOpenBusinessSettings: onOpenBusinessSettings,
        onLogout: onLogout,
      ),
    );
  }

  String get _userInitial {
    final name = session.user.fullName.trim();
    if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    final email = session.user.email.trim();
    if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final user = session.user;
    final company = session.company;
    final role = user.role.toUpperCase();
    final permissions = user.permissions
        .split(',')
        .map<String>((String p) => p.trim())
        .where((String p) => p.isNotEmpty)
        .toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(22),
        decoration: AppTheme.neuCardDecoration(radius: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Avatar and Close Button
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: AppTheme.neuOrbDecoration(
                    active: true,
                    activeColor: const Color(0xFF2B3548),
                  ),
                  child: Center(
                    child: Text(
                      _userInitial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName.trim().isNotEmpty
                            ? user.fullName.trim()
                            : 'Invoicely User',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          role,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2563EB),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded,
                      size: 20, color: Color(0xFF64748B)),
                  splashRadius: 20,
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 18),

            // User & Company Detail Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildProfileInfoRow(
                    icon: Icons.alternate_email_rounded,
                    label: 'Email',
                    value: user.email,
                  ),
                  const Divider(height: 16, color: Color(0xFFE2E8F0)),
                  _buildProfileInfoRow(
                    icon: Icons.badge_outlined,
                    label: 'Account Role',
                    value: role,
                  ),
                  if (company != null) ...[
                    const Divider(height: 16, color: Color(0xFFE2E8F0)),
                    _buildProfileInfoRow(
                      icon: Icons.apartment_rounded,
                      label: 'Company',
                      value: company.name,
                    ),
                    if (company.code != null &&
                        company.code!.trim().isNotEmpty) ...[
                      const Divider(height: 16, color: Color(0xFFE2E8F0)),
                      _buildProfileInfoRow(
                        icon: Icons.tag_rounded,
                        label: 'Organization Code',
                        value: company.code!,
                      ),
                    ],
                  ],
                ],
              ),
            ),

            if (permissions.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Access & Permissions',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final perm in permissions)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        perm,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                ],
              ),
            ],

            const SizedBox(height: 22),

            // Actions row: Business Settings (if provided) & Logout
            Row(
              children: [
                if (onOpenBusinessSettings != null)
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        onOpenBusinessSettings!();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: AppTheme.neuPillDecoration(radius: 16),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.settings_outlined,
                                size: 16, color: Color(0xFF334155)),
                            SizedBox(width: 7),
                            Text(
                              'Settings',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (onOpenBusinessSettings != null) const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      Navigator.of(context).pop();
                      await onLogout();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: AppTheme.neuPillDecoration(
                        radius: 16,
                        active: true,
                        activeColor: const Color(0xFFDC2626),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded,
                              size: 16, color: Colors.white),
                          SizedBox(width: 7),
                          Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
