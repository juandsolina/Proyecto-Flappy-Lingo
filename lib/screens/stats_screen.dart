import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, int> correct = {};
  Map<String, int> incorrect = {};
  List<String> categories = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final detectedCategories = <String>{};

    for (final key in keys) {
      if (key.startsWith('correct_')) {
        detectedCategories.add(key.substring('correct_'.length));
      }
      if (key.startsWith('incorrect_')) {
        detectedCategories.add(key.substring('incorrect_'.length));
      }
    }

    final sortedCategories = detectedCategories.toList()..sort();

    setState(() {
      categories = sortedCategories;
      for (final c in categories) {
        correct[c] = prefs.getInt('correct_$c') ?? 0;
        incorrect[c] = prefs.getInt('incorrect_$c') ?? 0;
      }
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : categories.isEmpty
              ? const Center(
                  child: Text(
                    'Aún no hay estadísticas guardadas.',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final cat in categories) _buildCard(cat),
                  ],
                ),
    );
  }

  Widget _buildCard(String category) {
    final c = correct[category] ?? 0;
    final i = incorrect[category] ?? 0;
    final total = c + i;
    final pct = total == 0 ? 0.0 : c / total;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category.toUpperCase(),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('✅ Correctas: $c'),
                Text('❌ Incorrectas: $i'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: pct, minHeight: 8),
            const SizedBox(height: 4),
            Text('${(pct * 100).toStringAsFixed(0)}% de acierto'),
          ],
        ),
      ),
    );
  }
}
