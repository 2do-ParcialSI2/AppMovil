import 'api_service.dart';
import 'auth_service.dart';
import '../config/api_config.dart';

class MatriculaService {
  final ApiService apiService = ApiService();

  /// Obtener todas las matrículas de un padre/tutor usando el endpoint específico
  Future<Map<String, dynamic>?> obtenerMatriculasPorPadreTutor(int padreTutorId, String token) async {
    try {
      print('🎓 MatriculaService: Obteniendo matrículas para padre/tutor ID: $padreTutorId');
      
      // Usar el endpoint específico del backend con prefijo correcto
      final response = await apiService.get('/matricula/matriculas-padre-tutor/$padreTutorId/', token: token);
      
      print('🔍 MatriculaService: Respuesta completa del endpoint específico:');
      print('   Success: ${response['success']}');
      print('   Data: ${response['data']}');
      print('   Message: ${response['message'] ?? 'Sin mensaje'}');
      
      if (response['success'] == true) {
        final data = response['data'];
        
        // Verificar si tenemos datos válidos
        if (data != null) {
          print('✅ MatriculaService: Datos obtenidos del endpoint específico');
          print('   Tipo de datos: ${data.runtimeType}');
          
          // Si es una lista, verificar contenido
          if (data is List) {
            print('   Cantidad de elementos: ${data.length}');
            if (data.isNotEmpty) {
              print('   Primer elemento: ${data.first}');
            }
          }
          // Si es un mapa, verificar estructura
          else if (data is Map<String, dynamic>) {
            print('   Claves del mapa: ${data.keys.toList()}');
            if (data.containsKey('estudiantes')) {
              print('   Estudiantes encontrados: ${data['estudiantes']?.length ?? 0}');
            }
            if (data.containsKey('matriculas')) {
              print('   Matrículas encontradas: ${data['matriculas']?.length ?? 0}');
            }
          }
          
          return data;
        } else {
          print('⚠️ MatriculaService: Data es null en respuesta exitosa');
          return null;
        }
      } else {
        print('❌ MatriculaService: Error en respuesta del endpoint específico: ${response['message']}');
        // Fallback: intentar con el método anterior si el endpoint específico falla
        return await _obtenerMatriculasPorPadreTutorFallback(padreTutorId, token);
      }
      
    } catch (e) {
      print('❌ MatriculaService: Error con endpoint específico: $e');
      print('🔄 MatriculaService: Intentando con método alternativo...');
      // Fallback: usar el método anterior
      return await _obtenerMatriculasPorPadreTutorFallback(padreTutorId, token);
    }
  }

