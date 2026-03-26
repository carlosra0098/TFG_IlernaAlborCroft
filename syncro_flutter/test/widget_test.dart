// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:syncro_flutter/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Build our app and trigger a frame.
    await tester.pumpWidget(const SyncroApp());

    // Verify that our counter starts at 0.
    expect(find.text('SYNCRO'), findsOneWidget);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.text('Entrar con cuenta demo'));
    await tester.pumpAndSettle();

    // Verify that app navigates into the main shell.
    expect(find.text('Perfil'), findsOneWidget);
  });
}
