enum FuturePath { security, balanced, growth, entrepreneurial, wealth }

extension FuturePathDetails on FuturePath {
  String get label => const [
    'Security-first',
    'Balanced',
    'Growth',
    'Entrepreneurial',
    'Wealth-building',
  ][index];
  String get description => const [
    'Prioritize accessible cash and a larger safety net.',
    'Balance today’s lifestyle with saving and investing.',
    'Invest more surplus and accept larger market swings.',
    'Model career or business upside with volatile returns.',
    'Spend less today and invest consistently over time.',
  ][index];
  double get investmentShare => const [.15, .45, .75, .65, .70][index];
  double get expenseFactor => const [.95, 1.0, 1.0, .95, .80][index];
  double get annualReturn => const [4.0, 6.0, 9.0, 10.0, 8.0][index];
  double get shockLoss => const [.05, .12, .25, .40, .20][index];
  String get risk =>
      const ['Lower', 'Moderate', 'Higher', 'Very high', 'Higher'][index];
}

class VerseSettings {
  final int years, jobLossMonths, shockMonth;
  final double incomeGrowth, inflation, returnAdjustment;
  final bool marketShock;
  const VerseSettings({
    this.years = 7,
    this.incomeGrowth = 4,
    this.inflation = 4,
    this.returnAdjustment = 0,
    this.jobLossMonths = 0,
    this.shockMonth = 12,
    this.marketShock = false,
  });
  VerseSettings copyWith({
    int? years,
    int? jobLossMonths,
    int? shockMonth,
    double? incomeGrowth,
    double? inflation,
    double? returnAdjustment,
    bool? marketShock,
  }) => VerseSettings(
    years: years ?? this.years,
    incomeGrowth: incomeGrowth ?? this.incomeGrowth,
    inflation: inflation ?? this.inflation,
    returnAdjustment: returnAdjustment ?? this.returnAdjustment,
    jobLossMonths: jobLossMonths ?? this.jobLossMonths,
    shockMonth: shockMonth ?? this.shockMonth,
    marketShock: marketShock ?? this.marketShock,
  );
  Map<String, dynamic> toJson() => {
    'years': years,
    'incomeGrowth': incomeGrowth,
    'inflation': inflation,
    'returnAdjustment': returnAdjustment,
    'jobLossMonths': jobLossMonths,
    'shockMonth': shockMonth,
    'marketShock': marketShock,
  };
  factory VerseSettings.fromJson(Map<String, dynamic> j) => VerseSettings(
    years: j['years'] ?? 7,
    incomeGrowth: (j['incomeGrowth'] as num? ?? 4).toDouble(),
    inflation: (j['inflation'] as num? ?? 4).toDouble(),
    returnAdjustment: (j['returnAdjustment'] as num? ?? 0).toDouble(),
    jobLossMonths: j['jobLossMonths'] ?? 0,
    shockMonth: j['shockMonth'] ?? 12,
    marketShock: j['marketShock'] ?? false,
  );
}

class MonthProjection {
  final int month;
  final double cash, invested, income, outgo, shortfall;
  const MonthProjection(
    this.month,
    this.cash,
    this.invested,
    this.income,
    this.outgo,
    this.shortfall,
  );
  // Crash projections keep the deficit in signed cash; future projections
  // floor cash at zero and track unfunded needs separately. Count it once.
  double get assets => cash + invested - (cash < 0 ? 0 : shortfall);
  Map<String, dynamic> toJson() => {
    'month': month,
    'cash': cash,
    'invested': invested,
    'income': income,
    'outgo': outgo,
    'unfunded': shortfall,
    'netFinancialAssets': assets,
  };
}

class VerseResult {
  final FuturePath path;
  final List<MonthProjection> months;
  final int? targetMonth, firstShortfall;
  final double annualReturn, expenseFactor;
  const VerseResult(
    this.path,
    this.months,
    this.targetMonth,
    this.firstShortfall,
    this.annualReturn,
    this.expenseFactor,
  );
  MonthProjection get last => months.last;
}

