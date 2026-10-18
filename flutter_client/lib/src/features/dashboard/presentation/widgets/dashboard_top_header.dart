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
        vertical: isDesktop ? 10 : 12,
      ),
      decoration: AppTheme.neuCardDecoration(radius: 20),
      child: isDesktop
          ? Row(
              children: [
                _buildCompanyTopNavBadge(isDesktop: true),
                const Spacer(),
                _buildSearchField(width: 270),
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildSearchField()),
                    const SizedBox(width: 8),
                    _buildFilterDropdown(context),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildCompanyTopNavBadge({required bool isDesktop}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFF0B1736),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.apartment_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 240 : 160),
            child: Text(
              companyName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: Color(0xFF64748B),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField({double? width}) {
    return Container(
      height: 38,
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        style: const TextStyle(
            fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        decoration: const InputDecoration(
          filled: false,
          hintText: 'Search invoices, clients, etc...',
          hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          prefixIcon:
              Icon(Icons.search_rounded, size: 17, color: Color(0xFF94A3B8)),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 9),
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
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF475569)),
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
              width: 8,
              height: 8,
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
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFE0E7FF),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFC7D2FE), width: 1.0),
          ),
          child: Center(
            child: Text(
              userInitial,
              style: const TextStyle(
                color: Color(0xFF1E3A8A),
                fontSize: 14.5,
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
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
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
                    ? const Color(0xFF1D68F0)
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
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 13, color: Color(0xFF475569)),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Text(
                selectedFilter,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 15, color: Color(0xFF64748B)),
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
        // Waving Hand Emoji
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Text(
              '👋',
              style: TextStyle(fontSize: 22),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $userName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        if (onCreateInvoice != null) ...[
          const SizedBox(width: 12),
          InkWell(
            onTap: onCreateInvoice,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1D68F0), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x381D68F0),
                    offset: Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.post_add_rounded, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'New Invoice',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
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
    final isCompact = MediaQuery.sizeOf(context).width < 620;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEFF6FF), // Soft icy blue
            Color(0xFFF5F3FF), // Soft lavender
            Color(0xFFFDF4FF), // Soft violet-pink
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E7FF), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            offset: Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sparkle Orb
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x104F46E5),
                  offset: Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF1D68F0),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI INVOICE ASSISTANT',
                  style: TextStyle(
                    color: Color(0xFF4F46E5),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Generate invoices & insights in seconds',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isCompact) ...[
                  const SizedBox(height: 3),
                  const Text(
                    'Auto-fill security guard line items, calculate daily wages & GST, and query metrics.',
                    style: TextStyle(
                      fontSize: 12,
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
          const SizedBox(width: 14),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 14 : 18,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x354F46E5),
                    offset: Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isCompact ? 'Try AI' : 'Try Assistant',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
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
