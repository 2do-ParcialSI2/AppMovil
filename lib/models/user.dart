class User {
  final int id;
  final String email;  // Campo principal (no username)
  final String firstName;
  final String lastName;
  final String? genero;  // M o F
  final bool activo;
  final List<int> roles;  // IDs de roles como en tu response
  
  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.genero,
    required this.activo,
    required this.roles,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      genero: json['genero'],
      activo: json['activo'] ?? true,
      roles: List<int>.from(json['roles'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'genero': genero,
      'activo': activo,
      'roles': roles,
    };
  }

  // Método para obtener el nombre completo
  String get fullName => '$firstName $lastName'.trim();
  
  // Método para verificar si tiene un rol específico (por ID)
  bool hasRoleId(int roleId) => roles.contains(roleId);
  
  // Métodos útiles para roles conocidos (según tu sistema)
  bool get isAdmin => hasRoleId(1); // Asumiendo que 1 es ADMINISTRADOR
  bool get isDocente => roles.any((role) => role == 2); // Ajustar según tu BD
  bool get isEstudiante => roles.any((role) => role == 3); // Ajustar según tu BD
  bool get isPadreTutor => roles.any((role) => role == 4); // Ajustar según tu BD
  
  // Getter para género formateado
  String get generoCompleto {
    switch (genero) {
      case 'M':
        return 'Masculino';
      case 'F':
        return 'Femenino';
      default:
        return 'No especificado';
    }
  }
} 