import 'package:firststop_m/first_stop_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

String english(String text, String _) => text;
String identity(String value) => value;

Widget dashboardFor(String role) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: FirstStopDashboard(
        profile: const {'display_name': 'Pilot'},
        role: role,
        washes: const [],
        cafes: const [],
        staff: const [],
        t: english,
        roleName: identity,
        statusName: identity,
        onRefresh: () {},
      ),
    ),
  ),
);

void main() {
  testWidgets('owner dashboard has branded header and honest empty states',
      (tester) async {
    await tester.pumpWidget(dashboardFor('owner'));
    expect(find.text('Your business, at a glance'), findsOneWidget);
    expect(find.text('No wash tickets yet'), findsOneWidget);
    expect(find.text('No coffee orders yet'), findsOneWidget);
    expect(find.text('Your team'), findsOneWidget);
    expect(find.textContaining('READ-ONLY PILOT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('barista dashboard hides car wash and staff information',
      (tester) async {
    await tester.pumpWidget(dashboardFor('barista'));
    expect(find.text('Car wash queue'), findsNothing);
    expect(find.text('Your team'), findsNothing);
    expect(find.text('No coffee orders yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
