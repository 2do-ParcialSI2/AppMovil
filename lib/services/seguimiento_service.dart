import '../models/seguimiento_models.dart';
import '../services/api_service.dart';

class SeguimientoService {
  final ApiService apiService = ApiService();

  // ========================= SEGUIMIENTOS =========================

  /// Obtener materias de un estudiante específico
  Future<List<SeguimientoDetallado>> obtenerMateriasPorEstudiante(int estudianteId, String token) async {
    try {
      print('📚 SeguimientoService: Obteniendo materias del estudiante $estudianteId');
      
      final response = await apiService.get(
        '/seguimiento/?estudiante=$estudianteId',
        token: token,
      );

      print('🔍 SeguimientoService: Respuesta completa: $response');
      print('🔍 SeguimientoService: Success: ${response['success']}');
      print('🔍 SeguimientoService: Data type: ${response['data'].runtimeType}');
      print('🔍 SeguimientoService: Data content: ${response['data']}');

      if (response['success'] == true && response['data'] is List) {
        final List<dynamic> data = response['data'];
        print('📚 SeguimientoService: ${data.length} materias encontradas');
        
        // Convertir los seguimientos básicos a seguimientos detallados
        // Aquí podríamos necesitar hacer llamadas adicionales para obtener detalles completos
        List<SeguimientoDetallado> seguimientosDetallados = [];
        
        for (final item in data) {
          print('🔍 SeguimientoService: Procesando item: $item');
          try {
            // Crear un seguimiento detallado básico con la información disponible
            // Nota: Puede que necesitemos ajustar esto según la estructura real de la respuesta
            seguimientosDetallados.add(SeguimientoDetallado.fromJson(item));
          } catch (e) {
            print('❌ SeguimientoService: Error al procesar item: $e');
            print('❌ SeguimientoService: Item problemático: $item');
          }
        }
        
        return seguimientosDetallados;
      } else {
        throw Exception('Formato de respuesta inválido para materias');
      }
    } catch (e) {
      print('❌ SeguimientoService: Error al obtener materias: $e');
      throw Exception('Error al obtener materias del estudiante: $e');
    }
  }

  /// Obtener seguimiento específico por ID
  Future<Seguimiento> obtenerSeguimiento(int seguimientoId, String token) async {
    try {
      print('📊 SeguimientoService: Obteniendo seguimiento $seguimientoId');
      
      final response = await apiService.get(
        '/seguimiento/$seguimientoId/',
        token: token,
      );

      if (response['success'] == true && response['data'] != null) {
        return Seguimiento.fromJson(response['data']);
      } else {
        throw Exception('Seguimiento no encontrado');
      }
    } catch (e) {
      print('❌ SeguimientoService: Error al obtener seguimiento: $e');
      throw Exception('Error al obtener seguimiento: $e');
    }
  }

  // ========================= TAREAS =========================

  /// Obtener tareas por seguimiento
  Future<List<Tarea>> obtenerTareasPorSeguimiento(int seguimientoId, String token) async {
    try {
      print('📝 SeguimientoService: Obteniendo tareas del seguimiento $seguimientoId');
      
      final response = await apiService.get(
        '/seguimiento/tareas/por_seguimiento/?seguimiento_id=$seguimientoId',
        token: token,
      );

      if (response['success'] == true && response['data'] is List) {
        final List<dynamic> data = response['data'];
        print('📝 SeguimientoService: ${data.length} tareas encontradas');
        
        return data.map<Tarea>((json) => Tarea.fromJson(json)).toList();
      } else {
        throw Exception('Formato de respuesta inválido para tareas');
      }
    } catch (e) {
      print('❌ SeguimientoService: Error al obtener tareas: $e');
      throw Exception('Error al obtener tareas: $e');
    }
  }

  /// Obtener todas las tareas
  Future<List<Tarea>> obtenerTareas(String token, {int? seguimientoId}) async {
    try {
      String url = '/seguimiento/tareas/';
      if (seguimientoId != null) {
        url += '?seguimiento=$seguimientoId';
      }
      
      final response = await apiService.get(url, token: token);

      if (response['success'] == true && response['data'] is List) {
        final List<dynamic> data = response['data'];
        return data.map<Tarea>((json) => Tarea.fromJson(json)).toList();
      } else {
        throw Exception('Formato de respuesta inválido para tareas');
      }
    } catch (e) {
      print('❌ SeguimientoService: Error al obtener tareas: $e');
      throw Exception('Error al obtener tareas: $e');
    }
  }

