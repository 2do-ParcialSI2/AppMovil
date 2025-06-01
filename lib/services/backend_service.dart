import '../config/api_config.dart';
import '../services/auth_service.dart';

class BackendService {
  static final BackendService _instance = BackendService._internal();
  factory BackendService() => _instance;
  BackendService._internal();

  final AuthService _authService = AuthService();

  /// **ESTUDIANTES**
  
  /// Obtener lista de estudiantes
  Future<List<Map<String, dynamic>>> getEstudiantes() async {
    final response = await _authService.authenticatedRequest(
      'GET',
      ApiConfig.estudiantesEndpoint,
    );
    return List<Map<String, dynamic>>.from(response['results'] ?? response);
  }

  /// Obtener un estudiante por ID
  Future<Map<String, dynamic>> getEstudiante(int id) async {
    return await _authService.authenticatedRequest(
      'GET',
      '${ApiConfig.estudiantesEndpoint}$id/',
    );
  }

  /// Crear un nuevo estudiante
  Future<Map<String, dynamic>> createEstudiante(Map<String, dynamic> data) async {
    return await _authService.authenticatedRequest(
      'POST',
      ApiConfig.estudiantesEndpoint,
      body: data,
    );
  }

  /// Actualizar un estudiante
  Future<Map<String, dynamic>> updateEstudiante(int id, Map<String, dynamic> data) async {
    return await _authService.authenticatedRequest(
      'PUT',
      '${ApiConfig.estudiantesEndpoint}$id/',
      body: data,
    );
  }

  /// Eliminar un estudiante
  Future<void> deleteEstudiante(int id) async {
    await _authService.authenticatedRequest(
      'DELETE',
      '${ApiConfig.estudiantesEndpoint}$id/',
    );
  }

  /// **DOCENTES**
  
  /// Obtener lista de docentes
  Future<List<Map<String, dynamic>>> getDocentes() async {
    final response = await _authService.authenticatedRequest(
      'GET',
      ApiConfig.docentesEndpoint,
    );
    return List<Map<String, dynamic>>.from(response['results'] ?? response);
  }

  /// Obtener un docente por ID
  Future<Map<String, dynamic>> getDocente(int id) async {
    return await _authService.authenticatedRequest(
      'GET',
      '${ApiConfig.docentesEndpoint}$id/',
    );
  }

  /// Obtener horarios de un docente
  Future<Map<String, dynamic>> getDocenteHorarios(int docenteId) async {
    return await _authService.authenticatedRequest(
      'GET',
      '${ApiConfig.docentesEndpoint}$docenteId/horarios/',
    );
  }

  /// Crear un nuevo docente
  Future<Map<String, dynamic>> createDocente(Map<String, dynamic> data) async {
    return await _authService.authenticatedRequest(
      'POST',
      ApiConfig.docentesEndpoint,
      body: data,
    );
  }

  /// Actualizar un docente
  Future<Map<String, dynamic>> updateDocente(int id, Map<String, dynamic> data) async {
    return await _authService.authenticatedRequest(
      'PUT',
      '${ApiConfig.docentesEndpoint}$id/',
      body: data,
    );
  }

  /// Eliminar un docente
  Future<void> deleteDocente(int id) async {
    await _authService.authenticatedRequest(
      'DELETE',
      '${ApiConfig.docentesEndpoint}$id/',
    );
  }

  /// **PADRES/TUTORES**
  
  /// Obtener lista de padres/tutores
  Future<List<Map<String, dynamic>>> getPadresTutores() async {
    final response = await _authService.authenticatedRequest(
      'GET',
      ApiConfig.padresTutoresEndpoint,
    );
    return List<Map<String, dynamic>>.from(response['results'] ?? response);
  }

  /// Obtener un padre/tutor por ID
  Future<Map<String, dynamic>> getPadreTutor(int id) async {
    return await _authService.authenticatedRequest(
      'GET',
      '${ApiConfig.padresTutoresEndpoint}$id/',
    );
  }

  /// Crear un nuevo padre/tutor
  Future<Map<String, dynamic>> createPadreTutor(Map<String, dynamic> data) async {
    return await _authService.authenticatedRequest(
      'POST',
      ApiConfig.padresTutoresEndpoint,
      body: data,
    );
  }

  /// Actualizar un padre/tutor
  Future<Map<String, dynamic>> updatePadreTutor(int id, Map<String, dynamic> data) async {
    return await _authService.authenticatedRequest(
      'PUT',
      '${ApiConfig.padresTutoresEndpoint}$id/',
      body: data,
    );
  }

  /// Eliminar un padre/tutor
  Future<void> deletePadreTutor(int id) async {
    await _authService.authenticatedRequest(
      'DELETE',
      '${ApiConfig.padresTutoresEndpoint}$id/',
    );
  }

  /// **USUARIOS**
  
  /// Obtener lista de usuarios
  Future<List<Map<String, dynamic>>> getUsuarios() async {
    final response = await _authService.authenticatedRequest(
      'GET',
      ApiConfig.usuariosEndpoint,
    );
    return List<Map<String, dynamic>>.from(response['results'] ?? response);
  }

  /// Obtener un usuario por ID
  Future<Map<String, dynamic>> getUsuario(int id) async {
    return await _authService.authenticatedRequest(
      'GET',
      '${ApiConfig.usuariosEndpoint}$id/',
    );
  }

  /// **ROLES**
  
  /// Obtener lista de roles
  Future<List<Map<String, dynamic>>> getRoles() async {
    final response = await _authService.authenticatedRequest(
      'GET',
      ApiConfig.rolesEndpoint,
    );
    return List<Map<String, dynamic>>.from(response['results'] ?? response);
  }

  /// **MÉTODOS GENÉRICOS ÚTILES**
  
  /// Buscar en cualquier endpoint con parámetros
  Future<List<Map<String, dynamic>>> search(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await _authService.authenticatedRequest(
      'GET',
      endpoint,
      queryParams: queryParams,
    );
    return List<Map<String, dynamic>>.from(response['results'] ?? response);
  }

  /// Realizar cualquier petición autenticada personalizada
  Future<Map<String, dynamic>> customRequest(
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
} 