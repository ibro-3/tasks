import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tasks/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    
    await tester.pumpWidget(TaskApp(prefs: prefs));
    await tester.pumpAndSettle();
    
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}