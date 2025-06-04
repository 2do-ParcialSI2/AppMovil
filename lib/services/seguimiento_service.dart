import '../models/seguimiento_models.dart';
import '../services/api_service.dart';

class SeguimientoService {
  final ApiService apiService = ApiService();

  // ========================= SEGUIMIENTOS =========================

  /// Obtener todas las materias de un estudiante con sus seguimientos
  Future<List<EstudianteMateria>> obtenerMateriasEstudiante(int estudianteId, String token) async {
    try {
      print('🔍 SeguimientoService: Obteniendo materias del estudiante $estudianteId');
      
      // Obtener seguimientos usando el endpoint específico para el estudiante
      final seguimientosResponse = await apiService.get(
        '/seguimiento/seguimientos/por_estudiante/?estudiante_id=$estudianteId',
        token: token,
      );

      print('🔍 SeguimientoService: Respuesta seguimientos básicos: $seguimientosResponse');

      if (seguimientosResponse['success'] != true || seguimientosResponse['data'] is! List) {
        print('❌ Error obteniendo seguimientos del estudiante');
        return [];
      }

      final List<dynamic> seguimientosData = seguimientosResponse['data'];
      print('📊 SeguimientoService: ${seguimientosData.length} seguimientos encontrados');

      // Convertir seguimientos básicos a detallados
      List<SeguimientoDetallado> seguimientosDetallados = [];
      for (final seguimientoData in seguimientosData) {
        try {
          final seguimiento = SeguimientoDetallado.fromJson(seguimientoData);
          seguimientosDetallados.add(seguimiento);
          print('✅ Seguimiento procesado: ${seguimiento.materiaNombre} - ${seguimiento.trimestreNombre} - ${seguimiento.estudianteNombre} ${seguimiento.estudianteApellido}');
        } catch (e) {
          print('❌ Error procesando seguimiento: $e');
          continue;
        }
      }

      return _procesarSeguimientosDetallados(seguimientosDetallados);
      
    } catch (e) {
      print('❌ SeguimientoService Error: $e');
      return [];
    }
  }

  /// Método auxiliar para procesar seguimientos detallados
  List<EstudianteMateria> _procesarSeguimientosDetallados(dynamic seguimientosData) {
    final List<dynamic> dataList = seguimientosData is List ? seguimientosData : [];
    print('📊 SeguimientoService: Procesando ${dataList.length} seguimientos');

    // Agrupar seguimientos por materia para crear materias únicas
    Map<String, List<SeguimientoDetallado>> materiasSeguimientos = {};
    
    for (final seguimientoData in dataList) {
      try {
        final seguimiento = seguimientoData is SeguimientoDetallado 
            ? seguimientoData 
            : SeguimientoDetallado.fromJson(seguimientoData);
        final materiaNombre = seguimiento.materiaNombre;
        
        if (materiaNombre.isNotEmpty) {
          if (materiasSeguimientos[materiaNombre] == null) {
            materiasSeguimientos[materiaNombre] = [];
          }
          materiasSeguimientos[materiaNombre]!.add(seguimiento);
          
          print('📋 Seguimiento procesado: $materiaNombre - ${seguimiento.trimestreNombre} - Docente: ${seguimiento.docenteCompleto}');
        } else {
          print('⚠️ Seguimiento sin nombre de materia: $seguimientoData');
        }
        
      } catch (e) {
        print('❌ Error procesando seguimiento: $e');
        print('❌ Datos problemáticos: $seguimientoData');
        continue;
      }
    }

    // Convertir a EstudianteMateria con información completa
    List<EstudianteMateria> materias = [];
    
    for (final entry in materiasSeguimientos.entries) {
      final materiaNombre = entry.key;
      final seguimientos = entry.value;
      
      if (seguimientos.isNotEmpty) {
        // Usar información del primer seguimiento como base
        final primerSeguimiento = seguimientos.first;
        
        // Calcular totales sumando todos los trimestres
        int totalTareas = 0;
        int totalParticipaciones = 0;
        int totalAsistencias = 0;
        int totalExamenes = 0;
        
        for (final seg in seguimientos) {
          totalTareas += seg.tareas?.length ?? 0;
          totalParticipaciones += seg.participaciones?.length ?? 0;
          totalAsistencias += seg.asistencias?.length ?? 0;
          totalExamenes += seg.examenes?.length ?? 0;
        }
        
        double promedioGeneral = 0.0;
        if (seguimientos.isNotEmpty) {
          final sumaNotas = seguimientos.fold(0.0, (sum, s) => sum + s.notaTrimestral);
          promedioGeneral = sumaNotas / seguimientos.length;
        }
        
        final materia = EstudianteMateria(
          seguimientoId: primerSeguimiento.id,
          materiaId: 0, // No disponible en este endpoint
          materiaCursoId: 0, // Podríamos obtenerlo del seguimiento si está disponible
          materiaNombre: materiaNombre,
          descripcion: '', // No disponible en este endpoint
          docenteCompleto: primerSeguimiento.docenteCompleto,
          cursoNombre: primerSeguimiento.cursoNombre,
          trimestreNombre: '${seguimientos.length} trimestres',
          notaTrimestral: promedioGeneral,
          seguimientos: seguimientos,
          totalTareas: totalTareas,
          totalParticipaciones: totalParticipaciones,
          totalAsistencias: totalAsistencias,
          totalExamenes: totalExamenes,
        );
        
        materias.add(materia);
        print('✅ Materia procesada: $materiaNombre');
        print('   Docente: ${primerSeguimiento.docenteCompleto}');
        print('   Trimestres: ${seguimientos.length}');
        print('   Totales: T:$totalTareas P:$totalParticipaciones A:$totalAsistencias E:$totalExamenes');
      }
    }

    print('✅ SeguimientoService: ${materias.length} materias únicas procesadas con información completa');
    return materias;
  }

