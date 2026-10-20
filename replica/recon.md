# Recon map: AI rizz / dating-wingman apps (iOS)

Scope: the core wingman loop shared by RizzGPT, RIZZ (TREND IT), Plug AI and WingAI —
chat screenshot → AI replies in a chosen tone, plus openers from a profile, pickup lines,
a "vibe check" of a chat, bio review, a coach chat, and a reply keyboard.
For: Dean's own iPhone app (SwiftUI), built to be sellable on the App Store.
Date: 2026-10-17
Method: public App Store listings, public review aggregators and hands-on review articles only.
No accounts logged into, no app binaries or network traffic inspected.

## Sources

| # | source | URL | notes |
| --- | --- | --- | --- |
| 1 | App Store: RizzGPT: AI Dating Wingman | https://apps.apple.com/us/app/-/id6444730312 | features, tones (friendly/funny/flirty/NSFW), rizz meter, bio rating, IAP list |
| 2 | App Store: Rizz! AI keyboard | https://apps.apple.com/app/id1661403200 | keyboard, screenshot upload, tones, subjects, referral words |
| 3 | mwm.ai: RIZZ (TREND IT) | https://mwm.ai/apps/rizz/1663430725 | adaptive style, "Chat Wrapped" (interest level, red/green flags, compatibility), $9.99/wk |
| 4 | App Store: Plug AI | https://apps.apple.com/us/app/plug-ai-pick-up-lines-rizz/id6449148120 | openers from bio, follow-ups, weekly/yearly pricing |
| 5 | App Store: WingAI | https://apps.apple.com/app/id6448704223 | screenshot of chat or bio → replies/openers, 4.8 from 20K |
| 6 | VentureRadar on Plug AI | https://ventureradar.substack.com/p/this-23-year-olds-ai-app-makes-200kmonth | 3-4 replies per screenshot, safe→spicy slider, coach chat, iMessage keyboard, 3-day trial → weekly |
| 7 | FireTexts hands-on of Plug AI | https://firetexts.com/is-plug-ai-worth-it-rizz-app/ | home menu (respond / pickup line / ask), ~2 suggestions per screenshot, no free version |
| 8 | SwipeStats Rizz review | https://www.swipestats.io/blog/rizz-app-review | onboarding quiz (style, humour, goals), free 5-10/day claim, tiers |
| 9 | Roast.dating RizzGPT review | https://roast.dating/blog/rizz-gpt-review | flow: context → tone → generate → edit; privacy advice to redact |

## Core loop

Upload a screenshot of a chat, pick a tone, get 3-4 replies you can copy and send.

## Screens

| ID | screen | how to reach | purpose | key components | states seen |
| --- | --- | --- | --- | --- | --- |
| S01 | Welcome carousel | first launch | pitch the value | hero, page dots, primary button | filled |
| S02 | Style quiz | after S01 | your vibe (funny/chill/bold/sweet), goal, 18+ confirm | choice chips, progress bar | filled, incomplete |
| S03 | Paywall | after quiz, on limit hit, from settings | sell Pro | plan cards, trial toggle, restore, close X | loading, purchased, error, already pro |
| S04 | Home | tab 1 | pick a tool | tool cards grid, credits pill | free, pro, out of credits |
| S05 | Screenshot import + review | S04 "Reply" | pick screenshot(s), read text, fix who-said-what | photo picker, message bubbles (me/them), redact toggle | empty, OCR loading, OCR failed, filled |
| S06 | Tone + goal | from S05/S08 | choose tone and what you want | tone chips, goal chips, spice slider, extra context field | default, filled |
| S07 | Reply results | generate | show 3-4 replies | reply cards (copy, favourite), regenerate, tone switcher | loading (skeleton), filled, error, limit hit |
| S08 | Opener from profile | S04 "Opener" | first message from bio/profile | screenshot or paste field | empty, OCR loading, filled |
| S09 | Pickup lines | S04 "Lines" | lines for a name/topic | text field, topic chips, line list | empty, loading, filled |
| S10 | Vibe check | S04 / S05 action | rate a chat: interest, flags, next move | meter gauge, flag lists, advice | loading, filled, error |
| S11 | Bio review | S04 "Bio" | score + rewrites of your bio | text area, score ring, rewrites | empty, loading, filled |
| S12 | Coach chat | tab 2 | ask dating/texting questions | chat bubbles, composer, suggestion chips | empty, typing, filled, error |
| S13 | History | tab 3 | past generations, favourites | list rows, search, swipe delete | empty, filled |
| S14 | Settings | tab 4 | plan, defaults, keyboard, privacy, delete data | grouped list, toggles | free, pro |
| S15 | Keyboard extension | system keyboard | insert saved replies in any app | reply chips, globe/next keyboard, open app | no full access, empty, filled |
| S16 | Keyboard setup | S14 | how to enable the keyboard | numbered steps, open Settings button | filled |

