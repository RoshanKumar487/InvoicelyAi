import '../../../core/api/api_client.dart';

class ReportRepository {
  const ReportRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> loadStatistics() =>
      _apiClient.getJson('api/v1/dashboard/stats');

  Future<List<Map<String, dynamic>>> loadInvoices() =>
      _apiClient.getListJson('api/v1/invoices');

  Future<List<Map<String, dynamic>>> loadExpenses() =>
      _apiClient.getListJson('api/v1/expenses');
}