class CrashSettings {
  final int jobLossMonths;
  final double incomeDrop, rateRise, emergency;
  const CrashSettings({
    this.jobLossMonths = 3,
    this.incomeDrop = 0,
    this.rateRise = 2,
    this.emergency = 40000,
  });
  CrashSettings copyWith({
    int? jobLossMonths,
    double? incomeDrop,
    double? rateRise,
    double? emergency,
  }) => CrashSettings(
    jobLossMonths: jobLossMonths ?? this.jobLossMonths,
    incomeDrop: incomeDrop ?? this.incomeDrop,
    rateRise: rateRise ?? this.rateRise,
    emergency: emergency ?? this.emergency,
  );
  Map<String, dynamic> toJson() => {
    'jobLossMonths': jobLossMonths,
    'incomeDrop': incomeDrop,
    'rateRise': rateRise,
    'emergency': emergency,
  };
  factory CrashSettings.fromJson(Map<String, dynamic> j) => CrashSettings(
    jobLossMonths: j['jobLossMonths'] ?? 3,
    incomeDrop: (j['incomeDrop'] as num? ?? 0).toDouble(),
    rateRise: (j['rateRise'] as num? ?? 2).toDouble(),
    emergency: (j['emergency'] as num? ?? 40000).toDouble(),
  );
}

class CrashResult {
  final List<MonthProjection> baseline, stressed;
  final double baselineEmi,
      stressedEmi,
      baselineBuffer,
      shockBuffer,
      minimumBuffer,
      baselineSafeEmi,
      stressedSafeEmi,
      recoverySafeEmi;
  final int? failureMonth;
  const CrashResult({
    required this.baseline,
    required this.stressed,
    required this.baselineEmi,
    required this.stressedEmi,
    required this.baselineBuffer,
    required this.shockBuffer,
    required this.minimumBuffer,
    required this.baselineSafeEmi,
    required this.stressedSafeEmi,
    required this.recoverySafeEmi,
    required this.failureMonth,
  });
}

enum ScheduleKind { subscription, sip, transfer }

class PlannedPayment {
  final String id, name;
  final ScheduleKind kind;
  final double amount;
  final int day;
  final bool unused;
  const PlannedPayment({
    required this.id,
    required this.name,
    required this.kind,
    required this.amount,
    this.day = 5,
    this.unused = false,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kind': kind.name,
    'amount': amount,
    'day': day,
    'unused': unused,
  };
  factory PlannedPayment.fromJson(Map<String, dynamic> j) => PlannedPayment(
    id: j['id'],
    name: j['name'],
    kind: ScheduleKind.values.byName(j['kind']),
    amount: (j['amount'] as num).toDouble(),
    day: j['day'],
    unused: j['unused'] ?? false,
  );
}

class GuardBudget {
  final double discretionary;
  final int salaryDay, emiDay;
  final List<PlannedPayment> payments;
  const GuardBudget({
    this.discretionary = 0,
    this.salaryDay = 1,
    this.emiDay = 5,
    this.payments = const [],
  });
  double get extraOutgo => payments
      .where((p) => p.kind != ScheduleKind.subscription)
      .fold(0.0, (s, p) => s + p.amount);
  double get subscriptions => payments
      .where((p) => p.kind == ScheduleKind.subscription)
      .fold(0.0, (s, p) => s + p.amount);
  Map<String, dynamic> toJson() => {
    'discretionary': discretionary,
    'salaryDay': salaryDay,
    'emiDay': emiDay,
    'payments': payments.map((p) => p.toJson()).toList(),
  };
  factory GuardBudget.fromJson(Map<String, dynamic> j) => GuardBudget(
    discretionary: (j['discretionary'] as num? ?? 0).toDouble(),
    salaryDay: j['salaryDay'] ?? 1,
    emiDay: j['emiDay'] ?? 5,
    payments: (j['payments'] as List? ?? [])
        .map((p) => PlannedPayment.fromJson(p))
        .toList(),
  );
}

enum GuardActionKind {
  pauseSip,
  pauseTransfer,
  cancelSubscription,
  cutBudget,
  moveEmi,
}

class GuardAction {
  final String id, title, detail;
  final GuardActionKind kind;
  final double monthlyRelease;
  const GuardAction(
    this.id,
    this.title,
    this.detail,
    this.kind,
    this.monthlyRelease,
  );
  bool get providerOnly => kind == GuardActionKind.moveEmi;
  bool get reducesExpenses =>
      kind == GuardActionKind.cutBudget ||
      kind == GuardActionKind.cancelSubscription;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'detail': detail,
    'kind': kind.name,
    'monthlyRelease': monthlyRelease,
  };
  factory GuardAction.fromJson(Map<String, dynamic> j) => GuardAction(
    j['id'],
    j['title'],
    j['detail'],
    GuardActionKind.values.byName(j['kind']),
    (j['monthlyRelease'] as num).toDouble(),
  );
}

