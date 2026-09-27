# FINPATH USP implementation and demo

FIN-VERSE, FIN-CRASH and FIN-GUARD work on Android and web without API keys. All settings, selected strategies, comparison snapshots, approved plans and receipts are saved locally. These are modelled financial scenarios and local prototype actions, not live banking services.

## A five-minute demo

1. Open **Financial profile** and enter income, living expenses, accessible savings and existing EMIs. Choose a goal in **Plan & compare**.
2. Open **FIN-VERSE** from Home or the menu. Compare the five curves. Turn on a six-month job loss or market shock; select a strategy to see its assumptions and yearly checkpoints. Save the comparison or export every month.
3. Open **FIN-CRASH**. Try three months without income, a two-percentage-point rate rise and a ₹40,000 emergency. Compare the safe EMI and survival buffer, then inspect the first negative cash month. **Find weakest combination** searches within your selected shock limits.
4. Open **FIN-GUARD** and enable **Monitor changes to my saved finances**. Open **Budget & schedules**, add your categories and recurring payments, or load the explicitly labelled editable demo schedules. Save.
5. Choose **Record income change**, for example ₹80,000 → ₹64,000. The saved profile changes and a new recovery proposal appears automatically. Choose actions and compare retained cash, outgo, runway and day-90 cash.
6. Tick the review/approval checkbox and select **Activate 90-Day Protection Mode**. The effective budget changes immediately and selected demo payment occurrences are suppressed. Review or export the receipt. **End protection** restores the regular local budget.

Demo schedules are fictional: ₹1,800 unused subscriptions, ₹5,000 SIP and ₹2,000 transfer. The demo discretionary category is capped at ₹8,000 and 25% of entered living expenses. Outcomes depend on the entered finances; marketing examples are not hardcoded results.

## FIN-VERSE model

Every strategy starts with the same accessible savings in cash and zero modelled investments. Existing investments and debt principal are not supplied by the current profile. Net financial assets here mean simulated cash + investments − unfunded needs, not complete net worth.

| Strategy | Living-cost factor | Surplus invested | Annual return assumption | One-time market-shock loss |
|---|---:|---:|---:|---:|
| Security-first | 95% | 15% | 4% | 5% |
| Balanced | 100% | 45% | 6% | 12% |
| Growth | 100% | 75% | 9% | 25% |
| Entrepreneurial | 95% | 65% | 10% | 40% |
| Wealth-building | 80% | 70% | 8% | 20% |

These are editable scenario assumptions through the common return adjustment, not market forecasts. The entrepreneurial path is a higher-volatility capital-allocation scenario; it does not simulate an actual business balance sheet.

- Monthly income and expenses compound using entered annual growth and inflation.
- Existing EMI stays constant because its outstanding term is unknown.
- Positive surplus first covers accumulated unfunded needs, then splits between cash and investments. Cash earns zero interest.
- Deficits draw cash first, then investments, then become explicitly unfunded needs. The model does not invent a loan to cover them.
- Job loss begins in the chosen month; the market shock, if selected, applies once to the investment balance in that month.
- The savings goal rises with inflation. Goal timing is the **first crossing**, not a guarantee that the balance stays above the target. The proposed goal loan is excluded from these savings alternatives.
- Strategies replace existing SIP allocations, avoiding double counting. Other declared transfers remain outflows. Long-term comparisons use the regular budget, not temporary FIN-GUARD cuts.
- Fees, taxes, liquidation delays and variable market returns are not modelled. The app exposes all assumptions and retains the exact input snapshot when saving.

## FIN-CRASH model

The comparison includes the goal loan: savings minus down payment at month zero, with the emergency expense deducted immediately in the stressed case. It uses the regular budget including recurring SIP/transfer outflows. Temporary protection changes are compared separately in FIN-GUARD.

- Job loss starts in month one. After returning, income reflects the selected permanent income cut.
- The proposed loan reprices immediately by the chosen rate increase, over the original full tenure. Existing EMIs stay fixed; the proposed EMI ends at its loan term.
- Monthly cash = previous cash + income − living expenses − scheduled outflows − applicable EMIs.
- Survival buffer = non-negative accessible cash / monthly outgo, assuming no income. The lowest buffer scans the full 12-month projection.
- Safe new EMI = max(0, min(35% of income − existing EMI, 80% of income − living expenses − recurring outflows − existing EMI)). Job loss makes income-funded safe EMI zero.
- Negative cash is a financing gap, not an automatically approved overdraft. Exports do not subtract the same gap twice.
- Weakest-case search tries zero, half and maximum selected job loss, rate increase and emergency cost: at most 27 combinations. It holds the income-cut input fixed and minimizes the lowest projected cash balance. It estimates no probabilities and cannot find every real-world risk.

## FIN-GUARD model and execution

Monitoring is off until consent is enabled. It reacts to profile edits, reviewed document updates, goals and budget/schedule edits inside FINPATH. It is not a background connection to a bank.

Subscriptions and discretionary spending must be categories **inside** existing living expenses. SIPs and transfers are declared **additional** outflows. Validation prevents category totals exceeding living expenses. Only subscriptions explicitly marked unused are proposed for removal.

Available actions:

- Pause selected SIP/transfer demo occurrences for 90 days. Retain the contribution in cash; this is not extra income or investment profit.
- Suppress unused subscription demo occurrences and reduce the corresponding local expense projection.
- Temporarily halve the declared discretionary category; leave essentials unchanged.
- Prepare an EMI-date follow-up when the due date precedes payday. This has **zero cash savings** and remains provider-dependent.

Monthly outgo includes existing and proposed EMIs. Starting cash deducts the proposed goal down payment. The day-90 comparison uses three 30-day months at the current income/outgo; it is not a day-by-day bank balance prediction. Deficit-funded runway divides cash by outgo minus income; if income covers outgo, the UI says **No monthly deficit**. A separate zero-income buffer divides cash by all outgo. Buffer ratios describe the current plan's burn rate; protection itself lasts only 90 days.

Execution requires monitoring consent, a current unmodified proposal, valid selected actions and explicit approval. Duplicate activation is idempotent. The source profile is preserved; the effective budget is a temporary overlay used by current affordability, planner and assistant calculations. The receipt records each selected action, activation, expiry and scheduled payment occurrences. Provider instructions are never sent.

Stopping protection, revoking monitoring, editing underlying finances or reaching expiry restores the regular budget. Changed finances generate a fresh proposal when consent remains enabled. Expiry is checked when loading, resuming the app and once a minute while open. A receipt remains a historical record even after restoration. Up to ten receipts and ten saved future comparisons are retained; the privacy export includes them and reset clears them.

## Goal-first visuals

Natural-language goal entry, goal planning and simulation charts work now. The goal-first message mentions future illustrated journeys with visuals. Those illustrations/storytelling screens are intentionally deferred as requested.

## Source map

- `lib/domain/resilience_models.dart`: scenario, projection, payment, action and receipt models.
- `lib/domain/resilience_engine.dart`: deterministic simulations, search and recovery proposals.
- `lib/data/app_store.dart`: persistence, monitoring, stale-proposal checks and local execution lifecycle.
- `lib/features/finverse/`, `crash/`, `guard/`: responsive feature screens.
- `lib/ui/resilience_widgets.dart`: charts, controls, statistics and JSON export.
- `test/resilience_*_test.dart`: arithmetic, state lifecycle, persistence and phone/desktop interaction tests.

No new dependencies, backend endpoints or Gemini key settings are required for these features. Bank feeds, real payment execution, lender/provider APIs, encrypted production storage and push/background monitoring remain future integrations.
