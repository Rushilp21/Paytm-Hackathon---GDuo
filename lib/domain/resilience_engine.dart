import 'dart:convert';
import 'dart:math' as math;
import 'finance_engine.dart';
import 'models.dart';
import 'resilience_models.dart';

class ResilienceEngine {
  static void validateProfile(FinanceProfile p) {
    for (final value in [p.income, p.expenses, p.savings, p.existingEmi]) {
      if (!value.isFinite || value < 0) {
        throw ArgumentError('Enter finite, non-negative finances.');
      }
    }
  }

  static List<VerseResult> verse(
    FinanceProfile p,
    FinancialGoal g,
    VerseSettings s,
  ) {
    validateProfile(p);
    if (s.years < 1 ||
        s.years > 20 ||
        s.jobLossMonths < 0 ||
        s.jobLossMonths > 12 ||
        s.shockMonth < 1 ||
        s.shockMonth > s.years * 12 ||
        !s.incomeGrowth.isFinite ||
        s.incomeGrowth < -20 ||
        s.incomeGrowth > 20 ||
        !s.inflation.isFinite ||
        s.inflation < 0 ||
        s.inflation > 15 ||
        !s.returnAdjustment.isFinite ||
        s.returnAdjustment < -15 ||
        s.returnAdjustment > 15) {
      throw ArgumentError(
        'Simulation assumptions are outside the supported range.',
      );
    }
    return FuturePath.values.map((path) {
      var cash = p.savings;
      var invested = 0.0;
      var debt = 0.0; // Unfunded cash needs, not an invented credit facility.
      int? firstShortfall;
      int? targetMonth = p.savings >= g.amount ? 0 : null;
      final rate = path.annualReturn + s.returnAdjustment;
      final monthlyReturn = math.pow(1 + rate / 100, 1 / 12).toDouble() - 1;
      final rows = <MonthProjection>[
        MonthProjection(0, cash, 0, p.income, p.expenses + p.existingEmi, 0),
      ];
      for (var m = 1; m <= s.years * 12; m++) {
        final growth = math
            .pow(1 + s.incomeGrowth / 100, (m - 1) / 12)
            .toDouble();
        final inflation = math
            .pow(1 + s.inflation / 100, (m - 1) / 12)
            .toDouble();
        final lost = m >= s.shockMonth && m < s.shockMonth + s.jobLossMonths;
        final income = lost ? 0.0 : p.income * growth;
        final outgo =
            p.expenses * path.expenseFactor * inflation + p.existingEmi;
        invested *= 1 + monthlyReturn;
        if (s.marketShock && m == s.shockMonth) invested *= 1 - path.shockLoss;
        var surplus = income - outgo;
        if (surplus >= 0) {
          final payShortfall = math.min(debt, surplus);
          debt -= payShortfall;
          surplus -= payShortfall;
          invested += surplus * path.investmentShare;
          cash += surplus * (1 - path.investmentShare);
        } else {
          var need = -surplus;
          final fromCash = math.min(cash, need);
          cash -= fromCash;
          need -= fromCash;
          final sell = math.min(invested, need);
          invested -= sell;
          need -= sell;
          if (need > .005) {
            firstShortfall ??= m;
            debt += need;
          }
        }
        final row = MonthProjection(m, cash, invested, income, outgo, debt);
        rows.add(row);
        final inflatedTarget =
            g.amount * math.pow(1 + s.inflation / 100, m / 12);
        if (row.assets >= inflatedTarget) targetMonth ??= m;
      }
      return VerseResult(
        path,
        rows,
        targetMonth,
        firstShortfall,
        rate,
        path.expenseFactor,
      );
    }).toList();
  }

