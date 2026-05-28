import 'package:flutter/material.dart';
import '../data/session_repository.dart';
import '../screens/deck_selection_screen.dart';
import '../screens/login_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/stats_screen.dart';
import '../screens/profile_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _session = SessionRepository();
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _session.getUser();
    if (mounted) setState(() => _userName = user?.name ?? '');
  }

  Future<void> _logout() async {
    await _session.clearSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _navigate(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF87CEEB), Color(0xFF4A90D9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),

              // ── Header ──────────────────────────────────────
              const Text('🐦', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 8),
              const Text(
                'Flappy Lingo',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 6, color: Colors.black26)],
                ),
              ),
              if (_userName.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Hola, $_userName 👋',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],

              const SizedBox(height: 48),

              // ── Botones ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    _MenuButton(
                      icon: '🎮',
                      label: 'Jugar',
                      color: const Color(0xFF1565C0),
                      onTap: () => _navigate(const DeckSelectionScreen()),
                    ),
                    const SizedBox(height: 16),
                    _MenuButton(
                      icon: '🏆',
                      label: 'Leaderboard',
                      color: const Color(0xFFE65100),
                      onTap: () => _navigate(const LeaderboardScreen()),
                    ),
                    const SizedBox(height: 16),
                    _MenuButton(
                      icon: '📊',
                      label: 'Estadísticas',
                      color: const Color(0xFF2E7D32),
                      onTap: () => _navigate(const StatsScreen()),
                    ),
                    const SizedBox(height: 16),
                    _MenuButton(
                      icon: '👤',
                      label: 'Perfil',
                      color: const Color(0xFF6A1B9A),
                      onTap: () => _navigate(const ProfileScreen()),
                    ),
                    const SizedBox(height: 32),
                    // Cerrar sesión
                    TextButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.white70),
                      label: const Text(
                        'Cerrar sesión',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
