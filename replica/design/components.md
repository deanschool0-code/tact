# Tact components (SwiftUI) — built in ios/Tact/Design/Components.swift

All colours/radii come from `Theme` (tokens.json). Icons: SF Symbols (Apple's system set, licensed for use in iOS apps). No assets from any other app.

```
PrimaryButton
  variants  primary (accent fill), secondary (surface-2 fill), ghost (text only)
  size      52pt tall, radius md, headline font
  states    default, pressed (scale .97), disabled (40% opacity), loading (ProgressView, label kept for VoiceOver)
  a11y      Button, 44pt+ hit area
  used on   S01-S16

ToolCard
  icon in accent circle, title (headline), subtitle (footnote, muted), chevron
  states    default, pressed, locked (lock badge when out of free uses)
  used on   S04

Chip
  pill, surface-2 when off, accent fill + on-accent text when on; border-input outline when off
  states    off, on, disabled; haptic selection on tap
  a11y      .isSelected trait
  used on   S02, S06, S09, S12

MessageBubble
  me: bubble-me on right; them: bubble-them on left; radius lg; tap to flip side; swipe to delete
  used on   S05, S12

ReplyCard
  surface, radius lg, body text, footnote "why" in muted, actions: copy, favourite, tweak menu (shorter / funnier / bolder / softer)
  states    default, copied (check + "Copied" 1.5s), loading skeleton (3 shimmering lines)
  used on   S07, S08, S09, S13

CreditsPill   "3 free left" / "Pro" — caption font, surface-2
Meter         circular gauge 0-100, accent stroke, number in display font; animates in
PlanCard      selectable, accent border when selected, "Best value" badge
EmptyState    SF Symbol, title, one line, optional button
ErrorBanner   danger text on surface, retry button
```
