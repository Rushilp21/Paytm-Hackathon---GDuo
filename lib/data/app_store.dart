import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models.dart';
import '../domain/finance_engine.dart';

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
    profile = value;
    log(
      'Financial profile',
      'Updated the local financial twin and recalculated affordability',
    );
    save();
  }

  void updateGoal(FinancialGoal value) {
    goal = value;
    save();
  }

  void setConsent(String key, bool value) {
    consent[key] = value;
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
    profile = FinanceProfile.fromJson(merged);
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
    final a = FinanceEngine.assess(profile, goal);
    application = {
      'id': 'FP-${DateTime.now().millisecondsSinceEpoch}',
      'created': DateTime.now().toIso8601String(),
      'stage': 0,
      'profile': profile.toJson(),
      'goal': goal.toJson(),
      'emi': a.emi,
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
    final a = FinanceEngine.assess(profile, goal);
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
    await save();
  }
}
