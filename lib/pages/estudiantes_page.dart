import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import '../services/api_service.dart';
import '../models/auth_response.dart';

class EstudiantesPage extends StatefulWidget {
  const EstudiantesPage({super.key});

  @override
  State<EstudiantesPage> createState() => _EstudiantesPageState();
}

class _EstudiantesPageState extends State<EstudiantesPage> {
  final BackendService _backendService = BackendService();
  List<Map<String, dynamic>> estudiantes = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEstudiantes();
  }

  Future<void> _loadEstudiantes() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final data = await _backendService.getEstudiantes();
      
      setState(() {
        estudiantes = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e is ApiError ? e.message : e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estudiantes'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEstudiantes,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navegar a página de crear estudiante
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Función de crear estudiante por implementar'),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando estudiantes...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar estudiantes',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEstudiantes,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (estudiantes.isEmpty) {
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
              'No hay estudiantes registrados',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEstudiantes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: estudiantes.length,
        itemBuilder: (context, index) {
          final estudiante = estudiantes[index];
          return _buildEstudianteCard(estudiante);
        },
      ),
    );
  }

  Widget _buildEstudianteCard(Map<String, dynamic> estudiante) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            _getInitials(estudiante),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '${estudiante['first_name'] ?? ''} ${estudiante['last_name'] ?? ''}'.trim(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (estudiante['email'] != null)
              Text(
                estudiante['email'],
                style: TextStyle(color: Colors.grey[600]),
              ),
            if (estudiante['curso'] != null)
              Text(
                'Curso: ${estudiante['curso']['nombre'] ?? 'Sin asignar'}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            if (estudiante['fecha_nacimiento'] != null)
              Text(
                'Fecha nac.: ${estudiante['fecha_nacimiento']}',
                style: TextStyle(color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, estudiante),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('Ver detalles'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showEstudianteDetails(estudiante),
      ),
    );
  }

  String _getInitials(Map<String, dynamic> estudiante) {
    final firstName = estudiante['first_name']?.toString() ?? '';
    final lastName = estudiante['last_name']?.toString() ?? '';
    
    String initials = '';
    if (firstName.isNotEmpty) initials += firstName[0].toUpperCase();
    if (lastName.isNotEmpty) initials += lastName[0].toUpperCase();
    
    return initials.isEmpty ? 'E' : initials;
  }

  void _handleMenuAction(String action, Map<String, dynamic> estudiante) {
    switch (action) {
      case 'view':
        _showEstudianteDetails(estudiante);
        break;
      case 'edit':
        // TODO: Implementar edición
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Función de editar por implementar')),
        );
        break;
      case 'delete':
        _confirmDelete(estudiante);
        break;
    }
  }

  void _showEstudianteDetails(Map<String, dynamic> estudiante) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${estudiante['first_name']} ${estudiante['last_name']}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Email', estudiante['email']),
                _buildDetailRow('Género', estudiante['genero']),
                _buildDetailRow('Dirección', estudiante['direccion']),
                _buildDetailRow('Fecha de nacimiento', estudiante['fecha_nacimiento']),
                _buildDetailRow('Estado', estudiante['activo'] ? 'Activo' : 'Inactivo'),
                if (estudiante['curso'] != null)
                  _buildDetailRow('Curso', estudiante['curso']['nombre']),
                if (estudiante['padre_tutor'] != null)
                  _buildDetailRow('Padre/Tutor', estudiante['padre_tutor']['nombre']),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value?.toString() ?? 'No especificado'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> estudiante) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Estás seguro de que quieres eliminar a ${estudiante['first_name']} ${estudiante['last_name']}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteEstudiante(estudiante['id']);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEstudiante(int id) async {
    try {
      await _backendService.deleteEstudiante(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estudiante eliminado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      _loadEstudiantes(); // Recargar lista
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 