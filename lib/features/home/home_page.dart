import 'package:flutter/material.dart';
import '../../data/app_store.dart';
import '../../data/ai_service.dart';
import '../../domain/finance_engine.dart';
import '../../domain/models.dart';
import '../../ui/components.dart';
import '../../ui/theme.dart';

class HomePage extends StatefulWidget {
  final AppStore store;
  final ValueChanged<int> navigate;
  final AiService ai;
  const HomePage({
    required this.store,
    required this.navigate,
    required this.ai,
    super.key,
  });
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final input = TextEditingController();
  bool planning = false;
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Future<void> start([String? goal]) async {
    if (planning) return;
    final text = goal ?? input.text;
    if (text.trim().isEmpty) {
      toast(context, 'Tell us what you’d like to work towards.');
      return;
    }
    var parsed = FinanceEngine.goalFromText(text);
    final store = widget.store;
    if (store.consent['ai'] == true) {
      setState(() => planning = true);
      try {
        store.log(
          'Gemini goal matching',
          'Sent the entered goal and selected language to identify the journey and stated budget',
        );
        store.save();
        parsed = await widget.ai.planGoal(text, store.language);
        if (!mounted) return;
        if (store.consent['ai'] != true) {
          toast(context, 'AI consent changed. Please enter your goal again.');
          return;
        }
      } catch (e) {
        if (!mounted) return;
        toast(
          context,
          'AI matching unavailable. Using the local matcher; review the goal and estimated cost.',
        );
      } finally {
        if (mounted) setState(() => planning = false);
      }
    }
    if (!mounted) return;
    if (parsed.kind == GoalKind.insurance) {
      widget.navigate(3);
      return;
    }
    widget.store.updateGoal(parsed);
    widget.navigate(1);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.store;
    final p = s.profile;
    final a = FinanceEngine.assess(p, s.goal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (planning) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
          const Text('Finding the right journey with Gemini…'),
          const SizedBox(height: 12),
        ],
        PageHeading(
          'A little clarity. A lot of possibility.',
          'Hello, ${p.name.split(' ').first.isEmpty ? 'there' : p.name.split(' ').first} 👋',
          'Let’s make your next big thing happen.',
          action: const Tag('Your space, your pace', icon: Icons.spa_outlined),
        ),
        ResponsiveSplit(
          leftFlex: 7,
          rightFlex: 3,
          breakpoint: 930,
          left: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF142F42), Color(0xFF124D52)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, c) => Padding(
                    padding: const EdgeInsets.all(30),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .10),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'A SMARTER WAY FORWARD',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    letterSpacing: 1.7,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFA6E3D0),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Big dreams.\nClear next steps.',
                                style: TextStyle(
                                  fontSize: 35,
                                  height: 1.12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1.4,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 15),
                              const Text(
                                'From “someday” to a plan. Understand your money,\nexplore your options, and move forward confidently.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.7,
                                  color: Color(0xFFC0D3D6),
                                ),
                              ),
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: () => widget.navigate(1),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFB4EFDA),
                                  foregroundColor: const Color(0xFF143E3C),
                                ),
                                label: const Text('Explore my plan'),
                                icon: const Icon(Icons.arrow_forward, size: 16),
                                iconAlignment: IconAlignment.end,
                              ),
                            ],
                          ),
                        ),
                        if (c.maxWidth > 630) const JourneyArt(),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(
                      'What’s your next chapter?',
                      subtitle:
                          'Tell us your goal. We’ll help you connect the dots.',
                    ),
                    TextField(
                      controller: input,
                      onSubmitted: (_) => start(),
                      textInputAction: TextInputAction.go,
                      decoration: InputDecoration(
                        hintText: 'I want to buy a bike for ₹1.5 lakh…',
                        hintStyle: const TextStyle(fontSize: 13, color: muted),
                        prefixIcon: const Icon(
                          Icons.auto_awesome_outlined,
                          color: blue,
                          size: 20,
                        ),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(7),
                          child: IconButton.filled(
                            tooltip: 'Create my plan',
                            onPressed: start,
                            icon: const Icon(Icons.arrow_forward, size: 19),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 17),
                    const Text(
                      'OR START WITH SOMETHING YOU HAVE IN MIND',
                      style: TextStyle(
                        fontSize: 8.5,
                        color: muted,
                        letterSpacing: 1.25,
                      ),
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, c) {
                        // Some Android devices briefly report a very narrow
                        // viewport while the first frame/insets settle. Keep
                        // the goal tiles valid at every width instead of
                        // producing a negative SizedBox constraint.
                        final count = c.maxWidth >= 550
                            ? 6
                            : c.maxWidth >= 240
                            ? 3
                            : c.maxWidth >= 150
                            ? 2
                            : 1;
                        final tileWidth = ((c.maxWidth -
                                    (count - 1) * 10) /
                                count)
                            .clamp(0.0, double.infinity)
                            .toDouble();
                        final goals = [
                          'Buy a bike',
                          'Buy a car',
                          'Education',
                          'A new home',
                          'My business',
                          'Health insurance',
                        ];
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: List.generate(
                            6,
                            (i) => SizedBox(
                              width: tileWidth,
                              child: InkWell(
                                onTap: () =>
                                    start('I want ${goals[i].toLowerCase()}'),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: i == 0
                                        ? const Color(0xFFF0F5FF)
                                        : const Color(0xFFFAFBFD),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: i == 0
                                          ? const Color(0xFFD9E6FF)
                                          : line,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        goalIcon(GoalKind.values[i]),
                                        size: 25,
                                        color: i == 0 ? blue : muted,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        goals[i],
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          right: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const IconTile(Icons.fingerprint, color: teal),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Your financial twin',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'A clearer picture of your money.',
                  style: TextStyle(fontSize: 11.5, color: muted),
                ),
                const SizedBox(height: 24),
                Center(
                  child: SizedBox(
                    width: 135,
                    height: 135,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: (a.bufferMonths / 6).clamp(0, 1),
                            strokeWidth: 10,
                            backgroundColor: line,
                            color: teal,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              a.bufferMonths.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 33,
                                fontWeight: FontWeight.w700,
                                color: ink,
                              ),
                            ),
                            const Text(
                              'months of buffer',
                              style: TextStyle(fontSize: 10, color: muted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Center(
                  child: Tag(
                    a.affordable
                        ? 'Room to move forward'
                        : 'Let’s strengthen your buffer',
                    color: a.affordable ? teal : amber,
                    icon: Icons.favorite_outline,
                  ),
                ),
                const SizedBox(height: 24),
                _twinRow(
                  'Monthly income',
                  money(p.income),
                  Icons.account_balance_wallet_outlined,
                  teal,
                ),
                _twinRow(
                  'Living expenses',
                  money(p.expenses),
                  Icons.shopping_bag_outlined,
                  violet,
                ),
                _twinRow(
                  'Existing EMIs',
                  money(p.existingEmi),
                  Icons.credit_card,
                  blue,
                ),
                const Divider(height: 26),
                _twinRow(
                  'Free cash / month',
                  money(p.surplus),
                  Icons.savings_outlined,
                  teal,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => widget.navigate(7),
                    child: const Text(
                      'Update my profile',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Sample profile • editable by you',
                    style: TextStyle(fontSize: 9.5, color: muted),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        SectionTitle(
          'Small steps. Real progress.',
          subtitle: 'Your financial journey, all in one place.',
          trailing: TextButton(
            onPressed: () => widget.navigate(5),
            child: const Text(
              'View journey  →',
              style: TextStyle(fontSize: 11),
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth > 800 ? 3 : 1;
            final cards = [
              _actionCard(
                '01',
                s.goal.title,
                'See how ${money(a.emi)}/month fits into your life.',
                goalIcon(s.goal.kind),
                blue,
                'Explore financing',
                () => widget.navigate(1),
              ),
              _actionCard(
                '02',
                'Less paperwork. More living.',
                '${s.documents.length} documents added. Upload once, review and autofill.',
                Icons.description_outlined,
                violet,
                'Manage documents',
                () => widget.navigate(2),
              ),
              _actionCard(
                '03',
                'Support when it matters',
                'Prepare your health claim with a clear checklist.',
                Icons.favorite_border,
                teal,
                'Start a claim',
                () => widget.navigate(3),
              ),
            ];
            return Wrap(
              spacing: 18,
              runSpacing: 18,
              children: cards
                  .map(
                    (w) => SizedBox(
                      width: (c.maxWidth - (cols - 1) * 18) / cols,
                      child: w,
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _twinRow(String title, String value, IconData icon, Color color) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 11, color: muted),
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
  Widget _actionCard(
    String number,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String action,
    VoidCallback onTap,
  ) => Panel(
    padding: const EdgeInsets.all(22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconTile(icon, color: color),
            const Spacer(),
            Text(
              number,
              style: const TextStyle(
                fontSize: 22,
                color: line,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 19),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 7),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11.5, height: 1.6, color: muted),
        ),
        const SizedBox(height: 17),
        InkWell(
          onTap: onTap,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  action,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Icon(Icons.arrow_forward, size: 14, color: color),
            ],
          ),
        ),
      ],
    ),
  );
}
