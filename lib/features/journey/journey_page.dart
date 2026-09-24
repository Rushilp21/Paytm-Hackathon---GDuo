import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../data/app_store.dart';
import '../../domain/models.dart';
import '../../domain/finance_engine.dart';
import '../../ui/components.dart';
import '../../ui/theme.dart';

class JourneyPage extends StatefulWidget {
  final AppStore store;
  final ValueChanged<int> navigate;
  const JourneyPage({required this.store, required this.navigate, super.key});
  @override
  State<JourneyPage> createState() => _JourneyPageState();
}

class _JourneyPageState extends State<JourneyPage> {
  bool approved = false;
  Future<void> export() async {
    try {
      await FilePicker.platform.saveFile(
        dialogTitle: 'Save application snapshot',
        fileName: 'finpath-application.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: utf8.encode(
          const JsonEncoder.withIndent('  ').convert({
            'mode': 'local_demo_not_submitted',
            ...widget.store.application!,
          }),
        ),
      );
    } catch (_) {
      if (mounted) {
        toast(context, 'Unable to export. Check download permissions.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.store;
    final app = s.application;
    final g = app == null ? s.goal : FinancialGoal.fromJson(app['goal']);
    final p = app == null ? s.profile : FinanceProfile.fromJson(app['profile']);
    final a = FinanceEngine.assess(p, g);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeading(
          'From a goal to a next step',
          app == null ? 'Ready when you are.' : 'Look how far you’ve come.',
          app == null
              ? 'Review the details before starting your demo application.'
              : 'Your plan, paperwork and progress. Together in one place.',
          action: const Tag(
            'Local demo journey',
            color: violet,
            icon: Icons.science_outlined,
          ),
        ),
        ResponsiveSplit(
          leftFlex: 6,
          rightFlex: 4,
          left: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconTile(goalIcon(g.kind), size: 54),
                    const SizedBox(width: 16),
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
                            app == null ? 'Application preview' : app['id'],
                            style: const TextStyle(fontSize: 11, color: muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 40),
                if (app == null) ...[
                  _detail('Applicant', p.name),
                  _detail(
                    'Email',
                    p.email.isEmpty ? 'Missing — update profile' : p.email,
                  ),
                  _detail('Monthly income', money(p.income)),
                  _detail('Goal cost', money(g.amount)),
                  _detail('Down payment', money(g.downPayment)),
                  _detail('Loan requested', money(g.amount - g.downPayment)),
                  _detail(
                    'Term / rate',
                    '${g.months} months / ${g.rate}% p.a.',
                  ),
                  _detail('Estimated EMI', money(a.emi)),
                  _detail('Total loan repayment', money(a.repayment)),
                  const SizedBox(height: 20),
                  Notice(
                    a.affordable
                        ? 'Within the demo budget rules. This is not a lender approval.'
                        : a.reasons.join('\n'),
                    color: a.affordable ? teal : amber,
                  ),
                  const SizedBox(height: 18),
                  if (!s.canApply) ...[
                    const Notice(
                      'Before continuing: review an income document and complete your name, email and income.',
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => widget.navigate(2),
                      child: const Text('Complete my documents'),
                    ),
                  ],
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: approved,
                    onChanged: (v) => setState(() => approved = v ?? false),
                    title: const Text(
                      'I reviewed these details. I understand this creates a local demo application and sends nothing to a lender.',
                      style: TextStyle(fontSize: 11, height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 15),
                  FilledButton.icon(
                    onPressed: s.canApply && approved
                        ? () {
                            s.submitApplication();
                            toast(
                              context,
                              'Demo application created. Your submitted details are now a saved snapshot.',
                            );
                          }
                        : null,
                    icon: const Icon(Icons.arrow_forward, size: 17),
                    iconAlignment: IconAlignment.end,
                    label: const Text('Create demo application'),
                  ),
                ] else ...[
                  Notice(
                    app['stage'] == 3
                        ? 'Demo journey completed. No real loan has been approved or disbursed.'
                        : 'Your demo application is in progress. Advance each stage to explore the journey.',
                    color: teal,
                    icon: Icons.check_circle_outline,
                  ),
                  const SizedBox(height: 30),
                  ...List.generate(
                    4,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 26),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: i <= app['stage'] ? mint : canvas,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              i <= app['stage']
                                  ? Icons.check
                                  : Icons.more_horiz,
                              color: i <= app['stage'] ? teal : muted,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  [
                                    'Application prepared',
                                    'Document review',
                                    'Credit assessment',
                                    'Approval & disbursal',
                                  ][i],
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  [
                                    'Your confirmed details were saved on this device.',
                                    'Simulated review of your self-confirmed documents.',
                                    'Simulated underwriting — no bureau has been queried.',
                                    'Simulated outcome — no money moves.',
                                  ][i],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (i == app['stage'])
                            const Tag('Current', color: blue),
                        ],
                      ),
                    ),
                  ),
                  if (app['stage'] < 3)
                    FilledButton(
                      onPressed: s.advanceApplication,
                      child: const Text('Advance demo stage  →'),
                    ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: export,
                    icon: const Icon(Icons.download_outlined, size: 17),
                    label: const Text('Export application snapshot'),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Later profile or simulator edits do not change this saved application.',
                    style: TextStyle(fontSize: 10, color: muted),
                  ),
                ],
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
                    const Icon(Icons.route, color: Color(0xFF91E7C7), size: 35),
                    const SizedBox(height: 20),
                    const Text(
                      'Every big move starts\nwith a little clarity.',
                      style: TextStyle(
                        fontSize: 25,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      '${money(a.emi)} / month',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Color(0xFFB4EFDA),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Your estimated EMI',
                      style: TextStyle(color: Color(0xFFAEC7D0), fontSize: 11),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      '${a.bufferMonths.toStringAsFixed(1)} months',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Your savings buffer after down payment',
                      style: TextStyle(color: Color(0xFFAEC7D0), fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle('Your next good move'),
                    _step(
                      Icons.description_outlined,
                      'Keep your documents handy',
                      'Review every extracted field before using it.',
                    ),
                    _step(
                      Icons.savings_outlined,
                      'Keep room for the unexpected',
                      'Watch your emergency buffer as plans change.',
                    ),
                    _step(
                      Icons.chat_bubble_outline,
                      'Ask the small questions',
                      'Your assistant can explain the numbers.',
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => widget.navigate(4),
                      child: const Text(
                        'Talk it through  →',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detail(String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 12, color: muted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
  Widget _step(IconData icon, String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: teal, size: 19),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(body, style: const TextStyle(fontSize: 11, color: muted)),
            ],
          ),
        ),
      ],
    ),
  );
}
