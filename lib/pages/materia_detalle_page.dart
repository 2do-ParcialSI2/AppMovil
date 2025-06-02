import 'package:flutter/material.dart';
import '../models/seguimiento_models.dart';
import '../services/seguimiento_service.dart';
import '../services/auth_service.dart';
import '../pages/trimestre_detalle_page.dart';

class MateriaDetallePage extends StatefulWidget {
  final EstudianteMateria materia;

  const MateriaDetallePage({super.key, required this.materia});

  @override
  State<MateriaDetallePage> createState() => _MateriaDetallePageState();
}

class _MateriaDetallePageState extends State<MateriaDetallePage> {
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

      // Obtener información del estudiante actual
      final user = await AuthService().getCurrentUser();
      if (user == null) {
        throw Exception('Usuario no disponible');
      }

      print('🔍 MateriaDetallePage: Usuario actual ID: ${user.id} (${user.email})');

      // Obtener el estudiante_id real que corresponde a este email
      final estudiantesResponse = await SeguimientoService().apiService.get('/estudiantes/', token: token);
      
      if (estudiantesResponse['success'] != true || estudiantesResponse['data'] is! List) {
        throw Exception('Error al obtener lista de estudiantes');
      }

      final estudiantes = estudiantesResponse['data'] as List<dynamic>;
      final estudianteData = estudiantes.firstWhere(
        (estudiante) => estudiante['email'] == user.email,
        orElse: () => null,
      );
      
      if (estudianteData == null) {
        throw Exception('No se encontró información del estudiante para ${user.email}');
      }
      
      final estudianteId = estudianteData['id'] as int;
      print('🔍 MateriaDetallePage: Estudiante ID encontrado: $estudianteId para email ${user.email}');

      // Primero intentar usar los seguimientos que ya vienen en la materia
      if (widget.materia.seguimientos != null && widget.materia.seguimientos!.isNotEmpty) {
        print('🔍 MateriaDetallePage: Usando seguimientos ya cargados (${widget.materia.seguimientos!.length})');
        
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
        backgroundColor: Colors.blue[700],
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
        // Header con información de la materia
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        children: [
          // Header del trimestre
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[600],
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
                    backgroundColor: Colors.blue[700],
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
        onPressed: () {
          // TODO: Implementar predicción de 3er trimestre
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Función de predicción en desarrollo'),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
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

  Widget _buildStat(String label, int value) {
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
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNotaStat(String label, double value) {
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
          value.toStringAsFixed(0),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _verDetallesTrimestre(SeguimientoDetallado seguimiento) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrimestreDetallePage(seguimiento: seguimiento),
      ),
    );
  }
} 