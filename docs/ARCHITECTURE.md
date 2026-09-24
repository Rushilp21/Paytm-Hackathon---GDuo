# Architecture and extension guide

The app deliberately stays in Dart throughout so a Flutter team can own it.

## Data flow

`UI action → AppStore → FinanceEngine / AiService → notifyListeners → UI`

`AppStore` is a `ChangeNotifier` with one shared profile and current goal. `AppShell` listens and rebuilds the selected feature. Each feature owns only transient form inputs and local view state. Storage writes are queued in order so a rapid slider movement cannot persist an older state over a newer state.

`domain/` has no Flutter dependency. EMI, affordability, goal parsing and document parsing can be unit tested independently. `ui/` is shared styling, not financial logic. `features/` separates user journeys. `data/` owns side effects and local persistence.

Document extraction never mutates the profile directly. It creates an unreviewed `DocumentRecord`; the review action merges only approved supported values. A new demo application captures a JSON snapshot of the goal and profile, so future edits do not alter its submitted terms.

## AI boundary

The Flutter client has only `API_BASE_URL`. The Dart backend loads `GEMINI_API_KEY` from `backend/.env` or environment variables. It binds to loopback by default, accepts local browser origins and one optional explicit origin, limits body size, checks task routes and consent, calls Gemini, and returns validated answer/field shapes. It does not write request contents or original documents to disk.

Routes:

| Route | Contract |
|---|---|
| `GET /health` | `{ok: true, configured: bool}`; does not validate the key with Google |
| `POST /api/chat` | consent, message, language, financial context, recent history → answer |
| `POST /api/goal` | consent, goal text, language → validated intent and stated INR budget; unspecified costs remain editable estimates |
| `POST /api/extract` | consent, selected attachment `{mimeType, data: base64}` → supported fields |
| `POST /api/contract` | consent, pasted contract text → answer |
| `POST /api/claim` | consent, claim draft text → answer |

AI consent is checked before requests and again before accepting results; revocation cannot recall an already transmitted request. Document and voice consent are independently enforced. The activity log describes purpose, while the local export contains the actual saved state.

Gemini is used for language/document tasks. It does not decide EMI, invent eligibility probabilities, or execute lender actions. Uploaded documents are treated as untrusted data in the system prompt. Supported extracted fields are allowlisted server-side, then explicitly reviewed by the user.

## Extending it

- Add true lender integrations behind a new repository/service interface; keep the simulator deterministic and expose actual lender fees/APR and consent requirements.
- Add authentication and secure storage before using real financial data or exposing the backend beyond a trusted demo environment.
- Add a real document processing pipeline for multi-page extraction, provenance, confidence and reconciliation. Do not equate model extraction with verification.
- Replace the local claim/application trackers with provider events only when integrations exist; retain explicit demo mode for presentations.
- For a larger team, split `AppStore` by journey or introduce Riverpod. Current `ChangeNotifier` avoids extra concepts for a small hackathon team.
