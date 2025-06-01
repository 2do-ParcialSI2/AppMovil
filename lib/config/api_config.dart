class ApiConfig {
  // URL base de tu backend Django
  static const String baseUrl = 'http://192.168.0.6:8001/api';
  
  // Endpoints según tu urls.py
  static const String loginEndpoint = '/login/';
  static const String logoutEndpoint = '/logout/';
  static const String refreshTokenEndpoint = '/token/refresh/';
  static const String usuariosEndpoint = '/usuarios/';
  static const String estudiantesEndpoint = '/estudiantes/';
  static const String docentesEndpoint = '/docentes/';
  static const String padresTutoresEndpoint = '/padres-tutores/';
  static const String rolesEndpoint = '/roles/';
  
  // Headers por defecto
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Headers con token de autorización (Bearer format)
  static Map<String, String> getAuthHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
  
  // URLs completas
  static String get loginUrl => baseUrl + loginEndpoint;
  static String get logoutUrl => baseUrl + logoutEndpoint;
  static String get refreshTokenUrl => baseUrl + refreshTokenEndpoint;
  static String get usuariosUrl => baseUrl + usuariosEndpoint;
  static String get estudiantesUrl => baseUrl + estudiantesEndpoint;
  static String get docentesUrl => baseUrl + docentesEndpoint;
  static String get padresTutoresUrl => baseUrl + padresTutoresEndpoint;
  static String get rolesUrl => baseUrl + rolesEndpoint;
  
  // Timeout para las requests
  static const Duration requestTimeout = Duration(seconds: 30);
} 