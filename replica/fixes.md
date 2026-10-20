# Fixes and angle

Sample: 40 review excerpts and reviewer criticisms from 8 sources (App Store pages, justuseapp,
mwm.ai, 3 hands-on review articles). Only 3 carried star ratings. This is a small sample:
treat the ranking as directional. The App Store customer-reviews RSS feed was blocked by
robots.txt for the fetch tool, so it was not read. Next pass: read 100+ reviews by hand in
the App Store app (sort by most recent) and add them to `reviews.csv`.

## 1. What they hate

1. **Replies are generic, cringe or preset** — 12 reviews, 6 sources (biggest theme).
   "These are literally just preset cringy responses." — https://justuseapp.com/en/app/6449750416/rizzgpt/reviews
   "Poor context awareness" — https://firetexts.com/is-plug-ai-worth-it-rizz-app/
   Side effect users report: getting blocked or reported after sending lines.
2. **Price, weekly plans** — 8 reviews, 3 sources.
   "9.99 a week is crazy not worth" — https://mwm.ai/apps/rizz/1663430725
3. **Trapped on the paywall, no close button** — 6 reviews, 3 sources.
   "it don't show an X or anything to click it off." — https://justuseapp.com/en/app/6448704223/wingai-your-ai-wingman/reviews
4. **Surprise charges / cancelling** — 3 reviews, 2 sources.
   "Got wrongfully charged for 60 dollars when trying to cancel my subscription." — https://justuseapp.com/en/app/6449750416/rizzgpt/reviews
5. **Privacy of uploaded chats** (thin: 2, 1 source + Roast.dating advice to redact).

## 2. What is missing

1. **A typing option** (thin, 1): "Only problem is that there is no typing option." — https://justuseapp.com/en/app/6449750416/rizzgpt/reviews
2. **Replies that sound like me** (reviewer criticism, 2 sources): "Copy-pasted replies may not sound like you" — https://roast.dating/blog/rizz-gpt-review

## 3. What is unsolved

- People who want help *without* sounding like a pickup-line generator — the whole category
  sells "rizz", but its users get punished for sending it.
- People who don't want their private chats uploaded to a stranger's server.

## Fix plan

| # | fix | size | skill | evidence |
| --- | --- | --- | --- | --- |
| 1 | Voice match: user pastes 3-5 of their real texts once; every reply mimics length, casing, emoji use. Prompt bans pickup-line clichés outside the Lines tool and requires referencing a detail from the chat | M | build/backend | theme 1, 12 reviews |
| 2 | "Read the room": each result includes a one-line read; if the other person is pulling back or said no, it says so and offers a graceful reply instead of pushing | S | backend | theme 1 (blocked/reported) |
| 3 | Tweak buttons on every reply: shorter, funnier, bolder, softer; edit before copy | S | build | theme 1 |
| 4 | On-device OCR + auto-redaction of phone numbers, emails, links. The image never leaves the phone, only the text | M | build | theme 5 |
| 5 | Honest paywall: always a visible close button, 3 free replies every day, no weekly plan, one-tap Manage Subscription | S | build/launch | themes 2, 3, 4 |
| 6 | Paste-text mode on every tool | S | build | missing #1 |

## Angle

A. For people who've been left on read after sending an AI pickup line, Tact writes replies
   that sound like you — your length, your slang, about what they actually said.
   Evidence: theme 1, 12 reviews across 6 sources.
B. For people who got trapped by a $9.99/week wingman, Tact gives 3 free replies every day
   and a paywall you can close. Evidence: themes 2-4, 17 reviews across 4 sources.
C. For people who don't want their DMs on someone's server, Tact reads screenshots on your
   phone. Evidence: thin (2 + review advice).

**Recommended: A**, with B and C as supporting proof points in the listing.
