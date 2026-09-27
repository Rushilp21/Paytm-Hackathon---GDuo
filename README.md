# FINPATH

> **Bigger tomorrows start here.**

FINPATH is an AI-powered financial journey companion built for the **AI-Powered Financial Journeys** hackathon track. It makes lending, insurance and personal-finance journeys easier to understand, compare and complete.

Instead of asking users to search through financial products, FINPATH begins with a life goal. It builds a financial profile, checks affordability, explains trade-offs, processes documents with user review, prepares applications or insurance claims, and keeps the user informed throughout the journey.

The prototype is built with **Flutter and Dart**, runs on Android and web, and uses a local Dart backend as a secure proxy for the **Google Gemini API**. Core calculations and demo journeys continue to work without an API key.

The latest working USPs are **FIN-VERSE** (five simulated futures), **FIN-CRASH** (combined financial stress tests), and **FIN-GUARD** (an approval-based, 90-day local protection plan). Find all three on the home screen or in the navigation menu. [Try the USP demo and read the calculation assumptions](docs/RESILIENCE_GUIDE.md).

## Problem Statement

**AI-Powered Financial Journeys**

Make insurance, lending and fintech simpler, faster and more human. Reimagine customer-facing journeys using AI by removing friction, reducing complexity, and helping customers complete important financial tasks with greater confidence.

## Solution Summary

FINPATH combines financial planning, explainable calculations, document assistance, insurance support and consent controls in one responsive application.

The main journey is:

```text
Life Goal → Financial Profile → Affordable Options → Document Review
          → Application or Claim → Progress Tracking → Human Support
```

Key principles:

- Start with the user's goal instead of a product catalogue.
- Check real affordability instead of showing eligibility alone.
- Keep EMI and affordability calculations deterministic and explainable.
- Use Gemini for language and document tasks, not final financial decisions.
- Require consent and user review before using extracted information.
- Clearly identify simulated applications, providers and approval stages.

## Features

### 1. Financial Digital Twin

Builds a continuously updated financial profile using income, expenses, savings, existing EMIs, dependents, insurance cover, credit information and goals. The profile is editable and saved locally.

### 2. Goal-to-Product AI

Accepts natural-language goals such as `I want to buy a bike for 1.5 lakh`. Gemini can identify the goal category and stated budget when enabled. A deterministic local parser provides a fallback when AI is unavailable.

**Goal-first journey:** Tell FINPATH your goal and build a financial journey around it. Illustrated goal journeys **with visuals are planned next**; this release includes working simulation charts and comparison tables.

### 3. Affordability Engine

Calculates whether a loan fits the user's finances using proposed EMI, total debt-to-income ratio, disposable income and emergency savings. It explains why a plan is considered comfortable or risky.

### 4. Explainable Loan Advisor

Explains principal, EMI, interest, total repayment and monthly budget impact in everyday language. The local advisor handles common questions without an API key, while Gemini supports broader conversations.

### 5. Financial What-if Simulator

Lets users change the down payment, repayment period, annual interest rate and potential income reduction. Every change immediately updates EMI, interest, repayment and financial-buffer calculations.

### 6. AI Document Intelligence

Processes labelled TXT and CSV files locally. With Gemini enabled, it can extract supported fields from PDF, PNG and JPEG files up to 5 MB. Extracted information is never treated as verified KYC data.

### 7. Smart Form Autofill

Uses the reviewed document fields to populate the financial profile and application preview. The flow is deliberately `extract → review or correct → confirm → autofill`.

### 8. Eligibility Predictor

Provides a transparent rule-based estimate using the entered income, credit score and existing obligations. It does not claim to provide a real lender approval probability.

### 9. Personalized Insurance Gap Detector

Compares existing health and life cover with clearly labelled planning assumptions. It highlights potential protection gaps without presenting the result as regulated financial advice.

### 10. Claim Copilot

Collects policy, treatment and hospital details, prepares a structured claim draft, maintains a document checklist and provides a simulated claim-progress tracker. Gemini can improve the draft when consent is enabled.

### 11. Financial Scam Detector

Flags suspicious requests for credentials, advance payments, urgent transfers, guaranteed approvals and unofficial communication channels. It identifies warning signs without certifying a message as safe.

### 12. Multilingual Voice Finance Agent

Supports speech-to-text, typed input and read-aloud responses. The interface includes English, Hindi, Marathi, Tamil and Telugu language selection, with local English and Hindi starter responses.

### 13. Explain My Contract

Scans pasted financial agreements for important clauses involving interest, penalties, exclusions, auto-debit and obligations. Gemini can produce a more detailed plain-language explanation when enabled.

