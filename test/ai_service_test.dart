import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:finpath/data/ai_service.dart';
import 'package:finpath/domain/models.dart';

void main() {
  test(
    'goal adapter sends consent and accepts validated model output',
    () async {
      final ai = AiService(
        client: MockClient((request) async {
          expect(request.url.path, '/api/goal');
          final body = jsonDecode(request.body);
          expect(body['consent'], true);
          expect(body['language'], 'hi-IN');
          return http.Response('{"kind":"education","amount":250000}', 200);
        }),
      );
      final goal = await ai.planGoal('My college fees', 'hi-IN');
      expect(goal.kind, GoalKind.education);
      expect(goal.amount, 250000);
      expect(goal.downPayment, 62500);
    },
  );

  test('missing AI budget uses an editable estimate', () {
    final goal = AiService.goalFromResponse('A family car', {
      'kind': 'car',
      'amount': null,
    });
    expect(goal.amount, 850000);
    expect(goal.title, 'A family car');
  });

  test('invalid AI fields cannot reach financial calculations', () {
    for (final result in [
      {'kind': 'unknown', 'amount': 50000},
      {'kind': 'bike', 'amount': -1},
      {'kind': 'bike', 'amount': '75000'},
      {'kind': 'bike', 'amount': double.infinity},
    ]) {
      expect(
        () => AiService.goalFromResponse('A bike', result),
        throwsA(isA<AiException>()),
      );
    }
  });

  test(
    'backend error is surfaced instead of pretending AI succeeded',
    () async {
      final ai = AiService(
        client: MockClient(
          (_) async => http.Response('{"error":"Add GEMINI_API_KEY"}', 503),
        ),
      );
      await expectLater(
        ai.planGoal('A bike', 'en-IN'),
        throwsA(
          isA<AiException>().having(
            (e) => e.message,
            'message',
            'Add GEMINI_API_KEY',
          ),
        ),
      );
    },
  );
}
