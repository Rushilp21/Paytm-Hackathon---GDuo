import 'package:flutter_test/flutter_test.dart';
import 'package:finpath/domain/models.dart';
import 'package:finpath/domain/resilience_engine.dart';
import 'package:finpath/domain/resilience_models.dart';

void main() {
  test('signed cash deficits are counted once in exported assets', () {
    const crash = MonthProjection(1, -12000, 0, 0, 12000, 12000);
    const future = MonthProjection(1, 0, 0, 0, 12000, 12000);
    expect(crash.toJson()['netFinancialAssets'], -12000);
    expect(future.toJson()['netFinancialAssets'], -12000);
  });
  const profile = FinanceProfile(
    income: 80000,
    expenses: 35000,
    savings: 400000,
    existingEmi: 0,
  );
  const goal = FinancialGoal(
    amount: 100000,
    downPayment: 0,
    rate: 0,
    months: 10,
  );

  test(
    'five futures share start; balanced zero returns conserve cash and investments',
    () {
      final results = ResilienceEngine.verse(
        profile,
        goal,
        const VerseSettings(
          years: 1,
          incomeGrowth: 0,
          inflation: 0,
          returnAdjustment: -6,
        ),
      );
      expect(results.length, 5);
      expect(results.every((r) => r.months.first.assets == 400000), true);
      final balanced = results[1];
      expect(balanced.last.assets, closeTo(400000 + 45000 * 12, .01));
      expect(balanced.last.invested, closeTo(45000 * 12 * .45, .01));
    },
  );
  test('verse job loss and portfolio loss cannot create wealth', () {
    final normal = ResilienceEngine.verse(
      profile,
      goal,
      const VerseSettings(years: 3),
    );
    final shock = ResilienceEngine.verse(
      profile,
      goal,
      const VerseSettings(years: 3, jobLossMonths: 6, marketShock: true),
    );
    for (var i = 0; i < 5; i++) {
      expect(shock[i].last.assets, lessThan(normal[i].last.assets));
    }
  });
  test(
    'verse sells assets before recording unfunded needs and accounts for recovery',
    () {
      final p = profile.copyWith(income: 0, savings: 1000, expenses: 1000);
      final r = ResilienceEngine.verse(
        p,
        goal,
        const VerseSettings(years: 1, inflation: 0),
      )[1];
      expect(r.firstShortfall, 2);
      expect(r.last.cash, 0);
      expect(r.last.invested, 0);
      expect(r.last.shortfall, 11000);
      expect(r.last.assets, -11000);
    },
  );
  test('crash with no shock matches baseline including loan maturity', () {
    final r = ResilienceEngine.crash(
      profile,
      goal,
      const CrashSettings(jobLossMonths: 0, emergency: 0, rateRise: 0),
    );
    expect(r.stressed.map((m) => m.cash), r.baseline.map((m) => m.cash));
    expect(r.stressed[10].outgo, 45000);
    expect(r.stressed[11].outgo, 35000);
    expect(r.failureMonth, isNull);
  });
  test('job loss, emergency and recovery use exact cash arithmetic', () {
    final r = ResilienceEngine.crash(
      profile.copyWith(savings: 100000),
      goal,
      const CrashSettings(
        jobLossMonths: 3,
        rateRise: 0,
        emergency: 40000,
        incomeDrop: .2,
      ),
    );
    expect(r.stressed.first.cash, 60000);
    expect(r.stressed[1].cash, 15000);
    expect(r.stressed[2].cash, -30000);
    expect(r.stressed[3].cash, -75000);
    expect(r.stressed[4].cash, -56000);
    expect(r.failureMonth, 2);
    expect(r.stressedSafeEmi, 0);
    expect(r.recoverySafeEmi, 16200);
  });
  test(
    'worst combination search finds a case no safer than the current one',
    () {
      const caps = CrashSettings(
        jobLossMonths: 6,
        rateRise: 4,
        emergency: 80000,
      );
      final worst = ResilienceEngine.worstCase(profile, goal, caps);
      expect(worst.jobLossMonths, 6);
      expect(worst.rateRise, 4);
      expect(worst.emergency, 80000);
    },
  );
  test('invalid and non-finite inputs are rejected', () {
    expect(
      () => ResilienceEngine.crash(
        profile,
        goal,
        const CrashSettings(emergency: double.nan),
      ),
      throwsArgumentError,
    );
    expect(
      () =>
          ResilienceEngine.verse(profile, goal, const VerseSettings(years: 0)),
      throwsArgumentError,
    );
    expect(
      () => ResilienceEngine.verse(
        profile,
        goal,
        const VerseSettings(incomeGrowth: double.infinity),
      ),
      throwsArgumentError,
    );
  });
  test(
    'guard releases only declared categories, counts subscriptions once and date move zero',
    () {
      const b = GuardBudget(
        discretionary: 8000,
        salaryDay: 10,
        emiDay: 5,
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
          PlannedPayment(
            id: 'used',
            name: 'Required',
            kind: ScheduleKind.subscription,
            amount: 1000,
          ),
        ],
      );
      final p = ResilienceEngine.guard(profile, goal, b);
      final ids = p.actions.map((a) => a.id).toSet();
      expect(ids, {'sip', 'sub', 'budget', 'emi-date'});
      expect(p.beforeOutgo, 50000);
      expect(p.release(ids), 10800);
      expect(p.afterOutgo(ids), 39200);
      expect(p.release({'emi-date'}), 0);
      expect(p.cashAtDay(90, ids) - p.cashAtDay(90, {}), 32400);
      expect(p.runway(ids), isNull);
    },
  );
  test('invalid double-counted budget cannot be approved', () {
    expect(
      () => ResilienceEngine.validateBudget(
        profile,
        const GuardBudget(discretionary: 36000),
      ),
      throwsArgumentError,
    );
  });
  test(
    '90-day schedule has correct boundary and unchanged unselected payments',
    () {
      const b = GuardBudget(
        payments: [
          PlannedPayment(
            id: 'sip',
            name: 'SIP',
            kind: ScheduleKind.sip,
            amount: 5000,
            day: 5,
          ),
        ],
      );
      final plan = ResilienceEngine.guard(
        profile,
        goal,
        b,
        now: DateTime(2026, 1, 1),
      );
      final run = ProtectionRun(
        plan: plan,
        selected: {'sip'},
        activated: DateTime(2026, 1, 1),
        expires: DateTime(2026, 4, 1),
      );
      final events = ResilienceEngine.schedule(b, run);
      expect(events.length, 3);
      expect(
        events.every((e) => e['status'] == 'Suppressed in demo schedule'),
        true,
      );
      expect(run.activeAt(DateTime(2026, 3, 31)), true);
      expect(run.activeAt(DateTime(2026, 4, 1)), false);
    },
  );
}
