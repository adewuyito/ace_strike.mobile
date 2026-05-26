import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ace_strike/main.dart';

void main() {
  testWidgets('App starts and builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AceStrikeApp(),
      ),
    );

    expect(find.byType(AceStrikeApp), findsOneWidget);
  });
}
