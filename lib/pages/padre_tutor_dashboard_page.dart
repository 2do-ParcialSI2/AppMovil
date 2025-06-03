import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../pages/estudiante_dashboard_page_para_padre.dart';

class PadreTutorDashboardPage extends StatefulWidget {
  const PadreTutorDashboardPage({super.key});

  @override
  State<PadreTutorDashboardPage> createState() => _PadreTutorDashboardPageState();
}

class _PadreTutorDashboardPageState extends State<PadreTutorDashboardPage> {
  List<Map<String, dynamic>> _hijos = [];
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _padreTutorData;

  @override
  void initState() {
    super.initState();
    _cargarHijos();
  }

  Future<void> _cargarHijos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      print('👨‍👩‍👧‍👦 PadreTutorDashboard: Cargando hijos para usuario ${user.email}');

      // Obtener token
      String? token = await authProvider.getAccessToken();
      if (token == null) {
        throw Exception('No hay token de acceso');
      }

      // Obtener información del padre/tutor por email - esto ya incluye los estudiantes
      final padresResponse = await authProvider.authenticatedRequest(
        'GET',
        '/padres-tutores/?email=${user.email}',
      );

      print('📋 PadreTutorDashboard: Respuesta padres-tutores: $padresResponse');

      List<dynamic> padresData;
      if (padresResponse['results'] != null) {
        padresData = padresResponse['results'];
      } else if (padresResponse['data'] != null) {
        padresData = padresResponse['data'];
      } else {
        padresData = [padresResponse];
      }

      if (padresData.isEmpty) {
        throw Exception('No se encontró información del padre/tutor');
      }

      // Buscar el padre/tutor que coincida con el email
      Map<String, dynamic>? padreTutorEncontrado;
      for (final padre in padresData) {
        if (padre['email'] == user.email) {
          padreTutorEncontrado = padre;
          break;
        }
      }

      if (padreTutorEncontrado == null) {
        throw Exception('No se encontró el padre/tutor con email ${user.email}');
      }

      _padreTutorData = padreTutorEncontrado;
      final padreTutorId = _padreTutorData!['id'] as int;
      
      print('👨‍👩‍👧‍👦 PadreTutorDashboard: ID del padre/tutor: $padreTutorId');

      // Obtener los estudiantes del campo 'estudiantes' que ya viene en el serializer
      List<dynamic> estudiantesData = [];
      if (_padreTutorData!['estudiantes'] != null) {
        estudiantesData = _padreTutorData!['estudiantes'] as List<dynamic>;
        print('✅ PadreTutorDashboard: Estudiantes obtenidos desde el serializer del padre/tutor');
      }

      // Si no vienen estudiantes en el serializer, obtener manualmente
      if (estudiantesData.isEmpty) {
        print('⚠️ No hay estudiantes en el serializer, obteniendo manualmente...');
        
        final estudiantesResponse = await authProvider.authenticatedRequest(
          'GET',
          '/estudiantes/',
        );
        
        List<dynamic> todosLosEstudiantes = [];
        if (estudiantesResponse['results'] != null) {
          todosLosEstudiantes = estudiantesResponse['results'];
        } else if (estudiantesResponse['data'] != null) {
          todosLosEstudiantes = estudiantesResponse['data'];
        }

        // Filtrar manualmente por padre_tutor
        estudiantesData = todosLosEstudiantes.where((estudiante) {
          final padreTutorField = estudiante['padre_tutor'];
          if (padreTutorField == null) return false;
          
          // Si es un objeto con id
          if (padreTutorField is Map<String, dynamic> && padreTutorField['id'] != null) {
            return padreTutorField['id'] == padreTutorId;
          }
          
          // Si es un número directo
          if (padreTutorField is int) {
            return padreTutorField == padreTutorId;
          }
          
          return false;
        }).toList();
        
        print('🔍 PadreTutorDashboard: Filtrado manual - ${estudiantesData.length} hijos encontrados');
      }

      setState(() {
        _hijos = List<Map<String, dynamic>>.from(estudiantesData);
        _isLoading = false;
      });

      print('✅ PadreTutorDashboard: ${_hijos.length} hijos cargados para padre/tutor ID: $padreTutorId');
      
      // Debug: mostrar los estudiantes encontrados
      for (final hijo in _hijos) {
        print('👶 Hijo encontrado: ${hijo['first_name']} ${hijo['last_name']} (ID: ${hijo['id']})');
      }

    } catch (e) {
      print('❌ PadreTutorDashboard: Error: $e');
      setState(() {
        _error = 'Error al cargar información de hijos: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Hijos'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                icon: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    authProvider.currentUser?.firstName.substring(0, 1).toUpperCase() ?? 'P',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onSelected: (value) async {
                  switch (value) {
                    case 'logout':
                      await authProvider.logout();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
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
              );
            },
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
            Text('Cargando información de sus hijos...'),
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
              onPressed: _cargarHijos,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header con información del padre/tutor
        _buildHeader(),
        // Lista de hijos
        Expanded(
          child: _hijos.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.family_restroom, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No se encontraron hijos registrados'),
                      SizedBox(height: 8),
                      Text(
                        'Contacte con la institución para verificar\nque sus hijos estén correctamente asociados.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _hijos.length,
                  itemBuilder: (context, index) {
                    final hijo = _hijos[index];
                    return _buildHijoCard(hijo);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[700],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¡Hola, ${user?.firstName ?? 'Padre/Tutor'}!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seleccione a su hijo/a para ver su información académica',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.family_restroom, size: 16, color: Colors.white.withValues(alpha: 0.8)),
              const SizedBox(width: 4),
              Text(
                'Padre/Tutor',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHijoCard(Map<String, dynamic> hijo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _verDetallesHijo(hijo),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar del estudiante
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.orange[100],
                child: Text(
                  _getInitials(hijo),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Información del estudiante
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${hijo['first_name'] ?? ''} ${hijo['last_name'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (hijo['curso'] != null)
                      Row(
                        children: [
                          Icon(Icons.school, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Curso: ${hijo['curso']['nombre']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.email, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          hijo['email'] ?? 'Sin email',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Estado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (hijo['activo'] ?? true) ? Colors.green[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (hijo['activo'] ?? true) ? 'Activo' : 'Inactivo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: (hijo['activo'] ?? true) ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Icono de flecha
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(Map<String, dynamic> hijo) {
    final firstName = hijo['first_name']?.toString() ?? '';
    final lastName = hijo['last_name']?.toString() ?? '';
    
    String initials = '';
    if (firstName.isNotEmpty) initials += firstName[0];
    if (lastName.isNotEmpty) initials += lastName[0];
    
    return initials.isEmpty ? 'E' : initials.toUpperCase();
  }

  void _verDetallesHijo(Map<String, dynamic> hijo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EstudianteDashboardPageParaPadre(
          estudiante: hijo,
        ),
      ),
    );
  }
} 