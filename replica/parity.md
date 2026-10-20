# Parity report

Feature score: **95.5 / 100**, must-haves 12/12 written (see parity-score.md).
Layout score: not measured — no reference screenshots of the originals were saved (recon used public listings only).
Verdict: **better than the original on paper, not yet shippable** — the iOS code has passed a syntax check but has
not been compiled in Xcode or run on a device yet. Run the manual cases in test-plan.md first.

Behaviour differences
| flow | original | Tact | keep/fix |
| --- | --- | --- | --- |
| F01 | upload → tone → ~2-4 replies, taps ~5 | screenshot → (tone on same screen) → 4 replies + read line, 4-5 taps | keep |
| F07 | hard paywall / trial on launch, weekly plans | 3 free/day, closable paywall, monthly/yearly | keep |
| privacy | image uploaded | OCR on device, redaction | keep |

Next 5 to build: 1) compile + device pass, 2) generate inside the keyboard (Full Access + API), 3) learn voice from sent history,
4) App Attest for free-quota abuse, 5) referral credits.
