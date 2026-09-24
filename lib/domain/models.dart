enum GoalKind { bike, car, education, home, business, insurance, personal }

class FinanceProfile {
  final String name, email, employer;
  final double income, expenses, existingEmi, savings, healthCover, lifeCover;
  final int creditScore, dependents;
  const FinanceProfile({
    this.name = 'Aarav Sharma',
    this.email = '',
    this.employer = 'Acme Studio',
    this.income = 75000,
    this.expenses = 32000,
    this.existingEmi = 8500,
    this.savings = 180000,
    this.creditScore = 742,
    this.dependents = 2,
    this.healthCover = 300000,
    this.lifeCover = 1000000,
  });
  double get surplus => income - expenses - existingEmi;
  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'employer': employer,
    'income': income,
    'expenses': expenses,
    'existingEmi': existingEmi,
    'savings': savings,
    'creditScore': creditScore,
    'dependents': dependents,
    'healthCover': healthCover,
    'lifeCover': lifeCover,
  };
  factory FinanceProfile.fromJson(Map<String, dynamic> j) => FinanceProfile(
    name: j['name'] as String? ?? '',
    email: j['email'] as String? ?? '',
    employer: j['employer'] as String? ?? '',
    income: (j['income'] as num).toDouble(),
    expenses: (j['expenses'] as num).toDouble(),
    existingEmi: (j['existingEmi'] as num).toDouble(),
    savings: (j['savings'] as num).toDouble(),
    creditScore: j['creditScore'] as int,
    dependents: j['dependents'] as int,
    healthCover: (j['healthCover'] as num).toDouble(),
    lifeCover: (j['lifeCover'] as num).toDouble(),
  );
}

class FinancialGoal {
  final String title;
  final GoalKind kind;
  final double amount, downPayment, rate;
  final int months;
  const FinancialGoal({
    this.title = 'My first bike',
    this.kind = GoalKind.bike,
    this.amount = 142000,
    this.downPayment = 35000,
    this.rate = 9.5,
    this.months = 36,
  });
  FinancialGoal copyWith({
    String? title,
    GoalKind? kind,
    double? amount,
    double? downPayment,
    double? rate,
    int? months,
  }) => FinancialGoal(
    title: title ?? this.title,
    kind: kind ?? this.kind,
    amount: amount ?? this.amount,
    downPayment: downPayment ?? this.downPayment,
    rate: rate ?? this.rate,
    months: months ?? this.months,
  );
  Map<String, dynamic> toJson() => {
    'title': title,
    'kind': kind.name,
    'amount': amount,
    'downPayment': downPayment,
    'rate': rate,
    'months': months,
  };
  factory FinancialGoal.fromJson(Map<String, dynamic> j) => FinancialGoal(
    title: j['title'],
    kind: GoalKind.values.byName(j['kind']),
    amount: (j['amount'] as num).toDouble(),
    downPayment: (j['downPayment'] as num).toDouble(),
    rate: (j['rate'] as num).toDouble(),
    months: j['months'],
  );
}

class DocumentRecord {
  final String name, source;
  final Map<String, String> fields;
  final DateTime created;
  final bool reviewed;
  const DocumentRecord({
    required this.name,
    required this.fields,
    required this.source,
    required this.created,
    this.reviewed = false,
  });
  DocumentRecord review() => DocumentRecord(
    name: name,
    fields: fields,
    source: source,
    created: created,
    reviewed: true,
  );
  Map<String, dynamic> toJson() => {
    'name': name,
    'fields': fields,
    'source': source,
    'created': created.toIso8601String(),
    'reviewed': reviewed,
  };
  factory DocumentRecord.fromJson(Map<String, dynamic> j) => DocumentRecord(
    name: j['name'],
    fields: Map<String, String>.from(j['fields']),
    source: j['source'],
    created: DateTime.parse(j['created']),
    reviewed: j['reviewed'] ?? false,
  );
}

class AuditEntry {
  final String category, purpose;
  final DateTime time;
  const AuditEntry(this.category, this.purpose, this.time);
  Map<String, dynamic> toJson() => {
    'category': category,
    'purpose': purpose,
    'time': time.toIso8601String(),
  };
  factory AuditEntry.fromJson(Map<String, dynamic> j) =>
      AuditEntry(j['category'], j['purpose'], DateTime.parse(j['time']));
}

class ChatMessage {
  final String text;
  final bool isUser;
  const ChatMessage(this.text, {this.isUser = false});
  Map<String, dynamic> toJson() => {'text': text, 'isUser': isUser};
  factory ChatMessage.fromJson(Map<String, dynamic> j) =>
      ChatMessage(j['text'], isUser: j['isUser']);
}
