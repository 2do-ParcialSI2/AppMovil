import 'package:flutter/material.dart';
import '../services/matricula_service.dart';
import '../services/auth_service.dart';

class HistorialMatriculasPage extends StatefulWidget {
  final Map<String, dynamic> estudiante;

  const HistorialMatriculasPage({
    super.key,
    required this.estudiante,
  });

  @override
  State<HistorialMatriculasPage> createState() => _HistorialMatriculasPageState();
}

class _HistorialMatriculasPageState extends State<HistorialMatriculasPage> {
  List<Map<String, dynamic>> _matriculas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarHistorialMatriculas();
  }

  Future<void> _cargarHistorialMatriculas() async {
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

      print('📋 HistorialMatriculas: Cargando para estudiante ${widget.estudiante['first_name']} ${widget.estudiante['last_name']}');

      final matriculaService = MatriculaService();
      final result = await matriculaService.obtenerMatriculasPorPadreTutor(padreTutorId, token);

      if (result != null) {
        // Filtrar matrículas del estudiante específico
        final estudianteId = widget.estudiante['id'];
        List<Map<String, dynamic>> todasMatriculas = [];
        
        print('🔍 HistorialMatriculas: Procesando resultado:');
        print('   Tipo de result: ${result.runtimeType}');
        print('   Claves disponibles: ${result.keys.toList()}');
        
        // Método 1: Buscar en matriculas_por_estudiante (datos mock)
        if (result['matriculas_por_estudiante'] != null) {
          print('📋 HistorialMatriculas: Usando matriculas_por_estudiante');
          final matriculasPorEstudiante = result['matriculas_por_estudiante'] as Map<String, dynamic>;
          if (matriculasPorEstudiante['$estudianteId'] != null) {
            todasMatriculas = List<Map<String, dynamic>>.from(matriculasPorEstudiante['$estudianteId']);
          }
        }
        // Método 2: Buscar en estudiantes (estructura procesada)
        else if (result['estudiantes'] != null) {
          print('📋 HistorialMatriculas: Usando estructura estudiantes');
          final estudiantes = result['estudiantes'] as List<dynamic>;
          
          for (final estudiante in estudiantes) {
            if (estudiante['id'] == estudianteId) {
              if (estudiante['matriculas'] != null) {
                todasMatriculas = List<Map<String, dynamic>>.from(estudiante['matriculas']);
              }
              break;
            }
          }
        }
        // Método 3: Si result es directamente una lista de matrículas
        else if (result is List) {
          print('📋 HistorialMatriculas: Result es una lista directa');
          // Filtrar por estudiante
          final resultList = result as List<dynamic>;
          todasMatriculas = resultList.where((matricula) {
            if (matricula['estudiante'] is Map) {
              return matricula['estudiante']['id'] == estudianteId;
            } else {
              return matricula['estudiante'] == estudianteId;
            }
          }).map((m) => Map<String, dynamic>.from(m)).toList();
        }
        // Método 4: Si result contiene directamente las matrículas
        else if (result['matriculas'] != null) {
          print('📋 HistorialMatriculas: Usando campo matriculas directo');
          final matriculas = result['matriculas'] as List<dynamic>;
          // Filtrar por estudiante
          todasMatriculas = matriculas.where((matricula) {
            if (matricula['estudiante'] is Map) {
              return matricula['estudiante']['id'] == estudianteId;
            } else {
              return matricula['estudiante'] == estudianteId;
            }
          }).map((m) => Map<String, dynamic>.from(m)).toList();
        }

        // Ordenar por fecha (más recientes primero)
        todasMatriculas.sort((a, b) {
          final fechaA = DateTime.tryParse(a['fecha_pago'] ?? a['fecha'] ?? '') ?? DateTime(1900);
          final fechaB = DateTime.tryParse(b['fecha_pago'] ?? b['fecha'] ?? '') ?? DateTime(1900);
          return fechaB.compareTo(fechaA);
        });

        setState(() {
          _matriculas = todasMatriculas;
          _isLoading = false;
        });

        print('✅ HistorialMatriculas: ${_matriculas.length} matrículas encontradas');
        if (_matriculas.isNotEmpty) {
          print('   Primera matrícula: ${_matriculas.first}');
        }
      } else {
        print('⚠️ HistorialMatriculas: Result es null');
        setState(() {
          _matriculas = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ HistorialMatriculas: Error: $e');
      setState(() {
        _error = 'Error al cargar historial: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de Pagos'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
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
            Text('Cargando historial de pagos...'),
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
              onPressed: _cargarHistorialMatriculas,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header con información del estudiante
        _buildHeader(),
        // Lista de matrículas
        Expanded(
          child: _matriculas.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No se encontraron pagos registrados'),
                      SizedBox(height: 8),
                      Text(
                        'Este estudiante no tiene matrículas pagadas',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _matriculas.length,
                  itemBuilder: (context, index) {
                    final matricula = _matriculas[index];
                    return _buildMatriculaCard(matricula);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[700],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Text(
                  _getInitials(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.estudiante['first_name'] ?? ''} ${widget.estudiante['last_name'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (widget.estudiante['curso'] != null)
                      Text(
                        'Curso: ${widget.estudiante['curso']['nombre']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Total de pagos: ${_matriculas.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatriculaCard(Map<String, dynamic> matricula) {
    final fechaPago = matricula['fecha_pago'] ?? matricula['fecha'] ?? 'No especificada';
    final monto = matricula['monto'] ?? 0.0;
    final descuento = matricula['descuento'] ?? 0.0;
    final montoFinal = monto - descuento;
    final vigente = matricula['vigente'] ?? false;
    final estado = matricula['estado'] ?? false;

    Color estadoColor = Colors.green;
    IconData estadoIcon = Icons.check_circle;
    String estadoTexto = 'Vigente';
    
    // Manejar el estado correctamente (puede ser booleano o string)
    if (vigente) {
      estadoColor = Colors.green;
      estadoIcon = Icons.check_circle;
      estadoTexto = 'Vigente';
    } else {
      estadoColor = Colors.orange;
      estadoIcon = Icons.warning;
      estadoTexto = 'Vencido';
    }
    
    // Si estado es false (inactivo), cambiar a rojo
    if (estado == false || estado == 'inactiva') {
      estadoColor = Colors.red;
      estadoIcon = Icons.cancel;
      estadoTexto = 'Inactivo';
    }

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header de la matrícula
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(estadoIcon, size: 14, color: estadoColor),
                      const SizedBox(width: 4),
                      Text(
                        estadoTexto,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: estadoColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'Bs. ${montoFinal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Detalles de la matrícula
            _buildDetalleRow(Icons.calendar_today, 'Fecha de pago', fechaPago),
            if (matricula['tipo_pago'] != null)
              _buildDetalleRow(Icons.payment, 'Tipo de pago', matricula['tipo_pago']['nombre'] ?? 'No especificado'),
            if (matricula['metodo_pago'] != null)
              _buildDetalleRow(Icons.credit_card, 'Método de pago', matricula['metodo_pago']['nombre'] ?? 'No especificado'),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            // Resumen de montos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Monto:', style: TextStyle(color: Colors.grey[600])),
                Text('Bs. ${monto.toStringAsFixed(2)}'),
              ],
            ),
            if (descuento > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Descuento:', style: TextStyle(color: Colors.grey[600])),
                  Text('- Bs. ${descuento.toStringAsFixed(2)}', style: TextStyle(color: Colors.green[600])),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Bs. ${montoFinal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalleRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials() {
    final firstName = widget.estudiante['first_name']?.toString() ?? '';
    final lastName = widget.estudiante['last_name']?.toString() ?? '';
    
    String initials = '';
    if (firstName.isNotEmpty) initials += firstName[0];
    if (lastName.isNotEmpty) initials += lastName[0];
    
    return initials.isEmpty ? 'E' : initials.toUpperCase();
  }
} 