  static CrashResult crash(FinanceProfile p, FinancialGoal g, CrashSettings s) {
    validateProfile(p);
    if (s.jobLossMonths < 0 ||
        s.jobLossMonths > 12 ||
        !s.incomeDrop.isFinite ||
        s.incomeDrop < 0 ||
        s.incomeDrop > 1 ||
        !s.rateRise.isFinite ||
        s.rateRise < 0 ||
        s.rateRise > 10 ||
        !s.emergency.isFinite ||
        s.emergency < 0 ||
        s.emergency > 10000000) {
      throw ArgumentError('Invalid crash-test inputs.');
    }
    final base = FinanceEngine.assess(p, g);
    final stressGoal = g.copyWith(rate: g.rate + s.rateRise);
    final recovery = FinanceEngine.assess(
      p,
      stressGoal,
      incomeDrop: s.incomeDrop,
    );
    final lost = FinanceEngine.assess(
      p,
      stressGoal,
      incomeDrop: s.jobLossMonths > 0 ? 1 : s.incomeDrop,
    );
    List<MonthProjection> project(bool stressed) {
      var cash = p.savings - g.downPayment - (stressed ? s.emergency : 0);
      final rows = <MonthProjection>[
        MonthProjection(
          0,
          cash,
          0,
          p.income,
          p.expenses + p.existingEmi + (stressed ? recovery.emi : base.emi),
          math.max(0, -cash),
        ),
      ];
      for (var m = 1; m <= 12; m++) {
        final income = stressed
            ? (m <= s.jobLossMonths ? 0.0 : p.income * (1 - s.incomeDrop))
            : p.income;
        // Proposed loan ends at its contracted tenure; existing EMIs persist
        // because the profile does not contain their outstanding term.
        final emi = m <= g.months ? (stressed ? recovery.emi : base.emi) : 0.0;
        final outgo = p.expenses + p.existingEmi + emi;
        cash += income - outgo;
        rows.add(
          MonthProjection(m, cash, 0, income, outgo, math.max(0, -cash)),
        );
      }
      return rows;
    }

    final baseline = project(false);
    final stressed = project(true);
    final outgo = p.expenses + p.existingEmi + recovery.emi;
    final minCash = stressed.map((r) => r.cash).reduce(math.min);
    return CrashResult(
      baseline: baseline,
      stressed: stressed,
      baselineEmi: base.emi,
      stressedEmi: recovery.emi,
      baselineBuffer: base.bufferMonths,
      shockBuffer: outgo > 0 ? math.max(0, stressed.first.cash) / outgo : 0,
      minimumBuffer: outgo > 0 ? math.max(0, minCash) / outgo : 0,
      baselineSafeEmi: base.safeEmi,
      stressedSafeEmi: lost.safeEmi,
      recoverySafeEmi: recovery.safeEmi,
      failureMonth: stressed.where((r) => r.cash < 0).firstOrNull?.month,
    );
  }

  /// Exhaustive, bounded search; no prediction of the likelihood of shocks.
  static CrashSettings worstCase(
    FinanceProfile p,
    FinancialGoal g,
    CrashSettings caps,
  ) {
    var worst = const CrashSettings(
      jobLossMonths: 0,
      rateRise: 0,
      emergency: 0,
    );
    var minimum = double.infinity;
    for (final jobs in {0, caps.jobLossMonths ~/ 2, caps.jobLossMonths}) {
      for (final rate in {0.0, caps.rateRise / 2, caps.rateRise}) {
        for (final emergency in {0.0, caps.emergency / 2, caps.emergency}) {
          final s = CrashSettings(
            jobLossMonths: jobs,
            rateRise: rate,
            emergency: emergency,
            incomeDrop: caps.incomeDrop,
          );
          final low = crash(
            p,
            g,
            s,
          ).stressed.map((m) => m.cash).reduce(math.min);
          if (low < minimum) {
            minimum = low;
            worst = s;
          }
        }
      }
    }
    return worst;
  }

  static void validateBudget(FinanceProfile p, GuardBudget b) {
    validateProfile(p);
    if (!b.discretionary.isFinite ||
        b.discretionary < 0 ||
        b.salaryDay < 1 ||
        b.salaryDay > 28 ||
        b.emiDay < 1 ||
        b.emiDay > 28 ||
        b.payments.map((x) => x.id).toSet().length != b.payments.length) {
      throw ArgumentError('Invalid budget or duplicate payment.');
    }
    for (final item in b.payments) {
      if (item.name.trim().isEmpty ||
          !item.amount.isFinite ||
          item.amount <= 0 ||
          item.amount > 10000000 ||
          item.day < 1 ||
          item.day > 28) {
        throw ArgumentError(
          'Use a name, positive amount and day 1–28 for each schedule.',
        );
      }
    }
    if (b.discretionary + b.subscriptions > p.expenses) {
      throw ArgumentError(
        'Discretionary spending and subscriptions are already inside living expenses; their sum cannot exceed it.',
      );
    }
  }

