import 'package:flutter/material.dart';
import '../../data/app_store.dart';
import '../../domain/resilience_engine.dart';
import '../../domain/resilience_models.dart';
import '../../ui/components.dart';
import '../../ui/resilience_widgets.dart';
import '../../ui/theme.dart';

class FinversePage extends StatelessWidget {
  final AppStore store;
  final ValueChanged<int> navigate;
  const FinversePage({required this.store, required this.navigate, super.key});
  @override
  Widget build(BuildContext context) {
    final s = store.verseSettings;
    final results = ResilienceEngine.verse(store.verseProfile, store.goal, s);
    final chosen = results[store.chosenFuture.index];
    void update(VerseSettings value) => store.updateVerse(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeading(
          'FIN-VERSE • Explore before you decide',
          'One life. Five simulated futures.',
          'Same starting finances. Different saving, spending and investing choices.',
        ),
        Notice(
          'Goal: ${store.goal.title} • ${money(store.goal.amount)} today. These are savings paths toward its inflation-adjusted cost; no new goal loan is taken in this simulation.',
          color: teal,
        ),
        const SizedBox(height: 20),
        ResponsiveSplit(
          leftFlex: 3,
          rightFlex: 2,
          left: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle(
                  'Explore your financial futures',
                  subtitle:
                      'Projected financial assets = liquid cash + investments − unfunded needs.',
                ),
                ProjectionChart(
                  series: results
                      .map((r) => r.months.map((m) => m.assets).toList())
                      .toList(),
                  names: FuturePath.values.map((p) => p.label).toList(),
                  colors: pathColors,
                ),
                const SizedBox(height: 18),
                Text(
                  'Starting cash ${money(store.verseProfile.savings)} • Income ${money(store.profile.income)}/month',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          right: Panel(
            child: Column(
              children: [
                const SectionTitle(
                  'Shared assumptions',
                  subtitle:
                      'Change an assumption and all five futures recalculate.',
                ),
                ControlSlider(
                  label: 'Time horizon',
                  value: '${s.years} years',
                  current: s.years.toDouble(),
                  min: 1,
                  max: 15,
                  divisions: 14,
                  onChanged: (v) => update(
                    s.copyWith(
                      years: v.round(),
                      shockMonth: s.shockMonth.clamp(1, v.round() * 12),
                    ),
                  ),
                ),
                ControlSlider(
                  label: 'Annual income growth',
                  value: '${s.incomeGrowth.round()}%',
                  current: s.incomeGrowth,
                  min: -10,
                  max: 15,
                  divisions: 25,
                  onChanged: (v) => update(s.copyWith(incomeGrowth: v)),
                ),
                ControlSlider(
                  label: 'Annual cost inflation',
                  value: '${s.inflation.round()}%',
                  current: s.inflation,
                  max: 10,
                  divisions: 10,
                  onChanged: (v) => update(s.copyWith(inflation: v)),
                ),
                ControlSlider(
                  label: 'Return adjustment',
                  value: '${s.returnAdjustment.round()} pp',
                  current: s.returnAdjustment,
                  min: -15,
                  max: 10,
                  divisions: 25,
                  onChanged: (v) => update(s.copyWith(returnAdjustment: v)),
                ),
                ControlSlider(
                  label: 'Job loss duration',
                  value: '${s.jobLossMonths} months',
                  current: s.jobLossMonths.toDouble(),
                  max: 12,
                  divisions: 12,
                  onChanged: (v) =>
                      update(s.copyWith(jobLossMonths: v.round())),
                ),
                ControlSlider(
                  label: 'Shock begins',
                  value: 'Month ${s.shockMonth}',
                  current: s.shockMonth.toDouble(),
                  min: 1,
                  max: s.years * 12.0,
                  divisions: s.years * 12 - 1,
                  onChanged: (v) => update(s.copyWith(shockMonth: v.round())),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Add a market / business shock'),
                  subtitle: const Text(
                    'One-time loss on investments at the shock month.',
                  ),
                  value: s.marketShock,
                  onChanged: (v) => update(s.copyWith(marketShock: v)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const SectionTitle(
          'You choose the future',
          subtitle:
              'The highest projection can also carry the largest loss. Compare liquidity as well as assets.',
        ),
        ...results.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Panel(
              color: store.chosenFuture == r.path
                  ? const Color(0xFFEDF3FF)
                  : Colors.white,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(Icons.alt_route, color: pathColors[r.path.index]),
                      Text(
                        r.path.label,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Tag(
                        '${r.path.risk} risk',
                        color: pathColors[r.path.index],
                      ),
                      ChoiceChip(
                        label: Text(
                          store.chosenFuture == r.path
                              ? 'Selected path'
                              : 'Explore this path',
                        ),
                        selected: store.chosenFuture == r.path,
                        onSelected: (_) => store.chooseFuture(r.path),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(r.path.description),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 24,
                    runSpacing: 8,
                    children: [
                      Text('Assets ${money(r.last.assets, compact: true)}'),
                      Text('Cash ${money(r.last.cash, compact: true)}'),
                      Text(
                        r.targetMonth == null
                            ? 'Goal not reached in this horizon'
                            : 'First goal crossing: month ${r.targetMonth}',
                      ),
                      Text(
                        r.firstShortfall == null
                            ? 'No unfunded month'
                            : 'First unfunded month: ${r.firstShortfall}',
                        style: TextStyle(
                          color: r.firstShortfall == null ? teal : amber,
                        ),
                      ),
                    ],
                  ),
                  if (store.chosenFuture == r.path) ...[
                    const Divider(height: 28),
                    Text(
                      'Assumptions: ${(r.path.investmentShare * 100).round()}% of positive surplus invested; ${(r.expenseFactor * 100).round()}% of current expenses; ${r.annualReturn.toStringAsFixed(1)}% annual investment return; ${(r.path.shockLoss * 100).round()}% loss if market shock is on.',
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Uses your regular budget without temporary FIN-GUARD cuts. These strategies replace existing SIP allocations. Other transfers remain outflows. Cash earns 0% in this model. Investments can be sold to fund a deficit, with no tax, exit fee or delay modelled. Existing EMI stays constant; debt principal is unknown. These are scenarios, not guaranteed returns.',
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionTitle('${chosen.path.label} • yearly checkpoints'),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Month')),
                    DataColumn(label: Text('Cash')),
                    DataColumn(label: Text('Investments')),
                    DataColumn(label: Text('Unfunded')),
                    DataColumn(label: Text('Net assets')),
                  ],
                  rows: chosen.months
                      .where((m) => m.month % 12 == 0)
                      .map(
                        (m) => DataRow(
                          cells: [
                            DataCell(Text('${m.month}')),
                            DataCell(Text(money(m.cash))),
                            DataCell(Text(money(m.invested))),
                            DataCell(Text(money(m.shortfall))),
                            DataCell(Text(money(m.assets))),
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
            FilledButton.icon(
              onPressed: () {
                store.saveFuture();
                toast(
                  context,
                  'Five futures saved with this profile and assumptions.',
                );
              },
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('Save these futures'),
            ),
            OutlinedButton(
              onPressed: () => exportScenario(context, 'finpath-finverse', {
                'profile': store.verseProfile.toJson(),
                'goal': store.goal.toJson(),
                'settings': s.toJson(),
                'selected': chosen.path.name,
                'futures': results
                    .map(
                      (r) => {
                        'path': r.path.name,
                        'months': r.months.map((m) => m.toJson()).toList(),
                      },
                    )
                    .toList(),
              }),
              child: const Text('Export projections'),
            ),
            OutlinedButton(
              onPressed: () => navigate(9),
              child: const Text('Crash-test a loan →'),
            ),
          ],
        ),
        if (store.savedFutures.isNotEmpty) ...[
          const SizedBox(height: 24),
          const SectionTitle(
            'Saved comparisons',
            subtitle:
                'Snapshots retain the original finances and assumptions. Latest 10.',
          ),
          ...store.savedFutures.map(
            (snapshot) => ExpansionTile(
              title: Text(
                '${FuturePath.values.byName(snapshot['chosen']).label} • ${snapshot['created'].toString().substring(0, 10)}',
              ),
              subtitle: Text(
                '${(snapshot['settings'] as Map)['years']} years • ${(snapshot['goal'] as Map)['title']}',
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Starting income ${money((snapshot['profile'] as Map)['income'])}; savings ${money((snapshot['profile'] as Map)['savings'])}',
                      ),
                      ...(snapshot['results'] as List).map(
                        (r) => Text(
                          '${FuturePath.values.byName(r['path']).label}: ${money(r['finalAssets'])}',
                        ),
                      ),
                      TextButton(
                        onPressed: () => exportScenario(
                          context,
                          'finpath-saved-future',
                          snapshot,
                        ),
                        child: const Text('Export this snapshot'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
