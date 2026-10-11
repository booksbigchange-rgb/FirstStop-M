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
      debugPrint('LOGIN-TEST: before client construction');
      final client = SupabaseClient(
        'https://example.supabase.co',
        'public-test-key',
      );
      debugPrint('LOGIN-TEST: after client construction');
      addTearDown(client.dispose);
      debugPrint('LOGIN-TEST: before mounting widget');
      await tester.pumpWidget(ConnectedApp(client: client));
      debugPrint('LOGIN-TEST: mounted widget');
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Add demo wash ticket'), findsNothing);
      debugPrint('LOGIN-TEST: before blank login tap');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      debugPrint('LOGIN-TEST: login tapped');
      await tester.pump(const Duration(milliseconds: 200));
      debugPrint('LOGIN-TEST: after login pump');
      expect(find.textContaining('Could not sign in'), findsOneWidget);
      debugPrint('LOGIN-TEST: before Amharic tap');
      await tester.tap(find.text('አማርኛ'));
      debugPrint('LOGIN-TEST: Amharic tapped');
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('ኢሜይል'), findsOneWidget);
      expect(find.text('የይለፍ ቃል'), findsOneWidget);
      debugPrint('LOGIN-TEST: before widget removal');
      await tester.pumpWidget(const SizedBox());
      debugPrint('LOGIN-TEST: widget removed');
    },
  );
}
