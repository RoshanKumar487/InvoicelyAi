import '../../../core/api/api_client.dart';
import 'expense.dart';

class ExpensesRepository {
  const ExpensesRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  bool get lastLoadUsedCache => _apiClient.lastGetUsedCache;

  Future<List<Expense>> list({String? category}) async {
    final filter = category?.trim();
    final rows = await _apiClient.getListJson(
      'api/v1/expenses',
      queryParameters:
          filter == null || filter.isEmpty ? null : {'category': filter},
    );
    return rows.map(Expense.fromJson).toList(growable: false);
  }

  Future<Expense> create(Expense expense) async {
    final data = await _apiClient.postJson(
      'api/v1/expenses',
      expense.toJson(),
    );
    return Expense.fromJson(data);
  }

  Future<Expense> scanReceipt({
    required String imageBase64,
    required String mimeType,
  }) async {
    final data = await _apiClient.postJson(
      'api/v1/ai/receipt-scan',
      {
        'imageBase64': imageBase64,
        'mimeType': mimeType,
      },
    );
    return Expense(
      title: _stringValue(data['title']),
      category: _stringValue(data['category'], fallback: 'General'),
      amount: _doubleValue(data['amount']),
      currency: _stringValue(data['currency'], fallback: 'USD'),
      currencySymbol: _currencySymbol(
        _stringValue(data['currency'], fallback: 'USD'),
      ),
      date: _stringValue(data['date']),
      vendor: _stringValue(data['vendor']),
      paymentMethod: _stringValue(data['paymentMethod'], fallback: 'Other'),
      taxAmount: _doubleValue(data['taxAmount']),
      notes: _stringValue(data['notes']),
    );
  }

  Future<Expense> update(Expense expense) async {
    final id = expense.id;
    if (id == null) {
      throw ArgumentError.value(
        id,
        'expense.id',
        'An ID is required to update',
      );
    }
    final data = await _apiClient.putJson(
      'api/v1/expenses/$id',
      expense.toJson(),
    );
    return Expense.fromJson(data);
  }

  Future<void> delete(int id) => _apiClient.deleteJson('api/v1/expenses/$id');
}

String _stringValue(Object? value, {String fallback = ''}) =>
    value is String ? value : fallback;

double _doubleValue(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

String _currencySymbol(String currency) => switch (currency.toUpperCase()) {
      'USD' => r'$',
      'EUR' => '€',
      'GBP' => '£',
      'CAD' => r'$',
      'AUD' => r'$',
      'JPY' => '¥',
      _ => currency.toUpperCase(),
    };
