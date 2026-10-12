import 'package:flutter/material.dart';

class AuditLog {
  const AuditLog({
    this.id,
    this.companyId,
    this.userId,
    this.userName = '',
    this.userRole = 'STAFF',
    required this.module,
    required this.action,
    this.entityId = '',
    required this.title,
    this.description = '',
    this.metadataJson = '{}',
    this.createdAt,
  });

  final int? id;
  final int? companyId;
  final int? userId;
  final String userName;
  final String userRole; // ADMIN, MANAGER, EMPLOYEE, STAFF, DEVELOPER
  final String module; // INVOICE, EXPENSE, CLIENT, EMPLOYEE, TEAM, SETTINGS, AUTH
  final String action; // CREATE, UPDATE, DELETE, STATUS_CHANGE, EXPORT_PDF, SCAN_OCR, ROLE_CHANGE
  final String entityId;
  final String title;
  final String description;
  final String metadataJson;
  final DateTime? createdAt;

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: (json['id'] as num?)?.toInt(),
      companyId: (json['companyId'] as num?)?.toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      userName: json['userName']?.toString() ?? '',
      userRole: json['userRole']?.toString() ?? 'STAFF',
      module: json['module']?.toString() ?? 'GENERAL',
      action: json['action']?.toString() ?? 'VIEW',
      entityId: json['entityId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      metadataJson: json['metadataJson']?.toString() ?? '{}',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (companyId != null) 'companyId': companyId,
      if (userId != null) 'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'module': module,
      'action': action,
      'entityId': entityId,
      'title': title,
      'description': description,
      'metadataJson': metadataJson,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  AuditLog copyWith({
    int? id,
    int? companyId,
    int? userId,
    String? userName,
    String? userRole,
    String? module,
    String? action,
    String? entityId,
    String? title,
    String? description,
    String? metadataJson,
    DateTime? createdAt,
  }) {
    return AuditLog(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      module: module ?? this.module,
      action: action ?? this.action,
      entityId: entityId ?? this.entityId,
      title: title ?? this.title,
      description: description ?? this.description,
      metadataJson: metadataJson ?? this.metadataJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Color get moduleColor {
    switch (module.toUpperCase()) {
      case 'INVOICE':
        return const Color(0xFF0284C7); // Blue
      case 'EXPENSE':
        return const Color(0xFFD97706); // Amber
      case 'CLIENT':
        return const Color(0xFF059669); // Emerald
      case 'EMPLOYEE':
        return const Color(0xFF7C3AED); // Violet
      case 'TEAM':
      case 'USER':
        return const Color(0xFFDC2626); // Red
      case 'SETTINGS':
        return const Color(0xFF4B5563); // Gray
      default:
        return const Color(0xFF2563EB);
    }
  }

  IconData get icon {
    switch (module.toUpperCase()) {
      case 'INVOICE':
        return Icons.receipt_long_rounded;
      case 'EXPENSE':
        return Icons.payments_rounded;
      case 'CLIENT':
        return Icons.people_alt_rounded;
      case 'EMPLOYEE':
        return Icons.badge_rounded;
      case 'TEAM':
        return Icons.security_rounded;
      case 'SETTINGS':
        return Icons.tune_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  String get relativeTime {
    final now = DateTime.now();
    final time = createdAt ?? now;
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
  }
}
