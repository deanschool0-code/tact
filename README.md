# Tact — AI reply coach (iPhone)

Your own take on the AI "rizz"/wingman apps: screenshot a chat → pick a vibe → get replies that sound like you.
Built with the Replica pack; planning docs are in `replica/` (recon, reviews, fixes, architecture, design, brand, tests, parity, launch, deploy).

```
ios/       SwiftUI app (iOS 17+) + Tact keyboard extension — open ios/Tact.xcodeproj
server/    Flask API that holds the AI key, free quota, Pro verification
site/      landing page (static HTML)
e2e/       smoke test against a running server + OCR heuristic check
tools/     icon + Xcode project generators
replica/   all the research and planning
```

## Run it (Mac)

**1. Server**
```bash
cd server
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env        # set AI_PROVIDER=anthropic and ANTHROPIC_API_KEY=...  (or AI_PROVIDER=mock to try without a key)
python wsgi.py              # http://localhost:5580
python -m pytest -q         # 23 tests
python ../e2e/smoke.py      # 14 end-to-end checks against the running server
```
Using your Ollama gateway instead: `AI_PROVIDER=openai_compat`, `OPENAI_BASE_URL=http://localhost:11434/v1`, `OPENAI_MODEL=...`.

**2. App**
1. Open `ios/Tact.xcodeproj` in Xcode 16 or newer.
2. Select the **Tact** target → Signing & Capabilities → pick your Team (do the same for **TactKeyboard**).
   If you change the bundle id, also change the App Group in `ios/Support/*.entitlements`, `Config.appGroup` and `Shared/SharedReplies.swift`.
3. Run on an iPhone Simulator — it talks to `http://localhost:5580` on your Mac.
4. Test purchases: the scheme uses `Tact.storekit` (Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration if it isn't picked up). Keep `ALLOW_XCODE_TRANSACTIONS=1` in the server's .env while testing.
5. On a real iPhone: expose the server with `cloudflared tunnel --url http://localhost:5580` and paste the https URL into Settings → Developer → Server in the app.

If signing complains about App Groups on a free Apple ID: remove the TactKeyboard target and the App Group entitlement — the app works without the keyboard.

## How it works
- Screenshots → Apple Vision OCR on the phone → bubbles split into me/them by position → phone numbers, emails, links and @handles hidden → only text goes to the server.
- Server builds the prompt (voice samples, tone, goal, hard rules: no clichés, use a detail from the chat, respect a "no", nothing explicit, nothing romantic if anyone may be under 18) → Claude → JSON → app.
- Free: 3 generations/day/device. Pro: StoreKit 2 subscription verified on the server with Apple's official library.
