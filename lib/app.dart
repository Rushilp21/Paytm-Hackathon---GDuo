import 'dart:async';
import 'package:flutter/material.dart';
import 'data/app_store.dart';
import 'data/ai_service.dart';
import 'features/home/home_page.dart';
import 'features/planner/planner_page.dart';
import 'features/documents/documents_page.dart';
import 'features/claims/claims_page.dart';
import 'features/assistant/assistant_page.dart';
import 'features/journey/journey_page.dart';
import 'features/profile/profile_page.dart';
import 'features/privacy/privacy_page.dart';
import 'features/finverse/finverse_page.dart';
import 'features/crash/crash_page.dart';
import 'features/guard/guard_page.dart';
import 'ui/components.dart';
import 'ui/theme.dart';

class FinpathApp extends StatelessWidget {
  final AppStore store;
  const FinpathApp({required this.store, super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FINPATH • Your next chapter',
    debugShowCheckedModeBanner: false,
    theme: finTheme(),
    home: AppShell(store: store),
  );
}

class AppShell extends StatefulWidget {
  final AppStore store;
  const AppShell({required this.store, super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int page = 0;
  final ai = AiService();
  Timer? protectionTimer;
  static const labels = [
    'Overview',
    'Plan & compare',
    'Documents',
    'Insurance claims',
    'AI assistant',
    'Your journey',
    'Privacy & consent',
    'Financial profile',
    'FIN-VERSE',
    'FIN-CRASH',
    'FIN-GUARD',
  ];
  static const icons = [
    Icons.grid_view_rounded,
    Icons.tune_rounded,
    Icons.description_outlined,
    Icons.favorite_border_rounded,
    Icons.auto_awesome_outlined,
    Icons.route_outlined,
    Icons.shield_outlined,
    Icons.person_outline,
    Icons.alt_route_rounded,
    Icons.bolt_outlined,
    Icons.health_and_safety_outlined,
  ];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    protectionTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => widget.store.refreshProtection(),
    );
    ai.health().then((ready) {
      if (mounted) setState(() => widget.store.aiReady = ready);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.store.refreshProtection();
  }

  @override
  void dispose() {
    protectionTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    ai.client.close();
    super.dispose();
  }

  void navigate(int value) {
    setState(() => page = value);
  }

  Widget sidebar({bool drawer = false}) => Container(
    width: 228,
    color: Colors.white,
    child: SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(26, 32, 24, 12),
              child: Brand(),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 27, bottom: 42),
              child: Text(
                'BIGGER TOMORROWS START HERE',
                style: TextStyle(
                  fontSize: 7.5,
                  letterSpacing: 1.3,
                  color: muted,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                'YOUR WORKSPACE',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w700,
                  color: muted.withValues(alpha: .8),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...List.generate(
              labels.length,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 3,
                ),
                child: Material(
                  color: page == i
                      ? const Color(0xFFECF2FF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                    leading: Icon(
                      icons[i],
                      size: 19,
                      color: page == i ? blue : muted,
                    ),
                    title: Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: page == i
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: page == i ? blue : ink,
                      ),
                    ),
                    onTap: () {
                      if (drawer) Navigator.pop(context);
                      navigate(i);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Panel(
                color: const Color(0xFFF0F7F6),
                padding: const EdgeInsets.all(17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.support_agent, color: teal, size: 25),
                    const SizedBox(height: 10),
                    const Text(
                      'A little guidance helps.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Make sense of your next move.',
                      style: TextStyle(fontSize: 10.5, color: muted),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        if (drawer) Navigator.pop(context);
                        navigate(4);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: teal,
                      ),
                      child: const Text(
                        'Let’s talk  →',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(27, 0, 20, 22),
              child: Text(
                'FINPATH  /  HACKATHON EDITION',
                style: TextStyle(fontSize: 8, letterSpacing: 1, color: muted),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) {
      final s = widget.store;
      final viewportWidth = MediaQuery.sizeOf(context).width;
      final wide = viewportWidth >= 1080;
      final compactHeader = viewportWidth < 330;
      final pages = <Widget>[
        HomePage(store: s, navigate: navigate, ai: ai),
        PlannerPage(store: s, navigate: navigate),
        DocumentsPage(store: s, ai: ai, navigate: navigate),
        ClaimsPage(store: s, ai: ai),
        AssistantPage(store: s, ai: ai, navigate: navigate),
        JourneyPage(store: s, navigate: navigate),
        PrivacyPage(store: s, ai: ai),
        ProfilePage(store: s),
        FinversePage(store: s, navigate: navigate),
        CrashPage(store: s, navigate: navigate),
        GuardPage(store: s),
      ];
      return Scaffold(
        drawer: wide ? null : Drawer(child: sidebar(drawer: true)),
        body: SafeArea(
          bottom: false,
          child: Row(
            children: [
              if (wide) sidebar(),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 82,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(bottom: BorderSide(color: line)),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: wide ? 36 : 16),
                      child: Row(
                        children: [
                          if (!wide)
                            Builder(
                              builder: (context) => IconButton(
                                tooltip: 'Open navigation',
                                onPressed: () =>
                                    Scaffold.of(context).openDrawer(),
                                icon: const Icon(Icons.menu_rounded),
                              ),
                            ),
                          if (wide) ...[
                            const Text(
                              'Workspace',
                              style: TextStyle(fontSize: 12, color: muted),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 13),
                              child: Text('/', style: TextStyle(color: line)),
                            ),
                            Text(
                              labels[page],
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ] else
                            Brand(compact: compactHeader),
                          const Spacer(),
                          if (MediaQuery.sizeOf(context).width > 520) ...[
                            Tag(
                              s.aiReady ? 'Gemini connected' : 'Local demo',
                              color: s.aiReady ? teal : muted,
                              icon: Icons.circle,
                            ),
                            const SizedBox(width: 17),
                          ],
                          if (!compactHeader)
                            IconButton(
                              tooltip: 'Your journey',
                              onPressed: () => navigate(5),
                              icon: const Icon(
                                Icons.notifications_none_rounded,
                                size: 22,
                              ),
                            ),
                          SizedBox(width: compactHeader ? 4 : 12),
                          InkWell(
                            onTap: () => navigate(7),
                            borderRadius: BorderRadius.circular(30),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFFF4DFC5),
                              child: Text(
                                s.profile.name.isEmpty
                                    ? 'F'
                                    : s.profile.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF906439),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        key: ValueKey(page),
                        padding: EdgeInsets.all(wide ? 34 : 20),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1320),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (s.persistenceError != null) ...[
                                  Notice(s.persistenceError!, color: amber),
                                  const SizedBox(height: 16),
                                ],
                                pages[page],
                                const SizedBox(height: 30),
                                const Center(
                                  child: Text(
                                    'Made for your next chapter.  •  FINPATH prototype',
                                    style: TextStyle(
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                height: 66,
                selectedIndex: [0, 1, 4, 5].contains(page)
                    ? [0, 1, 4, 5].indexOf(page)
                    : 0,
                onDestinationSelected: (i) => navigate([0, 1, 4, 5][i]),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.grid_view_outlined),
                    label: 'Home',
                  ),
                  NavigationDestination(icon: Icon(Icons.tune), label: 'Plan'),
                  NavigationDestination(
                    icon: Icon(Icons.auto_awesome_outlined),
                    label: 'Assistant',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.route_outlined),
                    label: 'Journey',
                  ),
                ],
              ),
      );
    },
  );
}
