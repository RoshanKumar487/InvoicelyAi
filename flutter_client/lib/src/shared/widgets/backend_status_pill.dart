import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class BackendStatusPill extends StatelessWidget {
  const BackendStatusPill({
    required this.isConnected,
    super.key,
  });

  final bool? isConnected;

  @override
  Widget build(BuildContext context) {
    final color = isConnected == null
        ? AppColors.muted
        : isConnected!
            ? AppColors.paid
            : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 9, color: color),
          const SizedBox(width: 8),
          Text(
            isConnected == null
                ? 'Checking backend...'
                : isConnected!
                    ? 'Backend connected'
                    : 'Backend unavailable',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
