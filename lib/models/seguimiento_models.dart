class Seguimiento {
  final int id;
  final int materiaCursoId;
  final int trimestreId;
  final int estudianteId;
  final double notaTrimestral;
  final String? resumenNota;
  final int totalAsistencias;
  final int totalTareas;
  final int totalParticipaciones;
  final int totalExamenes;

  Seguimiento({
    required this.id,
    required this.materiaCursoId,
    required this.trimestreId,
    required this.estudianteId,
    required this.notaTrimestral,
    this.resumenNota,
    required this.totalAsistencias,
    required this.totalTareas,
    required this.totalParticipaciones,
    required this.totalExamenes,
  });

  factory Seguimiento.fromJson(Map<String, dynamic> json) {
    return Seguimiento(
      id: json['id'] ?? 0,
      materiaCursoId: json['materia_curso'] ?? 0,
      trimestreId: json['trimestre'] ?? 0,
      estudianteId: json['estudiante'] ?? 0,
      notaTrimestral: (json['nota_trimestral'] ?? 0.0).toDouble(),
      resumenNota: json['resumen_nota'],
      totalAsistencias: json['total_asistencias'] ?? 0,
      totalTareas: json['total_tareas'] ?? 0,
      totalParticipaciones: json['total_participaciones'] ?? 0,
      totalExamenes: json['total_examenes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'materia_curso': materiaCursoId,
      'trimestre': trimestreId,
      'estudiante': estudianteId,
      'nota_trimestral': notaTrimestral,
      'resumen_nota': resumenNota,
      'total_asistencias': totalAsistencias,
      'total_tareas': totalTareas,
      'total_participaciones': totalParticipaciones,
      'total_examenes': totalExamenes,
    };
  }
}

class SeguimientoDetallado {
  final int id;
  final double notaTrimestral;
  final String estudianteNombre;
  final String estudianteApellido;
  final String materiaNombre;
  final String cursoNombre;
  final String trimestreNombre;
  final String docenteNombre;
  final String docenteApellido;

  SeguimientoDetallado({
    required this.id,
    required this.notaTrimestral,
    required this.estudianteNombre,
    required this.estudianteApellido,
    required this.materiaNombre,
    required this.cursoNombre,
    required this.trimestreNombre,
    required this.docenteNombre,
    required this.docenteApellido,
  });

  factory SeguimientoDetallado.fromJson(Map<String, dynamic> json) {
    return SeguimientoDetallado(
      id: json['id'] ?? 0,
      notaTrimestral: (json['nota_trimestral'] ?? 0.0).toDouble(),
      estudianteNombre: json['estudiante_nombre'] ?? '',
      estudianteApellido: json['estudiante_apellido'] ?? '',
      materiaNombre: json['materia_nombre'] ?? '',
      cursoNombre: json['curso_nombre'] ?? '',
      trimestreNombre: json['trimestre_nombre'] ?? '',
      docenteNombre: json['docente_nombre'] ?? '',
      docenteApellido: json['docente_apellido'] ?? '',
    );
  }

  String get nombreCompleto => '$estudianteNombre $estudianteApellido';
  String get docenteCompleto => '$docenteNombre $docenteApellido';
}

class Tarea {
  final int id;
  final int seguimientoId;
  final DateTime fecha;
  final double notaTarea;
  final String? titulo;
  final String? descripcion;
  final String? estudianteNombre;

  Tarea({
    required this.id,
    required this.seguimientoId,
    required this.fecha,
    required this.notaTarea,
    this.titulo,
    this.descripcion,
    this.estudianteNombre,
  });

  factory Tarea.fromJson(Map<String, dynamic> json) {
    return Tarea(
      id: json['id'] ?? 0,
      seguimientoId: json['seguimiento'] ?? 0,
      fecha: DateTime.parse(json['fecha']),
      notaTarea: (json['nota_tarea'] ?? 0.0).toDouble(),
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      estudianteNombre: json['estudiante_nombre'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seguimiento': seguimientoId,
      'fecha': fecha.toIso8601String().split('T')[0],
      'nota_tarea': notaTarea,
      'titulo': titulo,
      'descripcion': descripcion,
      'estudiante_nombre': estudianteNombre,
    };
  }

  String get fechaFormateada {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}

class Participacion {
  final int id;
  final int seguimientoId;
  final DateTime fechaParticipacion;
  final double notaParticipacion;
  final String? descripcion;
  final String? estudianteNombre;

  Participacion({
    required this.id,
    required this.seguimientoId,
    required this.fechaParticipacion,
    required this.notaParticipacion,
    this.descripcion,
    this.estudianteNombre,
  });

  factory Participacion.fromJson(Map<String, dynamic> json) {
    return Participacion(
      id: json['id'] ?? 0,
      seguimientoId: json['seguimiento'] ?? 0,
      fechaParticipacion: DateTime.parse(json['fecha_participacion']),
      notaParticipacion: (json['nota_participacion'] ?? 0.0).toDouble(),
      descripcion: json['descripcion'],
      estudianteNombre: json['estudiante_nombre'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seguimiento': seguimientoId,
      'fecha_participacion': fechaParticipacion.toIso8601String().split('T')[0],
      'nota_participacion': notaParticipacion,
      'descripcion': descripcion,
      'estudiante_nombre': estudianteNombre,
    };
  }

  String get fechaFormateada {
    return '${fechaParticipacion.day}/${fechaParticipacion.month}/${fechaParticipacion.year}';
  }
}

class Asistencia {
  final int id;
  final int seguimientoId;
  final DateTime fecha;
  final bool asistencia;
  final String? estudianteNombre;

  Asistencia({
    required this.id,
    required this.seguimientoId,
    required this.fecha,
    required this.asistencia,
    this.estudianteNombre,
  });

  factory Asistencia.fromJson(Map<String, dynamic> json) {
    return Asistencia(
      id: json['id'] ?? 0,
      seguimientoId: json['seguimiento'] ?? 0,
      fecha: DateTime.parse(json['fecha']),
      asistencia: json['asistencia'] ?? false,
      estudianteNombre: json['estudiante_nombre'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seguimiento': seguimientoId,
      'fecha': fecha.toIso8601String().split('T')[0],
      'asistencia': asistencia,
      'estudiante_nombre': estudianteNombre,
    };
  }

  String get fechaFormateada {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  String get estadoTexto => asistencia ? 'Presente' : 'Ausente';
}

class TipoExamen {
  final int id;
  final String nombre;
  final String? descripcion;

  TipoExamen({
    required this.id,
    required this.nombre,
    this.descripcion,
  });

  factory TipoExamen.fromJson(Map<String, dynamic> json) {
    return TipoExamen(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
    };
  }
}

class Examen {
  final int id;
  final int seguimientoId;
  final int? tipoExamenId;
  final String? tipoExamenNombre;
  final DateTime fecha;
  final double notaExamen;
  final int? matriculaId;
  final String? observaciones;
  final String? estudianteNombre;

  Examen({
    required this.id,
    required this.seguimientoId,
    this.tipoExamenId,
    this.tipoExamenNombre,
    required this.fecha,
    required this.notaExamen,
    this.matriculaId,
    this.observaciones,
    this.estudianteNombre,
  });

  factory Examen.fromJson(Map<String, dynamic> json) {
    return Examen(
      id: json['id'] ?? 0,
      seguimientoId: json['seguimiento'] ?? 0,
      tipoExamenId: json['tipo_examen'],
      tipoExamenNombre: json['tipo_examen_nombre'],
      fecha: DateTime.parse(json['fecha']),
      notaExamen: (json['nota_examen'] ?? 0.0).toDouble(),
      matriculaId: json['matricula'],
      observaciones: json['observaciones'],
      estudianteNombre: json['estudiante_nombre'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seguimiento': seguimientoId,
      'tipo_examen': tipoExamenId,
      'tipo_examen_nombre': tipoExamenNombre,
      'fecha': fecha.toIso8601String().split('T')[0],
      'nota_examen': notaExamen,
      'matricula': matriculaId,
      'observaciones': observaciones,
      'estudiante_nombre': estudianteNombre,
    };
  }

  String get fechaFormateada {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}

class Materia {
  final int id;
  final String nombre;
  final String? descripcion;

  Materia({
    required this.id,
    required this.nombre,
    this.descripcion,
  });

  factory Materia.fromJson(Map<String, dynamic> json) {
    return Materia(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
    };
  }
}

class EstudianteMateria {
  final int seguimientoId;
  final String materiaNombre;
  final String cursoNombre;
  final String trimestreNombre;
  final String docenteCompleto;
  final double notaTrimestral;
  final int totalTareas;
  final int totalParticipaciones;
  final int totalAsistencias;
  final int totalExamenes;

  EstudianteMateria({
    required this.seguimientoId,
    required this.materiaNombre,
    required this.cursoNombre,
    required this.trimestreNombre,
    required this.docenteCompleto,
    required this.notaTrimestral,
    required this.totalTareas,
    required this.totalParticipaciones,
    required this.totalAsistencias,
    required this.totalExamenes,
  });

  factory EstudianteMateria.fromSeguimientoDetallado(SeguimientoDetallado seguimiento) {
    return EstudianteMateria(
      seguimientoId: seguimiento.id,
      materiaNombre: seguimiento.materiaNombre,
      cursoNombre: seguimiento.cursoNombre,
      trimestreNombre: seguimiento.trimestreNombre,
      docenteCompleto: seguimiento.docenteCompleto,
      notaTrimestral: seguimiento.notaTrimestral,
      totalTareas: 0, // Se debe obtener del seguimiento básico
      totalParticipaciones: 0,
      totalAsistencias: 0,
      totalExamenes: 0,
    );
  }
} 