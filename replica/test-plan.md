# Test plan

Automated: `server/tests` (pytest, 23 cases) + `e2e/smoke.py` (14 checks against a running server) + `e2e/ocr_heuristics_test.py`.
Manual (needs Xcode + iPhone/Simulator): marked M.

F01 Reply from screenshot
- F01-H1 pick 1 iMessage screenshot → bubbles appear, sides right → Write my reply → 4 cards (M; server side automated)
- F01-H2 tweak "shorter" → 2 alternatives under the card (automated server, M UI)
- F01-E1 screenshot with no text → "Couldn't find any messages…" (M)
- F01-E2 sides wrong → tap bubble flips side (M)
- F01-E3 Instagram/WhatsApp/Hinge screenshots (avatars, reactions) → check attribution (M)
- F01-E4 3 screenshots in order → one merged chat (M)
- F01-E5 emoji/accents → preserved (automated: smoke sends 🥶)
- F01-E6 very long chat → 413 "crop to the last part" (automated)
- F01-E7 offline → "Can't reach Tact right now" (M)
- F01-E8 double tap Write → single request (M)
- F01-N1 they said "please stop texting me" → boundary banner + respectful replies (needs live model, M)
F02 Opener — H1 automated (server); E1 profile screenshot OCR (M)
F03 Lines — H1 automated; E1 offensive topic → polite lines (live model, M)
F04 Vibe — H1 automated; E1 2-message chat (M)
F05 Bio — H1 automated
F06 Coach — H1 automated; empty → 400 automated
F07 Pro — H1 StoreKit test purchase in Simulator with Tact.storekit → Pro pill (M); N1 limit → 402 → paywall opens (automated server, M UI); restore (M); cancel via Manage subscription (M)
F08 Keyboard — enable, Full Access off → hint; on → recent replies; tap inserts (M)
Privacy — delete my data clears history, voice, keyboard, server rows (server automated, M UI); phone/email redacted before send (M)
