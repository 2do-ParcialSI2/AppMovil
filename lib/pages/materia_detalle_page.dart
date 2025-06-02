import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/seguimiento_models.dart';
import '../services/seguimiento_service.dart';

class MateriaDetallePage extends StatefulWidget {
  final int seguimientoId;
  final String materiaNombre;
  final String docenteNombre;

  const MateriaDetallePage({
    Key? key,
    required this.seguimientoId,
    required this.materiaNombre,
    required this.docenteNombre,
  }) : super(key: key);

  @override
  State<MateriaDetallePage> createState() => _MateriaDetallePageState();
}

class _MateriaDetallePageState extends State<MateriaDetallePage> with TickerProviderStateMixin {
  late TabController _tabController;
  final SeguimientoService _seguimientoService = SeguimientoService();
  
  // Estados de carga para cada tab
  bool _tareasLoading = true;
  bool _participacionesLoading = true;
  bool _asistenciasLoading = true;
  bool _examenesLoading = true;
  
  // Datos para cada tab
  List<Tarea> _tareas = [];
  List<Participacion> _participaciones = [];
  List<Asistencia> _asistencias = [];
  List<Examen> _examenes = [];
  
  // Errores para cada tab
  String? _tareasError;
  String? _participacionesError;
  String? _asistenciasError;
  String? _examenesError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = await authProvider.getAccessToken();

    if (token == null) {
      _mostrarError('Usuario no autenticado');
      return;
    }

    // Cargar todos los datos en paralelo
    await Future.wait([
      _cargarTareas(token),
      _cargarParticipaciones(token),
      _cargarAsistencias(token),
      _cargarExamenes(token),
    ]);
  }

  Future<void> _cargarTareas(String token) async {
    try {
      setState(() {
        _tareasLoading = true;
        _tareasError = null;
      });

      final tareas = await _seguimientoService.obtenerTareasPorSeguimiento(
        widget.seguimientoId, 
        token,
      );

      if (mounted) {
        setState(() {
          _tareas = tareas;
          _tareasLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _tareasError = e.toString();
          _tareasLoading = false;
        });
      }
    }
  }

  Future<void> _cargarParticipaciones(String token) async {
    try {
      setState(() {
        _participacionesLoading = true;
        _participacionesError = null;
      });

      final participaciones = await _seguimientoService.obtenerParticipacionesPorSeguimiento(
        widget.seguimientoId, 
        token,
      );

      if (mounted) {
        setState(() {
          _participaciones = participaciones;
          _participacionesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _participacionesError = e.toString();
          _participacionesLoading = false;
        });
      }
    }
  }

  Future<void> _cargarAsistencias(String token) async {
    try {
      setState(() {
        _asistenciasLoading = true;
        _asistenciasError = null;
      });

      final asistencias = await _seguimientoService.obtenerAsistenciasPorSeguimiento(
        widget.seguimientoId, 
        token,
      );

      if (mounted) {
        setState(() {
          _asistencias = asistencias;
          _asistenciasLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _asistenciasError = e.toString();
          _asistenciasLoading = false;
        });
      }
    }
  }

  Future<void> _cargarExamenes(String token) async {
    try {
      setState(() {
        _examenesLoading = true;
        _examenesError = null;
      });

      final examenes = await _seguimientoService.obtenerExamenesPorSeguimiento(
        widget.seguimientoId, 
        token,
      );

      if (mounted) {
        setState(() {
          _examenes = examenes;
          _examenesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _examenesError = e.toString();
          _examenesLoading = false;
        });
      }
    }
  }

  void _mostrarError(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.red,
        ),
      );
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
              widget.materiaNombre,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Detalle',
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTareasTab(),
          _buildParticipacionTab(),
          _buildAsistenciasTab(),
          _buildExamenesTab(),
        ],
      ),
    );
  }

  // ========================= TAB TAREAS =========================
  Widget _buildTareasTab() {
    if (_tareasLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tareasError != null) {
      return _buildErrorWidget(_tareasError!, () => _cargarTareas);
    }

    if (_tareas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay tareas registradas', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = await authProvider.getAccessToken();
        if (token != null) await _cargarTareas(token);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tareas.length,
        itemBuilder: (context, index) {
          final tarea = _tareas[index];
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
    if (_participacionesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_participacionesError != null) {
      return _buildErrorWidget(_participacionesError!, () => _cargarParticipaciones);
    }

    if (_participaciones.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay participaciones registradas', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = await authProvider.getAccessToken();
        if (token != null) await _cargarParticipaciones(token);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _participaciones.length,
        itemBuilder: (context, index) {
          final participacion = _participaciones[index];
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
    if (_asistenciasLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_asistenciasError != null) {
      return _buildErrorWidget(_asistenciasError!, () => _cargarAsistencias);
    }

    if (_asistencias.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay registros de asistencia', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildAsistenciasSummary(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final token = await authProvider.getAccessToken();
              if (token != null) await _cargarAsistencias(token);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _asistencias.length,
              itemBuilder: (context, index) {
                final asistencia = _asistencias[index];
                return _buildAsistenciaCard(asistencia);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAsistenciasSummary() {
    final totalClases = _asistencias.length;
    final clasesAsistidas = _asistencias.where((a) => a.asistencia).length;
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
                  'Resumen de Asistencia',
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
    if (_examenesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_examenesError != null) {
      return _buildErrorWidget(_examenesError!, () => _cargarExamenes);
    }

    if (_examenes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay exámenes registrados', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = await authProvider.getAccessToken();
        if (token != null) await _cargarExamenes(token);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _examenes.length,
        itemBuilder: (context, index) {
          final examen = _examenes[index];
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

  // ========================= WIDGETS COMUNES =========================
  Widget _buildErrorWidget(String error, Function() retry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error al cargar datos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[700]),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final token = await authProvider.getAccessToken();
              if (token != null) retry();
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

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
} 