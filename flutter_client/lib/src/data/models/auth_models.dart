class AuthSession {
  const AuthSession({
    required this.user,
    this.company,
  });

  final UserSummary user;
  final CompanySummary? company;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    if (rawUser is! Map<String, dynamic>) {
      throw const FormatException('The authentication response has no user.');
    }
    final rawCompany = json['company'];
    return AuthSession(
      user: UserSummary.fromJson(rawUser),
      company: rawCompany is Map<String, dynamic>
          ? CompanySummary.fromJson(rawCompany)
          : null,
    );
  }
}

class UserSummary {
  const UserSummary({
    required this.fullName,
    required this.email,
    required this.role,
    this.companyId,
    this.mobile = '',
    this.status = 'ACTIVE',
    this.permissions = 'INVOICES,EXPENSES,CLIENTS,REPORTS',
  });

  final String fullName;
  final String email;
  final String role;
  final int? companyId;
  final String mobile;
  final String status;
  final String permissions;

  factory UserSummary.fromJson(Map<String, dynamic> json) => UserSummary(
        fullName: json['fullName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? 'EMPLOYEE',
        companyId: (json['companyId'] as num?)?.toInt(),
        mobile: json['mobile'] as String? ?? '',
        status: json['status'] as String? ?? 'ACTIVE',
        permissions: json['permissions'] as String? ??
            'INVOICES,EXPENSES,CLIENTS,REPORTS',
      );

  bool hasPermission(String permission) => permissions
      .split(',')
      .any((value) => value.trim().toUpperCase() == permission.toUpperCase());
}

class CompanySummary {
  const CompanySummary({
    required this.name,
    this.id,
    this.code,
  });

  final int? id;
  final String name;
  final String? code;

  factory CompanySummary.fromJson(Map<String, dynamic> json) =>
      CompanySummary(
        id: (json['id'] as num?)?.toInt(),
        name: json['companyName'] as String? ?? '',
        code: json['companyCode'] as String?,
      );
}
