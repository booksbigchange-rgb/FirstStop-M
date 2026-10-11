import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firststop_m/connected_app.dart';

void main() {
  test(
    'navigation follows the server role matrix and denies unknown roles',
    () {
      expect(canReadWash('washer'), isTrue);
      expect(canReadCafe('washer'), isFalse);
      expect(canReadCafe('barista'), isTrue);
      expect(canReadWash('barista'), isFalse);
      for (final role in ['owner', 'manager', 'cashier']) {
        expect(canReadWash(role) && canReadCafe(role), isTrue);
      }
      expect(canReadWash('admin') || canReadCafe('admin'), isFalse);
    },
  );

  testWidgets(
    'connected mode starts at bilingual login and rejects blank credentials',
    (tester) async {
      final client = SupabaseClient(
        'https://example.supabase.co',
        'public-test-key',
      );
      addTearDown(client.dispose);
      await tester.pumpWidget(ConnectedApp(client: client));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Add demo wash ticket'), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('Could not sign in'), findsOneWidget);
      await tester.tap(find.text('አማርኛ'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('ኢሜይል'), findsOneWidget);
      expect(find.text('የይለፍ ቃል'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
