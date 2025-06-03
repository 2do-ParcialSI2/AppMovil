import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/seguimiento_models.dart';
import '../services/seguimiento_service.dart';
import '../services/api_service.dart';
import '../pages/materia_detalle_page_para_padre.dart';

class EstudianteDashboardPageParaPadre extends StatefulWidget {
  final Map<String, dynamic> estudiante;

  const EstudianteDashboardPageParaPadre({
    super.key,
    required this.estudiante,
  });

  @override
  State<EstudianteDashboardPageParaPadre> createState() => _EstudianteDashboardPageParaPadreState();
}

class _EstudianteDashboardPageParaPadreState extends State<EstudianteDashboardPageParaPadre> {
  final SeguimientoService _seguimientoService = SeguimientoService();
  List<EstudianteMateria> _materias = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarMaterias();
  }

  Future<void> _cargarMaterias() async {
    try {
      if (!mounted) return;
      
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      print('📚 EstudianteDashboard (Padre): Cargando materias para estudiante ${widget.estudiante['id']}');

      // Obtener token
      String? token = await authProvider.getAccessToken();
      if (token == null) {
        throw Exception('No hay token de acceso');
      }

      final estudianteId = widget.estudiante['id'] as int;
      print('👨‍🎓 EstudianteDashboard (Padre): ID del estudiante: $estudianteId');

      // Usar el servicio existente para obtener las materias del estudiante
      try {
        final materias = await _seguimientoService.obtenerMateriasEstudiante(estudianteId, token);
        
        if (mounted) {
          setState(() {
            _materias = materias;
            _isLoading = false;
          });
        }

        print('✅ EstudianteDashboard (Padre): ${materias.length} materias cargadas');
      } catch (e) {
        print('⚠️ EstudianteDashboard (Padre): No se pudieron cargar materias: $e');
        if (mounted) {
          setState(() {
            _materias = [];
            _isLoading = false;
          });
        }
      }

    } catch (e) {
      print('❌ EstudianteDashboard (Padre): Error: $e');
      if (mounted) {
        setState(() {
          _materias = [];
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.estudiante['first_name']} ${widget.estudiante['last_name']}'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarMaterias,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.orange[100],
                child: Text(
                  _getInitials(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.estudiante['first_name']} ${widget.estudiante['last_name']}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (widget.estudiante['curso'] != null)
                      Row(
                        children: [
                          Icon(Icons.school, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Curso: ${widget.estudiante['curso']['nombre']}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Indicador de vista para padre
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.family_restroom, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 4),
                Text(
                  'Vista de Padre/Tutor',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando información académica...'),
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
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarMaterias,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_materias.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No se encontraron materias'),
            SizedBox(height: 8),
            Text(
              'Es posible que el estudiante no tenga\nmaterias asignadas aún.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarMaterias,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _materias.length,
        itemBuilder: (context, index) {
          final materia = _materias[index];
          return _buildMateriaCard(materia);
        },
      ),
    );
  }

  Widget _buildMateriaCard(EstudianteMateria materia) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _verDetalleMateria(materia),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado de la materia
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          materia.materiaNombre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Prof. ${materia.docenteCompleto}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Estadísticas de actividades
              Row(
                children: [
                  Flexible(child: _buildStatChip('Tareas', materia.totalTareas, Colors.blue)),
                  const SizedBox(width: 8),
                  Flexible(child: _buildStatChip('Participación', materia.totalParticipaciones, Colors.green)),
                  const SizedBox(width: 8),
                  Flexible(child: _buildStatChip('Asistencia', materia.totalAsistencias, Colors.orange)),
                  const SizedBox(width: 8),
                  Flexible(child: _buildStatChip('Exámenes', materia.totalExamenes, Colors.red)),
                ],
              ),
              const SizedBox(height: 12),
              // Nota promedio
              if (materia.notaTrimestral > 0) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Promedio General',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        materia.notaTrimestral.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getColorForNota(materia.notaTrimestral),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForNota(double nota) {
    if (nota >= 80) return Colors.green;
    if (nota >= 70) return Colors.orange;
    if (nota >= 60) return Colors.amber;
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

  void _verDetalleMateria(EstudianteMateria materia) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MateriaDetallePageParaPadre(
          materia: materia,
          estudiante: widget.estudiante,
        ),
      ),
    );
  }
} 