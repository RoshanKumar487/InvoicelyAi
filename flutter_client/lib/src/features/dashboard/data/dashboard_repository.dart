import '../../../core/api/api_client.dart';
import '../../invoices/data/invoice.dart';
import 'developer_overview.dart';
import 'dashboard_statistics.dart';

class DashboardRepository {
  const DashboardRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  bool get lastLoadUsedCache => _apiClient.lastGetUsedCache;

  Future<DashboardStatistics> loadStatistics({int? companyId}) async {
    final queryParameters =
        companyId == null ? null : {'companyId': '$companyId'};
    final data = await _apiClient.getJson(
      'api/v1/dashboard/stats',
      queryParameters: queryParameters,
    );
    return DashboardStatistics.fromJson(data);
  }

  Future<List<Invoice>> loadInvoices() async {
    final records = await _apiClient.getListJson('api/v1/invoices');
    return records.map(Invoice.fromJson).toList(growable: false);
  }

  Future<DeveloperOverview> loadDeveloperOverview() async {
    final data =
        await _apiClient.getJson('api/v1/dashboard/developer-overview');
    return DeveloperOverview.fromJson(data);
  }
}