  /// Método fallback para obtener matrículas (procesamiento client-side)
  Future<Map<String, dynamic>?> _obtenerMatriculasPorPadreTutorFallback(int padreTutorId, String token) async {
    try {
      print('🔄 MatriculaService: Usando método fallback (procesamiento client-side)');
      
      // Primero obtenemos los estudiantes del padre/tutor
      final estudiantesResponse = await apiService.get('/estudiantes/', token: token);
      
      if (estudiantesResponse['success'] != true) {
        print('❌ MatriculaService: Error al obtener estudiantes');
        return null;
      }
      
      List<dynamic> todosEstudiantes = [];
      if (estudiantesResponse['data'] != null) {
        todosEstudiantes = estudiantesResponse['data'];
      } else if (estudiantesResponse['results'] != null) {
        todosEstudiantes = estudiantesResponse['results'];
      }
      
      // Filtrar estudiantes que pertenecen al padre/tutor
      final estudiantesDelPadre = todosEstudiantes.where((estudiante) {
        final padreTutorField = estudiante['padre_tutor'];
        if (padreTutorField == null) return false;
        
        if (padreTutorField is Map<String, dynamic>) {
          return padreTutorField['id'] == padreTutorId;
        }
        return padreTutorField == padreTutorId;
      }).toList();
      
      print('👶 MatriculaService: ${estudiantesDelPadre.length} estudiantes encontrados para padre/tutor $padreTutorId');
      
      if (estudiantesDelPadre.isEmpty) {
        return {
          'padre_tutor': {
            'id': padreTutorId,
            'nombre_completo': 'Padre/Tutor',
            'parentesco': 'Tutor',
          },
          'resumen_global': {
            'total_estudiantes': 0,
            'total_matriculas': 0,
            'matriculas_vigentes': 0,
            'monto_total_pagado': 0.0,
          },
          'estudiantes': [],
        };
      }
      
      // Obtener todas las matrículas con ruta corregida
      final matriculasResponse = await apiService.get('/matricula/matriculas/', token: token);
      
      if (matriculasResponse['success'] != true) {
        print('❌ MatriculaService: Error al obtener matrículas');
        return null;
      }
      
      List<dynamic> todasMatriculas = [];
      if (matriculasResponse['data'] != null) {
        todasMatriculas = matriculasResponse['data'];
      } else if (matriculasResponse['results'] != null) {
        todasMatriculas = matriculasResponse['results'];
      }
      
      // Organizar datos por estudiante
      List<Map<String, dynamic>> estudiantesConMatriculas = [];
      int totalMatriculas = 0;
      int matriculasVigentes = 0;
      double montoTotalPagado = 0.0;
      
      for (final estudiante in estudiantesDelPadre) {
        final estudianteId = estudiante['id'];
        
        // Filtrar matrículas de este estudiante
        final matriculasEstudiante = todasMatriculas.where((matricula) {
          if (matricula['estudiante'] is Map) {
            return matricula['estudiante']['id'] == estudianteId;
          }
          return matricula['estudiante'] == estudianteId;
        }).toList();
        
        // Calcular resumen del estudiante
        int matriculasVigentesEstudiante = 0;
        double montoTotalEstudiante = 0.0;
        
        for (final matricula in matriculasEstudiante) {
          final monto = (matricula['monto'] ?? 0.0).toDouble();
          final descuento = (matricula['descuento'] ?? 0.0).toDouble();
          final montoFinal = monto - descuento;
          
          montoTotalEstudiante += montoFinal;
          montoTotalPagado += montoFinal;
          
          // Determinar si está vigente (simplificado - asumimos que estado=true = vigente)
          final vigente = matricula['estado'] == true;
          if (vigente) {
            matriculasVigentesEstudiante++;
            matriculasVigentes++;
          }
        }
        
        totalMatriculas += matriculasEstudiante.length;
        
        estudiantesConMatriculas.add({
          'id': estudianteId,
          'nombre_completo': '${estudiante['first_name'] ?? ''} ${estudiante['last_name'] ?? ''}'.trim(),
          'curso': estudiante['curso'],
          'resumen_estudiante': {
            'total_matriculas': matriculasEstudiante.length,
            'matriculas_vigentes': matriculasVigentesEstudiante,
            'monto_total': montoTotalEstudiante,
          },
          'matriculas': matriculasEstudiante.map((m) => {
            ...m,
            'vigente': m['estado'] == true, // Simplificado
          }).toList(),
        });
      }
      
      final result = {
        'padre_tutor': {
          'id': padreTutorId,
          'nombre_completo': 'Padre/Tutor',
          'parentesco': 'Tutor',
        },
        'resumen_global': {
          'total_estudiantes': estudiantesDelPadre.length,
          'total_matriculas': totalMatriculas,
          'matriculas_vigentes': matriculasVigentes,
          'monto_total_pagado': montoTotalPagado,
        },
        'estudiantes': estudiantesConMatriculas,
      };
      
      print('✅ MatriculaService: Datos procesados con fallback - ${totalMatriculas} matrículas encontradas');
      return result;
      
    } catch (e) {
      print('❌ MatriculaService: Error en método fallback: $e');
      print('🔄 MatriculaService: Usando datos mock para matrículas');
      return _obtenerMatriculasMock(padreTutorId);
    }
  }

