import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/app_store.dart';
import '../../data/ai_service.dart';
import '../../ui/components.dart';
import '../../ui/theme.dart';

class ClaimsPage extends StatefulWidget {
  final AppStore store;
  final AiService ai;
  const ClaimsPage({required this.store, required this.ai, super.key});
  @override
  State<ClaimsPage> createState() => _ClaimsPageState();
}

class _ClaimsPageState extends State<ClaimsPage> {
  final form = GlobalKey<FormState>();
  late TextEditingController policy, hospital, reason, amount;
  DateTime? date;
  final checklist = {
    'Policy schedule': false,
    'Itemised hospital bills': false,
    'Discharge summary': false,
    'Payment receipts': false,
  };
  bool busy = false;
  String? aiDraft, error;
  @override
  void initState() {
    super.initState();
    final c = widget.store.claim;
    String? extractedPolicy;
    for (final d in widget.store.documents) {
      if (d.reviewed && d.fields['policy'] != null) {
        extractedPolicy = d.fields['policy'];
        break;
      }
    }
    policy = TextEditingController(text: c?['policy'] ?? extractedPolicy ?? '');
    hospital = TextEditingController(text: c?['hospital'] ?? '');
    reason = TextEditingController(text: c?['reason'] ?? '');
    amount = TextEditingController(text: c?['amount']?.toString() ?? '');
    if (c?['date'] != null) date = DateTime.tryParse(c!['date']);
    if (c?['checklist'] != null) {
      for (final k in checklist.keys) {
        checklist[k] = c!['checklist'][k] == true;
      }
    }
  }

  @override
  void dispose() {
    policy.dispose();
    hospital.dispose();
    reason.dispose();
    amount.dispose();
    super.dispose();
  }

  String draft() =>
      'HEALTH INSURANCE CLAIM — DRAFT\n\nPolicy: ${policy.text}\nClaimant: ${widget.store.profile.name}\nHospital: ${hospital.text}\nTreatment / reason: ${reason.text}\nTreatment date: ${date?.toIso8601String().split('T').first ?? 'Not supplied'}\nClaimed amount: INR ${amount.text}\n\nDocuments self-reported as ready:\n${checklist.entries.where((e) => e.value).map((e) => '• ${e.key}').join('\n')}\n\nStill to gather:\n${checklist.entries.where((e) => !e.value).map((e) => '• ${e.key}').join('\n')}\n\nPlease assess this claim against the policy terms. I will provide any additional documentation requested.\n\nThis draft has not been sent to an insurer. Document readiness is self-reported, not verified. Coverage and settlement are not confirmed.';
  bool validate() {
    if (!form.currentState!.validate()) return false;
    if (date == null) {
      toast(context, 'Choose the treatment date.');
      return false;
    }
    return true;
  }

  void save() {
    if (!validate()) return;
    widget.store.saveClaim({
      'policy': policy.text.trim(),
      'hospital': hospital.text.trim(),
      'reason': reason.text.trim(),
      'amount': double.parse(amount.text),
      'date': date!.toIso8601String(),
      'checklist': Map<String, bool>.from(checklist),
      'draft': draft(),
      'stage': 0,
    });
    toast(
      context,
      'Claim draft saved locally. Nothing was sent to an insurer.',
    );
  }