  // ========================= PARTICIPACIONES =========================

  /// Obtener participaciones por seguimiento
  Future<List<Participacion>> obtenerParticipacionesPorSeguimiento(int seguimientoId, String token) async {
    try {
      print('🗣️ SeguimientoService: Obteniendo participaciones del seguimiento $seguimientoId');
      
      final response = await apiService.get(
        '/seguimiento/participaciones/?seguimiento=$seguimientoId',
        token: token,
      );

      if (response['success'] == true && response['data'] is List) {
        final List<dynamic> data = response['data'];
        print('🗣️ SeguimientoService: ${data.length} participaciones encontradas');
        
        return data.map<Participacion>((json) => Participacion.fromJson(json)).toList();
      } else {
        throw Exception('Formato de respuesta inválido para participaciones');
      }
    } catch (e) {
      print('❌ SeguimientoService: Error al obtener participaciones: $e');
      throw Exception('Error al obtener participaciones: $e');
    }
  }

  // ========================= ASISTENCIAS =========================

  /// Obtener asistencias por seguimiento
  Future<List<Asistencia>> obtenerAsistenciasPorSeguimiento(int seguimientoId, String token) async {
    try {
      print('✅ SeguimientoService: Obteniendo asistencias del seguimiento $seguimientoId');
      
      final response = await apiService.get(
        '/seguimiento/asistencias/?seguimiento=$seguimientoId',
        token: token,
      );

      if (response['success'] == true && response['data'] is List) {
        final List<dynamic> data = response['data'];
        print('✅ SeguimientoService: ${data.length} asistencias encontradas');
        
        return data.map<Asistencia>((json) => Asistencia.fromJson(json)).toList();
      } else {
        throw Exception('Formato de respuesta inválido para asistencias');
      }
    } catch (e) {
      print('❌ SeguimientoService: Error al obtener asistencias: $e');
      throw Exception('Error al obtener asistencias: $e');
    }
  }

  // ========================= EXÁMENES =========================

  /// Obtener exámenes por seguimiento
  Future<List<Examen>> obtenerExamenesPorSeguimiento(int seguimientoId, String token) async {
    try {
      print('📋 SeguimientoService: Obteniendo exámenes del seguimiento $seguimientoId');
      
      final response = await apiService.get(
        '/seguimiento/examenes/?seguimiento=$seguimientoId',
        token: token,
      );

      if (response['success'] == true && response['data'] is List) {
        final List<dynamic> data = response['data'];
        print('📋 SeguimientoService: ${data.length} exámenes encontrados');
        
        return data.map<Examen>((json) => Examen.fromJson(json)).toList();
      } else {
        throw Exception('Formato de respuesta inválido para exámenes');
      }
    } catch (e) {
      print('❌ SeguimientoService: Error al obtener exámenes: $e');
      throw Exception('Error al obtener exámenes: $e');
    }
  }

  /// Obtener tipos de examen disponibles
  Future<List<TipoExamen>> obtenerTiposExamen(String token) async {
    try {
      print('📋 SeguimientoService: Obteniendo tipos de examen');
      
      final response = await apiService.get(
        '/seguimiento/tipos-examen/',
        token: token,
      );

      if (response['success'] == true && response['data'] is List) {
        final List<dynamic> data = response['data'];
        print('📋 SeguimientoService: ${data.length} tipos de examen encontrados');
        
        return data.map<TipoExamen>((json) => TipoExamen.fromJson(json)).toList();
      } else {
        throw Exception('Formato de respuesta inválido para tipos de examen');
      }
    } catch (e) {
      print('❌ SeguimientoService: Error al obtener tipos de examen: $e');
      throw Exception('Error al obtener tipos de examen: $e');
    }
  }

  // ========================= RESUMEN ESTUDIANTE =========================

  /// Obtener resumen completo de un estudiante
  Future<Map<String, dynamic>> obtenerResumenEstudiante(int estudianteId, String token) async {
    try {
      print('📊 SeguimientoService: Obteniendo resumen del estudiante $estudianteId');
      
      final response = await apiService.get(
        '/seguimiento/resumen-estudiante/$estudianteId/',
        token: token,
      );

      if (response['success'] == true && response['data'] != null) {
        print('📊 SeguimientoService: Resumen obtenido exitosamente');
        return response['data'];
      } else {
        throw Exception('Formato de respuesta inválido para resumen');
      }
    } catch (e) {
      print('❌ SeguimientoService: Error al obtener resumen: $e');
      throw Exception('Error al obtener resumen del estudiante: $e');
    }
  }

