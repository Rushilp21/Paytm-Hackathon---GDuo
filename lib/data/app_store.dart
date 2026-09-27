import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models.dart';
import '../domain/finance_engine.dart';
import '../domain/resilience_models.dart';
import '../domain/resilience_engine.dart';

class AppStore extends ChangeNotifier {
  FinanceProfile profile = const FinanceProfile();
  FinancialGoal goal = const FinancialGoal();
  List<DocumentRecord> documents = [];
  List<AuditEntry> audit = [];
  List<ChatMessage> messages = [];
  Map<String, bool> consent = {'documents': true, 'ai': false, 'voice': false};
  Map<String, dynamic>? application;
  Map<String, dynamic>? claim;
  String language = 'en-IN';
  String? persistenceError;
  bool aiReady = false;
  VerseSettings verseSettings = const VerseSettings();
  CrashSettings crashSettings = const CrashSettings();
  FuturePath chosenFuture = FuturePath.balanced;
  List<Map<String, dynamic>> savedFutures = [];
  GuardBudget guardBudget = const GuardBudget();
  GuardPlan? guardDraft;
  ProtectionRun? protection;
  List<Map<String, dynamic>> protectionHistory = [];
  String? guardAlert;

  bool get protectionActive =>
      consent['guard'] == true && protection?.activeAt(DateTime.now()) == true;

  // Guard schedules are additional savings transfers; subscriptions are
  // already included in the profile's living expenses. Count each only once.
  FinanceProfile get planningProfile {
    final release = protectionActive
        ? protection!.plan.release(protection!.selected)
        : 0.0;
    return profile.copyWith(
      expenses: (profile.expenses + guardBudget.extraOutgo - release)
          .clamp(0, double.infinity)
          .toDouble(),
    );
  }

  FinanceProfile get baselineProfile =>
      profile.copyWith(expenses: profile.expenses + guardBudget.extraOutgo);

  // Long-term alternatives use the regular budget, not a temporary 90-day
  // overlay. Each strategy replaces SIP allocation; other transfers remain.
  FinanceProfile get verseProfile {
    final transfers = guardBudget.payments
        .where((p) => p.kind == ScheduleKind.transfer)
        .fold(0.0, (sum, p) => sum + p.amount);
    return profile.copyWith(expenses: profile.expenses + transfers);
  }

  void setAiReady(bool value) {
    aiReady = value;
    notifyListeners();
  }

