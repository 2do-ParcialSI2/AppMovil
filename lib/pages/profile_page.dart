import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
          
          if (user == null) {
            return const Center(
              child: Text('No hay información del usuario'),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Avatar
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    user.firstName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Información del usuario
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildInfoRow('Nombre completo', user.fullName),
                        _buildInfoRow('Email', user.email),
                        _buildInfoRow('Género', user.generoCompleto),
                        _buildInfoRow('Roles', _getRolesText(user.roles)),
                        _buildInfoRow('Estado', user.activo ? 'Activo' : 'Inactivo'),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Información adicional de roles
                if (user.isAdmin || user.isDocente || user.isEstudiante || user.isPadreTutor)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tipo de Usuario',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (user.isAdmin) _buildChip('Administrador', Colors.red),
                          if (user.isDocente) _buildChip('Docente', Colors.green),
                          if (user.isEstudiante) _buildChip('Estudiante', Colors.blue),
                          if (user.isPadreTutor) _buildChip('Padre/Tutor', Colors.orange),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // Botón de logout
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => authProvider.logout(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cerrar Sesión'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
      child: Chip(
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: color,
      ),
    );
  }

  String _getRolesText(List<int> roles) {
    if (roles.isEmpty) return 'Sin roles asignados';
    return roles.map((id) => 'Rol $id').join(', ');
  }
} 