import 'user.dart';

// Modelo para la respuesta de login según tu backend
class AuthResponse {
  final String token;  // Solo access token en el login
  final User user;

  AuthResponse({
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
    };
  }
}

// Modelo para la request de login (email + password)
class LoginRequest {
  final String email;  // Tu backend usa email, no username
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      email: json['email'] as String,
      password: json['password'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

// Modelo para la respuesta de refresh token
class RefreshTokenResponse {
  final String access;

  RefreshTokenResponse({
    required this.access,
  });

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponse(
      access: json['access'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access': access,
    };
  }
}

// Modelo para request de refresh token
class RefreshTokenRequest {
  final String refresh;

  RefreshTokenRequest({
    required this.refresh,
  });

  factory RefreshTokenRequest.fromJson(Map<String, dynamic> json) {
    return RefreshTokenRequest(
      refresh: json['refresh'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'refresh': refresh,
    };
  }
} 