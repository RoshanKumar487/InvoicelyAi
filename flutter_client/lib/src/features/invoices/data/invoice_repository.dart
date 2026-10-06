import '../../../core/api/api_client.dart';
import 'invoice.dart';

class InvoiceRepository {
  const InvoiceRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  bool get lastLoadUsedCache => _apiClient.lastGetUsedCache;

  Future<List<Invoice>> getInvoices({String? status}) async {
    final records = await _apiClient.getListJson(
      'api/v1/invoices',
      queryParameters: status == null ? null : {'status': status},
    );
    return records.map(Invoice.fromJson).toList(growable: false);
  }

  Future<Invoice> getInvoice(int id) async {
    return Invoice.fromJson(await _apiClient.getJson('api/v1/invoices/$id'));
  }

  Future<Invoice> createInvoice(Invoice invoice) async {
    return Invoice.fromJson(
      await _apiClient.postJson('api/v1/invoices', invoice.toJson()),
    );
  }

  Future<Invoice> updateInvoice(Invoice invoice) async {
    final id = invoice.id;
    if (id == null) {
      throw ArgumentError.value(id, 'invoice.id', 'An invoice ID is required.');
    }
    return Invoice.fromJson(
      await _apiClient.putJson('api/v1/invoices/$id', invoice.toJson()),
    );
  }

  Future<Invoice> updateStatus(int id, String status) async {
    return Invoice.fromJson(
      await _apiClient.patchJson(
        'api/v1/invoices/$id/status',
        queryParameters: {'status': status},
      ),
    );
  }

  Future<void> deleteInvoice(int id) async {
    await _apiClient.deleteJson('api/v1/invoices/$id');
  }
}
