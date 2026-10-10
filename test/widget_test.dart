import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firststop_m/main.dart';

void main() {
  testWidgets('shows dashboard and switches to Amharic', (tester) async {
    await tester.pumpWidget(const FirstStopApp());
    expect(find.text('Business overview'), findsOneWidget);
    await tester.tap(find.text('አማርኛ'));
    await tester.pumpAndSettle();
    expect(find.text('የንግድ አጠቃላይ እይታ'), findsOneWidget);
  });

  testWidgets('creates an in-memory wash ticket', (tester) async {
    await tester.pumpWidget(const FirstStopApp());
    await tester.tap(find.byIcon(Icons.local_car_wash_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add demo wash ticket'));
    await tester.pumpAndSettle();
    expect(find.text('Wash #1'), findsOneWidget);
  });
}
