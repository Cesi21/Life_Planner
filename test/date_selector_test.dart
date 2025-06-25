import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planner/widgets/date_selector.dart';

void main() {
  testWidgets('selects a day when tapped', (tester) async {
    DateTime selected = DateTime(2021, 1, 4); // Monday
    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: DateSelector(
          selected: selected,
          onChanged: (d) => selected = d,
        ),
      ),
    ));

    await tester.tap(find.text('Tue'));
    await tester.pump();
    expect(selected.weekday, 2);
  });
}