## Flows

```
F01 Reply to a chat from a screenshot (core loop)
    S04 -> S05 (pick screenshot, OCR) -> S06 (tone) -> S07 (copy reply)
    happy path taps: 5 (tool, pick, confirm text, generate, copy)   <- number to beat: 4
    edge: no text found, screenshot of non-chat, sides misattributed, very long chat,
          limit reached mid-flow, offline, model error, other person said "not interested"

F02 Write an opener from a profile
    S04 -> S08 (screenshot or paste bio) -> S06 -> S07
    edge: empty bio, profile in another language

F03 Get pickup lines
    S04 -> S09 (name/topic) -> generate -> copy
    edge: blank input -> generic lines; offensive input -> refuse politely

F04 Vibe check a chat
    S05 -> "Check the vibe" -> S10
    edge: too short a chat to judge

F05 Improve my bio
    S04 -> S11 -> paste -> review -> copy rewrite

F06 Ask the coach
    S12 -> type or chip -> answer; can attach the current chat

F07 Go Pro
    limit hit / S14 -> S03 -> purchase (StoreKit) -> back with unlimited
    edge: cancel, pending (Ask to Buy), restore, already subscribed on another device

F08 Use replies in another app
    S14 -> S16 -> enable keyboard -> in any app S15 -> tap reply to insert
```

## Components

| component | variants | states | used on |
| --- | --- | --- | --- |
| PrimaryButton | primary, secondary, ghost | default, pressed, disabled, loading | all |
| ToolCard | large, small | default, pressed, locked | S04 |
| Chip | single-select, multi-select | off, on, disabled | S02, S06, S09, S12 |
| MessageBubble | me, them | default, editing | S05, S12 |
| ReplyCard | — | default, copied, favourited, loading skeleton | S07, S08, S09, S13, S15 |
| CreditsPill | free (n left), pro | — | S04, S07 |
| Meter | 0-100 gauge | animating | S10, S11 |
| PlanCard | weekly/monthly/yearly | selected, best value badge | S03 |
| Toast | success, error | — | everywhere |
| EmptyState | — | — | S13, S05, S12 |

## Inferred data model

```
Profile (on device)  style (funny|chill|bold|sweet), goal, defaultTone, ageConfirmed, onboarded
    evidence: S02 quiz (src 8), "adaptive style" (src 3). confidence: medium

Generation  id, kind (reply|opener|lines|vibe|bio), input text, tone, goal, outputs [string], favourite, createdAt
    evidence: S07 results, history in RIZZ ("Recent Rizz", src 2). confidence: high

ChatTranscript  messages [{from: me|them, text}]
    evidence: screenshot analysis (src 1,5,6). confidence: high

VibeReport  interest 0-100, greenFlags[], redFlags[], nextMove
    evidence: "Chat Wrapped" (src 3), rizz meter (src 1). confidence: high

Entitlement  plan, expiresAt, freeUsedToday
    evidence: IAP lists (src 1,4,5), free limits (src 8). confidence: high

CoachMessage  role, text, createdAt  (src 6). confidence: medium
```

Relationships: Profile 1-n Generation; CoachThread 1-n CoachMessage. No server-side user
accounts needed — originals don't require sign-up for the core loop.

## Feature matrix

See `features.csv`.

## What cannot be cloned

- Their brand names ("Rizz", "Plug", "Wing"), icons, copy, TikTok content — skip.
- Their "trained on millions of chats" datasets — skip; we use a general LLM + our prompts.
- Linking to dating-app accounts (src 8 claims it): no official public Tinder/Hinge/Bumble API — skip.
- NSFW tone (src 1): skip on purpose (App Store risk, and reviews show it backfires).

## Size

16 screens, 8 flows, 5 entities. Hard parts: on-device OCR with correct me/them
attribution, StoreKit 2 subscriptions + server-side entitlement check, the keyboard
extension, and reply quality (the #1 complaint). Size: M (a few weeks to polish; MVP now).
