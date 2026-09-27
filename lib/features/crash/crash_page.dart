import 'package:flutter/material.dart';
import '../../data/app_store.dart';
import '../../domain/resilience_engine.dart';
import '../../domain/resilience_models.dart';
import '../../ui/components.dart';
import '../../ui/resilience_widgets.dart';
import '../../ui/theme.dart';

class CrashPage extends StatelessWidget {
  final AppStore store;
  final ValueChanged<int> navigate;
  const CrashPage({required this.store, required this.navigate, super.key});
  @override
  Widget build(BuildContext context) {
    final s = store.crashSettings;
    final r = ResilienceEngine.crash(store.baselineProfile, store.goal, s);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeading(
          'FIN-CRASH • Break the plan before committing',
          'How much pressure can your plan take?',
          'Combine shocks and see the month your cash would run out.',
        ),
        Notice(
          'Testing ${store.goal.title}, including its down payment and proposed EMI. Rate changes assume the new loan reprices immediately at the remaining full tenure; existing EMIs stay fixed. Uses your regular budget; temporary 90-day changes are compared in FIN-GUARD.',
          color: muted,
        ),
        const SizedBox(height: 20),
        StatTiles([
          (
            'Survival buffer after shock',
            '${r.baselineBuffer.toStringAsFixed(1)} → ${r.shockBuffer.toStringAsFixed(1)} mo',
            'Savings / monthly outgo, before income',
          ),
          (
            'Safe new EMI during shock',
            '${money(r.baselineSafeEmi)} → ${money(r.stressedSafeEmi)}',
            'Zero income means zero income-funded EMI',
          ),
          (
            'First cash deficit',
            r.failureMonth == null
                ? 'None in 12 months'
                : r.failureMonth == 0
                ? 'Immediately'
                : 'Month ${r.failureMonth}',
            'Negative balance means an unfunded need',
          ),
        ]),
        const SizedBox(height: 22),
        ResponsiveSplit(
          leftFlex: 2,
          rightFlex: 3,
          left: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle('Build the crash scenario'),
                ControlSlider(
                  label: 'Job loss from month 1',
                  value: '${s.jobLossMonths} months',
                  current: s.jobLossMonths.toDouble(),
                  max: 12,
                  divisions: 12,
                  onChanged: (v) =>
                      store.updateCrash(s.copyWith(jobLossMonths: v.round())),
                ),
                ControlSlider(
                  label: 'Income cut after return',
                  value: '${(s.incomeDrop * 100).round()}%',
                  current: s.incomeDrop,
                  max: 1,
                  divisions: 20,
                  onChanged: (v) =>
                      store.updateCrash(s.copyWith(incomeDrop: v)),
                ),
                ControlSlider(
                  label: 'Interest rate rise',
                  value: '+${s.rateRise.toStringAsFixed(1)} pp',
                  current: s.rateRise,
                  max: 10,
                  divisions: 20,
                  onChanged: (v) => store.updateCrash(s.copyWith(rateRise: v)),
                ),
                ControlSlider(
                  label: 'Emergency today',
                  value: money(s.emergency),
                  current: s.emergency,
                  max: 200000,
                  divisions: 40,
                  onChanged: (v) => store.updateCrash(s.copyWith(emergency: v)),
                ),
                FilledButton(
                  onPressed: () => store.updateCrash(
                    ResilienceEngine.worstCase(
                      store.baselineProfile,
                      store.goal,
                      s,
                    ),
                  ),
                  child: const Text('Find weakest combination'),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Searches up to 27 combinations from zero to the shocks above, keeping your income cut fixed. No likelihood is predicted.',
                  style: TextStyle(fontSize: 11, color: muted),
                ),
                TextButton(
                  onPressed: () => store.updateCrash(
                    const CrashSettings(
                      jobLossMonths: 0,
                      rateRise: 0,
                      emergency: 0,
                    ),
                  ),
                  child: const Text('Reset to no shocks'),
                ),
              ],
            ),
          ),
          right: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle('12 months of cash flow'),
                ProjectionChart(
                  series: [
                    r.baseline.map((m) => m.cash).toList(),
                    r.stressed.map((m) => m.cash).toList(),
                  ],
                  names: const ['Original plan', 'Crash scenario'],
                  colors: const [teal, amber],
                ),
                const SizedBox(height: 16),
                Text(
                  'Proposed EMI: ${money(r.baselineEmi)} → ${money(r.stressedEmi)}',
                ),
                Text(
                  'Safe new EMI after income resumes: ${money(r.recoverySafeEmi)}',
                ),
                Text(
                  'Lowest remaining survival buffer: ${r.minimumBuffer.toStringAsFixed(1)} months',
                ),
                const SizedBox(height: 16),
                Notice(
                  r.failureMonth != null
                      ? 'This plan develops an unfunded cash need. Compare a smaller loan, retain more savings, or create a recovery plan before proceeding.'
                      : 'This scenario stays funded for 12 months. Other shocks, taxes and fees may change the outcome.',
                  color: r.failureMonth != null ? amber : teal,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('Show the numbers'),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Month')),
                    DataColumn(label: Text('Income')),
                    DataColumn(label: Text('Outgo')),
                    DataColumn(label: Text('Original cash')),
                    DataColumn(label: Text('Stressed cash')),
                  ],
                  rows: r.stressed
                      .map(
                        (m) => DataRow(
                          cells: [
                            DataCell(Text('${m.month}')),
                            DataCell(Text(money(m.income))),
                            DataCell(Text(money(m.outgo))),
                            DataCell(Text(money(r.baseline[m.month].cash))),
                            DataCell(
                              Text(
                                money(m.cash),
                                style: TextStyle(
                                  color: m.cash < 0 ? amber : teal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton(
              onPressed: () => navigate(10),
              child: const Text('Create a FIN-GUARD plan'),
            ),
            OutlinedButton(
              onPressed: () => navigate(1),
              child: const Text('Rework the loan'),
            ),
            OutlinedButton(
              onPressed: () => exportScenario(context, 'finpath-crash-test', {
                'profile': store.baselineProfile.toJson(),
                'goal': store.goal.toJson(),
                'scenario': s.toJson(),
                'failureMonth': r.failureMonth,
                'baseline': r.baseline.map((m) => m.toJson()).toList(),
                'stressed': r.stressed.map((m) => m.toJson()).toList(),
              }),
              child: const Text('Export crash test'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Crash inputs are hypothetical and do not change your profile. FIN-GUARD uses your current saved finances; record an actual income change there to prepare recovery.',
          style: TextStyle(fontSize: 12, color: muted),
        ),
      ],
    );
  }
}
