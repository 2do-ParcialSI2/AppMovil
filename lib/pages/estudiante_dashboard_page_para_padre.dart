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
          child: Row(
            children: [
              // Icono de la materia
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getMateriaColor(materia.materiaNombre).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getMateriaIcon(materia.materiaNombre),
                  color: _getMateriaColor(materia.materiaNombre),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Información de la materia
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      materia.materiaNombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
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
                    if (materia.cursoNombre.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        materia.cursoNombre,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Indicador de trimestres disponibles
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Text(
                      '${materia.seguimientos?.length ?? 0} trimestres',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMateriaIcon(String materiaNombre) {
    final materiaLower = materiaNombre.toLowerCase();
    if (materiaLower.contains('matemática') || materiaLower.contains('matemática')) {
      return Icons.calculate;
    } else if (materiaLower.contains('física') || materiaLower.contains('fisica')) {
      return Icons.science;
    } else if (materiaLower.contains('química') || materiaLower.contains('quimica')) {
      return Icons.biotech;
    } else if (materiaLower.contains('historia')) {
      return Icons.history_edu;
    } else if (materiaLower.contains('literatura') || materiaLower.contains('lengua')) {
      return Icons.menu_book;
    } else if (materiaLower.contains('programación') || materiaLower.contains('programacion')) {
      return Icons.code;
    } else if (materiaLower.contains('educación') || materiaLower.contains('educacion')) {
      return Icons.sports_soccer;
    } else {
      return Icons.book;
    }
  }

  Color _getMateriaColor(String materiaNombre) {
    final materiaLower = materiaNombre.toLowerCase();
    if (materiaLower.contains('matemática') || materiaLower.contains('matemática')) {
      return Colors.blue[600]!;
    } else if (materiaLower.contains('física') || materiaLower.contains('fisica')) {
      return Colors.green[600]!;
    } else if (materiaLower.contains('química') || materiaLower.contains('quimica')) {
      return Colors.purple[600]!;
    } else if (materiaLower.contains('historia')) {
      return Colors.brown[600]!;
    } else if (materiaLower.contains('literatura') || materiaLower.contains('lengua')) {
      return Colors.orange[600]!;
    } else if (materiaLower.contains('programación') || materiaLower.contains('programacion')) {
      return Colors.indigo[600]!;
    } else if (materiaLower.contains('educación') || materiaLower.contains('educacion')) {
      return Colors.teal[600]!;
    } else {
      return Colors.grey[600]!;
    }
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