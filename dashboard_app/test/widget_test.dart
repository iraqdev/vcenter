// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import '../lib/main.dart';

void main() {
  testWidgets('Dashboard app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(DashboardApp());

    // Verify that our dashboard loads
    expect(find.text('لوحة التحكم - VCenter'), findsOneWidget);
    expect(find.text('إدارة المستخدمين'), findsOneWidget);
  });
}
