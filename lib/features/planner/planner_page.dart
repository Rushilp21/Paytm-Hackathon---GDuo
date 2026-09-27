import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/app_store.dart';
import '../../domain/finance_engine.dart';
import '../../ui/components.dart';
import '../../ui/theme.dart';

class PlannerPage extends StatefulWidget {
  final AppStore store;
  final ValueChanged<int> navigate;
  const PlannerPage({required this.store, required this.navigate, super.key});
  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  double incomeDrop = 0;
  Future<void> editGoal() async {
    final title = TextEditingController(text: widget.store.goal.title);
    final amount = TextEditingController(
      text: widget.store.goal.amount.toStringAsFixed(0),
    );
    final key = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Make this goal yours'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Goal name'),
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Give your goal a name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total cost in rupees',
                  ),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    return n == null || !n.isFinite || n < 1000 || n > 100000000
                        ? 'Enter ₹1,000 to ₹10 crore'
                        : null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!key.currentState!.validate()) return;
              final n = double.parse(amount.text);
              widget.store.updateGoal(
                widget.store.goal.copyWith(
                  title: title.text,
                  amount: n,
                  downPayment: math.min(widget.store.goal.downPayment, n),
                ),
              );
              Navigator.pop(c);
            },
            child: const Text('Save goal'),
          ),
        ],
      ),
    );
    // Dialog routes may animate after closing; controllers can be collected with the route.
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.store;
    final g = s.goal;
    final a = FinanceEngine.assess(
      s.planningProfile,
      g,
      incomeDrop: incomeDrop,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeading(
          'Your goal, with a game plan',
          'A little planning goes a long way.',
          'Explore the trade-offs before you make a commitment.',
          action: OutlinedButton.icon(
            onPressed: editGoal,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit goal'),
          ),
        ),
        Panel(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              IconTile(goalIcon(g.kind), size: 54),
              const SizedBox(width: 17),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Estimated cost ${money(g.amount)}  •  ${g.months} months',
                      style: const TextStyle(fontSize: 12, color: muted),
                    ),
                  ],
                ),
              ),
              if (MediaQuery.sizeOf(context).width > 620)
                const Tag(
                  'Your personalised sandbox',
                  color: violet,
                  icon: Icons.auto_awesome,
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ResponsiveSplit(
          leftFlex: 6,
          rightFlex: 4,
          left: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  'What if you made it your way?',
                  subtitle: 'Move the sliders. See your real monthly impact.',
                ),
                _slider(
                  'Down payment',
                  money(g.downPayment),
                  g.downPayment,
                  0,
                  g.amount,
                  (v) =>
                      s.updateGoal(g.copyWith(downPayment: v.roundToDouble())),
                  end: money(g.amount),
                ),
                _slider(
                  'Repayment period',
                  '${g.months} months',
                  g.months.toDouble(),
                  6,
                  360,
                  (v) => s.updateGoal(g.copyWith(months: v.round())),
                  divisions: 59,
                  end: '30 years',
                ),
                _slider(
                  'Annual interest rate',
                  '${g.rate.toStringAsFixed(1)}%',
                  g.rate,
                  0,
                  30,
                  (v) => s.updateGoal(g.copyWith(rate: (v * 10).round() / 10)),
                  divisions: 300,
                  end: '30%',
                ),
                const Divider(height: 36),
                const Text(
                  'LIFE HAPPENS. TEST YOUR BUFFER.',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 10),
                _slider(
                  'If my income dropped by',
                  '${(incomeDrop * 100).round()}%',
                  incomeDrop,
                  0,
                  .5,
                  (v) => setState(() => incomeDrop = v),
                  divisions: 10,
                  end: '50%',
                ),
                const Notice(
                  'Our demo budget rule: total EMIs ≤ 35% of income, keep 20% of income unspent, and retain at least 3 months of expenses + EMIs in savings.',
                  color: muted,
                ),
              ],
            ),
          ),
          right: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Panel(
                color: const Color(0xFF142F42),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR ESTIMATED MONTHLY EMI',
                      style: TextStyle(
                        color: Color(0xFFA3C8C8),
                        fontSize: 9,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      money(a.emi),
                      style: const TextStyle(
                        fontSize: 43,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Tag(
                      a.affordable
                          ? 'Fits your current budget'
                          : 'Your budget needs attention',
                      color: a.affordable
                          ? const Color(0xFF8AE9C6)
                          : const Color(0xFFFFD197),
                      icon: a.affordable
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                    ),
                    const SizedBox(height: 24),
                    _cost(
                      'Loan amount',
                      money(g.amount - g.downPayment),
                      light: true,
                    ),
                    _cost('Total interest', money(a.interest), light: true),
                    const Divider(color: Color(0xFF35535E), height: 26),
                    _cost(
                      'Total loan repayment',
                      money(a.repayment),
                      light: true,
                    ),
                    _cost(
                      'Total purchase outlay',
                      money(a.repayment + g.downPayment),
                      light: true,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Reducing-balance estimate. Excludes fees, taxes and insurance.',
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.5,
                        color: Color(0xFF9CB7C1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle('The everyday impact'),
                    _cost('Left each month', money(a.remaining)),
                    _cost(
                      'Emergency buffer',
                      '${a.bufferMonths.toStringAsFixed(1)} months',
                    ),
                    _cost(
                      'All EMIs / income',
                      '${(a.debtRatio * 100).toStringAsFixed(1)}%',
                    ),
                    _cost('Demo EMI ceiling', money(a.safeEmi)),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: a.debtRatio.clamp(0, 1),
                      color: a.debtRatio <= .35 ? teal : amber,
                      backgroundColor: line,
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 17),
                    Text(
                      a.reasons.isEmpty
                          ? 'Your plan leaves room for everyday living and a rainy-day fund.'
                          : a.reasons.join('\n\n'),
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: a.affordable ? teal : amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                'A longer tenure lowers EMI. But costs more.',
                subtitle:
                    'Compare the same principal and rate over different repayment periods.',
              ),
              SizedBox(
                height: 160,
                child: LayoutBuilder(
                  builder: (context, c) {
                    final tenures = g.months > 60
                        ? [60, 120, 180, 240, 300, 360]
                        : [12, 24, 36, 48, 60, 72];
                    final values = tenures
                        .map(
                          (m) => FinanceEngine.emi(
                            g.amount - g.downPayment,
                            g.rate,
                            m,
                          ),
                        )
                        .toList();
                    final max = math.max(1, values.reduce(math.max));
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(
                        tenures.length,
                        (i) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                FittedBox(
                                  child: Text(
                                    money(values[i]),
                                    style: TextStyle(
                                      fontSize: c.maxWidth < 450 ? 9 : 11,
                                      fontWeight: FontWeight.w600,
                                      color: ink,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  height: 90 * values[i] / max + 8,
                                  decoration: BoxDecoration(
                                    color: tenures[i] == g.months
                                        ? blue
                                        : const Color(0xFFD8E5FB),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(7),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                FittedBox(
                                  child: Text(
                                    '${tenures[i]} mo',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const SectionTitle(
          'Understand your options.',
          subtitle:
              'Illustrative products for comparison. These are not live lender offers.',
          trailing: Tag('Demo catalogue', color: muted),
        ),
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth > 780 ? 3 : 1;
            return Wrap(
              spacing: 18,
              runSpacing: 18,
              children: List.generate(3, (i) {
                final rates = [9.5, 13.5, 18.0];
                final names = [
                  'Horizon Bank',
                  'Bloom Finance',
                  'Velocity Credit',
                ];
                final fees = [1500, 1000, 500];
                final proposed = g.copyWith(rate: rates[i]);
                final result = FinanceEngine.assess(
                  s.planningProfile,
                  proposed,
                );
                return SizedBox(
                  width: (c.maxWidth - (cols - 1) * 18) / cols,
                  child: Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconTile(
                              Icons.account_balance_outlined,
                              color: i == 0 ? teal : blue,
                            ),
                            const Spacer(),
                            if (i == 0) const Tag('Lowest rate'),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          names[i],
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          [
                            'Bank loan',
                            'Flexible personal loan',
                            'Dealer financing',
                          ][i],
                          style: const TextStyle(fontSize: 11, color: muted),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '${money(result.emi)} / mo',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 17),
                        _cost('Interest rate', '${rates[i]}% p.a.'),
                        _cost('Processing fee', money(fees[i])),
                        _cost(
                          'Repayment + fee',
                          money(result.repayment + fees[i]),
                        ),
                        _cost(
                          'Heuristic fit',
                          FinanceEngine.eligibility(
                            s.planningProfile,
                            proposed,
                          ),
                        ),
                        const SizedBox(height: 17),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              s.updateGoal(proposed);
                              setState(() => incomeDrop = 0);
                              toast(
                                context,
                                '${names[i]} rate applied. Review your updated simulation above.',
                              );
                            },
                            child: const Text('Try this option  →'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(height: 24),
        Notice(
          'Eligibility is a rule-based estimate using your entered income, credit score and obligations. Only a lender can confirm eligibility. Product fees above are separate from the simulator’s repayment total.',
          color: muted,
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => widget.navigate(2),
            icon: const Icon(Icons.arrow_forward, size: 18),
            iconAlignment: IconAlignment.end,
            label: const Text('Continue to documents'),
          ),
        ),
      ],
    );
  }

  Widget _slider(
    String label,
    String value,
    double current,
    double min,
    double max,
    ValueChanged<double> changed, {
    int? divisions,
    String? end,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: blue,
              ),
            ),
          ],
        ),
        Slider(
          value: current.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          label: value,
          onChanged: changed,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              min == 0 ? '0' : min.toInt().toString(),
              style: const TextStyle(fontSize: 10, color: muted),
            ),
            Text(end ?? '', style: const TextStyle(fontSize: 10, color: muted)),
          ],
        ),
      ],
    ),
  );
  Widget _cost(String title, String value, {bool light = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: light ? const Color(0xFFAEC7D0) : muted,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: light ? Colors.white : ink,
            ),
          ),
        ),
      ],
    ),
  );
}
