import '../../../core/api/api_client.dart';

class NotificationRepository {
  NotificationRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Loads all saved notification templates for current company (with seeded defaults).
  Future<List<Map<String, dynamic>>> loadTemplates({int? companyId}) async {
    final query = <String, String>{};
    if (companyId != null) query['companyId'] = companyId.toString();

    return _apiClient.getListJson(
      '/api/v1/notification-templates',
      queryParameters: query.isEmpty ? null : query,
    );
  }

  /// Gets effective template by template name.
  Future<Map<String, dynamic>> loadTemplateByName({
    required String templateName,
    String? channel,
    int? companyId,
  }) async {
    final query = <String, String>{};
    if (channel != null) query['channel'] = channel;
    if (companyId != null) query['companyId'] = companyId.toString();

    final response = await _apiClient.getJson(
      '/api/v1/notification-templates/by-name/$templateName',
      queryParameters: query.isEmpty ? null : query,
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    return <String, dynamic>{};
  }

  /// Saves or updates a template from Settings UI.
  Future<Map<String, dynamic>> saveTemplate({
    required String templateName,
    required String channel,
    required String body,
    String? subject,
    String? title,
    String? metadataJson,
    int? companyId,
  }) async {
    final payload = <String, Object?>{
      'templateName': templateName,
      'channel': channel,
      'body': body,
      if (subject != null) 'subject': subject,
      if (title != null) 'title': title,
      if (metadataJson != null) 'metadataJson': metadataJson,
    };

    final query = <String, String>{};
    if (companyId != null) query['companyId'] = companyId.toString();

    final response = await _apiClient.postJson(
      '/api/v1/notification-templates',
      payload,
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    return response;
  }

  /// Updates existing template by ID.
  Future<Map<String, dynamic>> updateTemplate({
    required int id,
    required String templateName,
    required String channel,
    required String body,
    String? subject,
    String? title,
    String? metadataJson,
  }) async {
    final payload = <String, Object?>{
      'templateName': templateName,
      'channel': channel,
      'body': body,
      if (subject != null) 'subject': subject,
      if (title != null) 'title': title,
      if (metadataJson != null) 'metadataJson': metadataJson,
    };

    final response = await _apiClient.putJson(
      '/api/v1/notification-templates/$id',
      payload,
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    return response;
  }

  /// Resets a template to system default.
  Future<void> resetTemplate(int id) async {
    await _apiClient.deleteJson('/api/v1/notification-templates/$id');
  }

  /// Previews rendered template subject and body.
  Future<Map<String, dynamic>> previewTemplate({
    String? templateName,
    String channel = 'EMAIL',
    String? subject,
    String? body,
    int? invoiceId,
    Map<String, Object?>? variables,
  }) async {
    final payload = <String, Object?>{
      if (templateName != null) 'templateName': templateName,
      'channel': channel,
      if (subject != null) 'subject': subject,
      if (body != null) 'body': body,
      if (invoiceId != null) 'invoiceId': invoiceId,
      if (variables != null) 'variables': variables,
    };

    final response = await _apiClient.postJson(
      '/api/v1/notification-templates/preview',
      payload,
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    return response;
  }

  /// Queues an invoice reminder (Email or WhatsApp).
  Future<Map<String, dynamic>> sendInvoiceReminder({
    required int invoiceId,
    String channel = 'EMAIL',
    String? templateName,
    String? overrideRecipient,
    String? customMessage,
    String? scheduledAt,
  }) async {
    final payload = <String, Object?>{
      'invoiceId': invoiceId,
      'channel': channel,
      if (templateName != null) 'templateName': templateName,
      if (overrideRecipient != null) 'overrideRecipient': overrideRecipient,
      if (customMessage != null) 'customMessage': customMessage,
      if (scheduledAt != null) 'scheduledAt': scheduledAt,
    };

    final response = await _apiClient.postJson(
      '/api/v1/notifications/send-reminder',
      payload,
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    return response;
  }

  /// Queues a company invite (Email or WhatsApp).
  Future<Map<String, dynamic>> sendInvite({
    required String inviteeEmail,
    String? inviteePhone,
    String? inviteeName,
    String channel = 'EMAIL',
    String role = 'EMPLOYEE',
    String? customNote,
  }) async {
    final payload = <String, Object?>{
      'inviteeEmail': inviteeEmail,
      if (inviteePhone != null) 'inviteePhone': inviteePhone,
      if (inviteeName != null) 'inviteeName': inviteeName,
      'channel': channel,
      'role': role,
      if (customNote != null) 'customNote': customNote,
    };

    final response = await _apiClient.postJson(
      '/api/v1/notifications/send-invite',
      payload,
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    return response;
  }

  /// Pushes response to join request applicant.
  Future<Map<String, dynamic>> sendJoinRequestResponse({
    required int joinRequestId,
    required String action,
    String? customMessage,
    String channel = 'EMAIL',
    String? templateName,
  }) async {
    final payload = <String, Object?>{
      'joinRequestId': joinRequestId,
      'action': action,
      if (customMessage != null) 'customMessage': customMessage,
      'channel': channel,
      if (templateName != null) 'templateName': templateName,
    };

    final response = await _apiClient.postJson(
      '/api/v1/notifications/send-join-request-response',
      payload,
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    return response;
  }

  /// Loads notification queue outbox.
  Future<Map<String, dynamic>> loadQueue({
    String? status,
    String? channel,
    int page = 0,
    int size = 20,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
      if (status != null) 'status': status,
      if (channel != null) 'channel': channel,
    };

    return _apiClient.getJson(
      '/api/v1/notifications/queue',
      queryParameters: query,
    );
  }

  /// Loads audit logs.
  Future<Map<String, dynamic>> loadAuditLogs({
    int? notificationId,
    int page = 0,
    int size = 20,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
      if (notificationId != null) 'notificationId': notificationId.toString(),
    };

    return _apiClient.getJson(
      '/api/v1/notifications/audit-logs',
      queryParameters: query,
    );
  }

  /// Retries a stuck or failed notification.
  Future<Map<String, dynamic>> retryNotification(int id) async {
    final response = await _apiClient.postJson(
      '/api/v1/notifications/queue/$id/retry',
      const <String, Object?>{},
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    return response;
  }

  /// Loads delivery metrics.
  Future<Map<String, dynamic>> loadMetrics() async {
    final response = await _apiClient.getJson('/api/v1/notifications/metrics');
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    return <String, dynamic>{};
  }
}
