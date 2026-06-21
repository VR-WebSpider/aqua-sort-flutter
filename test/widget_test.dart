import 'package:flutter_test/flutter_test.dart';
import 'package:aqua_sort/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App load smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: AquaSortApp(),
      ),
    );

    // Verify that the app starts (e.g., checking for the 'Aqua Sort' title or similar)
    // Note: Since the app loads a router and might have async setup, 
    // we just verify it doesn't crash on initial pump.
    expect(find.byType(AquaSortApp), findsOneWidget);
  });
}
