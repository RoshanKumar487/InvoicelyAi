import '../../../core/api/api_client.dart';
import 'client.dart';

class ClientsRepository {
  const ClientsRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  bool get lastLoadUsedCache => _apiClient.lastGetUsedCache;

  Future<List<Client>> list({String search = ''}) async {
    final query = search.trim();
    final rows = await _apiClient.getListJson(
      'api/v1/clients',
      queryParameters: query.isEmpty ? null : {'search': query},
    );
    return rows.map(Client.fromJson).toList(growable: false);
  }

  Future<Client> create(Client client) async {
    final data = await _apiClient.postJson(
      'api/v1/clients',
      client.toJson(),
    );
    return Client.fromJson(data);
  }

  Future<Client> update(Client client) async {
    final id = client.id;
    if (id == null) {
      throw ArgumentError.value(id, 'client.id', 'An ID is required to update');
    }
    final data = await _apiClient.putJson(
      'api/v1/clients/$id',
      client.toJson(),
    );
    return Client.fromJson(data);
  }

  Future<void> delete(int id) => _apiClient.deleteJson('api/v1/clients/$id');
}
