# FINPATH

**Bigger tomorrows start here.** A Flutter + Dart hackathon prototype for **AI-Powered Financial Journeys**: make insurance, lending and fintech simpler, faster and more human.

Responsive Android / iOS / web app, a local Dart Gemini proxy, persistent demo state, and transparent financial calculations. The UI uses the supplied FINPATH concepts as inspiration, with a desktop workspace and adaptive mobile layout.

Built outputs are in `build/web/` and `build/app/outputs/flutter-apk/app-debug.apk`. To serve the compiled web app without a rebuild, run `dart tool/serve_web.dart` from this directory and open `http://127.0.0.1:5180`.

## Run it

For a physical Android phone or emulator, follow [the Android quickstart](docs/ANDROID_QUICKSTART.md). A USB helper is included: `./scripts/run_android.ps1 -DeviceId "YOUR_DEVICE_ID"`.

Requires Flutter 3.41+ / Dart 3.11+, Chrome for web, or an Android SDK/emulator. iOS builds require macOS + Xcode.

From this project directory:

```powershell
flutter pub get
flutter run -d chrome --web-port 5173
```

**No API key is needed for the local demo.** The sample profile is fictional. Changes persist on this device/browser. Keep a fixed web port to keep the same browser storage origin.

### Turn on Gemini

1. Open `backend/.env` (already created locally). Paste your key after `GEMINI_API_KEY=`. This file is ignored by Git and is never bundled in Flutter. After a fresh clone, copy `backend/.env.example` to `backend/.env`.
2. In a **second terminal**, run:

```powershell
cd backend
dart run bin/server.dart
```

3. In the app, open **Privacy & consent → Check connection**, then turn on **External AI processing**. Goal matching, PDF/image extraction, open-ended chat, contract explanations and claim drafting now use Gemini.
4. Restart the backend whenever you change `.env`. No backend packages or database are required.

The default model is `gemini-3.5-flash-lite`; change `GEMINI_MODEL` to a model available to your API account. Connection status checks configuration, not actual API quota or key validity. Failed calls display actionable errors and never pretend to be AI results.

Optional helper scripts: `./scripts/run_backend.ps1` and `./scripts/run_web.ps1`, in separate terminals.

### Android

```powershell
flutter devices
flutter run -d <device-id> --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

`10.0.2.2` reaches the host from an Android emulator. For a USB-connected physical Android device, use `adb reverse tcp:8080 tcp:8080` and `--dart-define=API_BASE_URL=http://127.0.0.1:8080`. Local HTTP is enabled only in the Android **debug** manifest. Release builds need an HTTPS backend URL.

For a phone on the same Wi-Fi, set backend `HOST=0.0.0.0`, use the computer’s LAN IP in `API_BASE_URL`, and allow port 8080 through your firewall only on a trusted network. The proxy is unauthenticated and intended for local development. Do not expose it publicly.

```powershell
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8080
flutter build web --dart-define=API_BASE_URL=https://your-secured-backend.example
```

## What works

| Feature | Implemented behavior |
|---|---|
| Financial digital twin | Editable income, living expenses, existing EMIs, savings, dependents, cover and self-reported score; shared reactive state; local persistence |
| Goal-to-product | Optional Gemini intent/budget extraction with validated output; local parser and explicit fallback without AI; editable goals and illustrative finance catalogue |
| Affordability | Reducing-balance EMI, debt-to-income, disposable cash, emergency buffer after down payment, explicit risk reasons |
| Explainable loan advisor | Live costs and plain-language local explanations; Gemini expands the conversation when enabled |
| What-if simulator | Down payment, tenure, annual rate and income-loss stress controls; tenure comparison chart |
| Document intelligence | Local labelled TXT/CSV parser; Gemini PDF/PNG/JPEG extraction up to 5 MB; no invented local fields |
| Smart autofill | Extract → correct/review → confirm → profile/application; extraction is never described as KYC verification |
| Eligibility | Transparent heuristic fit labels, not lender approval percentages |
| Insurance gap | Existing health/life cover compared against clearly labelled illustrative planning assumptions |
| Claim copilot | Policy/treatment details, dated claim draft, self-reported document checklist, optional Gemini drafting, saved local tracker |
| Scam detector | Local pattern flags for credentials, advance payments, urgency, guarantee claims and suspicious channels; no “safe” certification |
| Multilingual voice | Device/browser speech-to-text and read-aloud; English, Hindi, Marathi, Tamil, Telugu selection; Gemini multilingual replies; local English/Hindi starter responses |
| Explain my contract | Local clause scan and optional Gemini explanation of pasted text; a sample contract is bundled |
| Consent dashboard | Enforced document/AI/voice consent, processing activity log, local export, deletion and reset |
| Human escalation | Reviewable, copyable advisor summary with profile, risks and recent conversation; no live advisor connection |
| Application journey | Review gate, immutable submitted snapshot, JSON export, manually advanced demo stages |

