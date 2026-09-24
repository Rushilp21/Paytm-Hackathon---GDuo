import 'package:flutter_test/flutter_test.dart';
import 'package:finpath/domain/finance_engine.dart';
import 'package:finpath/domain/document_parser.dart';
import 'package:finpath/domain/models.dart';

void main() {
  test('zero new EMI does not hide existing budget pressure', () {
    const p = FinanceProfile(
      income: 50000,
      expenses: 15000,
      existingEmi: 25000,
      savings: 500000,
    );
    const g = FinancialGoal(amount: 10000, downPayment: 10000);
    final a = FinanceEngine.assess(p, g);
    expect(a.emi, 0);
    expect(a.affordable, false);
  });
  test('intent matching handles insurance and time before budget', () {
    expect(
      FinanceEngine.goalFromText('Car insurance').kind,
      GoalKind.insurance,
    );
    expect(
      FinanceEngine.goalFromText('Buy a bike in 6 months for 2 lakhs').amount,
      200000,
    );
    expect(
      FinanceEngine.goalFromText('My career training').kind,
      isNot(GoalKind.car),
    );
  });
  test('ordinary words do not trigger credential scam patterns', () {
    expect(
      FinanceEngine.scamFlags('Your shopping order is shipping tomorrow.'),
      isEmpty,
    );
    expect(FinanceEngine.scamFlags('Send your PIN'), isNotEmpty);
  });
  group('Reducing-balance EMI', () {
    test('matches independently known amortisation result', () {
      expect(FinanceEngine.emi(100000, 12, 12), closeTo(8884.8789, .001));
    });
    test('handles zero interest and no borrowing', () {
      expect(FinanceEngine.emi(120000, 0, 12), 10000);
      expect(FinanceEngine.emi(0, 9, 36), 0);
    });
    test('rejects invalid inputs', () {
      expect(() => FinanceEngine.emi(1, 9, 0), throwsArgumentError);
      expect(() => FinanceEngine.emi(-1, 9, 12), throwsArgumentError);
      expect(() => FinanceEngine.emi(double.nan, 9, 12), throwsArgumentError);
    });
  });
  group('Affordability decisions', () {
    test('includes existing debt and savings consumed by down payment', () {
      const p = FinanceProfile(
        income: 50000,
        expenses: 25000,
        existingEmi: 10000,
        savings: 100000,
      );
      const g = FinancialGoal(
        amount: 150000,
        downPayment: 50000,
        rate: 0,
        months: 20,
      );
      final a = FinanceEngine.assess(p, g);
      expect(a.emi, 5000);
      expect(a.remaining, 10000);
      expect(a.bufferMonths, 1.25);
      expect(a.affordable, false);
    });
    test('zero income cannot be affordable and never produces NaN', () {
      final a = FinanceEngine.assess(
        const FinanceProfile(income: 0),
        const FinancialGoal(),
      );
      expect(a.affordable, false);
      expect(a.debtRatio.isFinite, true);
    });
    test('income loss affects surplus and eligibility budget', () {
      final normal = FinanceEngine.assess(
        const FinanceProfile(),
        const FinancialGoal(),
      );
      final stress = FinanceEngine.assess(
        const FinanceProfile(),
        const FinancialGoal(),
        incomeDrop: .5,
      );
      expect(normal.affordable, true);
      expect(stress.affordable, false);
      expect(normal.remaining - stress.remaining, 37500);
    });
    test('down payment cannot spend savings that do not exist', () {
      final a = FinanceEngine.assess(
        const FinanceProfile(savings: 5000),
        const FinancialGoal(downPayment: 30000),
      );
      expect(a.affordable, false);
      expect(
        a.reasons.any((r) => r.contains('exceeds your available savings')),
        true,
      );
    });
  });
  test('goal parser understands Indian amounts and insurance routing', () {
    final g = FinanceEngine.goalFromText('I want to buy a car for 8.5 lakh');
    expect(g.kind, GoalKind.car);
    expect(g.amount, 850000);
    expect(
      FinanceEngine.goalFromText('A laptop for 60000').kind,
      GoalKind.personal,
    );
    expect(
      FinanceEngine.goalFromText('health insurance').kind,
      GoalKind.insurance,
    );
  });
  test(
    'extractor omits absent or malformed fields without inventing identity',
    () {
      final result = DocumentParser.extract(
        'Full Name: Demo Person\nNet Salary: INR 75,000\nEmail: demo@example.com\nMonthly Expenses: invalid',
      );
      expect(result['name'], 'Demo Person');
      expect(result['income'], '75000');
      expect(result.containsKey('expenses'), false);
      expect(result.containsKey('policy'), false);
    },
  );
  test('scam checker flags credentials, pressure and advance fee', () {
    final flags = FinanceEngine.scamFlags(
      'Guaranteed loan! Pay an upfront fee immediately and share your OTP.',
    );
    expect(flags.length, 4);
    expect(FinanceEngine.scamFlags('Your appointment is on Monday'), isEmpty);
  });
}
