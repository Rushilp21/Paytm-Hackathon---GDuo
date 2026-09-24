import 'dart:math' as math;
import 'models.dart';

class Affordability {
  final double emi,
      interest,
      repayment,
      remaining,
      bufferMonths,
      debtRatio,
      safeEmi;
  final bool affordable;
  final List<String> reasons;
  const Affordability({
    required this.emi,
    required this.interest,
    required this.repayment,
    required this.remaining,
    required this.bufferMonths,
    required this.debtRatio,
    required this.safeEmi,
    required this.affordable,
    required this.reasons,
  });
}

class FinanceEngine {
  // Reducing-balance EMI. Thresholds are demo assumptions, not underwriting.
  static double emi(double principal, double annualRate, int months) {
    if (!principal.isFinite ||
        principal < 0 ||
        !annualRate.isFinite ||
        annualRate < 0 ||
        months <= 0) {
      throw ArgumentError('Invalid loan inputs');
    }
    if (principal == 0) return 0;
    if (annualRate == 0) return principal / months;
    final r = annualRate / 1200;
    final factor = math.pow(1 + r, months).toDouble();
    return principal * r * factor / (factor - 1);
  }

  static Affordability assess(
    FinanceProfile p,
    FinancialGoal g, {
    double incomeDrop = 0,
  }) {
    final income = p.income * (1 - incomeDrop.clamp(0, 1));
    final principal = math.max(0.0, g.amount - g.downPayment);
    final monthly = emi(principal, g.rate, g.months);
    final remaining = income - p.expenses - p.existingEmi - monthly;
    final outgo = p.expenses + p.existingEmi + monthly;
    final liquid = math.max(0.0, p.savings - g.downPayment);
    final buffer = outgo > 0 ? liquid / outgo : 0.0;
    final debtRatio = income > 0 ? (p.existingEmi + monthly) / income : 1.0;
    final safe = math.max(
      0.0,
      math.min(
        income * .35 - p.existingEmi,
        income - p.expenses - p.existingEmi - income * .20,
      ),
    );
    final reasons = <String>[
      if (monthly > safe || debtRatio > .35 || remaining < income * .20)
        'The EMI exceeds the demo budget limit: keep all EMIs below 35% of income and reserve 20% of income.',
      if (buffer < 3)
        'Savings after the down payment cover less than 3 months of expenses and all EMIs.',
      if (g.downPayment > p.savings)
        'The down payment exceeds your available savings.',
      if (remaining < 0)
        'Monthly outgo exceeds income. Reduce the loan or revisit your budget.',
      if (income <= 0)
        'Add a positive monthly income before assessing affordability.',
    ];
    return Affordability(
      emi: monthly,
      interest: monthly * g.months - principal,
      repayment: monthly * g.months,
      remaining: remaining,
      bufferMonths: buffer,
      debtRatio: debtRatio,
      safeEmi: safe,
      affordable: reasons.isEmpty,
      reasons: reasons,
    );
  }

  static String eligibility(FinanceProfile p, FinancialGoal g) {
    final a = assess(p, g);
    if (p.income <= 0 || a.debtRatio > .5 || p.creditScore < 600) {
      return 'Needs improvement';
    }
    if (p.creditScore >= 720 && a.affordable) return 'Strong fit';
    return 'Worth reviewing';
  }

  static FinancialGoal goalFromText(String text) {
    final lower = text.toLowerCase();
    GoalKind kind = GoalKind.personal;
    if (RegExp(r'insur|health|coverage|बीमा').hasMatch(lower)) {
      kind = GoalKind.insurance;
    } else if (RegExp(r'\bcar\b|कार').hasMatch(lower)) {
      kind = GoalKind.car;
    } else if (RegExp(r'bike|scooter|motorcycle|बाइक').hasMatch(lower)) {
      kind = GoalKind.bike;
    } else if (RegExp(
      r'college|study|education|course|पढ़ाई',
    ).hasMatch(lower)) {
      kind = GoalKind.education;
    } else if (RegExp(r'house|home|घर').hasMatch(lower)) {
      kind = GoalKind.home;
    } else if (RegExp(r'business|shop|व्यापार').hasMatch(lower)) {
      kind = GoalKind.business;
    } else if (RegExp(r'insur|health|cover|बीमा').hasMatch(lower)) {
      kind = GoalKind.insurance;
    }
    final defaults = <GoalKind, double>{
      GoalKind.bike: 142000,
      GoalKind.car: 850000,
      GoalKind.education: 500000,
      GoalKind.home: 4500000,
      GoalKind.business: 400000,
      GoalKind.insurance: 500000,
      GoalKind.personal: 100000,
    };
    var amount = defaults[kind]!;
    final matches = RegExp(
      r'(?:₹|rs\.?\s*)?([\d,]+(?:\.\d+)?)\s*(lakhs?\b|lacs?\b|l\b|crores?\b|cr\b|k\b|thousand\b)?',
      caseSensitive: false,
    ).allMatches(lower);
    for (final match in matches) {
      final number = double.tryParse(match[1]!.replaceAll(',', ''));
      final unit = match[2];
      final scale = ['lakh', 'lakhs', 'lac', 'lacs', 'l'].contains(unit)
          ? 100000
          : ['crore', 'crores', 'cr'].contains(unit)
          ? 10000000
          : ['k', 'thousand'].contains(unit)
          ? 1000
          : 1;
      if (number != null && number * scale >= 1000) {
        amount = (number * scale).clamp(1000, 100000000);
        break;
      }
    }
    return FinancialGoal(
      title: text.trim().isEmpty ? 'My first bike' : text.trim(),
      kind: kind,
      amount: amount,
      downPayment: amount * .25,
      months: kind == GoalKind.home ? 240 : 36,
      rate: kind == GoalKind.home ? 8.5 : 9.5,
    );
  }

  static List<String> scamFlags(String text) {
    final t = text.toLowerCase();
    final flags = <String>[];
    if (RegExp(
      r'\b(?:otp|pin|password|cvv)\b|screen.?shar|remote access',
    ).hasMatch(t)) {
      flags.add(
        'Sensitive credentials or device access mentioned. Never share an OTP, PIN, password or screen access with an unknown caller.',
      );
    }
    if (RegExp(
      r'upfront|advance fee|pay first|processing.*(?:upi|personal)|deposit.*unlock',
    ).hasMatch(t)) {
      flags.add(
        'An advance payment or personal-account transfer may be requested. Verify fees independently with the provider.',
      );
    }
    if (RegExp(
      r'guaranteed|100% approval|no cibil|no credit check',
    ).hasMatch(t)) {
      flags.add(
        'Guaranteed approval or bypassing credit checks is a red flag.',
      );
    }
    if (RegExp(
      r'urgent|immediately|within .*minutes|last chance|expires today',
    ).hasMatch(t)) {
      flags.add(
        'Pressure to act quickly. Pause and independently verify the offer.',
      );
    }
    if (RegExp(r'bit\.ly|tinyurl|\.apk|whatsapp').hasMatch(t)) {
      flags.add(
        'A shortened link, app download or chat-only contact needs independent verification.',
      );
    }
    return flags;
  }

  static List<String> contractClauses(String text) {
    final clauses = text
        .split(RegExp(r'(?<=[.!?])\s+|\n'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    final keywords = RegExp(
      r'interest|apr|fee|penalt|foreclos|prepay|exclu|waiting|deduct|renew|cancel|collateral|default|variable|floating|premium|grace',
      caseSensitive: false,
    );
    return clauses.where((s) => keywords.hasMatch(s)).take(15).toList();
  }
}
