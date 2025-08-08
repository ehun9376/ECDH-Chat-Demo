// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:ecdh/app/my_app.dart';

void main() {
  testWidgets('ECDH Chat App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app title is present.
    expect(find.text('ECDH 加密聊天室'), findsOneWidget);
    expect(find.text('端對端加密聊天測試'), findsOneWidget);

    // Verify that user panels are present.
    expect(find.text('用戶 A'), findsOneWidget);
    expect(find.text('用戶 B'), findsOneWidget);
    expect(find.text('🌐 Server 傳輸記錄'), findsOneWidget);
  });
}
