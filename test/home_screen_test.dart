import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localnews_alerts_app/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await tester.pump();

    expect(find.text('Local News'), findsOneWidget);
    expect(find.text('What’s happening near you?'), findsOneWidget);
  });
}
