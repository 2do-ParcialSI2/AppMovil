import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../models/seguimiento_models.dart';
import '../services/seguimiento_service.dart';
import '../services/api_service.dart';
import '../pages/materia_detalle_page.dart';
import '../routes/app_routes.dart';

class EstudianteDashboardPage extends StatefulWidget {
  const EstudianteDashboardPage({Key? key}) : super(key: key);

  @override
  State<EstudianteDashboardPage> createState() => _EstudianteDashboardPageState();
}

class _EstudianteDashboardPageState extends State<EstudianteDashboardPage> {
  final SeguimientoService _seguimientoService = SeguimientoService();
  List<EstudianteMateria> _materias = [];
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _estudiante;

  @override
  void initState() {
    super.initState();
    _cargarMaterias();
  }

  Future<void> _cargarMaterias() async {
    try {
      if (!mounted) return; // Verificar si el widget sigue montado
      
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      print('📚 EstudianteDashboard: Cargando materias para usuario ${user.id}');

      // Obtener token simple
      String? token = await authProvider.getAccessToken();
      if (token == null) {
        throw Exception('No hay token de acceso');
      }

      // Buscar estudiante por email del usuario
      final estudiantesResponse = await _seguimientoService.apiService.get(
        '/estudiantes/?email=${user.email}',
        token: token,
      );

      print('📋 EstudianteDashboard: Respuesta estudiantes: $estudiantesResponse');

      if (estudiantesResponse['success'] != true || estudiantesResponse['data'] == null) {
        throw Exception('No se encontró información del estudiante');
      }

      final estudiantesData = estudiantesResponse['data'] as List;
      if (estudiantesData.isEmpty) {
        throw Exception('No se encontró el estudiante asociado al usuario');
      }

      // Buscar el estudiante que coincida con el email del usuario logueado
      Map<String, dynamic>? estudianteEncontrado;
      for (final estudiante in estudiantesData) {
        if (estudiante['email'] == user.email) {
          estudianteEncontrado = estudiante;
          break;
        }
      }

      if (estudianteEncontrado == null) {
        throw Exception('No se encontró el estudiante con email ${user.email}');
      }

      _estudiante = estudianteEncontrado;
      final estudianteId = _estudiante!['id'] as int;
      print('👨‍🎓 EstudianteDashboard: Datos del estudiante: $_estudiante');
      print('👨‍🎓 EstudianteDashboard: ID del estudiante: $estudianteId');

      // Intentar obtener las materias del estudiante
      try {
        final materias = await _seguimientoService.obtenerMateriasEstudiante(estudianteId, token);
        
        if (mounted) {
          setState(() {
            _materias = materias;
            _isLoading = false;
          });
        }

        print('✅ EstudianteDashboard: ${materias.length} materias cargadas');
      } catch (e) {
        // Si no hay materias, no es un error crítico
        print('⚠️ EstudianteDashboard: No se pudieron cargar materias: $e');
        if (mounted) {
          setState(() {
            _materias = [];
            _isLoading = false;
          });
        }
      }

    } catch (e) {
      print('❌ EstudianteDashboard: Error al cargar materias: $e');
      
      // Si es error 401 o token inválido, hacer logout simple
      if (e is ApiError && e.statusCode == 401) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();
        return;
      }
      
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    // La navegación se manejará automáticamente por el router
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Dashboard'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Quitar botón de menú
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarMaterias,
            tooltip: 'Actualizar',
          ),
          // Botón del usuario (como antes)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                GoRouter.of(context).push(AppRoutes.estudianteProfile);
              } else if (value == 'logout') {
                _mostrarDialogoLogout();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    const Text('Mi Perfil'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Text('Cerrar Sesión', style: TextStyle(color: Colors.red[600])),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  _getInitials(user?.firstName, user?.lastName),
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String? firstName, String? lastName) {
    String initials = '';
    if (firstName != null && firstName.isNotEmpty) {
      initials += firstName[0].toUpperCase();
    }
    if (lastName != null && lastName.isNotEmpty) {
      initials += lastName[0].toUpperCase();
    }
    return initials.isEmpty ? 'E' : initials;
  }

  void _mostrarDialogoLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Container(
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
          Text(
            'Bienvenido,',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: Colors.grey[600],
            ),
          ),
          Text(
            user?.firstName ?? 'Estudiante',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          if (_estudiante != null && _estudiante!['curso'] != null)
            Row(
              children: [
                Icon(Icons.school, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Curso: ${_estudiante!['curso']['nombre']}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
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
            Text('Cargando información...'),
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
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar información',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarMaterias,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    // Mostrar información del estudiante aunque no tenga materias
    if (_materias.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 80,
              color: Colors.blue[300],
            ),
            const SizedBox(height: 24),
            Text(
              _estudiante != null && _estudiante!['curso'] != null
                  ? 'Aún no tienes materias asignadas'
                  : 'No tienes curso ni materias asignadas',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _estudiante != null && _estudiante!['curso'] != null
                    ? 'Las materias aparecerán aquí una vez que sean asignadas por tu institución.'
                    : 'Contacta con la administración para que te asignen a un curso.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            if (_estudiante != null && _estudiante!['curso'] != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Estás inscrito en: ${_estudiante!['curso']['nombre']}',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarMaterias,
              child: const Text('Actualizar'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Mis Materias',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _cargarMaterias,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _materias.length,
              itemBuilder: (context, index) {
                final materia = _materias[index];
                return _buildMateriaCard(materia);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMateriaCard(EstudianteMateria materia) {
    // Calcular estadísticas de los seguimientos
    int totalTrimestres = materia.seguimientos?.length ?? 0;
    double promedioGeneral = 0.0;
    
    if (materia.seguimientos != null && materia.seguimientos!.isNotEmpty) {
      final sumaNotas = materia.seguimientos!.fold(0.0, (sum, s) => sum + s.notaTrimestral);
      promedioGeneral = sumaNotas / materia.seguimientos!.length;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _buildMateriaIcon(materia.materiaNombre),
            const SizedBox(width: 16),
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
                    'Profesor: ${materia.docenteCompleto}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _navigateToMateriaDetalle(materia),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Ver Detalle',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMateriaIcon(String materiaNombre) {
    final materiaLower = materiaNombre.toLowerCase();
    
    // Lista de iconos disponibles organizados por categorías
    final iconosCiencias = [Icons.science, Icons.biotech, Icons.psychology, Icons.scatter_plot];
    final iconosMatematicas = [Icons.calculate, Icons.functions, Icons.analytics, Icons.show_chart];
    final iconosLenguaje = [Icons.menu_book, Icons.translate, Icons.create, Icons.record_voice_over];
    final iconosSociales = [Icons.history_edu, Icons.public, Icons.groups, Icons.gavel];
    final iconosArtes = [Icons.palette, Icons.music_note, Icons.theater_comedy, Icons.brush];
    final iconosDeportes = [Icons.sports_soccer, Icons.sports_basketball, Icons.fitness_center, Icons.pool];
    final iconosTecnologia = [Icons.code, Icons.computer, Icons.engineering, Icons.memory];
    final iconosGenericos = [Icons.book, Icons.school, Icons.library_books, Icons.assignment];

    // Detectar categoría por palabras clave
    List<IconData> iconosCategoria;
    if (materiaLower.contains('matemática') || materiaLower.contains('matematica') || 
        materiaLower.contains('álgebra') || materiaLower.contains('algebra') ||
        materiaLower.contains('geometría') || materiaLower.contains('geometria') ||
        materiaLower.contains('cálculo') || materiaLower.contains('calculo') ||
        materiaLower.contains('estadística') || materiaLower.contains('estadistica')) {
      iconosCategoria = iconosMatematicas;
    } else if (materiaLower.contains('física') || materiaLower.contains('fisica') ||
               materiaLower.contains('química') || materiaLower.contains('quimica') ||
               materiaLower.contains('biología') || materiaLower.contains('biologia') ||
               materiaLower.contains('ciencias') || materiaLower.contains('laboratorio')) {
      iconosCategoria = iconosCiencias;
    } else if (materiaLower.contains('literatura') || materiaLower.contains('lengua') ||
               materiaLower.contains('español') || materiaLower.contains('inglés') ||
               materiaLower.contains('idioma') || materiaLower.contains('comunicación') ||
               materiaLower.contains('redacción') || materiaLower.contains('lectura')) {
      iconosCategoria = iconosLenguaje;
    } else if (materiaLower.contains('historia') || materiaLower.contains('geografía') ||
               materiaLower.contains('geografia') || materiaLower.contains('civismo') ||
               materiaLower.contains('social') || materiaLower.contains('política') ||
               materiaLower.contains('filosofía') || materiaLower.contains('filosofia')) {
      iconosCategoria = iconosSociales;
    } else if (materiaLower.contains('arte') || materiaLower.contains('música') ||
               materiaLower.contains('musica') || materiaLower.contains('dibujo') ||
               materiaLower.contains('pintura') || materiaLower.contains('teatro') ||
               materiaLower.contains('danza')) {
      iconosCategoria = iconosArtes;
    } else if (materiaLower.contains('educación física') || materiaLower.contains('educacion fisica') ||
               materiaLower.contains('deporte') || materiaLower.contains('gimnasia') ||
               materiaLower.contains('natación') || materiaLower.contains('natacion')) {
      iconosCategoria = iconosDeportes;
    } else if (materiaLower.contains('programación') || materiaLower.contains('programacion') ||
               materiaLower.contains('informática') || materiaLower.contains('informatica') ||
               materiaLower.contains('computación') || materiaLower.contains('computacion') ||
               materiaLower.contains('tecnología') || materiaLower.contains('tecnologia') ||
               materiaLower.contains('sistemas')) {
      iconosCategoria = iconosTecnologia;
    } else {
      iconosCategoria = iconosGenericos;
    }

    // Seleccionar icono basado en hash del nombre para consistencia
    final hash = materiaNombre.hashCode.abs();
    IconData iconData = iconosCategoria[hash % iconosCategoria.length];

    // Lista de colores vibrantes y diferenciados
    final colores = [
      Colors.blue[600]!,      // Azul
      Colors.green[600]!,     // Verde
      Colors.orange[600]!,    // Naranja
      Colors.purple[600]!,    // Morado
      Colors.red[600]!,       // Rojo
      Colors.teal[600]!,      // Verde azulado
      Colors.indigo[600]!,    // Índigo
      Colors.brown[600]!,     // Marrón
      Colors.pink[600]!,      // Rosa
      Colors.amber[600]!,     // Ámbar
      Colors.cyan[600]!,      // Cian
      Colors.deepOrange[600]!, // Naranja profundo
      Colors.lightGreen[600]!, // Verde claro
      Colors.deepPurple[600]!, // Morado profundo
      Colors.lime[600]!,      // Lima
      Colors.blueGrey[600]!,  // Azul gris
    ];

    // Generar color consistente basado en hash del nombre
    Color iconColor = colores[hash % colores.length];

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 28,
      ),
    );
  }

  Widget _buildEstadisticaChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotaChip(double nota) {
    Color color;
    if (nota >= 70) {
      color = Colors.green;
    } else if (nota >= 60) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        nota > 0 ? nota.toStringAsFixed(1) : 'S/N',
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _navigateToMateriaDetalle(EstudianteMateria materia) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MateriaDetallePage(
          materia: materia,
        ),
      ),
    );
  }
} 