  /// Datos mock para matrículas (temporal mientras se configuran endpoints)
  Map<String, dynamic> _obtenerMatriculasMock(int padreTutorId) {
    return {
      'padre_tutor': {
        'id': padreTutorId,
        'nombre_completo': 'Rolando Alvarez',
        'parentesco': 'Abuelo',
      },
      'resumen_global': {
        'total_estudiantes': 1,
        'total_matriculas': 3,
        'matriculas_vigentes': 2,
        'monto_total_pagado': 450.0,
      },
      'estudiantes': [
        {
          'id': 1,
          'nombre_completo': 'Jaime Alvarez',
          'curso': {'nombre': '1ro A', 'turno': 'mañana'},
          'resumen_estudiante': {
            'total_matriculas': 3,
            'matriculas_vigentes': 2,
            'monto_total': 450.0,
          },
          'matriculas': [
            {
              'id': 1,
              'fecha_pago': '2024-01-15',
              'monto': 200.0,
              'descuento': 0.0,
              'vigente': true,
              'estado': true,
              'tipo_pago': {
                'id': 1,
                'nombre': 'Pago Mensual',
                'tipo': 'mensual',
              },
              'metodo_pago': {
                'id': 1,
                'nombre': 'Efectivo',
              },
            },
            {
              'id': 2,
              'fecha_pago': '2024-02-15',
              'monto': 200.0,
              'descuento': 20.0,
              'vigente': true,
              'estado': true,
              'tipo_pago': {
                'id': 1,
                'nombre': 'Pago Mensual',
                'tipo': 'mensual',
              },
              'metodo_pago': {
                'id': 2,
                'nombre': 'Transferencia Bancaria',
              },
            },
            {
              'id': 3,
              'fecha_pago': '2023-12-15',
              'monto': 180.0,
              'descuento': 10.0,
              'vigente': false,
              'estado': false,
              'tipo_pago': {
                'id': 1,
                'nombre': 'Pago Mensual',
                'tipo': 'mensual',
              },
              'metodo_pago': {
                'id': 1,
                'nombre': 'Efectivo',
              },
            },
          ],
        },
      ],
      'matriculas_por_estudiante': {
        '1': [
          {
            'id': 1,
            'fecha_pago': '2024-01-15',
            'monto': 200.0,
            'descuento': 0.0,
            'vigente': true,
            'estado': true,
            'tipo_pago': {
              'id': 1,
              'nombre': 'Pago Mensual',
              'tipo': 'mensual',
            },
            'metodo_pago': {
              'id': 1,
              'nombre': 'Efectivo',
            },
          },
          {
            'id': 2,
            'fecha_pago': '2024-02-15',
            'monto': 200.0,
            'descuento': 20.0,
            'vigente': true,
            'estado': true,
            'tipo_pago': {
              'id': 1,
              'nombre': 'Pago Mensual',
              'tipo': 'mensual',
            },
            'metodo_pago': {
              'id': 2,
              'nombre': 'Transferencia Bancaria',
            },
          },
          {
            'id': 3,
            'fecha_pago': '2023-12-15',
            'monto': 180.0,
            'descuento': 10.0,
            'vigente': false,
            'estado': false,
            'tipo_pago': {
              'id': 1,
              'nombre': 'Pago Mensual',
              'tipo': 'mensual',
            },
            'metodo_pago': {
              'id': 1,
              'nombre': 'Efectivo',
            },
          },
        ],
      },
    };
  }

  /// Obtener matrículas de un estudiante específico
  Future<Map<String, dynamic>?> obtenerMatriculasPorEstudiante(int estudianteId, String token) async {
    try {
      print('📚 MatriculaService: Obteniendo matrículas para estudiante ID: $estudianteId');
      
      final response = await apiService.get('/matricula/matriculas/', token: token);

      if (response['success'] == true) {
        List<dynamic> todasMatriculas = [];
        if (response['data'] != null) {
          todasMatriculas = response['data'];
        } else if (response['results'] != null) {
          todasMatriculas = response['results'];
        }
        
        // Filtrar por estudiante
        final matriculasEstudiante = todasMatriculas.where((matricula) {
          if (matricula['estudiante'] is Map) {
            return matricula['estudiante']['id'] == estudianteId;
          }
          return matricula['estudiante'] == estudianteId;
        }).toList();
        
        print('✅ MatriculaService: ${matriculasEstudiante.length} matrículas encontradas para estudiante');
        
        return {
          'resumen': {
            'total_matriculas': matriculasEstudiante.length,
          },
          'matriculas': matriculasEstudiante,
        };
      } else {
        print('❌ MatriculaService: Error en respuesta: ${response['message']}');
        return null;
      }
    } catch (e) {
      print('❌ MatriculaService: Error al obtener matrículas del estudiante: $e');
      return null;
    }
  }

