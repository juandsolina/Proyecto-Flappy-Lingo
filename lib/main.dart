import 'package:flutter/material.dart';
import 'data/session_repository.dart';
import 'screens/menu_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const FlappyLingoApp());
}

class FlappyLingoApp extends StatelessWidget {
  const FlappyLingoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flappy Lingo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'sans-serif'),
      home: const _SplashRouter(),
    );
  }
}

/// Decide si mostrar Login o el juego según si hay sesión guardada.
class _SplashRouter extends StatefulWidget {
  const _SplashRouter();

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter> {
  final _session = SessionRepository();

  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final loggedIn = await _session.isLoggedIn();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => loggedIn ? const MenuScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla de splash mientras verifica sesión
    return const Scaffold(
      backgroundColor: Color(0xFF87CEEB),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🐦', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
