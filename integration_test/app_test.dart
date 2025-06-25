import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'package:planner/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('add and delete task flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'integration');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('integration'), findsOneWidget);

    await tester.drag(find.text('integration'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('integration'), findsNothing);
  });
}