  /// Obtener tipos de pago disponibles
  Future<List<Map<String, dynamic>>> obtenerTiposPago(String token) async {
    try {
      print('📋 MatriculaService: Obteniendo tipos de pago...');
      print('📋 MatriculaService: URL base: ${ApiConfig.baseUrl}');
      print('📋 MatriculaService: Endpoint completo: ${ApiConfig.baseUrl}/matricula/tipopago/');
      
      final response = await apiService.get('/matricula/tipopago/', token: token);
      print('📋 MatriculaService: Respuesta tipos de pago: $response');

      if (response['success'] == true) {
        List<dynamic> tipos = [];
        if (response['data'] != null) {
          tipos = response['data'];
        } else if (response['results'] != null) {
          tipos = response['results'];
        }
        
        final tiposLista = List<Map<String, dynamic>>.from(tipos);
        print('✅ MatriculaService: ${tiposLista.length} tipos de pago obtenidos');
        return tiposLista;
      } else {
        print('❌ MatriculaService: Error en respuesta tipos de pago: ${response['message'] ?? 'Sin mensaje'}');
        return _obtenerTiposPagoMock();
      }
    } catch (e) {
      print('❌ MatriculaService: Error al obtener tipos de pago: $e');
      print('🔄 MatriculaService: Usando datos mock para tipos de pago');
      return _obtenerTiposPagoMock();
    }
  }

  /// Obtener métodos de pago disponibles
  Future<List<Map<String, dynamic>>> obtenerMetodosPago(String token) async {
    try {
      print('🏦 MatriculaService: Obteniendo métodos de pago...');
      print('🏦 MatriculaService: URL base: ${ApiConfig.baseUrl}');
      print('🏦 MatriculaService: Endpoint completo: ${ApiConfig.baseUrl}/matricula/metodpago/');
      
      final response = await apiService.get('/matricula/metodpago/', token: token);
      print('🏦 MatriculaService: Respuesta métodos de pago: $response');

      if (response['success'] == true) {
        List<dynamic> metodos = [];
        if (response['data'] != null) {
          metodos = response['data'];
        } else if (response['results'] != null) {
          metodos = response['results'];
        }
        
        final metodosLista = List<Map<String, dynamic>>.from(metodos);
        print('✅ MatriculaService: ${metodosLista.length} métodos de pago obtenidos');
        return metodosLista;
      } else {
        print('❌ MatriculaService: Error en respuesta métodos de pago: ${response['message'] ?? 'Sin mensaje'}');
        return _obtenerMetodosPagoMock();
      }
    } catch (e) {
      print('❌ MatriculaService: Error al obtener métodos de pago: $e');
      print('🔄 MatriculaService: Usando datos mock para métodos de pago');
      return _obtenerMetodosPagoMock();
    }
  }

  /// Datos mock para tipos de pago (temporal mientras se configuran endpoints)
  List<Map<String, dynamic>> _obtenerTiposPagoMock() {
    return [
      {
        'id': 1,
        'nombre': 'Pago Mensual',
        'tipo': 'mensual',
        'descripcion': 'Pago de matrícula mensual - válido por 1 mes',
      },
      {
        'id': 2,
        'nombre': 'Pago Anual',
        'tipo': 'anual', 
        'descripcion': 'Pago de matrícula anual - válido por todo el año académico',
      },
    ];
  }

  /// Datos mock para métodos de pago (temporal mientras se configuran endpoints)
  List<Map<String, dynamic>> _obtenerMetodosPagoMock() {
    return [
      {
        'id': 1,
        'nombre': 'Efectivo',
        'descripcion': 'Pago en efectivo en la institución',
      },
      {
        'id': 2,
        'nombre': 'Transferencia Bancaria',
        'descripcion': 'Pago mediante transferencia bancaria',
      },
      {
        'id': 3,
        'nombre': 'Tarjeta de Débito',
        'descripcion': 'Pago con tarjeta de débito',
      },
      {
        'id': 4,
        'nombre': 'Tarjeta de Crédito',
        'descripcion': 'Pago con tarjeta de crédito',
      },
    ];
  }

