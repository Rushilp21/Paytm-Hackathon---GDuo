import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finpath/data/app_store.dart';
import 'package:finpath/domain/models.dart';
import 'package:finpath/domain/resilience_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<AppStore> setup() async {
    final s = AppStore();
    await s.load();
    s.updateGuardBudget(
      const GuardBudget(
        discretionary: 8000,
        payments: [
          PlannedPayment(
            id: 'sip',
            name: 'SIP',
            kind: ScheduleKind.sip,
            amount: 5000,
          ),
          PlannedPayment(
            id: 'sub',
            name: 'Unused',
            kind: ScheduleKind.subscription,
            amount: 1800,
            unused: true,
          ),
        ],
      ),
    );
    s.setConsent('guard', true);
    await s.save();
    return s;
  }

  test(
    'monitor detects income change but never executes without approval',
    () async {
      final s = await setup();
      s.updateProfile(s.profile.copyWith(income: 60000));
      expect(s.guardDraft!.income, 60000);
      expect(s.guardAlert, contains('75000'));
      expect(s.protectionActive, false);
      expect(
        () => s.activateProtection(s.guardDraft!.id, {'sip'}, approved: false),
        throwsStateError,
      );
      expect(s.planningProfile.expenses, 37000);
    },
  );
  test(
    'future allocation replaces SIPs and never extends temporary cuts',
    () async {
      final s = await setup();
      expect(s.verseProfile.expenses, 32000);
      expect(s.baselineProfile.expenses, 37000);
      s.activateProtection(s.guardDraft!.id, {
        'sip',
        'sub',
        'budget',
      }, approved: true);
      expect(s.planningProfile.expenses, 26200);
      expect(s.verseProfile.expenses, 32000);
      expect(s.baselineProfile.expenses, 37000);
      await s.save();
    },
  );
  test(
    'approved selection executes once, keeps raw profile, persists and revokes',
    () async {
      final s = await setup();
      final id = s.guardDraft!.id;
      expect(
        s.activateProtection(id, {'sip', 'sub', 'budget'}, approved: true),
        true,
      );
      expect(s.profile.expenses, 32000);
      expect(s.planningProfile.expenses, 26200);
      expect(s.activateProtection(id, {'sip'}, approved: true), false);
      expect(s.protectionHistory.length, 1);
      await s.save();
      final restored = AppStore();
      await restored.load();
      expect(restored.protectionActive, true);
      expect(restored.planningProfile.expenses, 26200);
      restored.setConsent('guard', false);
      expect(restored.planningProfile.expenses, 37000);
      expect(restored.protectionHistory.first['stopped'], true);
      await restored.save();
    },
  );
  test(
    'stale drafts, unknown actions and changed finances are rejected',
    () async {
      final s = await setup();
      final old = s.guardDraft!.id;
      expect(
        () => s.activateProtection(old, {'fake-action'}, approved: true),
        throwsStateError,
      );
      s.updateGoal(s.goal.copyWith(rate: 18));
      expect(
        () => s.activateProtection(old, {'sip'}, approved: true),
        throwsStateError,
      );
      final fresh = s.guardDraft!.id;
      s.activateProtection(fresh, {'sip'}, approved: true);
      s.updateProfile(s.profile.copyWith(income: 50000));
      expect(s.protectionActive, false);
      expect(s.guardDraft, isNotNull);
      await s.save();
    },
  );
  test('expiry restores base schedules after restart', () async {
    final s = await setup();
    s.activateProtection(
      s.guardDraft!.id,
      {'sip'},
      approved: true,
      now: DateTime.now().subtract(const Duration(days: 91)),
    );
    await s.save();
    final restored = AppStore();
    await restored.load();
    expect(restored.protectionActive, false);
    expect(restored.protection!.stopped, true);
    expect(restored.planningProfile.expenses, 37000);
    await restored.save();
  });
  test(
    'reviewed documents trigger guard and invalid categories require repair',
    () async {
      final s = await setup();
      s.addDocument(
        DocumentRecord(
          name: 'income.txt',
          fields: const {'income': '40000'},
          source: 'test',
          created: DateTime.now(),
        ),
      );
      s.reviewDocument(0, {'income': '40000'});
      expect(s.guardDraft!.income, 40000);
      s.updateProfile(s.profile.copyWith(expenses: 1000));
      expect(s.guardDraft, isNull);
      expect(s.guardAlert, contains('Review FIN-GUARD'));
      await s.save();
    },
  );
  test(
    'old storage migrates with disabled monitoring and saved futures are immutable',
    () async {
      final s = AppStore();
      await s.load();
      final old = s.toJson()
        ..removeWhere(
          (k, _) => [
            'verseSettings',
            'crashSettings',
            'chosenFuture',
            'savedFutures',
            'guardBudget',
            'guardDraft',
            'protection',
            'protectionHistory',
            'guardAlert',
          ].contains(k),
        );
      SharedPreferences.setMockInitialValues({'finpath.v1': jsonEncode(old)});
      final loaded = AppStore();
      await loaded.load();
      expect(loaded.consent['guard'], isNot(true));
      expect(loaded.persistenceError, isNull);
      loaded.saveFuture();
      loaded.updateProfile(loaded.profile.copyWith(income: 120000));
      expect(loaded.savedFutures.first['profile']['income'], 75000);
      await loaded.reset();
      expect(loaded.savedFutures, isEmpty);
      expect(loaded.protectionHistory, isEmpty);
    },
  );
}
