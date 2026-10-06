class AppConfig {
  AppConfig._();

  static const _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://invoicelyai.onrender.com/',
  );

  static Uri get apiBaseUri {
    final normalized = _configuredBaseUrl.endsWith('/')
        ? _configuredBaseUrl
        : '$_configuredBaseUrl/';
    return Uri.parse(normalized);
  }
}
