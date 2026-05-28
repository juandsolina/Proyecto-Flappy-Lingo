import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flappy_lingo/main.dart';

void main() {
  testWidgets('Game loads without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const FlappyLingoApp());
    // Solo verifica que el widget principal se renderiza sin esperar animaciones
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