### 14. Consent Dashboard

Shows whether document, AI and voice access are enabled, records why data was used, and lets users revoke consent. Users can export or reset their locally saved prototype data.

### 15. Human Escalation Agent

Creates a reviewable, copyable advisor summary containing the user's profile, goal, affordability risks and recent conversation context. The prototype does not connect to a live advisor service.

### 16. Application and Journey Tracking

Creates an immutable demo snapshot of the profile and selected goal, then displays simulated application, assessment, approval and disbursal stages. Later profile changes do not modify an already-created snapshot.

### 17. FIN-VERSE — One Life, Five Simulated Futures

Compares Security-first, Balanced, Growth, Entrepreneurial and Wealth-building strategies from the same starting finances. Adjust the horizon, income growth, inflation, investment-return assumption, job loss and market shock. View five curves, accessible cash, invested assets, first goal crossing, cash shortfalls and yearly checkpoints. Choose a path, save up to ten comparison snapshots, and export the monthly results as JSON.

### 18. FIN-CRASH — Financial Crash Test

Combines job loss, an income cut, rising interest and an emergency expense into a 12-month cash-flow simulation. Shows the survival buffer, safe new EMI, minimum cash buffer and first unfunded month. A bounded search tries up to 27 shock combinations to find the lowest cash balance within the selected limits. Includes baseline comparison, monthly tables and JSON export.

### 19. FIN-GUARD — Approval-Based Recovery

Detects changes to saved finances when monitoring consent is enabled. Users declare subscriptions, SIPs, transfers and discretionary spending; FIN-GUARD prepares a 90-day plan with selectable actions and before/after cash, runway and safe EMI. Approval applies temporary local budget cuts and suppresses selected demo schedules. Plans persist across restarts, expire after 90 days and can be stopped; changed finances require a fresh review. Receipts and schedule exports distinguish local actions from provider follow-up.

Real bank monitoring, mandate changes, subscription cancellation and lender-approved EMI date changes require future provider integrations. The app does not claim to execute these externally.

## Technology Stack

| Layer | Technology |
|---|---|
| Application | Flutter 3.41+, Dart 3.11+, Material 3 |
| Platforms | Android, web and iOS-ready scaffolding |
| State management | `ChangeNotifier` and `AnimatedBuilder` |
| Local persistence | `shared_preferences` |
| File selection | `file_picker` |
| Networking | Dart `http` package |
| Backend | Dart `dart:io` HTTP server |
| Generative AI | Google Gemini GenerateContent API |
| Voice input | `speech_to_text` |
| Voice output | `flutter_tts` |
| Formatting | `intl` |
| Testing | `flutter_test` and Dart backend smoke tests |

## Architecture

FINPATH uses a feature-first structure with a small shared application store:

```text
UI action
   ↓
AppStore
   ├── FinanceEngine / local parsers
   ├── AiService → Dart backend → Gemini
   └── SharedPreferences
   ↓
notifyListeners
   ↓
Updated UI
```

- `domain/` contains models, calculations and local parsers without Flutter dependencies.
- `data/` manages application state, persistence, consent, snapshots and API calls.
- `features/` contains the individual user journeys.
- `ui/` contains the shared theme and responsive components.
- `backend/` protects the Gemini key, validates requests and returns constrained responses.

The Flutter application only receives `API_BASE_URL`. The Gemini API key remains in the backend environment and is never bundled into the APK or web build.

## Project Structure

