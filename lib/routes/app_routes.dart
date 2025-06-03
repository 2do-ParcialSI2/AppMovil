import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../pages/login_page.dart';
import '../pages/home_page.dart';
import '../pages/profile_page.dart';
import '../pages/splash_page.dart';
import '../pages/estudiante_dashboard_page.dart';
import '../pages/padre_tutor_dashboard_page.dart';
import '../pages/materia_detalle_page.dart';

class AppRoutes {
  // Nombres de las rutas
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String estudianteDashboard = '/estudiante';
  static const String padreTutorDashboard = '/padre-tutor';
  static const String profile = '/home/profile';
  static const String estudianteProfile = '/estudiante/profile';
  static const String padreTutorProfile = '/padre-tutor/profile';

  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: splash,
      routes: [
        // Ruta de splash/carga inicial
        GoRoute(
          path: splash,
          name: 'splash',
          builder: (context, state) => const SplashPage(),
        ),
        
        // Ruta de login
        GoRoute(
          path: login,
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        
        // Ruta principal para administradores (requiere autenticación)
        GoRoute(
          path: home,
          name: 'home',
          builder: (context, state) => const HomePage(),
          routes: [
            // Subrutas para admin
            GoRoute(
              path: 'profile',
              name: 'profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
        
        // Ruta para dashboard de estudiante
        GoRoute(
          path: estudianteDashboard,
          name: 'estudiante-dashboard',
          builder: (context, state) => const EstudianteDashboardPage(),
          routes: [
            // Subrutas para estudiante
            GoRoute(
              path: 'profile',
              name: 'estudiante-profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
        
        // Ruta para dashboard de padre/tutor
        GoRoute(
          path: padreTutorDashboard,
          name: 'padre-tutor-dashboard',
          builder: (context, state) => const PadreTutorDashboardPage(),
          routes: [
            // Subrutas para padre/tutor
            GoRoute(
              path: 'profile',
              name: 'padre-tutor-profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
      
      // Redirección basada en el estado de autenticación y rol
      redirect: (context, state) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final isAuthenticated = authProvider.isAuthenticated;
        final isInitial = authProvider.status == AuthStatus.initial;
        final currentPath = state.fullPath;
        
        // Si estamos en el estado inicial, mostrar splash
        if (isInitial) {
          return splash;
        }
        
        // Si no está autenticado y no está en login, redirigir a login
        if (!isAuthenticated && currentPath != login) {
          return login;
        }
        
        // Si está autenticado y está en login o splash, redirigir según el rol
        if (isAuthenticated && (currentPath == login || currentPath == splash)) {
          return _getDashboardByRole(authProvider);
        }
        
        // Verificar que el usuario esté en el dashboard correcto según su rol
        if (isAuthenticated && currentPath != login && currentPath != splash) {
          final expectedDashboard = _getDashboardByRole(authProvider);
          
          // Si está en un dashboard pero no es el correcto para su rol
          if ((currentPath?.startsWith('/home') == true && expectedDashboard != home) ||
              (currentPath?.startsWith('/estudiante') == true && expectedDashboard != estudianteDashboard) ||
              (currentPath?.startsWith('/padre-tutor') == true && expectedDashboard != padreTutorDashboard)) {
            return expectedDashboard;
          }
        }
        
        // No hay redirección necesaria
        return null;
      },
      
      // Manejar errores de navegación
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
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
                'Página no encontrada',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'La página "${state.fullPath}" no existe.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(home),
                child: const Text('Ir al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Obtener la ruta del dashboard según el rol del usuario
  static String _getDashboardByRole(AuthProvider authProvider) {
    final user = authProvider.currentUser;
    
    if (user == null) {
      return login;
    }

    // Verificar el rol del usuario y redirigir al dashboard correspondiente
    if (user.isEstudiante) {
      print('🎒 AppRoutes: Usuario es estudiante, redirigiendo a dashboard estudiantil');
      return estudianteDashboard;
    } else if (user.isPadreTutor) {
      print('👨‍👩‍👧‍👦 AppRoutes: Usuario es padre/tutor, redirigiendo a dashboard de padre/tutor');
      return padreTutorDashboard;
    } else if (user.isDocente) {
      print('👨‍🏫 AppRoutes: Usuario es docente, redirigiendo a dashboard administrativo');
      return home; // Por ahora docentes van al mismo dashboard que admin
    } else {
      print('👑 AppRoutes: Usuario es admin o sin rol específico, redirigiendo a dashboard administrativo');
      return home;
    }
  }
}

// Extension para facilitar la navegación
extension AppNavigation on BuildContext {
  void goToLogin() => go(AppRoutes.login);
  void goToHome() => go(AppRoutes.home);
  void goToProfile() => go(AppRoutes.profile);
  void goToEstudianteDashboard() => go(AppRoutes.estudianteDashboard);
  void goToEstudianteProfile() => go(AppRoutes.estudianteProfile);
  void goToPadreTutorDashboard() => go(AppRoutes.padreTutorDashboard);
  void goToPadreTutorProfile() => go(AppRoutes.padreTutorProfile);
  
  /// Navegar al dashboard apropiado según el rol del usuario
  void goToDashboard() {
    final authProvider = Provider.of<AuthProvider>(this, listen: false);
    final dashboard = AppRoutes._getDashboardByRole(authProvider);
    go(dashboard);
  }
} 