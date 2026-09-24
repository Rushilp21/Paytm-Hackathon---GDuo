import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finpath/app.dart';
import 'package:finpath/data/app_store.dart';

void main() {
  for (final size in [
    const Size(1280, 720),
    const Size(390, 844),
    const Size(320, 800),
  ]) {
    testWidgets('goal journey renders and navigates at ${size.width}px', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = AppStore();
      await store.load();
      await tester.pumpWidget(FinpathApp(store: store));
      await tester.pumpAndSettle();
      expect(find.text('Big dreams.\nClear next steps.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final goal = find.byType(TextField).first;
      await tester.ensureVisible(goal);
      await tester.enterText(goal, 'Buy a car for 8 lakh');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pumpAndSettle();
      expect(store.goal.amount, 800000);
      expect(find.text('A little planning goes a long way.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 4));
    });
  }
}
