class DeveloperOverview {
  const DeveloperOverview({
    required this.totalCompanies,
    required this.totalUsers,
    required this.totalInvoices,
    required this.totalExpenses,
    required this.totalPlatformRevenue,
    required this.totalPlatformExpenses,
    required this.companies,
  });

  final int totalCompanies;
  final int totalUsers;
  final int totalInvoices;
  final int totalExpenses;
  final double totalPlatformRevenue;
  final double totalPlatformExpenses;
  final List<CompanyPlatformStatistics> companies;

  factory DeveloperOverview.fromJson(Map<String, dynamic> json) {
    final rawCompanies = json['companies'];
    return DeveloperOverview(
      totalCompanies: _asInt(json['totalCompanies']),
      totalUsers: _asInt(json['totalUsers']),
      totalInvoices: _asInt(json['totalInvoices']),
      totalExpenses: _asInt(json['totalExpenses']),
      totalPlatformRevenue: _asDouble(json['totalPlatformRevenue']),
      totalPlatformExpenses: _asDouble(json['totalPlatformExpenses']),
      companies: rawCompanies is List<Object?>
          ? rawCompanies
              .whereType<Map<String, dynamic>>()
              .map(CompanyPlatformStatistics.fromJson)
              .toList(growable: false)
          : const [],
    );
  }

  static int _asInt(Object? value) => (value as num?)?.toInt() ?? 0;

  static double _asDouble(Object? value) => (value as num?)?.toDouble() ?? 0;
}

class CompanyPlatformStatistics {
  const CompanyPlatformStatistics({
    required this.companyId,
    required this.companyCode,
    required this.companyName,
    required this.userCount,
    required this.invoiceCount,
    required this.expenseCount,
    required this.totalRevenue,
    required this.totalExpenses,
  });

  final int? companyId;
  final String companyCode;
  final String companyName;
  final int userCount;
  final int invoiceCount;
  final int expenseCount;
  final double totalRevenue;
  final double totalExpenses;

  factory CompanyPlatformStatistics.fromJson(Map<String, dynamic> json) =>
      CompanyPlatformStatistics(
        companyId: (json['companyId'] as num?)?.toInt(),
        companyCode: json['companyCode'] as String? ?? '',
        companyName: json['companyName'] as String? ?? '',
        userCount: (json['userCount'] as num?)?.toInt() ?? 0,
        invoiceCount: (json['invoiceCount'] as num?)?.toInt() ?? 0,
        expenseCount: (json['expenseCount'] as num?)?.toInt() ?? 0,
        totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
        totalExpenses: (json['totalExpenses'] as num?)?.toDouble() ?? 0,
      );
}
