// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:religious_tasks_app/app/religious_app.dart';

void main() {
  testWidgets('App title smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ReligiousApp());

    // Verify that our app title is visible.
    expect(find.text('مهامي اليومية'), findsOneWidget);

    // Verify that we have tasks.
    expect(find.text('صلاة الفجر'), findsOneWidget);
  });
}
