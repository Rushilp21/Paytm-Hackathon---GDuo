import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finpath/data/app_store.dart';
import 'package:finpath/domain/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  DocumentRecord sample() => DocumentRecord(
    name: 'sample.txt',
    fields: {'name': 'Demo', 'income': '50000', 'email': 'demo@example.com'},
    source: 'test',
    created: DateTime(2026),
  );
  test('consent actually prevents document processing', () async {
    final store = AppStore();
    await store.load();
    store.setConsent('documents', false);
    expect(() => store.addDocument(sample()), throwsStateError);
    expect(store.documents, isEmpty);
  });
  test(
    'extraction cannot autofill until reviewed; application keeps snapshot',
    () async {
      final store = AppStore();
      await store.load();
      store.addDocument(sample());
      expect(store.profile.income, 75000);
      expect(store.canApply, false);
      expect(() => store.submitApplication(), throwsStateError);
      store.reviewDocument(0, sample().fields);
      expect(store.profile.income, 50000);
      expect(store.canApply, true);
      store.submitApplication();
      final original = store.application!['goal']['rate'];
      store.updateGoal(store.goal.copyWith(rate: 29));
      expect(store.application!['goal']['rate'], original);
      await store.save();
      final restored = AppStore();
      await restored.load();
      expect(restored.profile.income, 50000);
      expect(restored.documents.single.reviewed, true);
      expect(restored.application!['id'], store.application!['id']);
    },
  );
  test(
    'demo progress stops at the final stage; reset revokes external consent',
    () async {
      final store = AppStore();
      await store.load();
      store.addDocument(sample());
      store.reviewDocument(0, sample().fields);
      store.submitApplication();
      for (var i = 0; i < 8; i++) {
        store.advanceApplication();
      }
      expect(store.application!['stage'], 3);
      store.setConsent('ai', true);
      await store.reset();
      expect(store.consent['ai'], false);
      expect(store.application, isNull);
      expect(store.documents, isEmpty);
    },
  );
}
