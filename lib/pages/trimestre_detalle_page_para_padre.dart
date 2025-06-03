import 'package:flutter/material.dart';
import '../models/seguimiento_models.dart';

class TrimestreDetallePageParaPadre extends StatefulWidget {
  final SeguimientoDetallado seguimiento;
  final Map<String, dynamic> estudiante;

  const TrimestreDetallePageParaPadre({
    super.key,
    required this.seguimiento,
    required this.estudiante,
  });

  @override
  State<TrimestreDetallePageParaPadre> createState() => _TrimestreDetallePageParaPadreState();
}

class _TrimestreDetallePageParaPadreState extends State<TrimestreDetallePageParaPadre> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.seguimiento.trimestreNombre}'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header con información del estudiante y materia
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.orange[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información del estudiante
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.orange[100],
                      child: Text(
                        _getInitials(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.estudiante['first_name']} ${widget.estudiante['last_name']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.estudiante['curso'] != null)
                            Text(
                              'Curso: ${widget.estudiante['curso']['nombre']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Indicador de vista para padre
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.family_restroom, size: 12, color: Colors.orange[700]),
                          const SizedBox(width: 4),
                          Text(
                            'Vista Padre',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Información de la materia y trimestre
                Text(
                  widget.seguimiento.materiaNombre,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.seguimiento.trimestreNombre,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Prof. ${widget.seguimiento.docenteCompleto}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Resumen de calificaciones
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
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
            child: Column(
              children: [
                Text(
                  'Nota Trimestral',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.seguimiento.notaTrimestral.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: _getColorForNota(widget.seguimiento.notaTrimestral),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'de 100 puntos',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 16),
                // Breakdown de componentes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildComponenteNota('Tareas\n(25%)', widget.seguimiento.promedioTareas),
                    _buildComponenteNota('Participación\n(15%)', widget.seguimiento.promedioParticipaciones),
                    _buildComponenteNota('Exámenes\n(50%)', widget.seguimiento.promedioExamenes),
                    _buildComponenteAsistencia('Asistencia\n(10%)', widget.seguimiento.porcentajeAsistencia),
                  ],
                ),
              ],
            ),
          ),
          // Lista de actividades
          Expanded(
            child: DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  TabBar(
                    labelColor: Colors.orange[700],
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.orange[700],
                    tabs: const [
                      Tab(text: 'Tareas'),
                      Tab(text: 'Participación'),
                      Tab(text: 'Asistencia'),
                      Tab(text: 'Exámenes'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildTareasTab(),
                        _buildParticipacionesTab(),
                        _buildAsistenciasTab(),
                        _buildExamenesTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponenteNota(String label, double promedio) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          promedio > 0 ? promedio.toStringAsFixed(1) : 'S/D',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: promedio > 0 ? _getColorForNota(promedio) : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildComponenteAsistencia(String label, double porcentaje) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          porcentaje > 0 ? '${porcentaje.toStringAsFixed(1)}%' : 'S/D',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: porcentaje > 0 ? _getColorForAsistencia(porcentaje) : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTareasTab() {
    final tareas = widget.seguimiento.tareas ?? [];
    if (tareas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay tareas registradas'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tareas.length,
      itemBuilder: (context, index) {
        final tarea = tareas[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getColorForNota(tarea.notaTarea),
              child: Text(
                tarea.notaTarea.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text(tarea.titulo ?? 'Tarea sin título'),
            subtitle: Text(tarea.descripcion ?? 'Sin descripción'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tarea.fechaFormateada,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${tarea.notaTarea}/100',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getColorForNota(tarea.notaTarea),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticipacionesTab() {
    final participaciones = widget.seguimiento.participaciones ?? [];
    if (participaciones.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.record_voice_over, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay participaciones registradas'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: participaciones.length,
      itemBuilder: (context, index) {
        final participacion = participaciones[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getColorForNota(participacion.notaParticipacion),
              child: Text(
                participacion.notaParticipacion.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            title: const Text('Participación en clase'),
            subtitle: Text(participacion.descripcion ?? 'Sin descripción'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  participacion.fechaFormateada,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${participacion.notaParticipacion}/100',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getColorForNota(participacion.notaParticipacion),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAsistenciasTab() {
    final asistencias = widget.seguimiento.asistencias ?? [];
    if (asistencias.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay asistencias registradas'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: asistencias.length,
      itemBuilder: (context, index) {
        final asistencia = asistencias[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: asistencia.asistencia ? Colors.green : Colors.red,
              child: Icon(
                asistencia.asistencia ? Icons.check : Icons.close,
                color: Colors.white,
              ),
            ),
            title: Text(asistencia.fechaFormateada),
            subtitle: Text(asistencia.estadoTexto),
            trailing: null, // Sin campo justificada en el modelo actual
          ),
        );
      },
    );
  }

  Widget _buildExamenesTab() {
    final examenes = widget.seguimiento.examenes ?? [];
    if (examenes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay exámenes registrados'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: examenes.length,
      itemBuilder: (context, index) {
        final examen = examenes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getColorForNota(examen.notaExamen),
              child: Text(
                examen.notaExamen.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text(examen.tipoExamenNombre ?? 'Examen'),
            subtitle: Text(examen.observaciones ?? 'Sin observaciones'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  examen.fechaFormateada,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${examen.notaExamen}/100',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getColorForNota(examen.notaExamen),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getColorForNota(double nota) {
    if (nota >= 80) return Colors.green;
    if (nota >= 70) return Colors.orange;
    if (nota >= 60) return Colors.amber;
    return Colors.red;
  }

  Color _getColorForAsistencia(double porcentaje) {
    if (porcentaje >= 90) return Colors.green;
    if (porcentaje >= 80) return Colors.orange;
    if (porcentaje >= 70) return Colors.amber;
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
} 