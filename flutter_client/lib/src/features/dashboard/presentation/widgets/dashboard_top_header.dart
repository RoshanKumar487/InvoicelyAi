import 'package:flutter/material.dart';

import '../../../../data/models/auth_models.dart';
import '../../../../theme/app_theme.dart';
import 'user_profile_dialog.dart';

class DashboardTopHeader extends StatelessWidget {
  const DashboardTopHeader({
    required this.companyName,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.userInitial,
    required this.onMenuTap,
    required this.unreadNotificationCount,
    required this.onOpenNotifications,
    required this.searchController,
    required this.onSearchChanged,
    this.onRefresh,
    required this.session,
    this.onOpenBusinessSettings,
    required this.onLogout,
    super.key,
  });

  final String companyName;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final String userInitial;
  final VoidCallback? onMenuTap;
  final int unreadNotificationCount;
  final VoidCallback onOpenNotifications;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onRefresh;
  final AuthSession session;
  final VoidCallback? onOpenBusinessSettings;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 850;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 18 : 14,
        vertical: isDesktop ? 12 : 12,
      ),
      decoration: AppTheme.neuCardDecoration(radius: 26),
      child: isDesktop
          ? Row(
              children: [
                _buildCompanyTopNavBadge(isDesktop: true),
                const Spacer(),
                _buildSearchField(width: 240),
                const SizedBox(width: 12),
                _buildFilterDropdown(context),
                const SizedBox(width: 10),
                _buildNeuIconButton(
                  tooltip: 'Sync dashboard',
                  icon: Icons.refresh_rounded,
                  onTap: onRefresh,
                ),
                const SizedBox(width: 10),
                _buildNotificationButton(),
                const SizedBox(width: 10),
                _buildUserAvatar(context),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildCompanyTopNavBadge(isDesktop: false)),
                    const SizedBox(width: 8),
                    _buildNeuIconButton(
                      tooltip: 'Sync dashboard',
                      icon: Icons.refresh_rounded,
                      onTap: onRefresh,
                    ),
                    const SizedBox(width: 8),
                    _buildNotificationButton(),
                    const SizedBox(width: 8),
                    _buildUserAvatar(context),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildSearchField()),
                    const SizedBox(width: 10),
                    _buildFilterDropdown(context),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildCompanyTopNavBadge({required bool isDesktop}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDesktop) ...[
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: -0.3,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              height: 18,
              child: VerticalDivider(width: 1, color: Color(0xFFCBD5E1)),
            ),
          ),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: AppTheme.neuPillDecoration(radius: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: AppTheme.neuOrbDecoration(
                    active: true,
                    activeColor: const Color(0xFF2B3548),
                  ),
                  child: const Icon(
                    Icons.business_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isDesktop ? 280 : 180),
                    child: Text(
                      companyName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField({double? width}) {
    return Container(
      height: 40,
      width: width,
      decoration: AppTheme.neuRecessedDecoration(radius: 18),
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
        decoration: const InputDecoration(
          filled: false,
          hintText: 'Search invoices, clients...',
          hintStyle: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          prefixIcon:
              Icon(Icons.search_rounded, size: 18, color: Color(0xFF475569)),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildNeuIconButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: AppTheme.neuOrbDecoration(),
          child: Icon(icon, size: 19, color: const Color(0xFF334155)),
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildNeuIconButton(
          tooltip: 'Notifications',
          icon: Icons.notifications_none_rounded,
          onTap: onOpenNotifications,
        ),
        if (unreadNotificationCount > 0)
          Positioned(
            top: 7,
            right: 7,
            child: Container(
              width: 8.5,
              height: 8.5,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    return Tooltip(
      message: 'View profile details',
      child: InkWell(
        onTap: () {
          UserProfileDialog.show(
            context,
            session: session,
            onOpenBusinessSettings: onOpenBusinessSettings,
            onLogout: onLogout,
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: AppTheme.neuOrbDecoration(
            active: true,
            activeColor: const Color(0xFFE2E8F0),
          ),
          child: Center(
            child: Text(
              userInitial,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(BuildContext context) {
    final options = [
      'FY 2025-26',
      'FY 2024-25',
      'FY 2023-24',
      'Apr 15, 2025 - May 15, 2025',
      'This Month',
      'Last 30 Days',
      'All Dates',
      'Custom Date Range...',
    ];

    return PopupMenuButton<String>(
      onSelected: onFilterChanged,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.9)),
      ),
      color: AppColors.neuSurface,
      elevation: 6,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => options.map((opt) {
        final isSelected = opt == selectedFilter;
        return PopupMenuItem<String>(
          value: opt,
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.calendar_today_outlined,
                size: 15,
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: AppTheme.neuPillDecoration(radius: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 13, color: Color(0xFF334155)),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 118),
              child: Text(
                selectedFilter,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }
}

class DashboardWelcomeRow extends StatelessWidget {
  const DashboardWelcomeRow({
    required this.userName,
    required this.subtitle,
    this.onCreateInvoice,
    super.key,
  });

  final String userName;
  final String subtitle;
  final VoidCallback? onCreateInvoice;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $userName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        if (onCreateInvoice != null) ...[
          const SizedBox(width: 10),
          InkWell(
            onTap: onCreateInvoice,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: AppTheme.neuPillDecoration(
                radius: 24,
                active: true,
                activeColor: const Color(0xFF2B3548),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline_rounded,
                      size: 17, color: Colors.white),
                  SizedBox(width: 7),
                  Text(
                    'New Invoice',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class DashboardAssistantBanner extends StatelessWidget {
  const DashboardAssistantBanner({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 520;
    return Container(
      decoration: AppTheme.neuCardDecoration(radius: 24),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: AppTheme.neuOrbDecoration(),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF2B3548),
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI INVOICE ASSISTANT',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Generate invoices & insights in seconds',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isCompact) ...[
                  const SizedBox(height: 2),
                  const Text(
                    'Auto-fill security guard line items, calculate daily wages & GST, and query metrics.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                      height: 1.35,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 12 : 16, vertical: 10),
              decoration: AppTheme.neuPillDecoration(
                radius: 22,
                active: true,
                activeColor: const Color(0xFF2B3548),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isCompact ? 'Open AI' : 'Try Assistant',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
