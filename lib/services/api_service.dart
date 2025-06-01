import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/auth_response.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Cliente HTTP reutilizable
  final http.Client _client = http.Client();

  /// Realizar petición GET
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      final response = await _client
          .get(uri, headers: headers ?? ApiConfig.defaultHeaders)
          .timeout(ApiConfig.requestTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Realizar petición POST
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    
    print('🌐 ApiService POST: $url');
    if (body != null) {
      print('📤 ApiService POST Body: $body');
    }
    if (headers != null) {
      print('📋 ApiService POST Headers: $headers');
    }
    
    final response = await http.post(
      url,
      headers: {
        ...ApiConfig.defaultHeaders,
        if (headers != null) ...headers,
      },
      body: body != null ? jsonEncode(body) : null,
    );

    print('📥 ApiService POST Response Status: ${response.statusCode}');
    print('📥 ApiService POST Response Body: ${response.body}');
    
    return _handleResponse(response);
  }

  /// Realizar petición PUT
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await _client
          .put(
            uri,
            headers: headers ?? ApiConfig.defaultHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.requestTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Realizar petición DELETE
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await _client
          .delete(uri, headers: headers ?? ApiConfig.defaultHeaders)
          .timeout(ApiConfig.requestTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Construir URI completa
  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
    final url = endpoint.startsWith('http') 
        ? endpoint 
        : '${ApiConfig.baseUrl}$endpoint';
    
    final uri = Uri.parse(url);
    
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: 
          queryParams.map((key, value) => MapEntry(key, value.toString())));
    }
    
    return uri;
  }

  /// Manejar respuesta HTTP
  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    
    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }
      try {
        return jsonDecode(response.body);
      } catch (e) {
        throw ApiError(
          message: 'Error al decodificar respuesta JSON',
          statusCode: statusCode,
        );
      }
    } else {
      String errorMessage = 'Error en el servidor';
      Map<String, dynamic>? errorDetails;
      
      try {
        final errorBody = jsonDecode(response.body);
        errorMessage = errorBody['detail'] ?? 
                      errorBody['message'] ?? 
                      errorBody['error'] ?? 
                      errorMessage;
        errorDetails = errorBody;
      } catch (e) {
        errorMessage = response.body.isNotEmpty 
            ? response.body 
            : 'Error HTTP $statusCode';
      }
      
      throw ApiError(
        message: errorMessage,
        statusCode: statusCode,
        details: errorDetails,
      );
    }
  }

  /// Manejar errores de conexión
  ApiError _handleError(dynamic error) {
    if (error is SocketException) {
      return ApiError(
        message: 'Sin conexión a internet. Verifica tu conexión.',
        statusCode: 0,
      );
    } else if (error is HttpException) {
      return ApiError(
        message: 'Error de HTTP: ${error.message}',
        statusCode: 0,
      );
    } else if (error is FormatException) {
      return ApiError(
        message: 'Error de formato en la respuesta del servidor',
        statusCode: 0,
      );
    } else if (error is ApiError) {
      return error;
    } else {
      return ApiError(
        message: 'Error inesperado: ${error.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Cerrar cliente HTTP
  void dispose() {
    _client.close();
  }
} 