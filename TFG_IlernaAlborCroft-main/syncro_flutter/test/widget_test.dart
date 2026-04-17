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
  testWidgets('Login demo flow works after splash', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Build our app and trigger a frame.
    await tester.pumpWidget(const SyncroApp());

    // Splash should render first.
    expect(find.text('SYNCRO'), findsOneWidget);

    // Wait for splash delay + transition.
    await tester.pump(const Duration(milliseconds: 3200));
    await tester.pumpAndSettle();

    // Continue with demo login flow.
    await tester.tap(find.text('Entrar con cuenta demo'));
    await tester.pumpAndSettle();

    // Verify that app navigates into the main shell.
    expect(find.text('Perfil'), findsOneWidget);
  });
}
