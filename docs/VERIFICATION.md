# Verification record

Environment: Windows, Flutter 3.41.6, Dart 3.11.4. Verified on 24 September 2026.

## Completed checks

- `flutter analyze --no-pub`: **no issues found**.
- `flutter test --no-pub`: **25 tests passed** on the final source.
- `dart run backend/test/server_smoke.dart`: **8 backend checks passed**, without external API calls.
- `flutter build web --no-pub --no-wasm-dry-run`: **release build succeeded**.
- `flutter build apk --debug --no-pub --dart-define=API_BASE_URL=http://127.0.0.1:8080`: **Android debug APK built** for the USB-phone setup.

Tests cover the amortisation formula, zero-interest/no-borrowing cases, invalid loan inputs, existing debt, depleted savings, income loss, goal/Indian-amount parsing, generic goals, conservative document parsing, scam flags, consent enforcement, review-before-autofill, persistence, immutable application snapshots, bounded demo progression and reset. Additional regressions cover zero-EMI budget pressure, insurance intent, time-before-budget parsing and scam keyword false positives. Mocked Gemini adapter tests cover goal response validation, consent payloads, missing budgets and backend failures. Widget checks cover home-to-plan navigation at 1280, 390 and 320 pixels wide, plus six secondary journeys at 360 and 1000 pixels wide.

- Android 16 physical-device runtime check on device `33c8cb3b`: Home, Plan, Assistant and Journey opened without Flutter exceptions after the first-frame narrow-layout fix. The final debug APK was rebuilt and installed on the device.

## Browser checks

The compiled release was opened in the Codex browser. Visually checked the desktop dashboard and phone journey layout. Exercised the sample payslip flow: seven fields extracted → review dialog → confirm/autofill → email and income in application preview → review acknowledgement → local demo application created and tracker shown. The final release preview uses port **5180**, leaving the README’s development port **5173** free.

## Backend checks without a key

- `GET /health`: HTTP 200, `configured: false`.
- Chat request without configured key: HTTP 503 with a setup message.
- Unapproved browser origin: HTTP 403.
- Unknown route: HTTP 404.
- Missing AI consent: HTTP 403.
- Non-object JSON and unsupported document MIME: HTTP 400.
- CORS preflight: HTTP 204.
- The `.env` file is ignored by Git.

The no-key backend process used for checks was stopped, so port 8080 is available for the user’s configured backend.

## Practical limits

- A real Gemini request, PDF/image extraction through Gemini, and AI multilingual output were **not live-tested** because no API key was supplied. The REST integration and its error handling are implemented.
- Microphone recognition and read-aloud require a supported device/browser and permissions; they were **not tested with a live microphone**.
- The debug APK was compiled, installed and exercised on one Android 16 physical device. Its baked API URL uses localhost with USB port forwarding (`adb reverse`). The Android helper configures this automatically; pass `-Emulator` to rebuild for the emulator host. See `ANDROID_QUICKSTART.md`.
- iOS project scaffolding and permission descriptions are present; iOS compilation/runtime testing requires macOS and Xcode and was **not performed**.
- Standard JavaScript web compilation is supported. The optional Wasm dry run reports third-party `flutter_tts` interop incompatibilities; a Wasm build is not claimed. Flutter also emits a Cupertino font tree-shaking warning; the FINPATH UI uses bundled Material icons and rendered successfully.
- The first native build took about 11 minutes and temporarily exhausted C: drive space. A concurrent test rerun was interrupted by the disk error. Project-generated Android intermediates were removed while retaining source and final outputs; the full test suite subsequently passed. A future clean Android build can need several gigabytes for intermediates and Gradle caches.

No actual lender/insurer approval, KYC verification, bank synchronisation, credit bureau lookup, payment or human handoff was performed or represented as real.