class GuardPlan {
  final String id, signature;
  final DateTime created;
  final double income,
      expenses,
      savings,
      existingEmi,
      proposedEmi,
      extraOutgo,
      startingCash;
  final List<GuardAction> actions;
  final List<String> reasons;
  const GuardPlan({
    required this.id,
    required this.signature,
    required this.created,
    required this.income,
    required this.expenses,
    required this.savings,
    required this.existingEmi,
    required this.proposedEmi,
    required this.extraOutgo,
    required this.startingCash,
    required this.actions,
    required this.reasons,
  });
  double get beforeOutgo => expenses + existingEmi + proposedEmi + extraOutgo;
  double release(Set<String> selected) => actions
      .where((a) => selected.contains(a.id) && !a.providerOnly)
      .fold(0.0, (s, a) => s + a.monthlyRelease);
  double expenseRelease(Set<String> selected) => actions
      .where((a) => selected.contains(a.id) && a.reducesExpenses)
      .fold(0.0, (s, a) => s + a.monthlyRelease);
  double afterOutgo(Set<String> selected) => beforeOutgo - release(selected);
  double cashAtDay(int day, Set<String> selected) =>
      startingCash + (income - afterOutgo(selected)) * day / 30;
  double? runway(Set<String> selected) => afterOutgo(selected) <= income
      ? null
      : startingCash.clamp(0, double.infinity) /
            (afterOutgo(selected) - income);
  Map<String, dynamic> toJson() => {
    'id': id,
    'signature': signature,
    'created': created.toIso8601String(),
    'income': income,
    'expenses': expenses,
    'savings': savings,
    'existingEmi': existingEmi,
    'proposedEmi': proposedEmi,
    'extraOutgo': extraOutgo,
    'startingCash': startingCash,
    'actions': actions.map((a) => a.toJson()).toList(),
    'reasons': reasons,
  };
  factory GuardPlan.fromJson(Map<String, dynamic> j) => GuardPlan(
    id: j['id'],
    signature: j['signature'],
    created: DateTime.parse(j['created']),
    income: (j['income'] as num).toDouble(),
    expenses: (j['expenses'] as num).toDouble(),
    savings: (j['savings'] as num).toDouble(),
    existingEmi: (j['existingEmi'] as num).toDouble(),
    proposedEmi: (j['proposedEmi'] as num).toDouble(),
    extraOutgo: (j['extraOutgo'] as num).toDouble(),
    startingCash: (j['startingCash'] as num).toDouble(),
    actions: (j['actions'] as List)
        .map((a) => GuardAction.fromJson(a))
        .toList(),
    reasons: List<String>.from(j['reasons']),
  );
}

class ProtectionRun {
  final GuardPlan plan;
  final Set<String> selected;
  final DateTime activated, expires;
  final bool stopped;
  const ProtectionRun({
    required this.plan,
    required this.selected,
    required this.activated,
    required this.expires,
    this.stopped = false,
  });
  bool activeAt(DateTime now) =>
      !stopped && !now.isBefore(activated) && now.isBefore(expires);
  Map<String, dynamic> toJson() => {
    'plan': plan.toJson(),
    'selected': selected.toList(),
    'activated': activated.toIso8601String(),
    'expires': expires.toIso8601String(),
    'stopped': stopped,
  };
  factory ProtectionRun.fromJson(Map<String, dynamic> j) => ProtectionRun(
    plan: GuardPlan.fromJson(j['plan']),
    selected: Set<String>.from(j['selected']),
    activated: DateTime.parse(j['activated']),
    expires: DateTime.parse(j['expires']),
    stopped: j['stopped'] ?? false,
  );
}
