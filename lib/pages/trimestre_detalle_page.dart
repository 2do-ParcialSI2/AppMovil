import 'package:flutter/material.dart';
import '../models/seguimiento_models.dart';
import '../services/seguimiento_service.dart';
import '../services/auth_service.dart';

class TrimestreDetallePage extends StatefulWidget {
  final SeguimientoDetallado seguimiento;

  const TrimestreDetallePage({super.key, required this.seguimiento});

  @override
  State<TrimestreDetallePage> createState() => _TrimestreDetallePageState();
}

class _TrimestreDetallePageState extends State<TrimestreDetallePage> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;

  // Datos específicos del seguimiento
  SeguimientoDetallado? _seguimientoDetallado;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _cargarDetallesSeguimiento();
  }

  Future<void> _cargarDetallesSeguimiento() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await AuthService().getAccessToken();
      if (token == null) {
        throw Exception('Token no disponible');
      }

      // Obtener información del estudiante actual para usar en el filtro manual
      final user = await AuthService().getCurrentUser();
      if (user == null) {
        throw Exception('Usuario no disponible');
      }

      // Buscar el estudiante por email
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
        throw Exception('No se encontró información del estudiante');
      }
      
      final estudianteId = estudianteData['id'] as int;
      
      print('🔍 TrimestreDetalle: Cargando detalles para:');
      print('   Seguimiento ID: ${widget.seguimiento.id}');
      print('   Estudiante ID: $estudianteId');
      print('   Materia: ${widget.seguimiento.materiaNombre}');
      print('   Trimestre: ${widget.seguimiento.trimestreNombre}');

      // Usar el método manual que filtra más específicamente
      final detalles = await SeguimientoService().obtenerDetallesSeguimientoManual(
        widget.seguimiento.id,
        estudianteId,
        widget.seguimiento.materiaNombre,
        widget.seguimiento.trimestreNombre,
        token,
      );

      if (detalles != null) {
        setState(() {
          _seguimientoDetallado = detalles;
          _isLoading = false;
        });
        
        print('✅ TrimestreDetalle: Detalles cargados correctamente');
        print('   Tareas: ${detalles.tareas?.length ?? 0}');
        print('   Participaciones: ${detalles.participaciones?.length ?? 0}');
        print('   Asistencias: ${detalles.asistencias?.length ?? 0}');
        print('   Exámenes: ${detalles.examenes?.length ?? 0}');
      } else {
        throw Exception('No se pudieron cargar los detalles del seguimiento');
      }
    } catch (e) {
      setState(() {
        _error = 'Error al cargar detalles: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.seguimiento.materiaNombre,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.seguimiento.trimestreNombre,
              style: TextStyle(fontSize: 14, color: Colors.grey[300]),
            ),
          ],
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Tareas'),
            Tab(text: 'Participación'),
            Tab(text: 'Asistencias'),
            Tab(text: 'Exámenes'),
          ],
        ),
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
            Text('Cargando detalles del trimestre...'),
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
              onPressed: _cargarDetallesSeguimiento,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildTareasTab(),
        _buildParticipacionTab(),
        _buildAsistenciasTab(),
        _buildExamenesTab(),
      ],
    );
  }

  // ========================= TAB TAREAS =========================
  Widget _buildTareasTab() {
    final tareas = _seguimientoDetallado?.tareas ?? [];

    if (tareas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay tareas registradas en este trimestre', style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDetallesSeguimiento,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tareas.length,
        itemBuilder: (context, index) {
          final tarea = tareas[index];
          return _buildTareaCard(tarea);
        },
      ),
    );
  }

  Widget _buildTareaCard(Tarea tarea) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.assignment,
                color: Colors.blue[600],
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tarea.fechaFormateada,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tarea.titulo ?? 'Tarea sin título',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (tarea.descripcion != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      tarea.descripcion!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getNotaColor(tarea.notaTarea).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                tarea.notaTarea.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getNotaColor(tarea.notaTarea),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================= TAB PARTICIPACIÓN =========================
  Widget _buildParticipacionTab() {
    final participaciones = _seguimientoDetallado?.participaciones ?? [];

    if (participaciones.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay participaciones registradas en este trimestre', style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDetallesSeguimiento,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: participaciones.length,
        itemBuilder: (context, index) {
          final participacion = participaciones[index];
          return _buildParticipacionCard(participacion);
        },
      ),
    );
  }

  Widget _buildParticipacionCard(Participacion participacion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.forum,
                color: Colors.green[600],
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    participacion.fechaFormateada,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Participación en clase',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (participacion.descripcion != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      participacion.descripcion!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getNotaColor(participacion.notaParticipacion).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                participacion.notaParticipacion.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getNotaColor(participacion.notaParticipacion),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================= TAB ASISTENCIAS =========================
  Widget _buildAsistenciasTab() {
    final asistencias = _seguimientoDetallado?.asistencias ?? [];

    if (asistencias.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay registros de asistencia en este trimestre', style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildAsistenciasSummary(asistencias),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _cargarDetallesSeguimiento,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: asistencias.length,
              itemBuilder: (context, index) {
                final asistencia = asistencias[index];
                return _buildAsistenciaCard(asistencia);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAsistenciasSummary(List<Asistencia> asistencias) {
    final totalClases = asistencias.length;
    final clasesAsistidas = asistencias.where((a) => a.asistencia).length;
    final porcentaje = totalClases > 0 ? (clasesAsistidas / totalClases * 100) : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, color: Colors.blue[600], size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen de Asistencia - ${widget.seguimiento.trimestreNombre}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$clasesAsistidas de $totalClases clases (${porcentaje.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getAsistenciaColor(porcentaje),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${porcentaje.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAsistenciaCard(Asistencia asistencia) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: asistencia.asistencia ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                asistencia.asistencia ? Icons.check_circle : Icons.cancel,
                color: asistencia.asistencia ? Colors.green[600] : Colors.red[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asistencia.fechaFormateada,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    asistencia.estadoTexto,
                    style: TextStyle(
                      fontSize: 14,
                      color: asistencia.asistencia ? Colors.green[600] : Colors.red[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================= TAB EXÁMENES =========================
  Widget _buildExamenesTab() {
    final examenes = _seguimientoDetallado?.examenes ?? [];

    if (examenes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay exámenes registrados en este trimestre', style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDetallesSeguimiento,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: examenes.length,
        itemBuilder: (context, index) {
          final examen = examenes[index];
          return _buildExamenCard(examen);
        },
      ),
    );
  }

  Widget _buildExamenCard(Examen examen) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.quiz,
                color: Colors.purple[600],
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    examen.fechaFormateada,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    examen.tipoExamenNombre ?? 'Examen',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (examen.observaciones != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      examen.observaciones!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getNotaColor(examen.notaExamen).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                examen.notaExamen.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getNotaColor(examen.notaExamen),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================= UTILIDADES =========================
  Color _getNotaColor(double nota) {
    if (nota >= 70) return Colors.green;
    if (nota >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getAsistenciaColor(double porcentaje) {
    if (porcentaje >= 80) return Colors.green;
    if (porcentaje >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
} 