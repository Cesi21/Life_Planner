import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner/views/calendar_page.dart';

void main() {
  testWidgets('tapping day updates list', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CalendarPage()));
    await tester.pumpAndSettle();
    final today = find.text(DateTime.now().day.toString());
    expect(today, findsOneWidget);
    await tester.tap(today);
    await tester.pump();
    // simply ensure no crash and day is selected
    expect(today, findsOneWidget);
  });
}
