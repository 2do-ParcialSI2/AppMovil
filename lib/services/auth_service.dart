import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/auth_response.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  
  // Keys para SharedPreferences
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  /// Realizar login con email y password
  Future<AuthResponse> login(String email, String password) async {
    try {
      print('🔐 AuthService: Iniciando login para email: $email');
      print('🔗 AuthService: URL del login: ${ApiConfig.loginEndpoint}');
      
      final loginRequest = LoginRequest(email: email, password: password);
      print('📤 AuthService: Datos de login: ${loginRequest.toJson()}');
      
      final response = await _apiService.post(
        ApiConfig.loginEndpoint,
        body: loginRequest.toJson(),
      );

      print('📥 AuthService: Respuesta del servidor: $response');
      
      final authResponse = AuthResponse.fromJson(response);
      print('✅ AuthService: AuthResponse creado exitosamente');
      print('🎫 AuthService: Token recibido: ${authResponse.token.substring(0, 20)}...');
      print('👤 AuthService: Usuario: ${authResponse.user.email}');
      
      // Guardar token y datos del usuario
      // Nota: Solo guardamos el access token ya que tu login no devuelve refresh token
      await _saveAuthData(authResponse);
      print('💾 AuthService: Datos guardados localmente');
      
      return authResponse;
    } catch (e) {
      print('❌ AuthService: Error en login: $e');
      if (e is ApiError) {
        print('📋 AuthService: Detalles del error API:');
        print('   - Status Code: ${e.statusCode}');
        print('   - Message: ${e.message}');
        print('   - Details: ${e.details}');
      }
      throw e;
    }
  }

  /// Realizar logout
  Future<void> logout() async {
    try {
      final token = await getAccessToken();
      if (token != null) {
        // Intentar hacer logout en el servidor
        try {
          await _apiService.post(
            ApiConfig.logoutEndpoint,
            headers: ApiConfig.getAuthHeaders(token),
            body: {'refresh': await getRefreshToken()}, // Tu endpoint requiere refresh token
          );
        } catch (e) {
          // Si falla el logout en el servidor, continúa con el logout local
          print('Error en logout del servidor: $e');
        }
      }
    } finally {
      // Limpiar datos locales siempre
      await _clearAuthData();
    }
  }

  /// Refrescar token de acceso
  Future<String?> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        throw ApiError(message: 'No hay token de refresh disponible');
      }

      final request = RefreshTokenRequest(refresh: refreshToken);
      final response = await _apiService.post(
        ApiConfig.refreshTokenEndpoint,
        body: request.toJson(),
      );

      final refreshResponse = RefreshTokenResponse.fromJson(response);
      await _saveAccessToken(refreshResponse.access);
      
      return refreshResponse.access;
    } catch (e) {
      // Si falla el refresh, limpiar datos de auth
      await _clearAuthData();
      throw e;
    }
  }

  /// Verificar si el usuario está autenticado
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null;
  }

  /// Obtener token de acceso
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Obtener token de refresh
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// Obtener datos del usuario actual
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    
    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return User.fromJson(userMap);
      } catch (e) {
        print('Error al decodificar datos del usuario: $e');
        return null;
      }
    }
    
    return null;
  }

  /// Obtener headers de autorización con Bearer token
  Future<Map<String, String>?> getAuthHeaders() async {
    final token = await getAccessToken();
    return token != null ? ApiConfig.getAuthHeaders(token) : null;
  }

  /// Verificar si el token ha expirado y refrescarlo si es necesario
  Future<String?> getValidAccessToken() async {
    String? token = await getAccessToken();
    
    if (token == null) {
      return null;
    }
    
    // TODO: Puedes agregar lógica para verificar si el token ha expirado
    // decodificando el JWT y verificando el campo 'exp'
    // Por ahora, simplemente devolvemos el token actual
    
    return token;
  }

  /// Guardar datos de autenticación después del login
  Future<void> _saveAuthData(AuthResponse authResponse) async {
    final prefs = await SharedPreferences.getInstance();
    
    await Future.wait([
      prefs.setString(_tokenKey, authResponse.token),
      prefs.setString(_userKey, jsonEncode(authResponse.user.toJson())),
      // Nota: No guardamos refresh token porque tu login no lo devuelve
      // Se guarda solo cuando se hace refresh
    ]);
  }

  /// Guardar solo el token de acceso (usado en refresh)
  Future<void> _saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Guardar el refresh token por separado (si lo obtienes de otra fuente)
  Future<void> saveRefreshToken(String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  /// Limpiar todos los datos de autenticación
  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await Future.wait([
      prefs.remove(_tokenKey),
      prefs.remove(_refreshTokenKey),
      prefs.remove(_userKey),
    ]);
  }

  /// Realizar petición HTTP autenticada automáticamente
  Future<Map<String, dynamic>> authenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
  }) async {
    final headers = await getAuthHeaders();
    if (headers == null) {
      throw ApiError(message: 'No hay token de acceso disponible');
    }

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          return await _apiService.get(endpoint, headers: headers, queryParams: queryParams);
        case 'POST':
          return await _apiService.post(endpoint, headers: headers, body: body);
        case 'PUT':
          return await _apiService.put(endpoint, headers: headers, body: body);
        case 'DELETE':
          return await _apiService.delete(endpoint, headers: headers);
        default:
          throw ApiError(message: 'Método HTTP no soportado: $method');
      }
    } catch (e) {
      // Si hay error 401, intentar refrescar token
      if (e is ApiError && e.statusCode == 401) {
        try {
          final newToken = await refreshAccessToken();
          if (newToken != null) {
            final newHeaders = ApiConfig.getAuthHeaders(newToken);
            // Reintentar la petición con el nuevo token
            switch (method.toUpperCase()) {
              case 'GET':
                return await _apiService.get(endpoint, headers: newHeaders, queryParams: queryParams);
              case 'POST':
                return await _apiService.post(endpoint, headers: newHeaders, body: body);
              case 'PUT':
                return await _apiService.put(endpoint, headers: newHeaders, body: body);
              case 'DELETE':
                return await _apiService.delete(endpoint, headers: newHeaders);
            }
          }
        } catch (refreshError) {
          // Si falla el refresh, propagar el error original
          throw e;
        }
      }
      throw e;
    }
  }
} 