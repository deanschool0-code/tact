# Deploy checklist: Tact

Date: 2026-10-17  Go from user: not yet — deploy step intentionally not run (needs Dean's accounts and a compiled build).

## Preflight
- [x] server tests green: 23/23 · e2e smoke 14/14 · OCR heuristic check passes
- [x] no open S1/S2 bugs reproduced
- [x] parity: must-haves 12/12 written, feature score 95.5
- [x] rebrand sweep clean (sweep.py exit 0)
- [x] store listing passes (listing.py exit 0)
- [ ] production build passes — **open the project in Xcode and build (not done yet)**
- [ ] privacy policy + terms live (update Config.privacyURL), processors: Anthropic, your host
- [x] delete my data works (server tested)
- [x] app icon is yours (tools/make_icon.py) — replace with a designer's version later

## Production (server)
- [ ] host: Render/Railway/Fly with the Dockerfile, persistent disk at /data
- [ ] env vars from server/.env.example: AI_PROVIDER=anthropic, ANTHROPIC_API_KEY, APP_BUNDLE_ID, APP_APPLE_ID, ALLOW_XCODE_TRANSACTIONS=0
- [ ] server/certs/AppleRootCA-G3.cer
- [ ] App Store Connect: app record, subscription group + 2 products, paid apps agreement, tax/banking
- [ ] Config.defaultServerURL → https production URL

## Domain
- [ ] api.<yourdomain> CNAME → host; HTTPS valid
- [ ] site/index.html on the apex (Cloudflare Pages / Netlify)

## App Store
- [ ] age rating 17+; privacy labels: "User Content (chat text) — not linked, not used for tracking"; Purchases
- [ ] review notes: explain OCR on device, free 3/day, StoreKit sandbox; 4.1 copycat: own name, icon, voice-matching + privacy features visible in screenshots
- [ ] TestFlight build to 10–20 testers first
