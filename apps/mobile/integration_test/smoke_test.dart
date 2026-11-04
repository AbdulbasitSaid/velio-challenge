// S7 V-E2E-1 integration smoke: code entry → invite → claim → You're in → Plan → My plans, on a
// simulator or device against a running API (local Compose or the deployed stack):
//   flutter test integration_test --dart-define=SMOKE_CODE=<a claimable vouch code> [--dart-define=API_BASE_URL=…]
// It books a spot, so use a test invite.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:velio/main.dart' as app;

const code = String.fromEnvironment('SMOKE_CODE');
final guest = 'E2E App ${DateTime.now().millisecondsSinceEpoch % 100000}';

Future<void> waitFor(WidgetTester t, Finder f, {Duration timeout = const Duration(seconds: 20)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 200));
    if (f.evaluate().isNotEmpty) return;
  }
  final shown = find.byType(Text).evaluate().map((e) => (e.widget as Text).data ?? '').where((d) => d.isNotEmpty);
  throw TestFailure('Timed out waiting for $f. On screen: ${shown.join(' | ')}');
}

Future<void> tapText(WidgetTester t, String text) async {
  await waitFor(t, find.text(text));
  final f = find.text(text).first;
  await t.ensureVisible(f);
  await t.pump(const Duration(milliseconds: 300));
  await t.tap(f);
  await t.pump(const Duration(milliseconds: 300));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a new guest claims from a code and finds the Plan', (t) async {
    expect(code, isNotEmpty, reason: 'pass --dart-define=SMOKE_CODE=…');
    await app.main();
    await waitFor(t, find.text('Got an invite code?'));

    // G8 → G1
    await t.enterText(find.byType(TextField), code.toLowerCase());
    await tapText(t, 'Open invite');
    await waitFor(t, find.text('Claim my spot'));
    expect(find.textContaining('wants you on', findRichText: true), findsOneWidget);
    // Live once the socket is up (FR-008).
    await waitFor(t, find.text('Live'));

    // G3 → G4
    await tapText(t, 'Claim my spot');
    await waitFor(t, find.text('Confirm my spot'));
    // A new guest fills two fields; a guest already signed in on this phone sees "Claiming as" (FR-010).
    final returning = find.textContaining('Claiming as').evaluate().isNotEmpty;
    if (!returning) {
      await t.enterText(find.byType(TextField).at(0), guest);
      await t.enterText(find.byType(TextField).at(1), 'e2e.app.${DateTime.now().millisecondsSinceEpoch}@example.com');
    }
    await tapText(t, 'Confirm my spot');
    await waitFor(t, find.textContaining('You’re in, '));
    expect(find.byWidgetPredicate((w) => w is SelectableText && (w.data ?? '').startsWith('VLO-')), findsOneWidget);

    // B4
    await tapText(t, 'See the plan');
    await waitFor(t, find.textContaining('(you)'));
    expect(find.textContaining('Via '), findsWidgets);

    // B6
    final back = find.bySemanticsLabel('Back to My plans');
    await waitFor(t, back);
    await t.tap(back);
    await waitFor(t, find.text('My plans'));
    await waitFor(t, find.textContaining('E2E App check'));
  });
}