  SharedPreferences? _prefs;
  Future<void> _writes = Future.value();

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getString('finpath.v1');
      if (raw == null) return;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final loadedProfile = FinanceProfile.fromJson(j['profile']);
      final loadedGoal = FinancialGoal.fromJson(j['goal']);
      final loadedDocs = (j['documents'] as List)
          .map((e) => DocumentRecord.fromJson(e))
          .toList();
      final loadedAudit = (j['audit'] as List)
          .map((e) => AuditEntry.fromJson(e))
          .toList();
      final loadedMessages = (j['messages'] as List)
          .map((e) => ChatMessage.fromJson(e))
          .toList();
      profile = loadedProfile;
      goal = loadedGoal;
      documents = loadedDocs;
      audit = loadedAudit;
      messages = loadedMessages;
      consent = Map<String, bool>.from(j['consent']);
      application = j['application'];
      claim = j['claim'];
      language = j['language'] ?? 'en-IN';
      verseSettings = VerseSettings.fromJson(j['verseSettings'] ?? {});
      crashSettings = CrashSettings.fromJson(j['crashSettings'] ?? {});
      chosenFuture = FuturePath.values.byName(j['chosenFuture'] ?? 'balanced');
      savedFutures = List<Map<String, dynamic>>.from(j['savedFutures'] ?? []);
      guardBudget = GuardBudget.fromJson(j['guardBudget'] ?? {});
      guardDraft = j['guardDraft'] == null
          ? null
          : GuardPlan.fromJson(j['guardDraft']);
      protection = j['protection'] == null
          ? null
          : ProtectionRun.fromJson(j['protection']);
      protectionHistory = List<Map<String, dynamic>>.from(
        j['protectionHistory'] ?? [],
      );
      guardAlert = j['guardAlert'];
      refreshProtection();
    } catch (_) {
      persistenceError =
          'Saved data could not be loaded. A fresh demo is open.';
    }
  }

  Map<String, dynamic> toJson() => {
    'profile': profile.toJson(),
    'goal': goal.toJson(),
    'documents': documents.map((e) => e.toJson()).toList(),
    'audit': audit.map((e) => e.toJson()).toList(),
    'messages': messages.map((e) => e.toJson()).toList(),
    'consent': consent,
    'application': application,
    'claim': claim,
    'language': language,
    'verseSettings': verseSettings.toJson(),
    'crashSettings': crashSettings.toJson(),
    'chosenFuture': chosenFuture.name,
    'savedFutures': savedFutures,
    'guardBudget': guardBudget.toJson(),
    'guardDraft': guardDraft?.toJson(),
    'protection': protection?.toJson(),
    'protectionHistory': protectionHistory,
    'guardAlert': guardAlert,
  };
  Future<void> save() {
    final snapshot = jsonEncode(toJson());
    notifyListeners();
    _writes = _writes.then((_) async {
      try {
        _prefs ??= await SharedPreferences.getInstance();
        if (!await _prefs!.setString('finpath.v1', snapshot)) {
          throw StateError('Storage unavailable');
        }
      } catch (_) {
        persistenceError =
            'Changes are only in memory. Local storage is unavailable.';
        notifyListeners();
      }
    });
    return _writes;
  }

  void log(String category, String purpose) {
    audit.insert(0, AuditEntry(category, purpose, DateTime.now()));
    if (audit.length > 100) audit.removeLast();
  }

  void updateProfile(FinanceProfile value) {
    final previousIncome = profile.income;
    _invalidateProtection('Financial profile changed');
    profile = value;
    log(
      'Financial profile',
      'Updated the local financial twin and recalculated affordability',
    );
    _monitor(previousIncome: previousIncome);
    save();
  }

  void updateGoal(FinancialGoal value) {
    _invalidateProtection('Goal assumptions changed');
    goal = value;
    _monitor();
    save();
  }

  void setConsent(String key, bool value) {
    consent[key] = value;
    if (key == 'guard') {
      if (!value) {
        _invalidateProtection('Monitoring consent revoked');
        guardDraft = null;
        guardAlert = null;
      } else {
        _monitor();
      }
    }
    log(
      'Consent',
      '${value ? 'Allowed' : 'Revoked'} $key processing for future requests',
    );
    save();
  }

  void setLanguage(String value) {
    language = value;
    save();
  }

  void addDocument(DocumentRecord value) {
    if (consent['documents'] != true) {
      throw StateError('Document processing is disabled in Privacy.');
    }
    documents.insert(0, value);
    log(
      'Documents',
      '${value.name}: ${value.source}; extracted fields stored locally, original file not retained',
    );
    save();
  }

  void reviewDocument(int index, Map<String, String> fields) {
    final d = documents[index];
    documents[index] = DocumentRecord(
      name: d.name,
      fields: fields,
      source: d.source,
      created: d.created,
      reviewed: true,
    );
    final merged = profile.toJson();
    for (final key in ['name', 'email', 'employer']) {
      if (fields[key]?.isNotEmpty == true) merged[key] = fields[key];
    }
    for (final key in [
      'income',
      'expenses',
      'existingEmi',
      'savings',
      'healthCover',
      'lifeCover',
    ]) {
      final n = double.tryParse(fields[key] ?? '');
      if (n != null && n.isFinite && n >= 0) merged[key] = n;
    }
    final previousIncome = profile.income;
    _invalidateProtection('Reviewed document changed finances');
    profile = FinanceProfile.fromJson(merged);
    _monitor(previousIncome: previousIncome);
    log(
      'Documents',
      'User reviewed ${d.name}; confirmed fields autofilled the local profile',
    );
    save();
  }

  void removeDocument(int index) {
    documents.removeAt(index);
    log(
      'Documents',
      'Deleted an extracted document record. Confirmed profile values are retained until edited or reset.',
    );
    save();
  }

  void chat(ChatMessage message) {
    messages.add(message);
    if (messages.length > 60) messages.removeAt(0);
    save();
  }

  bool get canApply =>
      profile.name.trim().isNotEmpty &&
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(profile.email) &&
      profile.income > 0 &&
      documents.any((d) => d.reviewed && d.fields.containsKey('income'));
  void submitApplication() {
    if (!canApply) {
      throw StateError(
        'Review an income document and complete your name, email and income first.',
      );
    }
    final a = FinanceEngine.assess(planningProfile, goal);
    application = {
      'id': 'FP-${DateTime.now().millisecondsSinceEpoch}',
      'created': DateTime.now().toIso8601String(),
      'stage': 0,
      'profile': profile.toJson(),
      'goal': goal.toJson(),
      'emi': a.emi,
      'planningExpenses': planningProfile.expenses,
    };
    log(
      'Application',
      'Created a local demo application snapshot; no lender received data',
    );
    save();
  }

  void advanceApplication() {
    if (application != null && application!['stage'] < 3) {
      application!['stage']++;
      save();
    }
  }

  void saveClaim(Map<String, dynamic> value) {
    claim = value;
    log('Claim', 'Saved a local claim draft; no insurer received data');
    save();
  }

  void advanceClaim() {
    if (claim != null && (claim!['stage'] as int) < 3) {
      claim!['stage']++;
      save();
    }
  }

  String handoffSummary() {
    final a = FinanceEngine.assess(planningProfile, goal);
    return 'FINPATH • Advisor handoff draft\nPrepared: ${DateTime.now().toIso8601String()}\nCustomer: ${profile.name}\nGoal: ${goal.title}\nGoal amount: INR ${goal.amount.toStringAsFixed(0)}\nIncome / expenses / existing EMI: INR ${profile.income} / ${profile.expenses} / ${profile.existingEmi}\nProposed EMI: INR ${a.emi.toStringAsFixed(0)}\nRisk notes: ${a.reasons.isEmpty ? 'Within demo affordability thresholds' : a.reasons.join(' ')}\nReviewed documents: ${documents.where((d) => d.reviewed).map((d) => d.name).join(', ')}\nApplication: ${application?['id'] ?? 'Not started'}\nClaim: ${claim?['policy'] ?? 'Not started'}\nRecent conversation:\n${messages.skip(messages.length > 6 ? messages.length - 6 : 0).map((m) => '${m.isUser ? 'Customer' : 'Assistant'}: ${m.text}').join('\n')}\n\nNot sent. Share with your chosen advisor after reviewing.';
  }

  Future<void> reset() async {
    profile = const FinanceProfile();
    goal = const FinancialGoal();
    documents = [];
    audit = [];
    messages = [];
    application = null;
    claim = null;
    consent = {'documents': true, 'ai': false, 'voice': false};
    language = 'en-IN';
    persistenceError = null;
    verseSettings = const VerseSettings();
    crashSettings = const CrashSettings();
    chosenFuture = FuturePath.balanced;
    savedFutures = [];
    guardBudget = const GuardBudget();
    guardDraft = null;
    protection = null;
    protectionHistory = [];
    guardAlert = null;
    await save();
  }

  void updateVerse(VerseSettings settings) {
    ResilienceEngine.verse(verseProfile, goal, settings);
    verseSettings = settings;
    save();
  }

  void chooseFuture(FuturePath path) {
    chosenFuture = path;
    save();
  }

  void saveFuture() {
    final results = ResilienceEngine.verse(verseProfile, goal, verseSettings);
    savedFutures.insert(0, {
      'created': DateTime.now().toIso8601String(),
      'profile': verseProfile.toJson(),
      'goal': goal.toJson(),
      'settings': verseSettings.toJson(),
      'chosen': chosenFuture.name,
      'results': results
          .map(
            (r) => {
              'path': r.path.name,
              'finalAssets': r.last.assets,
              'targetMonth': r.targetMonth,
              'firstShortfall': r.firstShortfall,
            },
          )
          .toList(),
    });
    if (savedFutures.length > 10) savedFutures.removeLast();
    log(
      'FIN-VERSE',
      'Saved five modelled futures and their exact assumptions locally',
    );
    save();
  }

  void updateCrash(CrashSettings settings) {
    ResilienceEngine.crash(baselineProfile, goal, settings);
    crashSettings = settings;
    save();
  }

  void updateGuardBudget(GuardBudget budget) {
    ResilienceEngine.validateBudget(profile, budget);
    _invalidateProtection('Budget schedules changed');
    guardBudget = budget;
    _monitor();
    log(
      'FIN-GUARD',
      'Updated user-declared budget categories and demo schedules',
    );
    save();
  }

  void _monitor({double? previousIncome}) {
    guardDraft = null;
    if (consent['guard'] != true) return;
    try {
      guardDraft = ResilienceEngine.guard(
        profile,
        goal,
        guardBudget,
        previousIncome: previousIncome,
      );
      guardAlert = guardDraft!.reasons.first;
      log(
        'FIN-GUARD',
        'Rechecked local finances; created a review-only 90-day recovery proposal',
      );
    } on ArgumentError {
      guardAlert =
          'Living expenses no longer cover the declared categories. Review FIN-GUARD budget settings.';
    }
  }

  void prepareProtection() {
    if (consent['guard'] != true) {
      throw StateError('Enable FIN-GUARD monitoring consent first.');
    }
    if (protectionActive) {
      throw StateError(
        'Stop the current protection plan before preparing another.',
      );
    }
    _monitor();
    save();
  }

  bool activateProtection(
    String draftId,
    Set<String> selected, {
    required bool approved,
    DateTime? now,
  }) {
    if (!approved || consent['guard'] != true) {
      throw StateError('Review and approve the plan with monitoring enabled.');
    }
    if (protection?.plan.id == draftId) return false;
    final draft = guardDraft;
    if (draft == null ||
        draft.id != draftId ||
        draft.signature !=
            ResilienceEngine.signature(profile, goal, guardBudget)) {
      throw StateError('Finances changed. Generate and review a fresh plan.');
    }
    if (selected.isEmpty ||
        !selected.every((id) => draft.actions.any((a) => a.id == id))) {
      throw StateError('Select valid actions to approve.');
    }
    final at = now ?? DateTime.now();
    final run = ProtectionRun(
      plan: draft,
      selected: Set.unmodifiable(selected),
      activated: at,
      expires: at.add(const Duration(days: 90)),
    );
    protection = run;
    protectionHistory.insert(0, {
      ...run.toJson(),
      'schedule': ResilienceEngine.schedule(guardBudget, run),
    });
    if (protectionHistory.length > 10) protectionHistory.removeLast();
    guardDraft = null;
    guardAlert =
        '90-day protection active in your local budget and demo schedules.';
    for (final action in draft.actions.where((a) => selected.contains(a.id))) {
      log(
        'FIN-GUARD',
        '${action.title}: ${action.providerOnly ? 'manual provider follow-up prepared' : 'applied to local budget/schedule only'}',
      );
    }
    save();
    return true;
  }

  void _invalidateProtection(String reason) {
    if (protection == null || protection!.stopped) return;
    final run = protection!;
    protection = ProtectionRun(
      plan: run.plan,
      selected: run.selected,
      activated: run.activated,
      expires: run.expires,
      stopped: true,
    );
    for (final record in protectionHistory) {
      if ((record['plan'] as Map)['id'] == run.plan.id) {
        record['stopped'] = true;
        record['stopReason'] = reason;
        record['stoppedAt'] = DateTime.now().toIso8601String();
      }
    }
    log(
      'FIN-GUARD',
      '$reason; temporary local changes ended. No provider actions were reversed or sent.',
    );
  }

  void stopProtection() {
    _invalidateProtection('User stopped protection');
    guardAlert =
        'Protection stopped. The base budget and schedules are restored.';
    save();
  }

  void refreshProtection() {
    if (protection != null &&
        !protection!.stopped &&
        !protection!.activeAt(DateTime.now())) {
      _invalidateProtection('90-day protection expired');
      guardAlert =
          'Protection expired. Review your current finances before reactivating.';
      save();
    }
  }
}
