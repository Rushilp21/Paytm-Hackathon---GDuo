import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/app_store.dart';
import '../../data/ai_service.dart';
import '../../ui/components.dart';
import '../../ui/theme.dart';

class PrivacyPage extends StatefulWidget {
  final AppStore store;
  final AiService ai;
  const PrivacyPage({required this.store, required this.ai, super.key});
  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool checking = false;
  Future<void> export() async {
    try {
      await FilePicker.platform.saveFile(
        dialogTitle: 'Export your FINPATH data',
        fileName: 'finpath-data.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: utf8.encode(
          const JsonEncoder.withIndent('  ').convert(widget.store.toJson()),
        ),
      );
    } catch (_) {
      if (mounted) {
        toast(context, 'Could not export. Check browser download permissions.');
      }
    }
  }

  Future<void> reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Reset this demo?'),
        content: const Text(
          'This removes saved documents, chats, applications, claim drafts and consent history on this device, then restores the fictional sample profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Keep my data'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Reset local data'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.store.reset();
      if (mounted) {
        toast(
          context,
          'Local data reset. External AI and voice consent are off.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.store;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeading(
          'Trust starts with transparency',
          'Your data. Your call.',
          'See what is used, understand why, and change your mind anytime.',
        ),
        ResponsiveSplit(
          left: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle('You’re in control'),
                    _permission(
                      'documents',
                      'Document processing',
                      'Read a file you choose, extract supported fields, and keep reviewed values locally. Original files are not retained.',
                      Icons.description_outlined,
                      violet,
                    ),
                    const Divider(height: 30),
                    _permission(
                      'ai',
                      'External AI processing • Gemini',
                      'When you explicitly use an AI action, send the question, relevant profile/calculations, recent chat or chosen file through the Dart backend to Google Gemini. Provider retention rules apply.',
                      Icons.auto_awesome,
                      blue,
                    ),
                    const Divider(height: 30),
                    _permission(
                      'voice',
                      'Microphone & voice services',
                      'Use your browser or device speech service to transcribe your voice and read replies. Audio processing may use the platform provider’s cloud.',
                      Icons.mic_none_rounded,
                      teal,
                    ),
                    const SizedBox(height: 22),
                    const Notice(
                      'Revoking permission blocks future requests. It cannot recall data already sent. Delete extracted records in Documents, or reset all local data below.',
                      color: muted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(
                      'Your activity, in the open',
                      subtitle:
                          'A local record of processing and consent changes. Latest 100 events.',
                    ),
                    if (s.audit.isEmpty)
                      const Text(
                        'No activity recorded yet.',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ...s.audit
                        .take(15)
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.history,
                                  color: muted,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.category,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        e.purpose,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: muted,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat(
                                          'd MMM, h:mm a',
                                        ).format(e.time),
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],
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
                      Icons.shield_outlined,
                      color: teal,
                      size: 54,
                    ),
                    const SizedBox(height: 18),
                    const SectionTitle('Privacy by choice'),
                    const Text(
                      'No hidden bank connections.\nNo automatic application submission.\nNo API key inside the Flutter app.',
                      style: TextStyle(fontSize: 12, height: 2, color: teal),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Local data is not encrypted. This is a personal-device hackathon prototype, not a production financial service.',
                      style: TextStyle(fontSize: 11, height: 1.7, color: teal),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionTitle('Your AI connection'),
                    Tag(
                      s.aiReady
                          ? 'Gemini is configured'
                          : 'Local tools are available',
                      color: s.aiReady ? teal : muted,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Add your key in backend/.env, start the Dart server, then check the connection.',
                      style: TextStyle(fontSize: 11, color: muted),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: checking
                          ? null
                          : () async {
                              setState(() => checking = true);
                              final ready = await widget.ai.health();
                              if (mounted) {
                                setState(() {
                                  s.aiReady = ready;
                                  checking = false;
                                });
                                s.setAiReady(ready);
                                toast(
                                  this.context,
                                  ready
                                      ? 'Gemini backend is configured.'
                                      : 'Backend unavailable or API key missing. See README for setup.',
                                );
                              }
                            },
                      child: Text(checking ? 'Checking…' : 'Check connection'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: export,
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Export my local data'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: reset,
                child: const Text(
                  'Reset all local demo data',
                  style: TextStyle(color: amber, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _permission(
    String key,
    String title,
    String detail,
    IconData icon,
    Color color,
  ) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      IconTile(icon, color: color),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 7),
            Text(
              detail,
              style: const TextStyle(fontSize: 11, height: 1.8, color: muted),
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Switch(
        value: widget.store.consent[key] == true,
        onChanged: (v) => widget.store.setConsent(key, v),
      ),
    ],
  );
}