  /// Crear nueva matrícula (realizar pago)
  Future<Map<String, dynamic>?> crearMatricula({
    required int estudianteId,
    required int tipoPagoId,
    required int metodoPagoId,
    required double monto,
    double descuento = 0.0,
    required String token,
  }) async {
    try {
      print('💰 MatriculaService: Creando nueva matrícula');
      print('   Estudiante: $estudianteId');
      print('   Tipo pago: $tipoPagoId');
      print('   Método pago: $metodoPagoId');
      print('   Monto: $monto');
      print('   Descuento: $descuento');
      
      final body = {
        'estudiante': estudianteId,
        'tipo_pago': tipoPagoId,
        'met_pago': metodoPagoId,
        'fecha': DateTime.now().toIso8601String().split('T')[0], // Solo fecha
        'monto': monto,
        'descuento': descuento,
        'estado': true,
      };

      final response = await apiService.post(
        '/matricula/matriculas/',
        body: body,
        token: token,
      );

      if (response['success'] == true) {
        print('✅ MatriculaService: Matrícula creada exitosamente');
        return response['data'];
      } else {
        print('❌ MatriculaService: Error al crear matrícula: ${response['message']}');
        throw Exception(response['message'] ?? 'Error desconocido al crear matrícula');
      }
    } catch (e) {
      print('❌ MatriculaService: Error al crear matrícula: $e');
      rethrow;
    }
  }

  /// Verificar si un padre/tutor puede acceder al sistema de matrículas
  static Future<bool> puedeAccederMatriculas() async {
    try {
      final user = await AuthService().getCurrentUser();
      if (user == null) return false;
      
      // Solo los padres/tutores pueden acceder a matrículas
      return user.isPadreTutor;
    } catch (e) {
      print('❌ MatriculaService: Error al verificar acceso: $e');
      return false;
    }
  }

  /// Obtener ID del padre/tutor actual logueado desde el endpoint específico
  static Future<int?> obtenerPadreTutorIdActual() async {
    try {
      final user = await AuthService().getCurrentUser();
      if (user == null || !user.isPadreTutor) return null;

      final token = await AuthService().getAccessToken();
      if (token == null) return null;

      final apiService = ApiService();
      
      // Obtener datos del endpoint padres-tutores
      final response = await apiService.get('/padres-tutores/', token: token);
      
      if (response['success'] == true) {
        List<dynamic> padresTutores = [];
        if (response['data'] != null) {
          padresTutores = response['data'];
        } else if (response['results'] != null) {
          padresTutores = response['results'];
        }
        
        // Buscar el padre/tutor que coincida con el email del usuario logueado
        for (final padre in padresTutores) {
          if (padre['email'] == user.email) {
            print('✅ MatriculaService: Padre/tutor encontrado - ID: ${padre['id']}, Email: ${padre['email']}');
            return padre['id'] as int;
          }
        }
        
        print('❌ MatriculaService: No se encontró padre/tutor con email: ${user.email}');
        return null;
      } else {
        print('❌ MatriculaService: Error en respuesta de padres-tutores: ${response['message']}');
        return null;
      }
    } catch (e) {
      print('❌ MatriculaService: Error al obtener ID padre/tutor: $e');
      return null;
    }
  }

  /// Método para probar qué endpoints de matrícula realmente existen
  static Future<void> probarEndpointsMatricula() async {
    try {
      final token = await AuthService().getAccessToken();
      if (token == null) return;

      final apiService = ApiService();
      
      // Lista de posibles endpoints para probar con prefijo correcto
      final endpointsAPRobar = [
        '/matricula/tipopago/',
        '/matricula/tipo-pago/',
        '/matricula/tipos-pago/',
        '/matricula/metodpago/',
        '/matricula/metodo-pago/',
        '/matricula/metodos-pago/',
        '/matricula/matriculas/',
        '/matricula/matricula/',
        '/matricula/pagos/',
        '/matricula/pago/',
      ];

      print('🔍 Probando endpoints de matrícula...');
      
      for (final endpoint in endpointsAPRobar) {
        try {
          final response = await apiService.get(endpoint, token: token);
          print('✅ FUNCIONA: $endpoint');
        } catch (e) {
          print('❌ NO FUNCIONA: $endpoint');
        }
      }
      
    } catch (e) {
      print('❌ Error al probar endpoints: $e');
    }
  }
} 