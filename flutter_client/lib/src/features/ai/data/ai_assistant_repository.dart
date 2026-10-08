import '../../../core/api/api_client.dart';
import 'ai_assistant_models.dart';

class AiAssistantRepository {
  const AiAssistantRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<AiChatResponse> sendMessage(String message) async {
    final json = await _apiClient.postJson(
      'api/v1/ai/chat',
      <String, Object?>{'message': message},
    );
    return AiChatResponse.fromJson(json);
  }

  Future<AiChatResponse> confirmCommand(String commandId) async {
    final json = await _apiClient.postJson(
      'api/v1/ai/commands/${Uri.encodeComponent(commandId)}/confirm',
      const <String, Object?>{},
    );
    return AiChatResponse.fromJson(json);
  }

  Future<AiInvoiceDraftResponse> prepareInvoiceDraft(String description) async {
    final json = await _apiClient.postJson(
      'api/v1/ai/invoice-draft',
      <String, Object?>{'message': description},
    );
    return AiInvoiceDraftResponse.fromJson(json);
  }
}
