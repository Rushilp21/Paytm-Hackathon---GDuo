# Architecture and extension guide

The app deliberately stays in Dart throughout so a Flutter team can own it.

## Data flow

`UI action → AppStore → FinanceEngine / AiService → notifyListeners → UI`

`AppStore` is a `ChangeNotifier` with one shared profile and current goal. `AppShell` listens and rebuilds the selected feature. Each feature owns only transient form inputs and local view state. Storage writes are queued in order so a rapid slider movement cannot persist an older state over a newer state.

`domain/` has no Flutter dependency. EMI, affordability, goal parsing and document parsing can be unit tested independently. `ui/` is shared styling, not financial logic. `features/` separates user journeys. `data/` owns side effects and local persistence.

Document extraction never mutates the profile directly. It creates an unreviewed `DocumentRecord`; the review action merges only approved supported values. A new demo application captures a JSON snapshot of the goal and profile, so future edits do not alter its submitted terms.

## Financial resilience features

`ResilienceEngine` and `resilience_models.dart` implement monthly future projections, combined stress tests, a bounded worst-case search and recovery proposals. They have no Flutter or network dependencies. FIN-VERSE, FIN-CRASH and FIN-GUARD screens use the existing store, responsive shell and a shared custom-painted chart.

`AppStore` persists simulation assumptions, chosen strategy, comparison snapshots, optional monitoring consent, recurring schedules, proposals and protection receipts. Monitoring reacts to saved profile, reviewed-document, goal and schedule changes. A proposal includes a signature of the exact inputs; activation checks this signature, consent, selected action IDs and explicit approval. Repeated activation is idempotent.

The original profile remains unchanged when protection is activated. `planningProfile` adds scheduled outflows and subtracts approved temporary cash releases. `baselineProfile` retains the regular budget for crash tests; `verseProfile` excludes existing SIP allocations because the five strategies replace them. This avoids both double-counting investments and extending temporary protection savings over long forecasts.

Protection ends on revocation, changed finances, explicit stop or expiry. The app checks expiry during startup, resume and periodically while open. Receipts keep the original plan and schedule as a historical record. No payment provider receives an instruction. See [the resilience guide](RESILIENCE_GUIDE.md) for formulas, a demo script and integration boundaries.

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