## The demo story (5–7 minutes)

1. **Overview:** introduce the financial twin. Enter “I want to buy a bike for 1.5 lakh”.
2. **Plan & compare:** adjust tenure/down payment. Drop income by 30–50% to reveal budget stress. Explain why a smaller EMI does not always mean lower total cost.
3. **Documents:** choose **Try a sample payslip**. Click **Review**, correct a value, then **Confirm & autofill**. Show the updated profile and application preview.
4. **Your journey:** review the numbers, tick the acknowledgement and create a demo application. Advance the stages. Show that editing the profile later does not rewrite the application snapshot.
5. **Insurance claims:** fill the sample, pick the documents you have, save the draft, and copy it. The demo tracker is explicitly simulated.
6. **AI assistant:** ask “Can I afford this EMI?”; then use the sample in **Scam check** and **Explain my contract**. With a key and consent, request Gemini explanation or speak a question.
7. **Privacy:** show exactly which access was logged, revoke AI consent, export local data, and explain the advisor handoff draft.

## Project structure

```text
lib/
  main.dart                      # Bootstrap + restore local state
  app.dart                       # Responsive shell and navigation
  domain/
    models.dart                  # Profile, goal, document and event models
    finance_engine.dart          # Pure calculations, intent/risk heuristics
    document_parser.dart         # Conservative local field extraction
    local_advisor.dart           # Honest no-key conversational guide
  data/
    app_store.dart               # Shared state, persistence, consent, snapshots
    ai_service.dart              # HTTP adapter to Dart backend
  features/
    home/ planner/ documents/ claims/
    assistant/ journey/ profile/ privacy/
  ui/
    theme.dart                   # Colour, typography, INR formatting
    components.dart              # Shared panels, responsive layouts, artwork
backend/
  bin/server.dart                # dart:io proxy; .env loader; Gemini REST calls
  .env.example                   # Safe config template
assets/samples/                  # Fictional payslip and loan contract
test/                           # Calculation, parsing, state and widget tests
docs/                           # Architecture and feature boundaries
```

## Calculations and boundaries

- `EMI = P × r × (1+r)^n / ((1+r)^n − 1)`; zero-rate EMI is `P/n`. `r` is annual percentage / 1200.
- Total interest = EMI × months − principal. Purchase outlay adds the down payment. Simulator totals exclude fees, taxes and premiums; catalogue cards show their illustrative processing fee separately.
- Demo affordability limits: **all EMIs ≤ 35% of net income**, retain **20% of monthly income**, keep **3 months of living expenses + all EMIs** after the down payment. These are product-demo assumptions, not universal advice or lender underwriting.
- Emergency buffer = max(0, savings − down payment) / (living expenses + existing EMI + proposed EMI).
- Product names/rates are fictional. No lender, credit bureau, bank, KYC vendor, insurer or human advisor is connected. There is no payment movement, real submission, approval or disbursal.
- Health coverage benchmark: ₹5 lakh × household count. Life benchmark: 10 × annual net income if there are dependents. Both are simplified demo rules, not individual advice.
- TXT/CSV intake expects one labelled field per line (see `assets/samples/payslip.txt`); arbitrary bank transaction tables are not locally categorised. Gemini handles unstructured PDFs/images, subject to extraction review.
- Voice requires browser/device support, permission and installed language services. Chrome/Android are preferred demo targets; browser speech may need internet. iOS scaffolding is supplied, but requires validation on macOS.
- Original uploaded bytes are not persisted by the app or backend. Extracted fields, profile, drafts and chat are stored **unencrypted** in SharedPreferences/browser storage. Use fictional data. Gemini and device speech providers have their own processing/retention policies.
- Future production work: authentication, encrypted storage, data lifecycle controls, monitored/audited backend, rate limiting, financial partner APIs, robust document/KYC validation, formal risk review and real advisor routing. This is intentionally a hackathon prototype.

## Validate

```powershell
flutter analyze
flutter test
dart run backend/test/server_smoke.dart
flutter build web
```

See `docs/VERIFICATION.md` for the checks actually run during implementation, including platform limitations.

## Technical references

- [Flutter documentation](https://docs.flutter.dev/)
- [Gemini GenerateContent API](https://ai.google.dev/api/generate-content)
- [Gemini model catalogue](https://ai.google.dev/gemini-api/docs/models)
- [speech_to_text platform requirements](https://pub.dev/packages/speech_to_text)
- [flutter_tts platform requirements](https://pub.dev/packages/flutter_tts)
