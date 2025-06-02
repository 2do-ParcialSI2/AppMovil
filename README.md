# Sistema Educativo Móvil 📱📚

Una aplicación móvil Flutter integrada con backend Django para gestión educativa completa.

## ✨ Características Principales

### 🔐 Autenticación
- Login con email y contraseña
- Autenticación JWT con tokens de acceso y refresh
- Almacenamiento seguro local con SharedPreferences
- Gestión automática de roles de usuario

### 👥 Roles del Sistema
- **Administrador**: Acceso completo al dashboard administrativo
- **Docente**: Gestión de materias y seguimiento de estudiantes
- **Estudiante**: Dashboard personalizado con materias y calificaciones
- **Padre/Tutor**: Seguimiento del progreso de estudiantes

### 🎓 Dashboard de Estudiante
- **Vista de Materias**: Lista completa de materias del estudiante
- **Información del Docente**: Datos del profesor de cada materia
- **Estadísticas por Materia**: Contadores de tareas, participaciones, etc.
- **Navegación Intuitiva**: Acceso rápido a detalles de cada materia

### 📊 Detalle de Materias (4 Secciones)

#### 📝 Tareas
- Lista completa de tareas asignadas
- Fecha de entrega y descripción
- Calificaciones obtenidas
- Estado visual por color según nota

#### 🗣️ Participación en Clase
- Registro de participaciones diarias
- Puntuación por participación
- Comentarios del docente
- Historial cronológico

#### ✅ Control de Asistencias
- **Resumen estadístico** con porcentaje de asistencia
- Registro día por día (Presente/Ausente)
- Indicadores visuales por color
- Cálculo automático de porcentajes

#### 📋 Exámenes
- Lista de todos los exámenes realizados
- Tipos de examen (Parcial, Final, Quiz, etc.)
- Calificaciones obtenidas
- Observaciones del docente

## 🏗️ Arquitectura del Sistema

### 📱 Frontend (Flutter)
```
lib/
├── config/           # Configuración de API
├── models/           # Modelos de datos
├── pages/            # Páginas de la aplicación
├── providers/        # State management (Provider)
├── routes/           # Navegación (GoRouter)
├── services/         # Servicios API
└── widgets/          # Componentes reutilizables
```

### 🗂️ Modelos Principales
- **User**: Usuario del sistema con roles
- **Estudiante**: Datos específicos del estudiante
- **EstudianteMateria**: Materias asignadas al estudiante
- **Seguimiento**: Seguimiento académico por materia
- **Tarea, Participacion, Asistencia, Examen**: Actividades académicas

### 🔌 Servicios
- **AuthService**: Autenticación y gestión de tokens
- **ApiService**: Cliente HTTP con manejo de errores
- **SeguimientoService**: CRUD para actividades académicas
- **BackendService**: Operaciones generales del backend

## 🚀 Configuración e Instalación

### Requisitos Previos
- Flutter SDK 3.x
- Dart SDK
- Android Studio / VS Code
- Dispositivo Android o emulador

### Backend Django
```bash
# El backend debe estar ejecutándose en:
http://localhost:8001/api
```

### Instalación de la App
```bash
# 1. Clonar el repositorio
git clone [repository-url]
cd se_movil_app

# 2. Instalar dependencias
flutter pub get

# 3. Ejecutar la aplicación
flutter run
```

## 📋 Dependencias Principales

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.1.2
  
  # Navegación
  go_router: ^14.6.1
  
  # HTTP y Almacenamiento
  http: ^1.2.2
  shared_preferences: ^2.3.2
  
  # UI
  cupertino_icons: ^1.0.8
```

## 🔧 Configuración de API

### Endpoints del Backend
```dart
// config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:8001/api';
  static const String loginEndpoint = '/login/';
  static const String logoutEndpoint = '/logout/';
  static const String refreshTokenEndpoint = '/token/refresh/';
}
```

### Autenticación JWT
- **Access Token**: 2 horas de validez
- **Refresh Token**: 1 día de validez
- **Header**: `Authorization: Bearer <token>`

## 📱 Flujo de Usuario

### 1. Autenticación
1. Splash screen con carga inicial
2. Login con email/contraseña
3. Validación y obtención de tokens
4. Redirección según rol del usuario

### 2. Dashboard de Estudiante
1. Carga automática de materias del estudiante
2. Visualización de lista de materias con estadísticas
3. Navegación a detalle de materia específica

### 3. Detalle de Materia
1. Carga paralela de 4 tipos de datos:
   - Tareas asignadas
   - Participaciones registradas
   - Asistencias tomadas
   - Exámenes aplicados
2. Navegación por tabs
3. Refresh manual en cada sección

## 🎨 Diseño y UX

### Paleta de Colores
- **Primario**: Azul (#2196F3)
- **Tareas**: Azul claro
- **Participación**: Verde
- **Asistencias**: Azul índigo
- **Exámenes**: Púrpura

### Iconografía
- Material Design Icons
- Iconos específicos por tipo de materia
- Estados visuales por color (notas, asistencias)

### Responsive Design
- Adaptado para diferentes tamaños de pantalla
- Cards responsivas
- Typography escalable

## 🔒 Seguridad

### Autenticación
- Tokens JWT seguros
- Refresh automático de tokens
- Logout automático en caso de error
- Validación de sesión al iniciar

### Almacenamiento
- SharedPreferences para datos locales
- No almacenamiento de contraseñas
- Limpieza automática al logout

## 🐛 Manejo de Errores

### Conexión de Red
- Detección de falta de internet
- Mensajes user-friendly
- Botones de reintentar

### Errores de API
- Parsing automático de errores del backend
- Logging detallado para debugging
- Fallbacks gracefuls

### Estados de Carga
- Indicadores de progreso
- Estados vacíos informativos
- Refresh manual disponible

## 📊 Estado del Proyecto

### ✅ Completado
- [x] Autenticación completa
- [x] Dashboard de estudiante
- [x] Detalle de materias con 4 tabs
- [x] Modelos y servicios completos
- [x] Navegación y routing
- [x] Manejo de estados y errores
- [x] UI/UX moderna y funcional

### 🚧 Pendiente de Backend
- [ ] Endpoints de seguimiento académico
- [ ] Datos de prueba en el backend
- [ ] Testing completo con datos reales

## 🤝 Contribución

Para contribuir al proyecto:

1. Fork el repositorio
2. Crear branch para feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit cambios (`git commit -am 'Agregar nueva funcionalidad'`)
4. Push al branch (`git push origin feature/nueva-funcionalidad`)
5. Crear Pull Request

## 📞 Soporte

Para soporte técnico o preguntas:
- Crear issue en GitHub
- Contactar al equipo de desarrollo

---

**Versión**: 1.0.0
**Última actualización**: Enero 2025
**Licencia**: MIT
