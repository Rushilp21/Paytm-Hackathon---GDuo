import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finpath/app.dart';
import 'package:finpath/data/app_store.dart';
import 'package:finpath/domain/resilience_models.dart';
import 'package:finpath/features/finverse/finverse_page.dart';
import 'package:finpath/features/crash/crash_page.dart';
import 'package:finpath/features/guard/guard_page.dart';
import 'package:finpath/ui/theme.dart';

void main() {
  for (final width in [320.0, 1200.0]) {
    testWidgets('resilience screens and approval journey work at $width', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final s = AppStore();
      await s.load();
      Future<void> show(Widget Function() page) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: finTheme(),
            home: Scaffold(
              body: AnimatedBuilder(
                animation: s,
                builder: (_, _) => SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: page(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$page at $width');
      }

      await show(() => FinversePage(store: s, navigate: (_) {}));
      final save = find.text('Save these futures');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(s.savedFutures.length, 1);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await show(() => CrashPage(store: s, navigate: (_) {}));
      final reset = find.text('Reset to no shocks');
      await tester.ensureVisible(reset);
      await tester.tap(reset);
      await tester.pumpAndSettle();
      expect(s.crashSettings.jobLossMonths, 0);
      s.updateGuardBudget(
        const GuardBudget(
          discretionary: 8000,
          payments: [
            PlannedPayment(
              id: 'sip',
              name: 'Sample SIP',
              kind: ScheduleKind.sip,
              amount: 5000,
            ),
          ],
        ),
      );
      s.setConsent('guard', true);
      await show(() => GuardPage(store: s));
      final budget = find.text('Budget & schedules');
      await tester.ensureVisible(budget);
      await tester.tap(budget);
      await tester.pumpAndSettle();
      final demo = find.text('Load editable demo schedules');
      await tester.ensureVisible(demo);
      await tester.tap(demo);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Save budget'));
      await tester.pumpAndSettle();
      expect(s.guardBudget.payments.length, 3);
      final income = find.text('Record income change');
      await tester.ensureVisible(income);
      await tester.tap(income);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '64000');
      await tester.tap(find.text('Save income'));
      await tester.pumpAndSettle();
      expect(s.guardDraft!.income, 64000);
      expect(tester.takeException(), isNull);
      final activate = find.byKey(const Key('guard-activate'));
      expect(tester.widget<FilledButton>(activate).onPressed, isNull);
      final approve = find.byKey(const Key('guard-approval'));
      await tester.ensureVisible(approve);
      await tester.tap(approve);
      await tester.pumpAndSettle();
      await tester.ensureVisible(activate);
      await tester.tap(activate);
      await tester.pumpAndSettle();
      expect(s.protectionActive, true);
      expect(find.text('Protection is active'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await s.save();
    });
  }
  testWidgets('home shortcuts reach all new pages through the app shell', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = AppStore();
    await s.load();
    await tester.pumpWidget(FinpathApp(store: s));
    await tester.pumpAndSettle();
    for (final item in [
      ('FIN-VERSE', 'One life. Five simulated futures.'),
      ('FIN-CRASH', 'How much pressure can your plan take?'),
      ('FIN-GUARD', 'Life changes. Your plan can adapt.'),
    ]) {
      final shortcut = find.text(item.$1).first;
      await tester.ensureVisible(shortcut);
      await tester.tap(shortcut);
      await tester.pumpAndSettle();
      expect(find.text(item.$2), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 4));
  });
}
