# Configuración Django para dispositivos móviles

## ⚡ URGENTE: Configurar Django para aceptar conexiones externas

Para que tu dispositivo móvil pueda conectarse a tu backend Django, necesitas hacer estos cambios:

### 1. Modifica settings.py de Django

```python
# En tu archivo settings.py de Django, cambia ALLOWED_HOSTS:

# ❌ ANTES (solo localhost):
ALLOWED_HOSTS = ['localhost', '127.0.0.1']

# ✅ DESPUÉS (acepta conexiones de la red local):
ALLOWED_HOSTS = [
    'localhost', 
    '127.0.0.1',
    '192.168.0.5',  # ⬅️ Cambia por TU IP real
    '0.0.0.0',      # Acepta todas las IPs (solo para desarrollo)
]
```

### 2. Ejecuta Django con la IP específica

En lugar de:
```bash
python manage.py runserver
```

Usa:
```bash
python manage.py runserver 0.0.0.0:8001
```

Esto hará que Django escuche en todas las interfaces de red.

### 3. Configura CORS si usas django-cors-headers

Si tienes configurado CORS, asegúrate de permitir tu IP:

```python
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://192.168.0.5:3000",  # ⬅️ Tu IP
]

# O para desarrollo, permite todas:
CORS_ALLOW_ALL_ORIGINS = True  # Solo para desarrollo
```

### 4. Pasos para encontrar tu IP real:

#### Windows:
1. Abre "Símbolo del sistema" (cmd)
2. Escribe: `ipconfig`
3. Busca "Adaptador de LAN inalámbrica Wi-Fi"
4. Anota la "Dirección IPv4" (ejemplo: 192.168.1.105)

#### Alternativa Windows:
1. Windows + R > escribe "cmd"
2. `ipconfig | findstr /i "IPv4"`

### 5. Actualiza Flutter con tu IP real

En `lib/config/api_config.dart`, cambia:
```dart
static const String baseUrl = 'http://TU_IP_REAL:8001/api';
```

Ejemplo:
```dart
static const String baseUrl = 'http://192.168.1.105:8001/api';
```

### 6. Verificación

1. Asegúrate de que tu computadora y dispositivo móvil estén en la misma red Wi-Fi
2. Ejecuta Django: `python manage.py runserver 0.0.0.0:8001`
3. Desde tu dispositivo, abre un navegador y ve a: `http://TU_IP:8001/api/usuarios/`
4. Deberías ver una respuesta JSON (aunque requiera autenticación)

## 🔥 Próximos pasos:

1. Encuentra tu IP real con `ipconfig`
2. Modifica Django settings.py
3. Ejecuta Django con `python manage.py runserver 0.0.0.0:8001`
4. Actualiza la IP en Flutter
5. Prueba el login desde la app

¡Con estos cambios debería funcionar perfectamente! 🚀 