```text
finpath/
├── android/                         # Android platform project
├── ios/                             # iOS project scaffolding
├── web/                             # Flutter web entry files
├── assets/
│   └── samples/
│       ├── payslip.txt              # Fictional payslip sample
│       ├── contract.txt             # Fictional loan contract
│       └── health_policy.txt         # Fictional policy sample
├── backend/
│   ├── bin/server.dart              # Dart Gemini proxy and REST routes
│   ├── test/server_smoke.dart        # Backend route and security checks
│   ├── .env.example                 # Environment template
│   └── pubspec.yaml
├── lib/
│   ├── main.dart                    # Bootstrap and local-state restoration
│   ├── app.dart                     # Responsive shell and navigation
│   ├── data/
│   │   ├── app_store.dart           # State, persistence and consent
│   │   └── ai_service.dart          # Backend API adapter
│   ├── domain/
│   │   ├── models.dart              # Financial and journey models
│   │   ├── finance_engine.dart      # EMI and affordability calculations
│   │   ├── resilience_engine.dart   # Future simulations, crash tests and recovery
│   │   ├── resilience_models.dart   # Scenarios, schedules and protection receipts
│   │   ├── document_parser.dart     # Conservative local extraction
│   │   └── local_advisor.dart       # Offline conversational guidance
│   ├── features/
│   │   ├── home/                    # Goal entry and financial twin
│   │   ├── planner/                 # Simulator and product comparison
│   │   ├── finverse/                # Five financial futures and saved comparisons
│   │   ├── crash/                   # Combined shocks and weakest-case search
│   │   ├── guard/                   # Consent, schedules and 90-day protection
│   │   ├── documents/               # Extraction, review and autofill
│   │   ├── claims/                  # Insurance claim copilot
│   │   ├── assistant/               # Chat, scam and contract tools
│   │   ├── journey/                 # Application tracking
│   │   ├── privacy/                 # Consent and activity history
│   │   └── profile/                 # Financial profile editing
│   └── ui/
│       ├── theme.dart               # Colour, typography and formatting
│       ├── resilience_widgets.dart  # Projection charts, controls and JSON exports
│       └── components.dart          # Shared responsive components
├── scripts/
│   ├── run_android.ps1              # Android launch and USB forwarding
│   ├── run_backend.ps1              # Backend launcher
│   └── run_web.ps1                  # Web launcher
├── test/                             # Unit, state and widget tests
├── docs/                             # Architecture and verification guides
└── pubspec.yaml
```

## Prerequisites

- Flutter 3.41 or newer
- Dart 3.11 or newer
- Android Studio and Android SDK for Android builds
- Chrome for Flutter web
- A Gemini API key only for optional AI features
- macOS and Xcode only if building for iOS

Check the development environment:

```powershell
flutter doctor
flutter devices
```

## Quick Start Without Gemini

The affordability engine, simulator, sample document flow, local assistant, scam checks, contract scan and demo trackers work without an API key.

FIN-VERSE, FIN-CRASH and FIN-GUARD also run entirely on-device without Gemini or a running backend. Financial projections use deterministic Dart calculations; Gemini remains optional for language and document tasks.

```powershell
cd finpath
flutter pub get
flutter run -d chrome --web-port 5173
```

Use a fixed web port to preserve the same browser-storage origin between runs.

## Enable Gemini

Create `backend/.env` from the supplied template if it does not already exist:

```powershell
Copy-Item backend\.env.example backend\.env
```

Add the API key:

```dotenv
GEMINI_API_KEY=your_key_here
GEMINI_MODEL=gemini-3.5-flash-lite
HOST=127.0.0.1
PORT=8080
ALLOWED_ORIGIN=
```

Start the backend in a separate terminal:

```powershell
cd finpath\backend
dart run bin/server.dart
```

Expected output:

```text
FINPATH backend: http://127.0.0.1:8080
Gemini configured.
```

In FINPATH, open **Privacy & consent**, select **Check connection**, and enable **External AI processing**. Restart the backend after changing `.env`.

## Run on a Physical Android Phone

1. Enable **Developer options** and **USB debugging** on the phone.
2. Connect it with a data-capable USB cable.
3. Unlock the phone and approve the debugging prompt.
4. Keep the backend running if Gemini is required.
5. Open PowerShell in the project directory:

```powershell
flutter devices
.\scripts\run_android.ps1 -DeviceId "YOUR_DEVICE_ID"
```

The helper script installs dependencies, creates `adb reverse tcp:8080 tcp:8080`, and launches Flutter with `http://127.0.0.1:8080` as the backend URL.

Run PowerShell scripts from PowerShell. From Git Bash, use:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass \
  -File "./scripts/run_android.ps1" \
  -DeviceId "YOUR_DEVICE_ID"
```

See [Android quickstart](docs/ANDROID_QUICKSTART.md) for troubleshooting and APK installation instructions.

## Run on an Android Emulator

Start an emulator from Android Studio Device Manager, copy its ID from `flutter devices`, and run:

```powershell
.\scripts\run_android.ps1 -DeviceId "emulator-5554" -Emulator
```

The Android emulator uses `http://10.0.2.2:8080` to reach the backend running on the computer.

## Helper Scripts

Start the backend:

```powershell
.\scripts\run_backend.ps1
```

Start the web application:

```powershell
.\scripts\run_web.ps1
```

Run these scripts in separate terminals when using Gemini.

## Build Outputs

Build an APK for a USB-connected physical phone:

```powershell
flutter build apk --debug --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

The APK is generated at:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

Build for an Android emulator:

```powershell
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Build the web application:

```powershell
flutter build web --dart-define=API_BASE_URL=https://your-secured-backend.example
```

Serve the existing compiled web build locally:

