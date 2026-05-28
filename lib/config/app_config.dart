class AppConfig {
  AppConfig._();

  // Permite sobreescribir por entorno sin tocar código:
  // flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000
  static const String _baseUrlOverride =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static const String _scheme =
      String.fromEnvironment('API_SCHEME', defaultValue: 'http');
  static const String _host =
      String.fromEnvironment('API_HOST', defaultValue: '192.168.10.19');
  static const String _port =
      String.fromEnvironment('API_PORT', defaultValue: '8000');

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) {
      return _baseUrlOverride;
    }
    return '$_scheme://$_host:$_port';
  }

  static String get questionEndpoint => "$baseUrl/api/v1/question";
}
