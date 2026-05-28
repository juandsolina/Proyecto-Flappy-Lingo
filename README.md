# Proyecto Flappy Lingo

Flappy Lingo es una aplicacion educativa que combina mecanicas tipo Flappy Bird con preguntas de vocabulario espanol-ingles.

El jugador avanza esquivando tuberias y responde retos de traduccion en tiempo real para sumar puntos extra y conservar vidas.

## Objetivo del proyecto

- Gamificar el aprendizaje de ingles con partidas cortas y repetibles.
- Medir progreso por usuario y por categoria de vocabulario.
- Integrar generacion de preguntas con IA, manteniendo fallback local si el backend no responde.

## Funcionalidades principales

- Registro e inicio de sesion con validaciones de email y contrasena.
- Persistencia de sesion en el cliente movil para auto-login.
- Menu principal con acceso a juego, leaderboard, estadisticas y perfil.
- Seleccion de mazos/categorias: verbs, animals, travel y food.
- Gameplay con fisica de salto, colisiones, puntaje y sistema de 3 vidas.
- Preguntas de vocabulario durante la partida con feedback de respuesta correcta/incorrecta.
- Bonus de puntaje por aciertos.
- Guardado de progreso en backend al terminar la partida.
- Leaderboard global (top N puntajes).
- Estadisticas locales por categoria (correctas/incorrectas) en el dispositivo.
- Endpoint de vocabulario adicional generado por IA para futuras dinamicas de estudio.

## Arquitectura general

El repositorio esta dividido en dos componentes:

- Frontend mobile/web en Flutter dentro de la raiz del proyecto.
- Backend API en Python FastAPI en la carpeta flappy_lingo_backend.

Flujo simplificado:

1. Usuario inicia sesion desde Flutter.
2. Backend autentica y devuelve JWT.
3. Flutter juega y consulta preguntas al endpoint de IA.
4. Al finalizar, Flutter envia score/progreso autenticado.
5. Backend actualiza progreso y leaderboard en SQLite.

## Tecnologias utilizadas

### Frontend

- Flutter (Dart 3)
- Material UI
- Paquete http para consumo de API REST
- shared_preferences para sesion y estadisticas locales
- mocktail para pruebas

### Backend

- Python 3
- FastAPI + Uvicorn
- SQLite
- python-jose para JWT
- passlib (pbkdf2_sha256) para hash seguro de contrasenas
- python-dotenv para configuracion por entorno

### IA / contenido dinamico

- Integracion principal con Groq (chat completions JSON)
- Soporte de librerias de Google Generative AI (dependencias presentes)
- Fallback local de preguntas y vocabulario cuando falla IA o conectividad

## Endpoints principales del backend

- POST /api/auth/register
- POST /api/auth/login
- POST /api/progress/save (requiere Bearer token)
- GET /api/leaderboard
- GET /api/v1/question
- GET /api/v1/questions-batch
- POST /api/ai/vocabulary (requiere Bearer token)

## Estructura resumida

- lib/: app Flutter (juego, pantallas, repositorios, modelos)
- test/: pruebas unitarias y de widgets
- flappy_lingo_backend/routes/: rutas API
- flappy_lingo_backend/services/: logica de negocio e integraciones IA
- flappy_lingo_backend/database/: conexion e inicializacion SQLite

## Configuracion y ejecucion local

### 1) Backend

Ubicate en flappy_lingo_backend y crea un entorno virtual:

PowerShell:

python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt

Ejecuta la API:

python main.py

La API corre por defecto en http://0.0.0.0:8000

Variables recomendadas en archivo .env dentro de flappy_lingo_backend:

- JWT_SECRET
- JWT_ALGORITHM=HS256
- JWT_EXPIRE_MINUTES=10080
- GROQ_API_KEY
- GROQ_MODEL (opcional)
- FLAPPY_DB_DIR (opcional)

### 2) Flutter

Desde la raiz del proyecto:

flutter pub get
flutter run

Si necesitas cambiar la URL del backend:

flutter run --dart-define=API_BASE_URL=http://IP_LOCAL:8000

Tambien puedes usar:

- API_SCHEME
- API_HOST
- API_PORT

## Pruebas

El proyecto incluye pruebas en la carpeta test.

Ejecutar:

flutter test

## Estado actual

- Juego funcional con autenticacion y progreso.
- Backend funcional con SQLite y JWT.
- Integracion IA con fallback para robustez.

## Equipo

Proyecto-Flappy-Lingo - Juan David Solina.