```powershell
dart tool/serve_web.dart
```

Then open `http://127.0.0.1:5180`.

Local HTTP is enabled only in the Android debug configuration. Production builds should use an authenticated HTTPS backend.

## Suggested Demo Flow

1. On **Overview**, enter `I want to buy a bike for 1.5 lakh`.
2. Open **Plan & compare** and adjust the down payment, tenure and interest rate.
3. Apply an income reduction to demonstrate financial stress and affordability warnings.
4. Open **Documents**, load the sample payslip, review a field and confirm autofill.
5. Open **Your journey**, acknowledge the prototype notice and create a demo application.
6. Open **Insurance claims**, prepare a claim draft and review its checklist.
7. Open **AI assistant** and try the EMI question, scam sample and contract sample.
8. Open **Privacy & consent** to show access history, export and consent revocation.

## Backend API

| Route | Purpose |
|---|---|
| `GET /health` | Reports server and Gemini configuration status |
| `POST /api/goal` | Extracts goal category and explicitly stated budget |
| `POST /api/chat` | Provides contextual multilingual financial explanations |
| `POST /api/extract` | Extracts allowlisted fields from supported documents |
| `POST /api/contract` | Explains pasted financial contract text |
| `POST /api/claim` | Improves a structured insurance claim draft |

The backend checks consent, origin, request size, route contract and supported document fields. It does not persist request bodies or original document bytes.

## Financial Calculations

Reducing-balance EMI:

```text
EMI = P × r × (1 + r)^n / ((1 + r)^n − 1)
```

Where:

- `P` is the principal after down payment.
- `r` is the monthly interest rate.
- `n` is the repayment period in months.
- A zero-interest loan uses `P / n`.

Prototype affordability assumptions:

- Total monthly EMIs should remain at or below 35% of net income.
- At least 20% of monthly income should remain after expenses and EMIs.
- Savings after down payment should cover at least three months of expenses and EMIs.
- Emergency buffer equals remaining savings divided by monthly expenses and total EMIs.

These assumptions are used to demonstrate explainability and are not universal lending rules.

## Testing and Validation

Run all checks from the project root:

```powershell
flutter analyze
flutter test
dart run backend/test/server_smoke.dart
flutter build web
```

The verified implementation currently includes:

- 46 passing Flutter unit, state and widget tests, including the new resilience journeys.
- 8 backend smoke checks passed in the earlier verification; backend code is unchanged in this update.
- Clean Flutter static analysis.
- Successful Android debug APK and Flutter web builds.
- Earlier physical-device checks on Android 16. The new USP build has phone-width widget coverage; no Android phone was connected for its runtime check.

See [verification record](docs/VERIFICATION.md) for the full test scope and known platform limitations.

## Privacy and Safety Boundaries

- Use fictional data when demonstrating the prototype.
- Original uploaded bytes are processed in memory and are not saved by the app or backend.
- Extracted values, profile data, chat, claims and demo applications are stored unencrypted in local prototype storage.
- AI, document and voice permissions are independently controlled.
- AI consent is checked before sending a request and again before accepting its result.
- Document fields must be reviewed before autofill.
- Gemini is not used to calculate EMI or make final approval decisions.
- Product names, interest rates and processing fees are illustrative.
- No real KYC, payment, lender submission, insurance submission, approval or disbursal occurs.

## Production Roadmap

Before using real financial data, the project should add:

- Authentication and role-based access control.
- Encrypted device and server-side storage.
- HTTPS deployment, rate limiting and secret management.
- Consent lifecycle, retention and deletion policies.
- Reliable document provenance, confidence and reconciliation.
- Regulated KYC, Account Aggregator, credit bureau, lender and insurer integrations.
- Provider-driven application and claim status events.
- Monitoring, audit controls and formal security review.
- Real human-advisor routing and service-level tracking.

## Additional Documentation

- [Architecture and extension guide](docs/ARCHITECTURE.md)
- [Android quickstart](docs/ANDROID_QUICKSTART.md)
- [Verification record](docs/VERIFICATION.md)
- [Technical approach diagram](docs/pitch_assets/technical_approach.jpg)
- [Workflow and technology stack diagram](docs/pitch_assets/finpath_workflow_and_stack.jpg)

## Technical References

- [Flutter documentation](https://docs.flutter.dev/)
- [Gemini GenerateContent API](https://ai.google.dev/api/generate-content)
- [Gemini model documentation](https://ai.google.dev/gemini-api/docs/models)
- [speech_to_text package requirements](https://pub.dev/packages/speech_to_text)
- [flutter_tts package requirements](https://pub.dev/packages/flutter_tts)
