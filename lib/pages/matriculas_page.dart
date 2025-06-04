import 'package:flutter/material.dart';
import '../services/matricula_service.dart';
import '../services/auth_service.dart';
import '../pages/nuevo_pago_page.dart';

class MatriculasPage extends StatefulWidget {
  const MatriculasPage({super.key});

  @override
  State<MatriculasPage> createState() => _MatriculasPageState();
}

class _MatriculasPageState extends State<MatriculasPage> {
  Map<String, dynamic>? _datosMatriculas;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarMatriculas();
  }

  Future<void> _cargarMatriculas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await AuthService().getAccessToken();
      if (token == null) {
        throw Exception('No hay token de acceso');
      }

      // Obtener el ID correcto del padre/tutor
      final padreTutorId = await MatriculaService.obtenerPadreTutorIdActual();
      if (padreTutorId == null) {
        throw Exception('No se pudo obtener el ID del padre/tutor');
      }

      print('🎓 MatriculasPage: Cargando matrículas para padre/tutor ID: $padreTutorId');

      final matriculaService = MatriculaService();
      final result = await matriculaService.obtenerMatriculasPorPadreTutor(padreTutorId, token);

      if (result != null) {
        setState(() {
          _datosMatriculas = result;
          _isLoading = false;
        });
        print('✅ MatriculasPage: Datos de matrículas cargados exitosamente');
      } else {
        throw Exception('No se pudieron obtener las matrículas');
      }
    } catch (e) {
      print('❌ MatriculasPage: Error al cargar matrículas: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matrículas'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _cargarMatriculas,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
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
            Text('Cargando matrículas...'),
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
              onPressed: _cargarMatriculas,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_datosMatriculas == null) {
      return const Center(
        child: Text('No se pudieron cargar los datos'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderInfo(),
          const SizedBox(height: 24),
          _buildResumenGlobal(),
          const SizedBox(height: 24),
          _buildListaEstudiantes(),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo() {
    final padreTutor = _datosMatriculas!['padre_tutor'];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.green[100],
                child: Icon(Icons.family_restroom, color: Colors.green[700], size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      padreTutor['nombre_completo'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      padreTutor['parentesco'] ?? 'Tutor',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (padreTutor['telefono'] != null)
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            padreTutor['telefono'],
                            style: TextStyle(
                              fontSize: 14,
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
        ],
      ),
    );
  }

  Widget _buildResumenGlobal() {
    final resumen = _datosMatriculas!['resumen_global'];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen General',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Estudiantes',
                  resumen['total_estudiantes'].toString(),
                  Icons.school,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Matrículas',
                  resumen['total_matriculas'].toString(),
                  Icons.receipt,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Vigentes',
                  resumen['matriculas_vigentes'].toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Pagado',
                  'Bs. ${resumen['monto_total_pagado'].toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListaEstudiantes() {
    final estudiantes = _datosMatriculas!['estudiantes'] as List<dynamic>;
    
    if (estudiantes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay estudiantes asignados',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mis Hijos (${estudiantes.length})',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...estudiantes.map((estudiante) => _buildEstudianteCard(estudiante)).toList(),
      ],
    );
  }

  Widget _buildEstudianteCard(Map<String, dynamic> estudiante) {
    final resumen = estudiante['resumen_estudiante'];
    final matriculas = estudiante['matriculas'] as List<dynamic>;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange[100],
          child: Text(
            _getInitials(estudiante['nombre_completo']),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
            ),
          ),
        ),
        title: Text(
          estudiante['nombre_completo'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (estudiante['curso'] != null)
              Text('${estudiante['curso']['nombre']} - ${estudiante['curso']['turno']}'),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildChip(
                  '${resumen['total_matriculas']} matrículas',
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildChip(
                  '${resumen['matriculas_vigentes']} vigentes',
                  resumen['matriculas_vigentes'] > 0 ? Colors.green : Colors.orange,
                ),
              ],
            ),
          ],
        ),
        children: [
          const Divider(),
          if (matriculas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No hay matrículas registradas'),
            )
          else
            ...matriculas.map((matricula) => _buildMatriculaItem(matricula)).toList(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total pagado: Bs. ${resumen['monto_total'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatriculaItem(Map<String, dynamic> matricula) {
    final vigente = matricula['vigente'] as bool;
    final estado = matricula['estado'] as bool;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: vigente ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: vigente ? Colors.green[200]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            vigente ? Icons.check_circle : (estado ? Icons.schedule : Icons.cancel),
            color: vigente ? Colors.green : (estado ? Colors.orange : Colors.red),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      matricula['fecha'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Bs. ${matricula['monto'].toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (matricula['tipo_pago'] != null)
                      _buildChip(
                        matricula['tipo_pago']['nombre'],
                        Colors.blue,
                      ),
                    const SizedBox(width: 8),
                    if (matricula['metodo_pago'] != null)
                      _buildChip(
                        matricula['metodo_pago']['nombre'],
                        Colors.purple,
                      ),
                    const Spacer(),
                    _buildChip(
                      vigente ? 'Vigente' : (estado ? 'Vencida' : 'Inactiva'),
                      vigente ? Colors.green : (estado ? Colors.orange : Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getInitials(String nombreCompleto) {
    final words = nombreCompleto.split(' ');
    String initials = '';
    for (int i = 0; i < words.length && i < 2; i++) {
      if (words[i].isNotEmpty) {
        initials += words[i][0];
      }
    }
    return initials.isEmpty ? 'E' : initials.toUpperCase();
  }
} 