  Future<void> improve() async {
    if (!validate()) return;
    if (widget.store.consent['ai'] != true) {
      toast(context, 'Enable external AI processing in Privacy first.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      widget.store.log(
        'Gemini claim access',
        'Sent claim draft, treatment details and checklist for drafting help',
      );
      widget.store.save();
      final result = await widget.ai.request('claim', {
        'consent': true,
        'message': draft(),
        'language': widget.store.language,
      });
      if (widget.store.consent['ai'] != true) {
        throw const AiException(
          'Consent revoked. Returned claim guidance discarded.',
        );
      }
      if (mounted) setState(() => aiDraft = result['answer']);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.store;
    final healthTarget = 500000.0 * (1 + s.profile.dependents);
    final lifeTarget = s.profile.dependents > 0
        ? s.profile.income * 12 * 10
        : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeading(
          'Support when it matters most',
          'A little less worry. A clearer claim.',
          'Understand your cover and get the paperwork into place.',
        ),
        ResponsiveSplit(
          leftFlex: 1,
          rightFlex: 1,
          breakpoint: 650,
          left: Metric(
            'Illustrative health coverage gap',
            money(
              math.max(0, healthTarget - s.profile.healthCover),
              compact: true,
            ),
            'Entered cover ${money(s.profile.healthCover, compact: true)}',
            Icons.health_and_safety_outlined,
            color: teal,
          ),
          right: Metric(
            'Illustrative life coverage gap',
            money(math.max(0, lifeTarget - s.profile.lifeCover), compact: true),
            'Entered cover ${money(s.profile.lifeCover, compact: true)}',
            Icons.family_restroom_outlined,
            color: violet,
          ),
        ),
        const SizedBox(height: 16),
        const Notice(
          'Planning assumptions only: health cover = ₹5 lakh × (you + dependents); life cover = 10 × annual net income when you have dependents. These simple demo rules are not a coverage recommendation. Your policy’s exclusions, waiting periods, limits and co-pay determine actual coverage.',
          color: muted,
        ),
        const SizedBox(height: 26),
        ResponsiveSplit(
          left: Panel(
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle(
                    'Let’s prepare your health claim',
                    subtitle:
                        'You stay in control. Nothing is sent automatically.',
                  ),
                  _field(policy, 'Policy number'),
                  _field(hospital, 'Hospital / care provider'),
                  _field(reason, 'Treatment or reason for the claim', lines: 3),
                  _field(amount, 'Claimed amount (₹)', number: true),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: date ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (selected != null && mounted) {
                        setState(() => date = selected);
                      }
                    },
                    icon: const Icon(Icons.calendar_today_outlined, size: 17),
                    label: Text(
                      date == null
                          ? 'Choose treatment date'
                          : date!.toIso8601String().split('T').first,
                    ),
                  ),
                  const SizedBox(height: 25),
                  const SectionTitle(
                    'Get your documents together',
                    subtitle:
                        'Tick the items you have ready. Your insurer may ask for more.',
                  ),
                  ...checklist.entries.map(
                    (e) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(e.key, style: const TextStyle(fontSize: 12)),
                      value: e.value,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (v) =>
                          setState(() => checklist[e.key] = v ?? false),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: save,
                        icon: const Icon(Icons.save_outlined, size: 17),
                        label: const Text('Save claim draft'),
                      ),
                      OutlinedButton(
                        onPressed: busy ? null : improve,
                        child: Text(
                          busy ? 'Preparing…' : 'Get Gemini guidance',
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            policy.text = 'DEMO-HEALTH-2026';
                            hospital.text = 'City Care Hospital';
                            reason.text =
                                'Hospitalisation — fictional demo case';
                            amount.text = '45000';
                            date = DateTime.now().subtract(
                              const Duration(days: 3),
                            );
                          });
                        },
                        child: const Text('Fill sample'),
                      ),
                    ],
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Notice(error!, color: amber),
                    ),
                  if (aiDraft != null) ...[
                    const SizedBox(height: 24),
                    const SectionTitle('Gemini’s drafting guidance'),
                    SelectableText(
                      aiDraft!,
                      style: const TextStyle(fontSize: 12, height: 1.8),
                    ),
                  ],
                ],
              ),
            ),
          ),
          right: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Panel(
                color: mint,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const IconTile(
                      Icons.favorite_border,
                      color: teal,
                      size: 52,
                    ),
                    const SizedBox(height: 18),
                    const SectionTitle('Start with your policy.'),
                    const Text(
                      'Before filing, check:\n\n• Is the treatment covered?\n• Have waiting periods ended?\n• Are there room rent or treatment limits?\n• Is there a co-pay or deductible?\n• Does cashless care need pre-authorisation?\n• What is the submission deadline?',
                      style: TextStyle(fontSize: 12, height: 1.8, color: teal),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Use “Explain my contract” in the assistant to understand pasted policy terms.',
                      style: TextStyle(fontSize: 11, color: teal),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              if (s.claim != null)
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionTitle(
                        'Your claim workspace',
                        subtitle: 'Demo tracker • no insurer connection',
                      ),
                      ...List.generate(
                        4,
                        (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Row(
                            children: [
                              Icon(
                                i <= s.claim!['stage']
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: i <= s.claim!['stage'] ? teal : muted,
                                size: 20,
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Text(
                                  [
                                    'Draft prepared',
                                    'Documents organised',
                                    'Submitted • simulated',
                                    'Review complete • simulated',
                                  ][i],
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: s.claim!['draft']),
                          );
                          toast(
                            context,
                            'Claim draft copied. Review it before sharing.',
                          );
                        },
                        child: const Text('Copy saved claim draft'),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: s.claim!['stage'] < 3
                            ? s.advanceClaim
                            : null,
                        child: const Text(
                          'Advance demo stage  →',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Editing and saving the draft restarts this local tracker. A completed demo review is not a claim settlement.',
                        style: TextStyle(fontSize: 10, color: muted),
                      ),
                    ],
                  ),
                )
              else
                const Notice(
                  'Save your first claim draft to start a local checklist and progress tracker.',
                  color: blue,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    int lines = 1,
    bool number = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 17),
    child: TextFormField(
      controller: c,
      minLines: lines,
      maxLines: lines,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        if ((v ?? '').trim().isEmpty) return 'Please fill this in';
        if (number) {
          final n = double.tryParse(v!);
          if (n == null || !n.isFinite || n <= 0 || n > 100000000) {
            return 'Enter a valid positive amount';
          }
        }
        return null;
      },
    ),
  );
}
