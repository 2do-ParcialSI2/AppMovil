import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../pages/login_page.dart';
import '../pages/home_page.dart';
import '../pages/profile_page.dart';
import '../pages/splash_page.dart';

class AppRoutes {
  // Nombres de las rutas
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/home/profile';

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
        
        // Ruta principal (requiere autenticación)
        GoRoute(
          path: home,
          name: 'home',
          builder: (context, state) => const HomePage(),
          routes: [
            // Subrutas que también requieren autenticación
            GoRoute(
              path: 'profile',
              name: 'profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
      
      // Redirección basada en el estado de autenticación
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
        
        // Si está autenticado y está en login o splash, redirigir a home
        if (isAuthenticated && (currentPath == login || currentPath == splash)) {
          return home;
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
}

// Extension para facilitar la navegación
extension AppNavigation on BuildContext {
  void goToLogin() => go(AppRoutes.login);
  void goToHome() => go(AppRoutes.home);
  void goToProfile() => go(AppRoutes.profile);
} 