  /// Obtener materias por curso (alternativa usando endpoint de curso)
  Future<List<EstudianteMateria>> obtenerMateriasPorCurso(int cursoId, String token) async {
    try {
      print('📚 SeguimientoService: Obteniendo materias del curso $cursoId');
      
      // Usar el endpoint que incluye información del docente y horario
      final response = await apiService.get(
        '/cursos/$cursoId/asignar-materias/$cursoId/',
        token: token,
      );

      print('🔍 SeguimientoService: Respuesta materias curso: $response');

      if (response['success'] == true && response['data'] is List) {
        final List<dynamic> materiasData = response['data'];
        print('📚 SeguimientoService: ${materiasData.length} materias del curso encontradas');
        
        List<EstudianteMateria> materias = [];
        
        for (final materiaData in materiasData) {
          try {
            // Aquí el backend debería devolver información completa de la materia con docente
            final materia = EstudianteMateria(
              seguimientoId: materiaData['seguimiento_id'],
              materiaId: materiaData['materia_id'],
              materiaCursoId: materiaData['materia_curso_id'],
              materiaNombre: materiaData['materia_nombre'],
              descripcion: materiaData['descripcion'],
              docenteCompleto: materiaData['docente_completo'],
              cursoNombre: materiaData['curso_nombre'],
              trimestreNombre: materiaData['trimestre_nombre'],
              notaTrimestral: materiaData['nota_trimestral'].toDouble(),
              seguimientos: [],
              totalTareas: materiaData['total_tareas'],
              totalParticipaciones: materiaData['total_participaciones'],
              totalAsistencias: materiaData['total_asistencias'],
              totalExamenes: materiaData['total_examenes'],
            );
            materias.add(materia);
            print('✅ Materia del curso procesada: ${materia.materiaNombre}');
          } catch (e) {
            print('❌ Error procesando materia del curso: $e');
            continue;
          }
        }
        
        return materias;
      } else {
        throw Exception('Formato de respuesta inválido para materias del curso');
      }
    } catch (e) {
      print('❌ SeguimientoService: Error al obtener materias del curso: $e');
      return [];
    }
  }