  static String signature(FinanceProfile p, FinancialGoal g, GuardBudget b) =>
      jsonEncode([p.toJson(), g.toJson(), b.toJson()]);

  static GuardPlan guard(
    FinanceProfile p,
    FinancialGoal g,
    GuardBudget b, {
    DateTime? now,
    double? previousIncome,
  }) {
    validateBudget(p, b);
    final at = now ?? DateTime.now();
    final base = FinanceEngine.assess(
      p.copyWith(expenses: p.expenses + b.extraOutgo),
      g,
    );
    final actions = <GuardAction>[];
    for (final payment in b.payments) {
      if (payment.kind == ScheduleKind.subscription && !payment.unused) {
        continue;
      }
      final kind = switch (payment.kind) {
        ScheduleKind.subscription => GuardActionKind.cancelSubscription,
        ScheduleKind.sip => GuardActionKind.pauseSip,
        ScheduleKind.transfer => GuardActionKind.pauseTransfer,
      };
      actions.add(
        GuardAction(
          payment.id,
          '${payment.kind == ScheduleKind.subscription ? 'Stop unused' : 'Pause'} ${payment.name}',
          'Suppress this demo schedule for 90 days. Confirm any real mandate change with the provider. ${payment.kind == ScheduleKind.sip ? 'Pausing investments reduces future contributions.' : ''}',
          kind,
          payment.amount,
        ),
      );
    }
    if (b.discretionary > 0) {
      actions.add(
        GuardAction(
          'budget',
          'Reduce discretionary budget',
          'Temporarily reduce the declared discretionary category by 50%; essentials stay unchanged.',
          GuardActionKind.cutBudget,
          b.discretionary * .5,
        ),
      );
    }
    if (b.emiDay < b.salaryDay && p.existingEmi + base.emi > 0) {
      actions.add(
        const GuardAction(
          'emi-date',
          'Request an EMI date after salary',
          'Provider approval required. Creates a manual follow-up; does not change your EMI, due date or cash balance.',
          GuardActionKind.moveEmi,
          0,
        ),
      );
    }
    return GuardPlan(
      id: 'GUARD-${at.microsecondsSinceEpoch}',
      signature: signature(p, g, b),
      created: at,
      income: p.income,
      expenses: p.expenses,
      savings: p.savings,
      existingEmi: p.existingEmi,
      proposedEmi: base.emi,
      extraOutgo: b.extraOutgo,
      startingCash: p.savings - g.downPayment,
      actions: actions,
      reasons: [
        if (previousIncome != null && p.income < previousIncome)
          'Income changed from INR ${previousIncome.toStringAsFixed(0)} to INR ${p.income.toStringAsFixed(0)} per month.',
        ...base.reasons,
        if (base.reasons.isEmpty)
          'No affordability breach detected. Review optional resilience improvements.',
      ],
    );
  }

  static List<Map<String, dynamic>> schedule(
    GuardBudget budget,
    ProtectionRun run,
  ) {
    final rows = <Map<String, dynamic>>[];
    for (
      var day = DateTime(
        run.activated.year,
        run.activated.month,
        run.activated.day,
      );
      day.isBefore(run.expires);
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      for (final item in budget.payments.where((p) => p.day == day.day)) {
        rows.add({
          'date': day.toIso8601String(),
          'name': item.name,
          'amount': item.amount,
          'status': run.selected.contains(item.id)
              ? 'Suppressed in demo schedule'
              : 'Scheduled in demo',
          'providerStatus': 'No provider instruction sent',
        });
      }
    }
    return rows;
  }
}
