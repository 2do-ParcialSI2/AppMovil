import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/seguimiento_service.dart';
import '../models/seguimiento_models.dart';
import 'materia_detalle_page.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  List<EstudianteMateria> _materias = [];
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Cargar datos del usuario
      final user = await AuthService().getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          _userData = user.toJson();
        });
      }

      await _cargarMaterias();
    } catch (e) {
      print('❌ Error cargando datos: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error al cargar datos: $e';
      });
    }
  }

  Future<void> _cargarMaterias() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await AuthService().getAccessToken();
      if (token == null) {
        throw Exception('Token no disponible');
      }

      final user = await AuthService().getCurrentUser();
      if (user == null) {
        throw Exception('Datos del estudiante no disponibles');
      }

      final estudianteId = user.id;
      print('🔍 Dashboard: Cargando materias del estudiante $estudianteId');

      // Usar el nuevo método que obtiene información completa del docente
      final materiasCompletas = await SeguimientoService().obtenerMateriasEstudiante(estudianteId, token);
      
      print('📚 Dashboard: ${materiasCompletas.length} materias cargadas');
      
      if (!mounted) return;
      
      if (materiasCompletas.isEmpty) {
        setState(() {
          _materias = [];
          _isLoading = false;
          _error = 'No tiene materias asignadas';
        });
      } else {
        setState(() {
          _materias = materiasCompletas;
          _isLoading = false;
          _error = null;
        });
        
        // Log de materias cargadas
        for (final materia in materiasCompletas) {
          print('📖 Materia: ${materia.materiaNombre}');
          print('   Docente: ${materia.docenteCompleto}');
          print('   Curso: ${materia.cursoNombre}');
          print('   Trimestres: ${materia.seguimientos?.length ?? 0}');
          print('   Totales: T:${materia.totalTareas} P:${materia.totalParticipaciones} A:${materia.totalAsistencias} E:${materia.totalExamenes}');
        }
      }
    } catch (e) {
      print('❌ Dashboard Error: $e');
      if (!mounted) return;
      
      setState(() {
        _materias = [];
        _isLoading = false;
        _error = 'Error al cargar materias: $e';
      });
    }
  }

  Future<void> _logout() async {
    try {
      await AuthService().logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: $e')),
        );
      }
    }
  }

  String _getInitials(String? firstName, String? lastName) {
    final first = firstName?.isNotEmpty == true ? firstName![0] : '';
    final last = lastName?.isNotEmpty == true ? lastName![0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Estudiante'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          if (_userData != null)
            PopupMenuButton<String>(
              onSelected: (String value) {
                if (value == 'perfil') {
                  // TODO: Navegar a página de perfil
                } else if (value == 'logout') {
                  _logout();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'perfil',
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Mi Perfil'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Cerrar Sesión'),
                    ],
                  ),
                ),
              ],
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                child: CircleAvatar(
                  backgroundColor: Colors.blue[500],
                  child: Text(
                    _getInitials(_userData?['first_name'], _userData?['last_name']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
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
            Text('Cargando materias...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.orange[600],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarDatos,
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
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No tiene materias asignadas',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MateriaDetallePage(materia: materia),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre de la materia
              Text(
                materia.materiaNombre,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              
              // Información del docente
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Prof. ${materia.docenteCompleto}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              
              // Información del curso
              Row(
                children: [
                  Icon(Icons.class_, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      materia.cursoNombre,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  // Indicador de trimestres disponibles
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      '${materia.seguimientos?.length ?? 0} trimestres',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 