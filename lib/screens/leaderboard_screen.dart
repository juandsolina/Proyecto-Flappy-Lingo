import 'package:flutter/material.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  static const List<Map<String, dynamic>> _mockData = [
    {'name': 'Carlos M.', 'score': 142},
    {'name': 'Sofía R.', 'score': 128},
    {'name': 'Andrés P.', 'score': 115},
    {'name': 'Valentina G.', 'score': 98},
    {'name': 'Juan D.', 'score': 87},
    {'name': 'Isabella T.', 'score': 74},
    {'name': 'Sebastián L.', 'score': 61},
    {'name': 'Camila H.', 'score': 53},
    {'name': 'Miguel F.', 'score': 41},
    {'name': 'Laura B.', 'score': 30},
  ];

  @override
  Widget build(BuildContext context) {
    final medals = ['🥇', '🥈', '🥉'];

    return Scaffold(
      backgroundColor: const Color(0xFF87CEEB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          '🏆 Leaderboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _mockData.length,
        itemBuilder: (context, i) {
          final e = _mockData[i];
          final medal = i < 3 ? medals[i] : '${i + 1}.';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: i == 0 ? const Color(0xFFFFF9C4) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(medal, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    e['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${e['score']} pts',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
