# Backend checklist

Stack: Flask + SQLite, Anthropic API (or OpenAI-compatible), Apple app-store-server-library.
Auth: anonymous device ID (Keychain) — no accounts, so no passwords/email. Apple's account-deletion rule doesn't apply (no sign-up), but "Delete my data" exists anyway.
Payments: StoreKit 2 (Apple IAP) instead of Stripe — Apple requires IAP for digital subscriptions.

- [x] secrets only in env vars, `.env` gitignored, no AI key in the app
- [x] input validated on every route (types, lengths, kinds)
- [x] per-device data only; second device sees nothing (test_free_limit…other_device)
- [x] rate limits per device and IP
- [x] signed transactions verified with Apple's library (Production/Sandbox; Xcode only when ALLOW_XCODE_TRANSACTIONS=1)
- [x] no chat text stored or logged
- [ ] App Attest before public launch (device IDs are spoofable)
- [ ] App Store Server Notifications v2 webhook for renewals/refunds (today the app re-sends its entitlement on launch)
- [ ] privacy policy listing processors: Anthropic (AI), your host
- [ ] put AppleRootCA-G3.cer in server/certs (download from apple.com/certificateauthority)