  // ========================= UTILIDADES =========================

  /// Convertir lista de seguimientos detallados a materias del estudiante
  List<EstudianteMateria> convertirAEstudianteMaterias(
    List<SeguimientoDetallado> seguimientos,
    List<Seguimiento> seguimientosBasicos,
  ) {
    return seguimientos.map((seguimientoDetallado) {
      // Buscar el seguimiento básico correspondiente para obtener los totales
      final seguimientoBasico = seguimientosBasicos.firstWhere(
        (s) => s.id == seguimientoDetallado.id,
        orElse: () => Seguimiento(
          id: seguimientoDetallado.id,
          materiaCursoId: 0,
          trimestreId: 0,
          estudianteId: 0,
          notaTrimestral: seguimientoDetallado.notaTrimestral,
          totalAsistencias: 0,
          totalTareas: 0,
          totalParticipaciones: 0,
          totalExamenes: 0,
        ),
      );

      return EstudianteMateria(
        seguimientoId: seguimientoDetallado.id,
        materiaNombre: seguimientoDetallado.materiaNombre,
        cursoNombre: seguimientoDetallado.cursoNombre,
        trimestreNombre: seguimientoDetallado.trimestreNombre,
        docenteCompleto: seguimientoDetallado.docenteCompleto,
        notaTrimestral: seguimientoDetallado.notaTrimestral,
        totalTareas: seguimientoBasico.totalTareas,
        totalParticipaciones: seguimientoBasico.totalParticipaciones,
        totalAsistencias: seguimientoBasico.totalAsistencias,
        totalExamenes: seguimientoBasico.totalExamenes,
      );
    }).toList();
  }

  /// Obtener materias del estudiante con información completa
  Future<List<EstudianteMateria>> obtenerMateriasCompletasEstudiante(int estudianteId, String token) async {
    try {
      print('📚 SeguimientoService: Obteniendo materias completas del estudiante $estudianteId');
      
      // Obtener seguimientos básicos del estudiante usando el endpoint correcto
      final response = await apiService.get('/seguimiento/seguimientos/?estudiante=$estudianteId', token: token);
      
      print('🔍 SeguimientoService: Respuesta completa: $response');
      
      if (response['success'] != true || response['data'] is! List) {
        print('❌ SeguimientoService: Formato de respuesta inválido');
        return [];
      }
      
      final List<dynamic> data = response['data'];
      print('📚 SeguimientoService: ${data.length} seguimientos encontrados');
      
      if (data.isEmpty) {
        print('ℹ️ SeguimientoService: No hay seguimientos para el estudiante $estudianteId');
        return [];
      }
      
      // Convertir cada seguimiento básico a EstudianteMateria
      List<EstudianteMateria> materias = [];
      
      for (final item in data) {
        try {
          print('🔍 SeguimientoService: Procesando seguimiento: $item');
          
          // Crear EstudianteMateria directamente con datos básicos
          // Nota: Usaremos IDs como nombres temporalmente hasta conseguir los nombres reales
          final materia = EstudianteMateria(
            seguimientoId: item['id'] ?? 0,
            materiaNombre: 'Materia ${item['materia_curso'] ?? 'N/A'}', // Temporal
            cursoNombre: 'Curso ${item['materia_curso'] ?? 'N/A'}', // Temporal  
            trimestreNombre: 'Trimestre ${item['trimestre'] ?? 'N/A'}', // Temporal
            docenteCompleto: 'Docente N/A', // Temporal
            notaTrimestral: (item['nota_trimestral'] ?? 0.0).toDouble(),
            totalTareas: item['total_tareas'] ?? 0,
            totalParticipaciones: item['total_participaciones'] ?? 0,
            totalAsistencias: item['total_asistencias'] ?? 0,
            totalExamenes: item['total_examenes'] ?? 0,
          );
          
          materias.add(materia);
          print('✅ SeguimientoService: Materia agregada: ${materia.materiaNombre}');
          
        } catch (e) {
          print('❌ SeguimientoService: Error al procesar seguimiento: $e');
          print('❌ SeguimientoService: Item problemático: $item');
        }
      }
      
      print('🎉 SeguimientoService: ${materias.length} materias procesadas exitosamente');
      return materias;
      
    } catch (e) {
      print('❌ SeguimientoService: Error al obtener materias completas: $e');
      throw Exception('Error al obtener materias completas del estudiante: $e');
    }
  }
} 