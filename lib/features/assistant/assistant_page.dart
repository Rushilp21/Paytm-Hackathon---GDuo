import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../data/app_store.dart';
import '../../data/ai_service.dart';
import '../../domain/models.dart';
import '../../domain/finance_engine.dart';
import '../../domain/local_advisor.dart';
import '../../ui/components.dart';
import '../../ui/theme.dart';

class AssistantPage extends StatefulWidget {
  final AppStore store;
  final AiService ai;
  final ValueChanged<int> navigate;
  const AssistantPage({
    required this.store,
    required this.ai,
    required this.navigate,
    super.key,
  });
  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final input = TextEditingController();
  final toolText = TextEditingController();
  final scroll = ScrollController();
  final speech = SpeechToText();
  final tts = FlutterTts();
  int tab = 0;
  bool busy = false, listening = false;
  String? result, error;
  @override
  void dispose() {
    speech.cancel();
    tts.stop();
    input.dispose();
    toolText.dispose();
    scroll.dispose();
    super.dispose();
  }

  void bottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && scroll.hasClients) {
        scroll.animateTo(
          scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> send([String? question]) async {
    if (busy) return;
    final text = (question ?? input.text).trim();
    if (text.isEmpty) return;
    final s = widget.store;
    s.chat(ChatMessage(text, isUser: true));
    input.clear();
    setState(() {
      busy = true;
      error = null;
    });
    bottom();
    try {
      String answer;
      if (s.consent['ai'] == true) {
        final a = FinanceEngine.assess(s.planningProfile, s.goal);
        s.log(
          'Gemini conversation',
          'Sent question, financial profile (without name/email/employer), goal, calculations and recent messages for a reply',
        );
        s.save();
        final profileContext =
            Map<String, dynamic>.from(s.planningProfile.toJson())
              ..remove('name')
              ..remove('email')
              ..remove('employer');
        final data = await widget.ai.request('chat', {
          'consent': true,
          'message': text,
          'language': s.language,
          'context': {
            'profile': profileContext,
            'goal': s.goal.toJson(),
            'calculation': {
              'emi': a.emi,
              'interest': a.interest,
              'repayment': a.repayment,
              'remaining': a.remaining,
              'bufferMonths': a.bufferMonths,
              'reasons': a.reasons,
            },
            'application': s.application == null
                ? null
                : {'mode': 'local demo', 'stage': s.application!['stage']},
          },
          'history': s.messages
              .skip(s.messages.length > 10 ? s.messages.length - 10 : 0)
              .map((m) => m.toJson())
              .toList(),
        });
        if (s.consent['ai'] != true) {
          throw const AiException(
            'Consent revoked. The returned AI reply was discarded.',
          );
        }
        answer = '${data['answer']}\n\n— Gemini • check important details';
      } else {
        answer =
            '${LocalAdvisor.answer(text, s.planningProfile, s.goal, s.language)}\n\n— Local guide • rule-based';
      }
      s.chat(ChatMessage(answer));
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) {
        setState(() => busy = false);
        bottom();
      }
    }
  }

  Future<void> voice() async {
    if (widget.store.consent['voice'] != true) {
      toast(context, 'Allow microphone & voice services in Privacy first.');
      return;
    }
    if (listening) {
      await speech.stop();
      if (mounted) setState(() => listening = false);
      return;
    }
    try {
      final ready = await speech.initialize(
        onError: (e) {
          if (mounted) {
            setState(() => listening = false);
            toast(
              context,
              'Speech recognition unavailable: ${e.errorMsg}. You can still type.',
            );
          }
        },
        onStatus: (status) {
          if (mounted && (status == 'done' || status == 'notListening')) {
            setState(() => listening = false);
          }
        },
      );
      if (!ready) {
        if (mounted) {
          toast(
            context,
            'Microphone permission or speech recognition is unavailable. Try Chrome or Android, or type your question.',
          );
        }
        return;
      }
      if (widget.store.consent['voice'] != true) return;
      widget.store.log(
        'Voice',
        'Started device/browser speech recognition in ${widget.store.language}',
      );
      widget.store.save();
      if (mounted) setState(() => listening = true);
      await speech.listen(
        listenOptions: SpeechListenOptions(
          localeId: widget.store.language,
          listenFor: const Duration(seconds: 30),
        ),
        onResult: (r) {
          if (mounted) setState(() => input.text = r.recognizedWords);
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() => listening = false);
        toast(context, 'Voice is unavailable here. Type your message instead.');
      }
    }
  }

  Future<void> speak(String text) async {
    if (widget.store.consent['voice'] != true) {
      toast(context, 'Allow voice services in Privacy to read replies aloud.');
      return;
    }
    try {
      await tts.setLanguage(widget.store.language);
      await tts.setSpeechRate(.48);
      await tts.speak(text);
      widget.store.log(
        'Voice',
        'Read an assistant reply using device/browser text-to-speech',
      );
      widget.store.save();
    } catch (_) {
      if (mounted) {
        toast(context, 'This voice is not installed on your device.');
      }
    }
  }

  Future<void> analyze({bool useAi = false}) async {
    if (toolText.text.trim().isEmpty) {
      toast(context, 'Paste the text you want to check first.');
      return;
    }
    setState(() {
      busy = true;
      result = null;
      error = null;
    });
    try {
      if (tab == 2) {
        final flags = FinanceEngine.scamFlags(toolText.text);
        result = flags.isEmpty
            ? 'No matching red-flag patterns found. This does NOT prove the message is safe. Independently verify the sender and terms through the provider’s official contact details.'
            : '${flags.length} patterns to look at carefully:\n\n${flags.map((f) => '• $f').join('\n\n')}\n\nThis is a local pattern check, not a fraud verdict.';
      } else if (useAi) {
        if (widget.store.consent['ai'] != true) {
          throw const AiException(
            'Allow external AI processing in Privacy first.',
          );
        }
        widget.store.log(
          'Gemini contract access',
          'Sent pasted contract text for a plain-language explanation',
        );
        widget.store.save();
        final data = await widget.ai.request('contract', {
          'consent': true,
          'message': toolText.text,
          'language': widget.store.language,
        });
        if (widget.store.consent['ai'] != true) {
          throw const AiException('Consent revoked. AI response discarded.');
        }
        result =
            '${data['answer']}\n\n— Gemini explanation; review against the original contract.';
      } else {
        final clauses = FinanceEngine.contractClauses(toolText.text);
        result = clauses.isEmpty
            ? 'No matching clauses found. This local keyword scan cannot establish that a contract is safe or complete. Use Gemini for a fuller explanation or ask a qualified advisor.'
            : 'Clauses worth reviewing (local keyword scan):\n\n${clauses.map((c) => '• $c').join('\n\n')}\n\nAsk about the effective annual cost, fees, exclusions, cancellation, late-payment consequences and anything the text does not explain.';
      }
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> handoff() async {
    final summary = widget.store.handoffSummary();
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('A warm handoff starts here'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: SelectableText(
              summary,
              style: const TextStyle(fontSize: 12, height: 1.7),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: summary));
              toast(
                context,
                'Copied. Review and share with your chosen advisor.',
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy summary'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.store;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeading(
          'A little help. A lot more clarity.',
          'Money questions, human answers.',
          'A companion for the bits that feel complicated.',
          action: OutlinedButton.icon(
            onPressed: handoff,
            icon: const Icon(Icons.support_agent, size: 17),
            label: const Text('Prepare advisor handoff'),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(
            3,
            (i) => ChoiceChip(
              selected: tab == i,
              label: Text(
                ['Your assistant', 'Explain my contract', 'Scam check'][i],
              ),
              onSelected: (_) => setState(() {
                tab = i;
                result = null;
                error = null;
              }),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ResponsiveSplit(
          leftFlex: 7,
          rightFlex: 3,
          left: Panel(
            child: tab == 0
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const IconTile(Icons.auto_awesome, color: violet),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your FINPATH companion',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Here to help you take the next step.',
                                  style: TextStyle(fontSize: 11, color: muted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Stop reading aloud',
                            onPressed: () => tts.stop(),
                            icon: const Icon(
                              Icons.volume_off_outlined,
                              size: 19,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      SizedBox(
                        height: 360,
                        child: s.messages.isEmpty
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const IconTile(
                                    Icons.waving_hand_outlined,
                                    color: teal,
                                    size: 70,
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Hi there. What’s on your mind?',
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'An EMI, a claim, or a “where do I even start?”\nLet’s work through it together.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.7,
                                      color: muted,
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                controller: scroll,
                                itemCount: s.messages.length,
                                itemBuilder: (context, i) {
                                  final m = s.messages[i];
                                  return Align(
                                    alignment: m.isUser
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        maxWidth: 580,
                                      ),
                                      margin: const EdgeInsets.only(bottom: 15),
                                      padding: const EdgeInsets.all(17),
                                      decoration: BoxDecoration(
                                        color: m.isUser
                                            ? const Color(0xFFEDF3FF)
                                            : const Color(0xFFF6F8FA),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SelectableText(
                                            m.text,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              height: 1.75,
                                            ),
                                          ),
                                          if (!m.isUser)
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: IconButton(
                                                tooltip: 'Read aloud',
                                                onPressed: () => speak(m.text),
                                                icon: const Icon(
                                                  Icons.volume_up_outlined,
                                                  size: 17,
                                                  color: muted,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 14),
                      if (busy) const LinearProgressIndicator(),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Notice(error!, color: amber),
                        ),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children:
                            [
                                  'Can I afford this EMI?',
                                  'Explain my total interest',
                                  'Help with a health claim',
                                ]
                                .map(
                                  (q) => ActionChip(
                                    label: Text(
                                      q,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    onPressed: busy ? null : () => send(q),
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 17),
                      TextField(
                        controller: input,
                        minLines: 1,
                        maxLines: 4,
                        onSubmitted: (_) => send(),
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: listening
                              ? 'Listening… tap microphone to stop'
                              : 'Ask a question in your own words…',
                          hintStyle: const TextStyle(fontSize: 12),
                          prefixIcon: IconButton(
                            tooltip: listening
                                ? 'Stop listening'
                                : 'Speak your question',
                            onPressed: busy ? null : voice,
                            icon: Icon(
                              listening ? Icons.stop_circle : Icons.mic_none,
                              color: listening ? teal : muted,
                            ),
                          ),
                          suffixIcon: IconButton(
                            tooltip: 'Send message',
                            onPressed: busy ? null : send,
                            icon: const Icon(
                              Icons.arrow_circle_up,
                              color: blue,
                              size: 31,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        s.consent['ai'] == true
                            ? 'Gemini mode • profile context and messages are sent with consent'
                            : 'Local guide • no AI API call • Hindi and English starter answers',
                        style: const TextStyle(fontSize: 9, color: muted),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionTitle(
                        tab == 1
                            ? 'Know what you’re signing.'
                            : 'A pause can protect you.',
                        subtitle: tab == 1
                            ? 'Paste contract text to find obligations, costs and things to ask about.'
                            : 'Paste a suspicious offer, message or loan pitch.',
                      ),
                      TextField(
                        controller: toolText,
                        minLines: 9,
                        maxLines: 16,
                        decoration: InputDecoration(
                          hintText: tab == 1
                              ? 'Paste the clauses or contract text here…'
                              : '“Guaranteed loan! Pay an upfront fee and share your OTP…”',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton(
                            onPressed: busy ? null : analyze,
                            child: Text(
                              tab == 1
                                  ? 'Find key clauses locally'
                                  : 'Check for red flags',
                            ),
                          ),
                          if (tab == 1)
                            OutlinedButton(
                              onPressed: busy
                                  ? null
                                  : () => analyze(useAi: true),
                              child: const Text('Explain with Gemini'),
                            ),
                          TextButton(
                            onPressed: busy
                                ? null
                                : () async {
                                    final sample = tab == 1
                                        ? await rootBundle.loadString(
                                            'assets/samples/contract.txt',
                                          )
                                        : 'Guaranteed loan with no CIBIL check! Pay an upfront fee to our personal UPI immediately. Share your OTP on WhatsApp to unlock funds.';
                                    if (mounted) {
                                      setState(() => toolText.text = sample);
                                    }
                                  },
                            child: const Text('Use sample'),
                          ),
                        ],
                      ),
                      if (busy)
                        const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: LinearProgressIndicator(),
                        ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Notice(error!, color: amber),
                        ),
                      if (result != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: SelectableText(
                            result!,
                            style: const TextStyle(fontSize: 13, height: 1.8),
                          ),
                        ),
                    ],
                  ),
          ),
          right: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle('In your own language'),
                    DropdownButtonFormField<String>(
                      initialValue: s.language,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'en-IN',
                          child: Text('English'),
                        ),
                        DropdownMenuItem(
                          value: 'hi-IN',
                          child: Text('हिन्दी • Hindi'),
                        ),
                        DropdownMenuItem(
                          value: 'mr-IN',
                          child: Text('मराठी • Marathi'),
                        ),
                        DropdownMenuItem(
                          value: 'ta-IN',
                          child: Text('தமிழ் • Tamil'),
                        ),
                        DropdownMenuItem(
                          value: 'te-IN',
                          child: Text('తెలుగు • Telugu'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) s.setLanguage(v);
                      },
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Voice availability depends on your device. Gemini supports open-ended multilingual replies. Local starter answers are in English and Hindi.',
                      style: TextStyle(fontSize: 11, height: 1.7, color: muted),
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: () => widget.navigate(6),
                      child: const Text(
                        'Manage AI & voice consent  →',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Panel(
                color: mint,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconTile(Icons.lightbulb_outline, color: teal),
                    SizedBox(height: 17),
                    Text(
                      'Clarity, without the jargon.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Ask what a term means, what a number changes, or what to do next. You don’t need to know the right words.',
                      style: TextStyle(fontSize: 12, height: 1.8, color: teal),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Notice(
                'No live advisor is connected. The handoff tool prepares a summary for you to review, copy and share yourself.',
                color: muted,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
