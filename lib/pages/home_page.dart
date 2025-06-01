import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'estudiantes_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema Educativo'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                icon: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    authProvider.currentUser?.firstName.substring(0, 1).toUpperCase() ?? 'U',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onSelected: (value) async {
                  switch (value) {
                    case 'profile':
                      // Navegar al perfil
                      break;
                    case 'logout':
                      await authProvider.logout();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.person),
                        const SizedBox(width: 8),
                        Text('Perfil'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        const Icon(Icons.logout, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Column(
            children: [
              // Header con información del usuario
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Hola, ${authProvider.currentUser?.firstName ?? 'Usuario'}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bienvenido al sistema educativo',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    // Mostrar tipo de usuario
                    const SizedBox(height: 8),
                    Text(
                      _getUserTypeText(authProvider.currentUser),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Contenido principal
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      
                      Text(
                        'Módulos del Sistema',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Grid de módulos
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          children: [
                            _buildModuleCard(
                              context,
                              'Estudiantes',
                              Icons.school,
                              Colors.blue,
                              () => _navigateToEstudiantes(context),  // Navegación real
                            ),
                            _buildModuleCard(
                              context,
                              'Profesores',
                              Icons.person_4,
                              Colors.green,
                              () => _showComingSoon(context, 'Módulo de Profesores'),
                            ),
                            _buildModuleCard(
                              context,
                              'Cursos',
                              Icons.book,
                              Colors.orange,
                              () => _showComingSoon(context, 'Módulo de Cursos'),
                            ),
                            _buildModuleCard(
                              context,
                              'Calificaciones',
                              Icons.grade,
                              Colors.red,
                              () => _showComingSoon(context, 'Módulo de Calificaciones'),
                            ),
                            _buildModuleCard(
                              context,
                              'Horarios',
                              Icons.schedule,
                              Colors.purple,
                              () => _showComingSoon(context, 'Módulo de Horarios'),
                            ),
                            _buildModuleCard(
                              context,
                              'Reportes',
                              Icons.analytics,
                              Colors.teal,
                              () => _showComingSoon(context, 'Módulo de Reportes'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.8),
                color,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Navegar a la página de estudiantes
  void _navigateToEstudiantes(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EstudiantesPage(),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String module) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(module),
          content: const Text(
            'Este módulo estará disponible próximamente. '
            'Aquí es donde podrás integrar las vistas específicas '
            'que correspondan a tus modelos, serializers y views de Django.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  // Obtener texto del tipo de usuario
  String _getUserTypeText(user) {
    if (user == null) return '';
    
    List<String> types = [];
    if (user.isAdmin) types.add('Administrador');
    if (user.isDocente) types.add('Docente');
    if (user.isEstudiante) types.add('Estudiante');
    if (user.isPadreTutor) types.add('Padre/Tutor');
    
    return types.isEmpty ? 'Usuario' : types.join(', ');
  }
} 