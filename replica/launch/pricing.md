# Pricing

Read 2026-10-17 from the public App Store pages (US). Prices change; re-check before launch.

| app | plans seen | source |
| --- | --- | --- |
| RizzGPT | Pro weekly $6.99–7.99, monthly $8.99, annual $79.99, plus credit/no-ads IAPs | https://apps.apple.com/us/app/-/id6444730312 |
| Plug AI | weekly $2.99–6.99, yearly $29.99–69.99 | https://apps.apple.com/us/app/plug-ai-pick-up-lines-rizz/id6449148120 |
| WingAI | monthly $3.99–19.99, yearly $29.99–79.99 | https://apps.apple.com/app/id6448704223 |
| RIZZ (TREND IT) | reviewers report $9.99/week | https://mwm.ai/apps/rizz/1663430725 |

What reviewers said (feedback.md): price/paywall 8 reviews, stuck on paywall 6, billing/cancel 3 — weekly plans are the sore spot.

## Tact

| tier | for | price | what |
| --- | --- | --- | --- |
| Free | trying it, light use | $0 | 3 generations a day across all tools, keyboard, history |
| Pro Monthly | active daters | $4.99/mo | unlimited everything |
| Pro Yearly | regulars | $29.99/yr (~$2.50/mo), 3-day free trial | unlimited everything |

No weekly plan. Paywall always has a "Not now" button. Manage/cancel button in Settings.

## Create in App Store Connect (Dean does this)

Subscription group "Tact Pro": `tact.pro.monthly` ($4.99, 1 month), `tact.pro.yearly` ($29.99, 1 year, intro offer: free 3 days).
Product IDs must match `ios/Tact/Config.swift` and `server/tact/entitlements.py`.
