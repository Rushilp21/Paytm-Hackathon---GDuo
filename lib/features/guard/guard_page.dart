import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/app_store.dart';
import '../../domain/resilience_models.dart';
import '../../ui/components.dart';
import '../../ui/resilience_widgets.dart';
import '../../ui/theme.dart';

class GuardPage extends StatefulWidget {
  final AppStore store;
  const GuardPage({required this.store, super.key});
  @override
  State<GuardPage> createState() => _GuardPageState();
}

class _GuardPageState extends State<GuardPage> {
  String? reviewedId;
  Set<String> selected = {};
  bool approved = false;

  void run(VoidCallback action) {
    try {
      action();
    } catch (e) {
      toast(context, e.toString());
    }
  }

  Future<void> editBudget() async {
    final result = await showDialog<GuardBudget>(
      context: context,
      builder: (_) => _BudgetDialog(widget.store),
    );
    if (result != null && mounted) {
      run(() => widget.store.updateGuardBudget(result));
    }
  }

  Future<void> recordIncome() async {
    final value = await showDialog<double>(
      context: context,
      builder: (_) => _IncomeDialog(widget.store.profile.income),
    );
    if (value != null && mounted) {
      widget.store.updateProfile(widget.store.profile.copyWith(income: value));
    }
  }

  Future<void> confirmStop() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('End protection mode?'),
        content: const Text(
          'Restore the original local budget and demo schedules. No bank or provider instruction was sent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Keep protection'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('End protection'),
          ),
        ],
      ),
    );
    if (ok == true) widget.store.stopProtection();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.store;
    final draft = s.guardDraft;
    if (reviewedId != draft?.id) {
      reviewedId = draft?.id;
      selected =
          draft?.actions
              .where((a) => !a.providerOnly)
              .map((a) => a.id)
              .toSet() ??
          {};
      approved = false;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeading(
          'FIN-GUARD • Your financial recovery copilot',
          'Life changes. Your plan can adapt.',
          'Detect risk, review a 90-day recovery plan, then approve the changes.',
        ),
        const Notice(
          'Local protection mode updates the in-app budget and suppresses demo schedules. Cancelling a real subscription, pausing a bank mandate or moving an EMI date still requires the provider.',
          color: muted,
        ),
        const SizedBox(height: 20),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Monitor changes to my saved finances'),
                subtitle: const Text(
                  'Rechecks income, spending, goals and schedules when you update them in FINPATH. No background bank monitoring.',
                ),
                value: s.consent['guard'] == true,
                onChanged: (v) => s.setConsent('guard', v),
              ),
              if (s.guardAlert != null) ...[
                const SizedBox(height: 12),
                Notice(s.guardAlert!, color: s.protectionActive ? teal : amber),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: recordIncome,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Record income change'),
                  ),
                  OutlinedButton.icon(
                    onPressed: editBudget,
                    icon: const Icon(Icons.event_note_outlined),
                    label: const Text('Budget & schedules'),
                  ),
                  FilledButton(
                    onPressed: s.consent['guard'] == true && !s.protectionActive
                        ? () => run(s.prepareProtection)
                        : null,
                    child: const Text('Prepare recovery plan'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Income ${money(s.profile.income)} • Living expenses ${money(s.profile.expenses)} • SIP / transfers ${money(s.guardBudget.extraOutgo)}/month',
              ),
              if (s.guardBudget.payments.isEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Add your recurring schedules and discretionary category to find actionable savings. No subscriptions are inferred from your data.',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ],
          ),
        ),
        if (draft != null && !s.protectionActive) ...[
          const SizedBox(height: 24),
          const SectionTitle(
            'Your proposed 90-day protection plan',
            subtitle:
                'Select only the changes you want. Totals update before you approve.',
          ),
          ...draft.actions.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Panel(
                padding: const EdgeInsets.all(12),
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(a.title),
                  subtitle: Text(
                    '${a.providerOnly ? 'Timing only • provider approval required' : '+${money(a.monthlyRelease)}/month retained in cash'}\n${a.detail}',
                  ),
                  value: selected.contains(a.id),
                  onChanged: (v) => setState(() {
                    approved = false;
                    if (v == true) {
                      selected.add(a.id);
                    } else {
                      selected.remove(a.id);
                    }
                  }),
                ),
              ),
            ),
          ),
          if (draft.actions.isEmpty)
            const Notice(
              'No reducible categories or schedules are declared. Edit the budget, reduce the proposed loan, or discuss the plan with an advisor.',
              color: amber,
            ),
          _comparison(draft, selected),
          const SizedBox(height: 18),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle('Recovery milestones'),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.shield_outlined, color: teal),
                  title: Text('Days 1–30 • Stabilize'),
                  subtitle: Text(
                    'Apply approved demo schedule pauses and budget limits. Contact providers for real changes.',
                  ),
                ),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.insights_outlined, color: blue),
                  title: Text('Days 31–60 • Recheck'),
                  subtitle: Text(
                    'Review actual income and spending. Updated finances invalidate this plan and require fresh approval.',
                  ),
                ),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.flag_outlined, color: violet),
                  title: Text('Days 61–90 • Rebuild'),
                  subtitle: Text(
                    'Review the cash buffer and decide what to resume. Temporary local changes expire after 90 days.',
                  ),
                ),
                CheckboxListTile(
                  key: const Key('guard-approval'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'I approve the selected local changes for 90 days.',
                  ),
                  subtitle: const Text(
                    'I understand that provider actions must be completed separately and these cash projections are estimates.',
                  ),
                  value: approved,
                  onChanged: (v) => setState(() => approved = v ?? false),
                ),
                FilledButton.icon(
                  key: const Key('guard-activate'),
                  onPressed: approved && selected.isNotEmpty
                      ? () => run(() {
                          s.activateProtection(
                            draft.id,
                            selected,
                            approved: approved,
                          );
                          toast(
                            context,
                            'Protection activated in your local budget and demo schedule.',
                          );
                        })
                      : null,
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('Activate 90-Day Protection Mode'),
                ),
              ],
            ),
          ),
        ],
        if (s.protectionActive) ...[
          const SizedBox(height: 24),
          Panel(
            color: mint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle(
                  'Protection is active',
                  subtitle:
                      'Approved actions have been applied to FINPATH’s local planning budget.',
                ),
                Text(
                  'Expires ${s.protection!.expires.toLocal().toString().substring(0, 10)} • Effective monthly planning expenses ${money(s.planningProfile.expenses)}',
                ),
                const SizedBox(height: 12),
                ...s.protection!.plan.actions
                    .where((a) => s.protection!.selected.contains(a.id))
                    .map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${a.providerOnly ? 'Pending provider request' : 'Applied locally'}: ${a.title}',
                        ),
                      ),
                    ),
                TextButton(
                  onPressed: confirmStop,
                  child: const Text(
                    'End protection and restore local schedule',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _comparison(s.protection!.plan, s.protection!.selected),
        ],
        if (s.protectionHistory.isNotEmpty) ...[
          const SizedBox(height: 24),
          const SectionTitle(
            'Execution receipts & demo schedule',
            subtitle:
                'Stored approvals, scheduled occurrences and manual follow-ups. No bank transactions.',
          ),
          ...s.protectionHistory.map((record) {
            final plan = GuardPlan.fromJson(record['plan']);
            final stopped = record['stopped'] == true;
            return ExpansionTile(
              title: Text(
                '${plan.id} • ${stopped
                    ? 'Ended'
                    : DateTime.parse(record['expires']).isAfter(DateTime.now())
                    ? 'Active'
                    : 'Expired'}',
              ),
              subtitle: Text(
                'Approved ${record['activated'].toString().substring(0, 10)}',
              ),
              children: [
                if (stopped) Text(record['stopReason'] ?? 'Protection ended'),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    stopped
                        ? 'This is the archived schedule created at approval. Its suppressions no longer apply.'
                        : 'These are planned demo occurrences, not confirmations of bank transactions.',
                  ),
                ),
                ...(record['schedule'] as List? ?? [])
                    .take(12)
                    .map(
                      (row) => ListTile(
                        title: Text('${row['name']} • ${money(row['amount'])}'),
                        subtitle: Text(
                          '${row['date'].toString().substring(0, 10)} • ${row['status']}',
                        ),
                      ),
                    ),
                TextButton(
                  onPressed: () => exportScenario(
                    context,
                    'finpath-protection-receipt',
                    record,
                  ),
                  child: const Text('Export complete receipt and schedule'),
                ),
              ],
            );
          }),
        ],
      ],
    );
  }

  Widget _comparison(GuardPlan p, Set<String> actions) {
    String runway(double? value) => value == null
        ? 'No monthly deficit'
        : '${value.toStringAsFixed(1)} months';
    final after = p.afterOutgo(actions);
    final safeBefore = math.max(
      0.0,
      math.min(
        p.income * .35 - p.existingEmi,
        p.income * .8 - p.expenses - p.extraOutgo - p.existingEmi,
      ),
    );
    final safeAfter = math.max(
      0.0,
      math.min(
        p.income * .35 - p.existingEmi,
        p.income * .8 -
            p.expenses -
            p.extraOutgo +
            p.release(actions) -
            p.existingEmi,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatTiles([
          (
            'Monthly cash retained',
            money(p.release(actions)),
            'Reallocated spending / contributions, not earnings',
          ),
          (
            'Monthly outgo',
            '${money(p.beforeOutgo)} → ${money(after)}',
            'Includes current and proposed EMIs',
          ),
          (
            'Day 90 projected cash',
            '${money(p.cashAtDay(90, {}))} → ${money(p.cashAtDay(90, actions))}',
            'Negative cash is an unfunded need',
          ),
        ]),
        const SizedBox(height: 14),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deficit-funded runway: ${runway(p.runway({}))} → ${runway(p.runway(actions))}',
              ),
              Text('Safe new EMI: ${money(safeBefore)} → ${money(safeAfter)}'),
              const SizedBox(height: 10),
              Text(
                'Zero-income buffer: ${(p.beforeOutgo > 0 ? math.max(0, p.startingCash) / p.beforeOutgo : 0).toStringAsFixed(1)} → ${(after > 0 ? math.max(0, p.startingCash) / after : 0).toStringAsFixed(1)} months',
              ),
              const SizedBox(height: 10),
              const Text(
                'Runway divides available cash by the monthly income shortfall. The zero-income buffer divides cash by all outgo. Projections use 30-day months, include the proposed loan, and exclude investment gains, fees and taxes.',
                style: TextStyle(fontSize: 11, color: muted),
              ),
              if (p.cashAtDay(90, actions) < 0) ...[
                const SizedBox(height: 12),
                const Notice(
                  'Selected changes still leave a cash shortfall. Consider reducing the loan or reviewing this plan with an advisor.',
                  color: amber,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _IncomeDialog extends StatefulWidget {
  final double income;
  const _IncomeDialog(this.income);
  @override
  State<_IncomeDialog> createState() => _IncomeDialogState();
}

class _IncomeDialogState extends State<_IncomeDialog> {
  late final input = TextEditingController(
    text: widget.income.toStringAsFixed(0),
  );
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Record new monthly income'),
    scrollable: true,
    content: Form(
      key: form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Current income ${money(widget.income)}. Saving updates your profile and triggers monitoring if enabled.',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: input,
            decoration: const InputDecoration(
              labelText: 'New income',
              prefixText: '₹ ',
            ),
            keyboardType: TextInputType.number,
            validator: (v) {
              final n = double.tryParse(v ?? '');
              return n == null || !n.isFinite || n < 0 || n > 100000000
                  ? 'Enter a valid amount'
                  : null;
            },
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (form.currentState!.validate()) {
            Navigator.pop(context, double.parse(input.text));
          }
        },
        child: const Text('Save income'),
      ),
    ],
  );
}

class _BudgetDialog extends StatefulWidget {
  final AppStore store;
  const _BudgetDialog(this.store);
  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late final discretionary = TextEditingController(
    text: widget.store.guardBudget.discretionary.toStringAsFixed(0),
  );
  late int salary = widget.store.guardBudget.salaryDay,
      emi = widget.store.guardBudget.emiDay;
  late List<PlannedPayment> payments = [...widget.store.guardBudget.payments];
  final name = TextEditingController(), amount = TextEditingController();
  ScheduleKind kind = ScheduleKind.subscription;
  bool unused = false;
  int day = 5;
  String? error;
  @override
  void dispose() {
    discretionary.dispose();
    name.dispose();
    amount.dispose();
    super.dispose();
  }

  void add() {
    final value = double.tryParse(amount.text);
    if (name.text.trim().isEmpty ||
        value == null ||
        !value.isFinite ||
        value <= 0 ||
        value > 10000000) {
      setState(() => error = 'Enter a schedule name and positive amount.');
      return;
    }
    setState(() {
      payments.add(
        PlannedPayment(
          id: 'payment-${DateTime.now().microsecondsSinceEpoch}',
          name: name.text.trim(),
          kind: kind,
          amount: value,
          day: day,
          unused: unused,
        ),
      );
      name.clear();
      amount.clear();
      error = null;
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Budget & recurring schedules'),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Living expenses: ${money(widget.store.profile.expenses)}. Subscriptions and discretionary spending are categories inside this amount. SIPs/transfers are additional cash outflows; do not add them twice.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: discretionary,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Discretionary category / month',
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 12),
            _day('Salary day', salary, (v) => setState(() => salary = v)),
            _day('EMI day', emi, (v) => setState(() => emi = v)),
            const Divider(height: 24),
            ...payments.map(
              (p) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${p.name} • ${money(p.amount)}'),
                subtitle: Text(
                  '${p.kind.name} • day ${p.day}${p.unused ? ' • marked unused' : ''}',
                ),
                trailing: IconButton(
                  tooltip: 'Remove schedule',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => payments.remove(p)),
                ),
              ),
            ),
            DropdownButtonFormField<ScheduleKind>(
              isExpanded: true,
              initialValue: kind,
              decoration: const InputDecoration(labelText: 'Schedule type'),
              items: ScheduleKind.values
                  .map((k) => DropdownMenuItem(value: k, child: Text(k.name)))
                  .toList(),
              onChanged: (v) => setState(() => kind = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Schedule name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly amount',
                prefixText: '₹ ',
              ),
            ),
            _day('Due day', day, (v) => setState(() => day = v)),
            if (kind == ScheduleKind.subscription)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('I no longer use this subscription'),
                value: unused,
                onChanged: (v) => setState(() => unused = v ?? false),
              ),
            OutlinedButton(
              onPressed: add,
              child: const Text('Add recurring schedule'),
            ),
            TextButton(
              onPressed: () => setState(() {
                final cap = widget.store.profile.expenses;
                discretionary.text = math
                    .min(8000, cap * .25)
                    .toStringAsFixed(0);
                payments = [
                  PlannedPayment(
                    id: 'sample-sub',
                    name: 'Sample unused subscriptions',
                    kind: ScheduleKind.subscription,
                    amount: math.max(1, math.min(1800, cap * .1)),
                    unused: true,
                    day: 7,
                  ),
                  const PlannedPayment(
                    id: 'sample-sip',
                    name: 'Sample SIP',
                    kind: ScheduleKind.sip,
                    amount: 5000,
                    day: 10,
                  ),
                  const PlannedPayment(
                    id: 'sample-transfer',
                    name: 'Sample planned transfer',
                    kind: ScheduleKind.transfer,
                    amount: 2000,
                    day: 15,
                  ),
                ];
              }),
              child: const Text('Load editable demo schedules'),
            ),
            if (error != null)
              Text(error!, style: const TextStyle(color: amber)),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          final n = double.tryParse(discretionary.text);
          if (n == null ||
              !n.isFinite ||
              n < 0 ||
              n +
                      payments
                          .where((p) => p.kind == ScheduleKind.subscription)
                          .fold(0.0, (s, p) => s + p.amount) >
                  widget.store.profile.expenses) {
            setState(
              () => error =
                  'Categories must be non-negative and fit inside living expenses.',
            );
            return;
          }
          Navigator.pop(
            context,
            GuardBudget(
              discretionary: n,
              salaryDay: salary,
              emiDay: emi,
              payments: payments,
            ),
          );
        },
        child: const Text('Save budget'),
      ),
    ],
  );
  Widget _day(String label, int value, ValueChanged<int> change) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: DropdownButtonFormField<int>(
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: List.generate(
        28,
        (i) => DropdownMenuItem(value: i + 1, child: Text('Day ${i + 1}')),
      ),
      onChanged: (v) => change(v!),
    ),
  );
}
