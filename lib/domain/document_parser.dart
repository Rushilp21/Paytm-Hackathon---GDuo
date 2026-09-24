class DocumentParser {
  // Conservative extraction: missing fields stay missing; this is not KYC.
  static Map<String, String> extract(String text) {
    final result = <String, String>{};
    const labels = <String, String>{
      'name': r'(?:full\s+name|employee\s+name|name)',
      'email': r'email',
      'employer': r'(?:employer|company)',
      'income': r'(?:net\s+salary|monthly\s+income|net\s+pay)',
      'expenses': r'(?:monthly\s+expenses|expenses)',
      'existingEmi': r'(?:existing\s+emis?|monthly\s+emi)',
      'savings': r'(?:available\s+savings|savings|closing\s+balance)',
      'policy': r'policy\s+(?:number|no\.?|id)',
      'healthCover': r'(?:health\s+cover|sum\s+insured)',
      'lifeCover': r'life\s+cover',
    };
    for (final entry in labels.entries) {
      final match = RegExp(
        '^\\s*${entry.value}\\s*[:=]\\s*(.+)\$',
        caseSensitive: false,
        multiLine: true,
      ).firstMatch(text);
      if (match != null) {
        final value = match[1]!.trim();
        if ([
          'income',
          'expenses',
          'existingEmi',
          'savings',
          'healthCover',
          'lifeCover',
        ].contains(entry.key)) {
          final clean = value.replaceAll(
            RegExp(r'inr|rs\.?|₹|,|\s', caseSensitive: false),
            '',
          );
          final number = double.tryParse(clean);
          if (number != null && number.isFinite && number >= 0) {
            result[entry.key] = number.toStringAsFixed(0);
          }
        } else if (value.isNotEmpty) {
          result[entry.key] = value;
        }
      }
    }
    return result;
  }
}
