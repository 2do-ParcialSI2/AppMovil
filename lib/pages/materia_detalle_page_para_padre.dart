import 'package:flutter/material.dart';
import '../models/seguimiento_models.dart';
import '../services/seguimiento_service.dart';
import '../services/auth_service.dart';
import '../pages/trimestre_detalle_page_para_padre.dart';

class MateriaDetallePageParaPadre extends StatefulWidget {
  final EstudianteMateria materia;
  final Map<String, dynamic> estudiante;

  const MateriaDetallePageParaPadre({
    super.key,
    required this.materia,
    required this.estudiante,
  });

  @override
  State<MateriaDetallePageParaPadre> createState() => _MateriaDetallePageParaPadreState();
}

class _MateriaDetallePageParaPadreState extends State<MateriaDetallePageParaPadre> {
  List<SeguimientoDetallado> _seguimientos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarSeguimientos();
  }

  Future<void> _cargarSeguimientos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await AuthService().getAccessToken();
      if (token == null) {
        throw Exception('Token no disponible');
      }

      print('🔍 MateriaDetalle (Padre): Cargando para estudiante ${widget.estudiante['id']}');
      print('📚 Materia: ${widget.materia.materiaNombre}');

      final estudianteId = widget.estudiante['id'] as int;

      // Primero intentar usar los seguimientos que ya vienen en la materia
      if (widget.materia.seguimientos != null && widget.materia.seguimientos!.isNotEmpty) {
        print('🔍 MateriaDetalle (Padre): Usando seguimientos ya cargados (${widget.materia.seguimientos!.length})');
        
        // Cargar detalles completos FILTRADOS para cada seguimiento
        List<SeguimientoDetallado> seguimientosDetallados = [];
        
        for (final seguimiento in widget.materia.seguimientos!) {
          print('🔍 Cargando detalles FILTRADOS para seguimiento ${seguimiento.id} - ${seguimiento.trimestreNombre}');
          
          // Usar el método manual que filtra correctamente por trimestre
          final detalles = await SeguimientoService().obtenerDetallesSeguimientoManual(
            seguimiento.id,
            estudianteId,
            seguimiento.materiaNombre,
            seguimiento.trimestreNombre,
            token,
          );
          
          if (detalles != null) {
            seguimientosDetallados.add(detalles);
            print('✅ Detalles FILTRADOS cargados: T:${detalles.tareas?.length ?? 0} P:${detalles.participaciones?.length ?? 0} A:${detalles.asistencias?.length ?? 0} E:${detalles.examenes?.length ?? 0}');
          }
        }
        
        setState(() {
          _seguimientos = seguimientosDetallados;
          _isLoading = false;
        });
        return;
      }

      // Fallback: Obtener seguimientos específicos de esta materia
      final seguimientos = await SeguimientoService().obtenerSeguimientosPorMateria(
        estudianteId,
        widget.materia.materiaNombre,
        token,
      );

      // Cargar detalles FILTRADOS para cada seguimiento
      List<SeguimientoDetallado> seguimientosDetallados = [];
      for (final seguimiento in seguimientos) {
        final detalles = await SeguimientoService().obtenerDetallesSeguimientoManual(
          seguimiento.id,
          estudianteId,
          seguimiento.materiaNombre,
          seguimiento.trimestreNombre,
          token,
        );
        if (detalles != null) {
          seguimientosDetallados.add(detalles);
        }
      }

      setState(() {
        _seguimientos = seguimientosDetallados;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _error = 'Error al cargar seguimientos: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.materia.materiaNombre),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando seguimientos...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarSeguimientos,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header con información de la materia y estudiante
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del estudiante
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.orange[100],
                    child: Text(
                      _getInitials(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.estudiante['first_name']} ${widget.estudiante['last_name']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.estudiante['curso'] != null)
                          Text(
                            'Curso: ${widget.estudiante['curso']['nombre']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Indicador de vista para padre
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.family_restroom, size: 12, color: Colors.orange[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Vista Padre',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Información de la materia
              Text(
                widget.materia.materiaNombre,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Prof. ${widget.materia.docenteCompleto}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.class_, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    widget.materia.cursoNombre,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Lista de trimestres
        Expanded(
          child: _seguimientos.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No hay seguimientos disponibles'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _seguimientos.length + 1, // +1 para el botón de predicción
                  itemBuilder: (context, index) {
                    if (index == _seguimientos.length) {
                      // Botón de predicción para 3er trimestre
                      return _buildPrediccionCard();
                    }
                    
                    final seguimiento = _seguimientos[index];
                    return _buildTrimestreCard(seguimiento, index + 1);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTrimestreCard(SeguimientoDetallado seguimiento, int numeroTrimestre) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        children: [
          // Header del trimestre
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[600],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${numeroTrimestre}° trimestre',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _verDetallesTrimestre(seguimiento),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.orange[700],
                  ),
                  child: const Text('ver detalles'),
                ),
              ],
            ),
          ),
          // Contenido del trimestre
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Estadísticas principales con promedios calculados
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatConPromedio('Tareas', seguimiento.tareas?.length ?? 0, seguimiento.promedioTareas),
                    _buildStatConPromedio('Participación', seguimiento.participaciones?.length ?? 0, seguimiento.promedioParticipaciones),
                    _buildStatConAsistencia('Asistencia', seguimiento.asistencias?.length ?? 0, seguimiento.porcentajeAsistencia),
                    _buildStatConPromedio('exámenes', seguimiento.examenes?.length ?? 0, seguimiento.promedioExamenes),
                  ],
                ),
                const SizedBox(height: 16),
                // Nota trimestral
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Nota Trimestral',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        seguimiento.notaTrimestral.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _getColorForNota(seguimiento.notaTrimestral),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'de 100 puntos',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrediccionCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton(
        onPressed: _predecirTercerTrimestre,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'predecir 3er trimestre',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _predecirTercerTrimestre() async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final token = await AuthService().getAccessToken();
      if (token == null) {
        throw Exception('Token no disponible');
      }

      final estudianteId = widget.estudiante['id'] as int;
      final cursoId = widget.estudiante['curso']['id'] as int;
      
      print('🔮 Predicción (Padre): Buscando materia-curso ID para ${widget.materia.materiaNombre}');
      print('👨‍🎓 Estudiante ID: $estudianteId, Curso ID: $cursoId');
      
      int? materiaCursoIdEncontrado;
      
      // ESTRATEGIA 1: Usar el endpoint específico del curso
      try {
        print('🔍 Obteniendo materias del curso $cursoId...');
        final response = await SeguimientoService().apiService.get('/materias/curso/$cursoId', token: token);
        
        print('📊 DEBUG (Padre) - Respuesta completa del endpoint materias/curso:');
        print('   Success: ${response['success']}');
        print('   Data type: ${response['data'].runtimeType}');
        print('   Data content: ${response['data']}');
        
        if (response['success'] == true && response['data'] is List) {
          final materias = response['data'] as List<dynamic>;
          print('📚 Encontradas ${materias.length} materias en el curso $cursoId');
          
          // Buscar la materia que coincida
          for (final materia in materias) {
            print('🔍 DEBUG (Padre) - Estructura de materia: $materia');
            final materiaNombre = materia['nombre']?.toString() ?? '';
            final materiaId = materia['id'] as int?;
            
            print('🔍 Comparando: "${widget.materia.materiaNombre}" vs "$materiaNombre"');
            print('   Buscado: "${widget.materia.materiaNombre.toLowerCase().trim()}"');
            print('   Encontrado: "${materiaNombre.toLowerCase().trim()}"');
            print('   Son iguales: ${materiaNombre.toLowerCase().trim() == widget.materia.materiaNombre.toLowerCase().trim()}');
            
            if (materiaNombre.toLowerCase().trim() == widget.materia.materiaNombre.toLowerCase().trim()) {
              materiaCursoIdEncontrado = materiaId;
              print('✅ ¡Materia encontrada! ID: $materiaId para "$materiaNombre"');
              break;
            }
          }
          
          if (materiaCursoIdEncontrado == null) {
            print('❌ No se encontró coincidencia exacta. Materias disponibles:');
            for (final materia in materias) {
              print('   - "${materia['nombre']}" (ID: ${materia['id']})');
            }
          }
        } else {
          print('❌ Formato de respuesta inesperado:');
          print('   Success: ${response['success']}');
          print('   Data: ${response['data']}');
        }
      } catch (e) {
        print('❌ Error al obtener materias del curso: $e');
      }
      
      // ESTRATEGIA 2: Si no encontramos en el curso, probar con todas las materias
      if (materiaCursoIdEncontrado == null) {
        try {
          print('🔍 Obteniendo todas las materias...');
          final response = await SeguimientoService().apiService.get('/materias/', token: token);
          
          if (response['success'] == true && response['data'] is List) {
            final materias = response['data'] as List<dynamic>;
            print('📚 Encontradas ${materias.length} materias en total');
            
            // Buscar la materia que coincida
            for (final materia in materias) {
              final materiaNombre = materia['nombre']?.toString() ?? '';
              final materiaId = materia['id'] as int?;
              
              print('🔍 Comparando: "${widget.materia.materiaNombre}" vs "$materiaNombre"');
              
              if (materiaNombre.toLowerCase().trim() == widget.materia.materiaNombre.toLowerCase().trim()) {
                materiaCursoIdEncontrado = materiaId;
                print('✅ ¡Materia encontrada! ID: $materiaId para "$materiaNombre"');
                break;
              }
            }
          }
        } catch (e) {
          print('❌ Error al obtener todas las materias: $e');
        }
      }
      
      // Cerrar el indicador de carga
      Navigator.of(context).pop();

      if (materiaCursoIdEncontrado != null) {
        // Usar el ID encontrado
        print('🎯 Usando ID encontrado: $materiaCursoIdEncontrado');
        final resultado = await SeguimientoService().predecirNota(
          estudianteId, 
          materiaCursoIdEncontrado,
          token
        );

        if (resultado != null && resultado['success'] == true) {
          print('🎉 Predicción exitosa!');
          _mostrarResultadoPrediccion(resultado['data'] ?? resultado['prediccion']);
          return;
        } else {
          throw Exception('La predicción falló. Verifica el backend de Machine Learning.');
        }
      } else {
        throw Exception('No se pudo encontrar el ID de la materia "${widget.materia.materiaNombre}" en el sistema.\n\nVerifica que:\n1. La materia esté registrada correctamente\n2. Esté asignada al curso del estudiante\n3. Los nombres coincidan exactamente');
      }

    } catch (e) {
      // Cerrar el indicador de carga si está abierto
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en la predicción: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 10),
        ),
      );
    }
  }

  void _mostrarResultadoPrediccion(Map<String, dynamic> prediccion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.psychology, color: Colors.orange[600]),
            const SizedBox(width: 8),
            const Flexible(child: Text('Predicción 3er Trimestre')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Nota Predicha',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${prediccion['nota_estimada']?.toStringAsFixed(1) ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _getColorForNota(prediccion['nota_estimada']?.toDouble() ?? 0.0),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'de 100 puntos',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (prediccion['confianza_valor'] != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Confianza:', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text('${prediccion['confianza_valor']?.toStringAsFixed(1) ?? 'N/A'}'),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (prediccion['clasificacion'] != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Clasificación:', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(prediccion['clasificacion']?.toString() ?? 'N/A'),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (prediccion['mensaje'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Text(
                  prediccion['mensaje']?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatConPromedio(String label, int cantidad, double promedio) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          cantidad.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (promedio > 0) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getColorForNota(promedio).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Prom: ${promedio.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 10,
                color: _getColorForNota(promedio),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatConAsistencia(String label, int cantidad, double porcentaje) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          cantidad.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (porcentaje > 0) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getColorForAsistencia(porcentaje).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${porcentaje.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 10,
                color: _getColorForAsistencia(porcentaje),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'S/D',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getColorForNota(double nota) {
    if (nota >= 80) return Colors.green;
    if (nota >= 70) return Colors.orange;
    if (nota >= 60) return Colors.amber;
    return Colors.red;
  }

  Color _getColorForAsistencia(double porcentaje) {
    if (porcentaje >= 90) return Colors.green;
    if (porcentaje >= 80) return Colors.orange;
    if (porcentaje >= 70) return Colors.amber;
    return Colors.red;
  }

  String _getInitials() {
    final firstName = widget.estudiante['first_name']?.toString() ?? '';
    final lastName = widget.estudiante['last_name']?.toString() ?? '';
    
    String initials = '';
    if (firstName.isNotEmpty) initials += firstName[0];
    if (lastName.isNotEmpty) initials += lastName[0];
    
    return initials.isEmpty ? 'E' : initials.toUpperCase();
  }

  void _verDetallesTrimestre(SeguimientoDetallado seguimiento) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrimestreDetallePageParaPadre(
          seguimiento: seguimiento,
          estudiante: widget.estudiante,
        ),
      ),
    );
  }
} 