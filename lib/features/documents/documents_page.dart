import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/ai_service.dart';
import '../../data/app_store.dart';
import '../../domain/document_parser.dart';
import '../../domain/models.dart';
import '../../ui/components.dart';
import '../../ui/theme.dart';

const fieldLabels = {
  'name': 'Full name',
  'email': 'Email',
  'employer': 'Employer',
  'income': 'Monthly net income',
  'expenses': 'Monthly expenses',
  'existingEmi': 'Existing EMIs',
  'savings': 'Available savings',
  'policy': 'Policy number',
  'healthCover': 'Health coverage',
  'lifeCover': 'Life coverage',
};

class DocumentsPage extends StatefulWidget {
  final AppStore store;
  final AiService ai;
  final ValueChanged<int> navigate;
  const DocumentsPage({
    required this.store,
    required this.ai,
    required this.navigate,
    super.key,
  });
  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  bool busy = false;
  String? error;
  final text = TextEditingController();
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> process({bool sample = false, bool paste = false}) async {
    final s = widget.store;
    if (s.consent['documents'] != true) {
      setState(
        () => error = 'Allow document processing in Privacy & consent first.',
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      String name, source;
      Map<String, String> fields;
      if (sample || paste) {
        final raw = sample
            ? await rootBundle.loadString('assets/samples/payslip.txt')
            : text.text;
        name = sample ? 'Sample payslip.txt' : 'Pasted document';
        fields = DocumentParser.extract(raw);
        source = 'Local label-based extraction';
      } else {
        final selection = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['txt', 'csv', 'pdf', 'jpg', 'jpeg', 'png'],
          withData: true,
        );
        if (selection == null) return;
        final file = selection.files.single;
        if (file.size > 5 * 1024 * 1024) {
          throw const AiException('Please select a file smaller than 5 MB.');
        }
        if (file.bytes == null) {
          throw const AiException(
            'The file could not be read. Please choose it again.',
          );
        }
        name = file.name;
        if (['txt', 'csv'].contains(file.extension?.toLowerCase())) {
          fields = DocumentParser.extract(utf8.decode(file.bytes!));
          source = 'Local label-based extraction';
        } else {
          if (s.consent['ai'] != true) {
            throw const AiException(
              'PDF and image extraction uses Gemini. Allow external AI processing in Privacy & consent first.',
            );
          }
          final mime = file.extension?.toLowerCase() == 'pdf'
              ? 'application/pdf'
              : file.extension?.toLowerCase() == 'png'
              ? 'image/png'
              : 'image/jpeg';
          s.log(
            'Gemini document access',
            '$name sent to Gemini for extraction after document and AI consent',
          );
          s.save();
          final result = await widget.ai.request('extract', {
            'consent': true,
            'message':
                'Extract the supported financial fields from this document.',
            'attachment': {'mimeType': mime, 'data': base64Encode(file.bytes!)},
          });
          if (s.consent['ai'] != true || s.consent['documents'] != true) {
            throw const AiException(
              'Consent was revoked. The returned extraction was discarded.',
            );
          }
          fields = Map<String, String>.from(result['fields']);
          source = 'Gemini extraction • review required';
        }
      }
      if (fields.isEmpty) {
        throw const AiException(
          'No supported fields found. Try a labelled payslip, use the sample, or paste lines such as “Full Name: Aarav” and “Net Salary: 75000”.',
        );
      }
      s.addDocument(
        DocumentRecord(
          name: name,
          fields: fields,
          source: source,
          created: DateTime.now(),
        ),
      );
      if (mounted) {
        toast(
          context,
          'Extracted ${fields.length} fields. Review them before autofilling.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is AiException
              ? e.message
              : 'Could not read this document. Try a supported file or paste its text.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> review(int index) async {
    final d = widget.store.documents[index];
    final controllers = d.fields.map(
      (k, v) => MapEntry(k, TextEditingController(text: v)),
    );
    final form = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Review before autofill'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Notice(
                    'Extraction is not verification. Correct any mistakes, then confirm the values to update your financial profile.',
                  ),
                  const SizedBox(height: 18),
                  ...controllers.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: TextFormField(
                        controller: e.value,
                        decoration: InputDecoration(
                          labelText: fieldLabels[e.key] ?? e.key,
                        ),
                        validator: (v) {
                          if ([
                            'income',
                            'expenses',
                            'existingEmi',
                            'savings',
                            'healthCover',
                            'lifeCover',
                          ].contains(e.key)) {
                            final n = double.tryParse(v ?? '');
                            if (n == null ||
                                !n.isFinite ||
                                n < 0 ||
                                n > 10000000000) {
                              return 'Enter a valid non-negative rupee amount';
                            }
                          }
                          if (e.key == 'email' &&
                              v!.isNotEmpty &&
                              !RegExp(
                                r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                              ).hasMatch(v)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!form.currentState!.validate()) return;
              widget.store.reviewDocument(
                index,
                controllers.map((k, v) => MapEntry(k, v.text.trim())),
              );
              Navigator.pop(c);
              toast(
                context,
                'Confirmed fields added to your profile and application form.',
              );
            },
            child: const Text('Confirm & autofill'),
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
        const PageHeading(
          'Less paperwork. More possibility.',
          'Your documents, doing the work.',
          'Extract once. Review together. Move forward with confidence.',
        ),
        ResponsiveSplit(
          left: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionTitle(
                      'A head start on the paperwork',
                      subtitle:
                          'Original files are processed in memory and are not saved by FINPATH.',
                    ),
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFF),
                        border: Border.all(color: const Color(0xFFD5E2F7)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const IconTile(Icons.cloud_upload_outlined, size: 58),
                          const SizedBox(height: 18),
                          const Text(
                            'Bring your documents. We’ll find the details.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'PDF, JPG, PNG, TXT or labelled CSV • up to 5 MB',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: muted),
                          ),
                          const SizedBox(height: 22),
                          FilledButton.icon(
                            onPressed: busy ? null : process,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Choose document'),
                          ),
                          const SizedBox(height: 9),
                          TextButton(
                            onPressed: busy
                                ? null
                                : () => process(sample: true),
                            child: const Text(
                              'Just exploring? Try a sample payslip',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (busy)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: LinearProgressIndicator(),
                      ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Notice(error!, color: amber),
                      ),
                    const SizedBox(height: 18),
                    const Notice(
                      'TXT / CSV use a local parser. PDF and image files are sent to Gemini only when you allow AI processing. Avoid uploading real IDs during a shared hackathon demo.',
                      color: muted,
                    ),
                    const SizedBox(height: 14),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text(
                        'Or paste document text',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      children: [
                        TextField(
                          controller: text,
                          minLines: 4,
                          maxLines: 8,
                          decoration: const InputDecoration(
                            hintText:
                                'Full Name: Aarav Sharma\nNet Salary: 75000\nEmployer: Acme Studio\nEmail: aarav@example.com',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton(
                            onPressed: busy ? null : () => process(paste: true),
                            child: const Text('Extract locally'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(
                      'Your document shelf',
                      subtitle:
                          '${s.documents.length} added • ${s.documents.where((d) => d.reviewed).length} reviewed',
                    ),
                    if (s.documents.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'A fresh start. Your documents will appear here.',
                            style: TextStyle(fontSize: 12, color: muted),
                          ),
                        ),
                      ),
                    ...s.documents.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            border: Border.all(color: line),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const IconTile(
                                    Icons.description_outlined,
                                    color: violet,
                                    size: 36,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      e.value.name,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete extracted record',
                                    onPressed: () => s.removeDocument(e.key),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 17,
                                      color: muted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${e.value.fields.length} extracted fields • ${e.value.source}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: muted,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Tag(
                                      e.value.reviewed
                                          ? 'Reviewed by you'
                                          : 'Needs your review',
                                      color: e.value.reviewed ? teal : amber,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => review(e.key),
                                    child: Text(
                                      e.value.reviewed
                                          ? 'View & edit  →'
                                          : 'Review  →',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          right: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const IconTile(
                  Icons.assignment_turned_in_outlined,
                  color: teal,
                  size: 50,
                ),
                const SizedBox(height: 20),
                const SectionTitle(
                  'Your application preview',
                  subtitle:
                      'Your confirmed profile is the single source of truth.',
                ),
                ...{
                  'Full name': s.profile.name,
                  'Email': s.profile.email.isEmpty
                      ? 'Needs your input'
                      : s.profile.email,
                  'Employer': s.profile.employer,
                  'Monthly net income': money(s.profile.income),
                  'Goal': s.goal.title,
                }.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.key,
                          style: const TextStyle(fontSize: 10, color: muted),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          e.value,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Notice(
                  s.canApply
                      ? 'Your local application is ready for a final review.'
                      : 'Review an income document and add a valid name, email and monthly income before applying.',
                  color: s.canApply ? teal : amber,
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => widget.navigate(5),
                  child: const Text('Review application  →'),
                ),
                TextButton(
                  onPressed: () => widget.navigate(7),
                  child: const Text(
                    'Edit profile',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () => widget.navigate(6),
                  child: const Text(
                    'Manage document consent',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
