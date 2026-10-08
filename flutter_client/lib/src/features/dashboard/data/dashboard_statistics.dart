class DashboardStatistics {
  const DashboardStatistics({
    required this.totalInvoices,
    required this.paidInvoices,
    required this.overdueInvoices,
    required this.draftInvoices,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.totalClients,
  });

  final int totalInvoices;
  final int paidInvoices;
  final int overdueInvoices;
  final int draftInvoices;
  final double totalRevenue;
  final double totalExpenses;
  final int totalClients;

  factory DashboardStatistics.fromJson(Map<String, dynamic> json) =>
      DashboardStatistics(
        totalInvoices: _int(json['totalInvoices']),
        paidInvoices: _int(json['paidInvoices']),
        overdueInvoices: _int(json['overdueInvoices']),
        draftInvoices: _int(json['draftInvoices']),
        totalRevenue: _double(json['totalRevenue']),
        totalExpenses: _double(json['totalExpenses']),
        totalClients: _int(json['totalClients']),
      );

  static int _int(Object? value) => (value as num?)?.toInt() ?? 0;

  static double _double(Object? value) => (value as num?)?.toDouble() ?? 0;
}
