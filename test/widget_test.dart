import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subguard/main.dart';
import 'package:subguard/screens/onboarding_screen.dart';
import 'package:subguard/screens/shell_screen.dart';
import 'package:subguard/services/storage.dart';
import 'package:subguard/state/app_state.dart';

Future<void> _openApp(WidgetTester tester, Map<String, Object> saved) async {
  SharedPreferences.setMockInitialValues(saved);
  final state = AppState(Storage());
  await state.load();
  await tester.pumpWidget(SubGuardApp(state: state));
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('First open shows the welcome pages', (tester) async {
    await _openApp(tester, {});
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('After the welcome pages the app opens on Home', (tester) async {
    await _openApp(tester, {'onboarding_seen': true});
    expect(find.byType(ShellScreen), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
