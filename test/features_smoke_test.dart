import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finpath/data/app_store.dart';
import 'package:finpath/data/ai_service.dart';
import 'package:finpath/features/documents/documents_page.dart';
import 'package:finpath/features/claims/claims_page.dart';
import 'package:finpath/features/assistant/assistant_page.dart';
import 'package:finpath/features/journey/journey_page.dart';
import 'package:finpath/features/profile/profile_page.dart';
import 'package:finpath/features/privacy/privacy_page.dart';
import 'package:finpath/ui/theme.dart';

void main() {
  for (final width in [360.0, 1000.0]) {
    testWidgets('all secondary journeys lay out at $width pixels', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final s = AppStore();
      await s.load();
      final ai = AiService();
      void navigate(int _) {}
      final pages = [
        DocumentsPage(store: s, ai: ai, navigate: navigate),
        ClaimsPage(store: s, ai: ai),
        AssistantPage(store: s, ai: ai, navigate: navigate),
        JourneyPage(store: s, navigate: navigate),
        ProfilePage(store: s),
        PrivacyPage(store: s, ai: ai),
      ];
      for (final page in pages) {
        await tester.pumpWidget(
          MaterialApp(
            theme: finTheme(),
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: page,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${page.runtimeType} at $width',
        );
      }
    });
  }
}
