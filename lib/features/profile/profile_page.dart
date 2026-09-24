import 'package:flutter/material.dart';
import '../../data/app_store.dart';
import '../../domain/models.dart';
import '../../ui/components.dart';
import '../../ui/theme.dart';

class ProfilePage extends StatefulWidget {
  final AppStore store;
  const ProfilePage({required this.store, super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final form = GlobalKey<FormState>();
  late Map<String, TextEditingController> fields;
  @override
  void initState() {
    super.initState();
    fields = widget.store.profile.toJson().map(
      (k, v) => MapEntry(k, TextEditingController(text: v.toString())),
    );
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  void save() {
    if (!form.currentState!.validate()) return;
    final data = <String, dynamic>{};
    for (final e in fields.entries) {
      data[e.key] = ['name', 'email', 'employer'].contains(e.key)
          ? e.value.text.trim()
          : ['creditScore', 'dependents'].contains(e.key)
          ? int.parse(e.value.text)
          : double.parse(e.value.text);
    }
    widget.store.updateProfile(FinanceProfile.fromJson(data));
    toast(
      context,
      'Your financial twin is updated. All planning tools now use these values.',
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const PageHeading(
        'A clearer picture of you',
        'Meet your financial twin.',
        'One profile that keeps your whole journey in sync.',
      ),
      ResponsiveSplit(
        left: Panel(
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  'First, a little about you',
                  subtitle:
                      'Start with sample data, then make the numbers your own.',
                ),
                _field('name', 'Full name', text: true),
                _field('email', 'Email', text: true),
                _field('employer', 'Employer / occupation', text: true),
                const SizedBox(height: 16),
                const SectionTitle(
                  'Your month in numbers',
                  subtitle: 'Use monthly amounts in INR, after tax.',
                ),
                _field('income', 'Net monthly income'),
                _field('expenses', 'Monthly living expenses (excluding EMIs)'),
                _field('existingEmi', 'Existing monthly EMIs'),
                _field('savings', 'Liquid savings available today'),
                _field(
                  'creditScore',
                  'Self-reported credit score (300–900)',
                  integer: true,
                ),
                const SizedBox(height: 16),
                const SectionTitle('Your safety net'),
                _field('dependents', 'Financial dependents', integer: true),
                _field('healthCover', 'Existing health insurance cover'),
                _field('lifeCover', 'Existing life insurance cover'),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: save,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Update my financial twin'),
                ),
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
                  const IconTile(Icons.fingerprint, color: teal, size: 56),
                  const SizedBox(height: 22),
                  Text(
                    'A profile that works\nwith your real life.',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Every update flows into your EMI estimate, affordability check, insurance gap analysis and assistant context.',
                    style: TextStyle(fontSize: 13, height: 1.8, color: teal),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Notice(
              'No bank account or credit bureau is connected. All values are entered by you or reviewed from documents. Credit score is self-reported.',
              color: muted,
            ),
            const SizedBox(height: 20),
            const Notice(
              'This prototype saves profile and extracted fields in local app/browser storage, which is not encrypted. Use fictional data on shared devices.',
              color: amber,
            ),
          ],
        ),
      ),
    ],
  );
  Widget _field(
    String key,
    String label, {
    bool text = false,
    bool integer = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 17),
    child: TextFormField(
      controller: fields[key],
      keyboardType: text
          ? key == 'email'
                ? TextInputType.emailAddress
                : TextInputType.text
          : const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixText: !text && !integer ? '₹ ' : null,
      ),
      validator: (v) {
        if (text) {
          if (key == 'name' && (v ?? '').trim().isEmpty) {
            return 'Please enter a name';
          }
          if (key == 'email' &&
              (v ?? '').isNotEmpty &&
              !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v!)) {
            return 'Enter a valid email address';
          }
          return null;
        }
        final n = double.tryParse(v ?? '');
        if (n == null || !n.isFinite || n < 0 || n > 10000000000) {
          return 'Enter a valid non-negative number';
        }
        if (integer && int.tryParse(v ?? '') == null) {
          return 'Enter a whole number';
        }
        if (key == 'creditScore' && (n < 300 || n > 900)) {
          return 'Enter 300 to 900';
        }
        if (key == 'dependents' && n > 20) return 'Enter 0 to 20';
        return null;
      },
    ),
  );
}
