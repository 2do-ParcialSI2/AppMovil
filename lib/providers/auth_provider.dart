import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/auth_response.dart';
import '../services/auth_service.dart';
import 'package:flutter/widgets.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  AuthStatus _status = AuthStatus.initial;
  User? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Inicializar provider - verificar si ya hay una sesión activa
  Future<void> initialize() async {
    print('🔄 AuthProvider: Iniciando inicialización...');
    
    // Postergar las notificaciones para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setLoading(true);
    });
    
    try {
      final isAuth = await _authService.isAuthenticated();
      print('🔍 AuthProvider: ¿Usuario autenticado? $isAuth');
      
      if (isAuth) {
        _currentUser = await _authService.getCurrentUser();
        print('👤 AuthProvider: Usuario cargado: ${_currentUser?.email}');
        _status = AuthStatus.authenticated;
      } else {
        print('❌ AuthProvider: No hay sesión activa');
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      print('⚠️ AuthProvider: Error al inicializar: $e');
      _status = AuthStatus.unauthenticated;
      _setError('Error al inicializar autenticación: ${e.toString()}');
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setLoading(false);
      });
    }
  }

  /// Realizar login con email y password
  Future<bool> login(String email, String password) async {
    print('🚀 AuthProvider: Iniciando login para: $email');
    _setLoading(true);
    _clearError();

    try {
      print('📡 AuthProvider: Enviando petición de login...');
      final authResponse = await _authService.login(email, password);
      print('✅ AuthProvider: Login exitoso. Usuario: ${authResponse.user.email}');
      
      _currentUser = authResponse.user;
      _status = AuthStatus.authenticated;
      _setLoading(false);
      
      print('🎉 AuthProvider: Estado actualizado a autenticado');
      return true;
    } catch (e) {
      print('❌ AuthProvider: Error en login: $e');
      _status = AuthStatus.unauthenticated;
      _setError(_getErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  /// Realizar logout
  Future<void> logout() async {
    print('🚪 AuthProvider: Iniciando logout...');
    _setLoading(true);
    
    try {
      await _authService.logout();
      print('✅ AuthProvider: Logout exitoso');
    } catch (e) {
      print('⚠️ AuthProvider: Error durante logout: $e');
    } finally {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _clearError();
      _setLoading(false);
      print('🔄 AuthProvider: Estado limpiado tras logout');
    }
  }

  /// Refrescar token
  Future<bool> refreshToken() async {
    try {
      await _authService.refreshAccessToken();
      return true;
    } catch (e) {
      await logout(); // Si falla el refresh, hacer logout
      return false;
    }
  }

  /// Actualizar datos del usuario
  Future<void> updateUser() async {
    try {
      _currentUser = await _authService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      print('Error al actualizar datos del usuario: $e');
    }
  }

  /// Verificar si el usuario tiene un rol específico por ID
  bool hasRoleId(int roleId) {
    return _currentUser?.hasRoleId(roleId) ?? false;
  }

  /// Verificar roles específicos del sistema
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isDocente => _currentUser?.isDocente ?? false;
  bool get isEstudiante => _currentUser?.isEstudiante ?? false;
  bool get isPadreTutor => _currentUser?.isPadreTutor ?? false;

  /// Obtener headers de autorización
  Future<Map<String, String>?> getAuthHeaders() async {
    return await _authService.getAuthHeaders();
  }

  /// Realizar petición autenticada
  Future<Map<String, dynamic>> authenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
  }) async {
    return await _authService.authenticatedRequest(
      method,
      endpoint,
      body: body,
      queryParams: queryParams,
    );
  }

  // Métodos privados para manejo de estado
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is ApiError) {
      return error.message;
    }
    return error.toString();
  }

  /// Limpiar todos los datos
  void clear() {
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
} 