# Architecture: Tact (iOS)

## Stack

| layer | choice | why |
| --- | --- | --- |
| app | SwiftUI, iOS 17+, Swift 5.9+ | Dean's stack for his other iPhone apps; native photo picker, Vision, StoreKit |
| local data | SwiftData (history, favourites) + AppStorage (profile) | no accounts needed; history stays on the phone |
| OCR | Apple Vision `VNRecognizeTextRequest`, on device | screenshot never leaves the phone (fix 4) |
| redaction | `NSDataDetector` (phone, link, address) + email regex, on device | fix 4 |
| keyboard | Custom keyboard extension, App Group shared JSON | parity with Plug AI / Rizz keyboard |
| payments | StoreKit 2 auto-renewable subscriptions (monthly, yearly) | Apple requires IAP for digital goods; Stripe is not allowed here |
| server | Python 3.11 + Flask, one file app + modules | Dean knows Flask; tiny surface |
| server DB | SQLite (one file on a persistent volume) | only usage counters + verified transactions; swap for Postgres if it grows |
| AI | Anthropic Messages API (default) or any OpenAI-compatible endpoint (e.g. his Ollama gateway) | his own keys; provider is an env var |
| pro check | Apple's official `app-store-server-library` `SignedDataVerifier` | verifies the StoreKit JWS on the server; never trust the client |
| hosting | Render / Fly.io / Railway (Docker) or his Mac + Cloudflare Tunnel for testing | one container |

## Schema (server, SQLite)

```sql
create table usage (
  device_id text not null,            -- random UUID kept in the iPhone's Keychain
  day text not null,                  -- YYYY-MM-DD in UTC
  count integer not null default 0,
  primary key (device_id, day)
);
create table entitlements (
  original_transaction_id text primary key,
  device_id text not null,
  product_id text not null,
  expires_at text,                    -- ISO8601 UTC
  environment text not null,          -- Production | Sandbox | Xcode
  updated_at text not null
);
create index entitlements_device on entitlements(device_id);
```

Access rule: every request carries `X-Device-ID`; the server only reads/writes rows for that
id. No chat text is stored on the server, and the server never logs request bodies.

Local (SwiftData): `Generation(id, kind, inputSummary, tone, outputs[], read, favourite, createdAt)`.

## API

| method path | does | input | output | flow |
| --- | --- | --- | --- | --- |
| GET /health | liveness | — | {ok} | — |
| GET /v1/quota | free uses left today, pro flag | headers | {pro, used, limit, remaining} | F07 |
| POST /v1/generate | replies / opener / lines / vibe / bio / tweak | {kind, transcript[], text, tone, goal, extra, style, voice[], tweak, base} | kind-specific JSON | F01-F05 |
| POST /v1/coach | coach chat | {messages[], context?} | {reply} | F06 |
| POST /v1/entitlement | verify a StoreKit JWS, store it | {jws} | {pro, expires_at} | F07 |
| POST /v1/data/delete | delete this device's server rows | headers | {deleted} | settings |

Free quota: 3 generations per device per UTC day (env `FREE_DAILY`). Coach counts as one.
Rate limit: 30 requests/minute per device and per IP. Inputs capped (60 messages, 6k chars).

## Parts that bite

- Reply quality is the product: prompts in `server/tact/prompts.py`, tested with fixtures.
- OCR attribution: bubbles on the right = me, left = them; drop clock/status/"Delivered" lines.
- StoreKit testing: Xcode-signed local transactions can't be verified by Apple's roots →
  `ALLOW_XCODE_TRANSACTIONS=1` in dev only.
- Device ID is spoofable → free-quota abuse possible. Before launch: add App Attest.
- Keyboard extensions need Full Access to read the App Group; must work (show a hint) without it.
- Age: App Store rating 17+; app asks for 18+ confirm; no NSFW tone.

## Build order

1. Vertical slice: S04 → S05 → S06 → S07 with the server's `mock` provider.
2. Must-haves: OCR + redaction, voice match, opener, lines, paywall + StoreKit, delete data.
3. Should-haves: vibe check, bio, coach, history, keyboard, tweaks.
4. Could: referral, adaptive style learning from history.
