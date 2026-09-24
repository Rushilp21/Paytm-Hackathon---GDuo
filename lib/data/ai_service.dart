import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/models.dart';
import '../domain/finance_engine.dart';

class AiService {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
  final http.Client client;
  AiService({http.Client? client}) : client = client ?? http.Client();

  Future<FinancialGoal> planGoal(String text, String language) async {
    final result = await request('goal', {
      'consent': true,
      'message': text,
      'language': language,
    });
    return goalFromResponse(text, result);
  }

  // Validate model output before it can affect financial calculations.
  static FinancialGoal goalFromResponse(
    String text,
    Map<String, dynamic> result,
  ) {
    final kind = GoalKind.values
        .where((k) => k.name == result['kind'])
        .firstOrNull;
    if (kind == null) {
      throw const AiException(
        'Gemini returned an unsupported goal. Please try again.',
      );
    }
    final seed = FinanceEngine.goalFromText(kind.name);
    final suppliedAmount = result['amount'];
    if (suppliedAmount != null &&
        (suppliedAmount is! num ||
            !suppliedAmount.isFinite ||
            suppliedAmount < 1000 ||
            suppliedAmount > 100000000)) {
      throw const AiException(
        'Gemini returned an invalid amount. Please enter the goal cost yourself.',
      );
    }
    final amount = suppliedAmount == null
        ? seed.amount
        : (suppliedAmount as num).toDouble();
    return seed.copyWith(
      title: text.trim(),
      kind: kind,
      amount: amount,
      downPayment: amount * .25,
    );
  }

  Future<Map<String, dynamic>> request(
    String task,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await client
          .post(
            Uri.parse('$baseUrl/api/$task'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 60));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw AiException(
          data['error'] as String? ?? 'AI request failed. Please retry.',
        );
      }
      return data;
    } on AiException {
      rethrow;
    } catch (_) {
      throw const AiException(
        'Cannot reach Gemini. Start the Dart backend, add your API key, and check API_BASE_URL. Your local tools still work.',
      );
    }
  }

  Future<bool> health() async {
    try {
      final response = await client
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200 &&
          jsonDecode(response.body)['configured'] == true;
    } catch (_) {
      return false;
    }
  }
}

class AiException implements Exception {
  final String message;
  const AiException(this.message);
  @override
  String toString() => message;
}