  /// Obtener seguimiento específico por ID
  Future<Seguimiento> obtenerSeguimiento(int seguimientoId, String token) async {
    try {
      print('📊 SeguimientoService: Obteniendo seguimiento $seguimientoId');
      
      final response = await apiService.get(
        '/seguimiento/seguimientos/$seguimientoId/',
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
        '/seguimiento/tareas/?seguimiento=$seguimientoId',
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

  /// Obtener seguimientos detallados de una materia específica por trimestre
  Future<List<SeguimientoDetallado>> obtenerSeguimientosPorMateria(
    int estudianteId, 
    String materiaNombre, 
    String token
  ) async {
    try {
      print('🔍 Obteniendo seguimientos de estudiante $estudianteId, materia $materiaNombre');
      
      // Obtener todos los seguimientos del estudiante usando endpoint específico
      final response = await apiService.get(
        '/seguimiento/seguimientos/por_estudiante/?estudiante_id=$estudianteId', 
        token: token
      );
      
      if (response['success'] != true || response['data'] is! List) {
        print('❌ Error obteniendo seguimientos detallados: ${response['message'] ?? 'Respuesta inválida'}');
        return [];
      }
      
      final List<dynamic> seguimientosData = response['data'];
      print('📊 Total de seguimientos recibidos del backend: ${seguimientosData.length}');
      
      // Filtrar solo los seguimientos de esta materia específica
      List<SeguimientoDetallado> seguimientos = [];
      
      for (final seguimientoData in seguimientosData) {
        try {
          final seguimiento = SeguimientoDetallado.fromJson(seguimientoData);
          
          print('📋 Procesando seguimiento: ${seguimiento.materiaNombre} - ${seguimiento.trimestreNombre}');
          
          // Solo filtrar por materia
          if (seguimiento.materiaNombre.toLowerCase().trim() == materiaNombre.toLowerCase().trim()) {
            seguimientos.add(seguimiento);
            print('✅ Seguimiento ACEPTADO: ${seguimiento.trimestreNombre} - Nota: ${seguimiento.notaTrimestral}');
          }
          
        } catch (e) {
          print('❌ Error procesando seguimiento individual: $e');
          continue;
        }
      }
      
      // Ordenar por trimestre
      seguimientos.sort((a, b) => a.trimestreNombre.compareTo(b.trimestreNombre));
      
      print('✅ ${seguimientos.length} seguimientos encontrados para la materia $materiaNombre del estudiante $estudianteId');
      return seguimientos;
      
    } catch (e) {
      print('❌ Error obteniendo seguimientos por materia: $e');
      return [];
    }
  }

  /// Obtener detalles de un seguimiento específico usando filtros específicos
  Future<SeguimientoDetallado?> obtenerDetallesSeguimientoConFiltros(
    int seguimientoId, 
    int trimestreId, 
    int estudianteId, 
    String token
  ) async {
    try {
      print('🔍 Obteniendo detalles con filtros: seguimiento=$seguimientoId, trimestre=$trimestreId, estudiante=$estudianteId');
      
      // Usar el endpoint detallado con filtros específicos
      final response = await apiService.get(
        '/seguimiento/seguimientos/detallado/?trimestre=$trimestreId&estudiante=$estudianteId',
        token: token,
      );
      
      if (response['success'] != true || response['data'] is! List) {
        print('❌ Error obteniendo seguimientos detallados con filtros');
        return null;
      }
      
      final List<dynamic> seguimientosData = response['data'];
      print('📊 Seguimientos con filtros: ${seguimientosData.length}');
      
      // Buscar el seguimiento específico en los resultados
      Map<String, dynamic>? seguimientoEspecifico;
      for (final seg in seguimientosData) {
        if (seg['id'] == seguimientoId) {
          seguimientoEspecifico = seg;
          break;
        }
      }
      
      if (seguimientoEspecifico == null) {
        print('❌ No se encontró el seguimiento $seguimientoId en los resultados filtrados');
        return null;
      }
      
      print('✅ Seguimiento encontrado con filtros: ${seguimientoEspecifico['materia_nombre']} - ${seguimientoEspecifico['trimestre_nombre']}');
      
      // Obtener datos específicos para este seguimiento
      final futures = await Future.wait([
        obtenerTareasPorSeguimiento(seguimientoId, token),
        obtenerParticipacionesPorSeguimiento(seguimientoId, token),
        obtenerAsistenciasPorSeguimiento(seguimientoId, token),
        obtenerExamenesPorSeguimiento(seguimientoId, token),
      ]);
      
      final tareas = futures[0] as List<Tarea>;
      final participaciones = futures[1] as List<Participacion>;
      final asistencias = futures[2] as List<Asistencia>;
      final examenes = futures[3] as List<Examen>;
      
      print('📊 Datos específicos cargados:');
      print('   Tareas: ${tareas.length}');
      print('   Participaciones: ${participaciones.length}');
      print('   Asistencias: ${asistencias.length}');
      print('   Exámenes: ${examenes.length}');
      
      return SeguimientoDetallado(
        id: seguimientoId,
        estudianteNombre: seguimientoEspecifico['estudiante_nombre'] ?? '',
        estudianteApellido: seguimientoEspecifico['estudiante_apellido'] ?? '',
        materiaNombre: seguimientoEspecifico['materia_nombre'] ?? '',
        cursoNombre: seguimientoEspecifico['curso_nombre'] ?? '',
        trimestreNombre: seguimientoEspecifico['trimestre_nombre'] ?? '',
        docenteNombre: seguimientoEspecifico['docente_nombre'] ?? '',
        docenteApellido: seguimientoEspecifico['docente_apellido'] ?? '',
        notaTrimestral: (seguimientoEspecifico['nota_trimestral'] ?? 0.0).toDouble(),
        tareas: tareas,
        participaciones: participaciones,
        asistencias: asistencias,
        examenes: examenes,
      );
      
    } catch (e) {
      print('❌ Error obteniendo detalles con filtros: $e');
      return null;
    }
  }

  /// Obtener detalles de un seguimiento específico (tareas, participaciones, etc.)
  Future<SeguimientoDetallado?> obtenerDetallesSeguimiento(int seguimientoId, String token) async {
    try {
      print('🔍 Obteniendo detalles del seguimiento $seguimientoId');
      
      // Primero intentar obtener información básica del seguimiento específico
      final seguimientoResponse = await apiService.get(
        '/seguimiento/seguimientos/$seguimientoId/',
        token: token,
      );
      
      if (seguimientoResponse['success'] != true) {
        print('❌ Error obteniendo seguimiento básico');
        return null;
      }
      
      final seguimientoData = seguimientoResponse['data'];
      print('📊 Datos del seguimiento específico: ${seguimientoData}');
      
      // Verificar si tenemos los IDs necesarios para usar filtros más específicos
      final trimestreId = seguimientoData['trimestre']?.toString();
      final estudianteId = seguimientoData['estudiante']?.toString();
      
      if (trimestreId != null && estudianteId != null) {
        print('🔍 Intentando usar filtros específicos...');
        final resultadoConFiltros = await obtenerDetallesSeguimientoConFiltros(
          seguimientoId,
          int.parse(trimestreId),
          int.parse(estudianteId),
          token,
        );
        
        if (resultadoConFiltros != null) {
          return resultadoConFiltros;
        }
      }
      
      // Fallback: usar el método original
      print('🔍 Usando método original como fallback...');
      
      // Obtener tareas, participaciones, asistencias y exámenes en paralelo
      print('🔍 Obteniendo datos específicos para seguimiento $seguimientoId...');
      final futures = await Future.wait([
        obtenerTareasPorSeguimiento(seguimientoId, token),
        obtenerParticipacionesPorSeguimiento(seguimientoId, token),
        obtenerAsistenciasPorSeguimiento(seguimientoId, token),
        obtenerExamenesPorSeguimiento(seguimientoId, token),
      ]);
      
      final tareas = futures[0] as List<Tarea>;
      final participaciones = futures[1] as List<Participacion>;
      final asistencias = futures[2] as List<Asistencia>;
      final examenes = futures[3] as List<Examen>;
      
      print('📊 Datos cargados para seguimiento $seguimientoId:');
      print('   Tareas: ${tareas.length}');
      print('   Participaciones: ${participaciones.length}');
      print('   Asistencias: ${asistencias.length}');
      print('   Exámenes: ${examenes.length}');
      
      // Crear seguimiento detallado con todos los datos
      return SeguimientoDetallado(
        id: seguimientoId,
        estudianteNombre: seguimientoData['estudiante_nombre'] ?? '',
        estudianteApellido: seguimientoData['estudiante_apellido'] ?? '',
        materiaNombre: seguimientoData['materia_nombre'] ?? '',
        cursoNombre: seguimientoData['curso_nombre'] ?? '',
        trimestreNombre: seguimientoData['trimestre_nombre'] ?? '',
        docenteNombre: seguimientoData['docente_nombre'] ?? '',
        docenteApellido: seguimientoData['docente_apellido'] ?? '',
        notaTrimestral: (seguimientoData['nota_trimestral'] ?? 0.0).toDouble(),
        tareas: tareas,
        participaciones: participaciones,
        asistencias: asistencias,
        examenes: examenes,
      );
      
    } catch (e) {
      print('❌ Error obteniendo detalles del seguimiento: $e');
      return null;
    }
  }

  /// Obtener todos los trimestres disponibles
  Future<List<Map<String, dynamic>>> obtenerTrimestres(String token) async {
    try {
      final response = await apiService.get('/cursos/trimestres/', token: token);
      
      if (response['success'] == true && response['data'] is List) {
        return List<Map<String, dynamic>>.from(response['data']);
      }
      
      return [];
    } catch (e) {
      print('❌ Error obteniendo trimestres: $e');
      return [];
    }
  }

  /// Método para predicción de notas usando Machine Learning
  Future<Map<String, dynamic>?> predecirNota(int estudianteId, int materiaCursoId, String token) async {
    try {
      print('🔮 Prediciendo nota para estudiante $estudianteId, materia-curso $materiaCursoId');
      
      final response = await apiService.post(
        '/seguimiento/seguimientos/predecir-nota/$estudianteId/$materiaCursoId/',
        body: {},
        token: token,
      );
      
      if (response['success'] == true) {
        return response;
      }
      
      return null;
    } catch (e) {
      print('❌ Error en predicción: $e');
      return null;
    }
  }

  /// Método alternativo: obtener detalles filtrando manualmente desde todos los seguimientos
  Future<SeguimientoDetallado?> obtenerDetallesSeguimientoManual(
    int seguimientoId, 
    int estudianteId,
    String materiaNombre,
    String trimestreNombre,
    String token
  ) async {
    try {
      print('🔍 Método manual: Obteniendo seguimientos del estudiante $estudianteId');
      
      // Obtener todos los seguimientos del estudiante
      final response = await apiService.get(
        '/seguimiento/seguimientos/por_estudiante/?estudiante_id=$estudianteId',
        token: token,
      );
      
      if (response['success'] != true || response['data'] is! List) {
        print('❌ Error obteniendo seguimientos del estudiante');
        return null;
      }
      
      final List<dynamic> seguimientosData = response['data'];
      print('📊 Total seguimientos del estudiante: ${seguimientosData.length}');
      
      // Buscar el seguimiento específico
      Map<String, dynamic>? seguimientoEspecifico;
      for (final seg in seguimientosData) {
        if (seg['id'] == seguimientoId && 
            seg['materia_nombre']?.toString().toLowerCase() == materiaNombre.toLowerCase() &&
            seg['trimestre_nombre']?.toString().toLowerCase() == trimestreNombre.toLowerCase()) {
          seguimientoEspecifico = seg;
          break;
        }
      }
      
      if (seguimientoEspecifico == null) {
        print('❌ No se encontró el seguimiento específico $seguimientoId');
        print('   Buscado: $materiaNombre - $trimestreNombre');
        // Log todos los seguimientos disponibles para debug
        for (final seg in seguimientosData) {
          print('   Disponible: ${seg['materia_nombre']} - ${seg['trimestre_nombre']} (ID: ${seg['id']})');
        }
        return null;
      }
      
      print('✅ Seguimiento específico encontrado: ${seguimientoEspecifico['materia_nombre']} - ${seguimientoEspecifico['trimestre_nombre']}');
      
      // Obtener datos específicos para este seguimiento usando filtros más específicos
      print('🔍 Obteniendo datos específicos solo para seguimiento $seguimientoId...');
      
      // VERIFICAR: Los endpoints de tareas, participaciones, etc. deben filtrar solo por este seguimiento
      final futures = await Future.wait([
        obtenerTareasPorSeguimiento(seguimientoId, token),
        obtenerParticipacionesPorSeguimiento(seguimientoId, token),
        obtenerAsistenciasPorSeguimiento(seguimientoId, token),
        obtenerExamenesPorSeguimiento(seguimientoId, token),
      ]);
      
      final tareas = futures[0] as List<Tarea>;
      final participaciones = futures[1] as List<Participacion>;
      final asistencias = futures[2] as List<Asistencia>;
      final examenes = futures[3] as List<Examen>;
      
      print('📊 Datos específicos del seguimiento $seguimientoId:');
      print('   Tareas: ${tareas.length}');
      print('   Participaciones: ${participaciones.length}');
      print('   Asistencias: ${asistencias.length}');
      print('   Exámenes: ${examenes.length}');
      
      // VALIDACIÓN ADICIONAL: Verificar que las tareas/participaciones correspondan al seguimiento
      final tareasValidas = tareas.where((t) => t.seguimientoId == seguimientoId).toList();
      final participacionesValidas = participaciones.where((p) => p.seguimientoId == seguimientoId).toList();
      final asistenciasValidas = asistencias.where((a) => a.seguimientoId == seguimientoId).toList();
      final examenesValidos = examenes.where((e) => e.seguimientoId == seguimientoId).toList();
      
      if (tareasValidas.length != tareas.length || 
          participacionesValidas.length != participaciones.length ||
          asistenciasValidas.length != asistencias.length ||
          examenesValidos.length != examenes.length) {
        print('⚠️ FILTRADO ADICIONAL: Datos no corresponden al seguimiento específico');
        print('   Tareas: ${tareas.length} -> ${tareasValidas.length}');
        print('   Participaciones: ${participaciones.length} -> ${participacionesValidas.length}');
        print('   Asistencias: ${asistencias.length} -> ${asistenciasValidas.length}');
        print('   Exámenes: ${examenes.length} -> ${examenesValidos.length}');
      }
      
      return SeguimientoDetallado(
        id: seguimientoId,
        estudianteNombre: seguimientoEspecifico['estudiante_nombre'] ?? '',
        estudianteApellido: seguimientoEspecifico['estudiante_apellido'] ?? '',
        materiaNombre: seguimientoEspecifico['materia_nombre'] ?? '',
        cursoNombre: seguimientoEspecifico['curso_nombre'] ?? '',
        trimestreNombre: seguimientoEspecifico['trimestre_nombre'] ?? '',
        docenteNombre: seguimientoEspecifico['docente_nombre'] ?? '',
        docenteApellido: seguimientoEspecifico['docente_apellido'] ?? '',
        notaTrimestral: (seguimientoEspecifico['nota_trimestral'] ?? 0.0).toDouble(),
        tareas: tareasValidas,  // Usar las listas filtradas
        participaciones: participacionesValidas,
        asistencias: asistenciasValidas,
        examenes: examenesValidos,
      );
      
    } catch (e) {
      print('❌ Error en método manual: $e');
      return null;
    }
  }
} 