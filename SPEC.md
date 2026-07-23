# StillBox — SPEC.md

> Single-source-of-truth for the design contract. Anything not documented here is **out of scope** for v1.

## 1. The North Star

**StillBox** is the first published app from Cerminara Consulting. Its job is twofold, in priority order:

1. **Showcase.** The app is a portfolio piece — when a prospect opens it, the design and craft of the experience IS the argument that Cerminara can build something good.
2. **Stand on its own.** Independently of (1), it must be a real, calm, useful breathwork app for anyone — parents, professionals, anyone who needs a minute.

Monetization (free + $2.99 one-time unlock for additional patterns and the custom-pattern creator) is a *real* revenue stream, but a *secondary* signal. The primary signal is "this team ships thoughtful software."

## 2. The Problem

People in moments of acute stress, mild anxiety, or simple tiredness reach for their phone. The current App Store options in the breathwork category are either over-engineered (Calm, Headspace — hundreds of features, accounts, subscriptions) or visibly low-craft (single-screen "breathe in, breathe out" with stock illustrations). There's a meaningful middle: a beautifully crafted, single-purpose tool that *just works* in the 30 seconds a person has.

## 3. The User

**Anyone.** The deliberate refusal to niche-down is the strategy. A parent's afternoon, a professional's pre-meeting minute, a teenager's late-night overwhelm — same product, same single screen. This is constraint, not feature-flagship.

**Three design implications:**

- The app must feel like a *break* from the rest of the phone, not another feed. → dark, calm, no chrome.
- The first-launch experience must be value-in-five-seconds, not "create an account." → no auth, no onboarding slides.
- A single screen, one gesture, no learning curve. → tap to start, tap to stop.

## 4. The Outcome Promise

**After one breath cycle (16 seconds for 4-4-4-4), the user feels calmer.** After three cycles (~48 seconds), they can return to what they were doing. The Peak-End Rule applies: what they *remember* is the last breath cycle. Therefore the **end-of-session experience** matters as much as the middle — it's the moment we earn the next visit.

## 5. Scope

### In scope for v1

| Element | Detail |
|---|---|
| App type | iOS native, SwiftUI, iOS 17+ |
| Screens | 1 main screen + 1 modal settings sheet + sub-screens inside settings (pattern creator, about) |
| Breathing patterns | Box (4-4-4-4), 4-7-8, 3-4-5-3, custom |
| Cue modalities | Visual (box scale + glow), haptic (on phase change), audio (subtle chime), always-on phase text |
| Sessions | Fixed round counts (4 / 8 / 12) and continuous |
| Reduce Motion | Honored (auto-detected) with manual override |
| Dynamic Type | Honored; layout reflows |
| In-app purchase | One-time unlock ($2.99) for additional patterns + custom pattern creator |
| Tip jar | One-time tip, three suggested tiers ($1, $3, $5) |
| Privacy | Zero data collected. No analytics SDK, no accounts, no tracking. |
| App Store | iPhone, iPad (universal layout), iOS 17 minimum |

### Out of scope for v1 (deferred to v2+)

- Apple Watch app
- Live Activity / home-screen widget
- HealthKit integration
- Audio-guided voice sessions
- Multi-language localization (English only)
- iCloud sync
- Apple TV / Mac Catalyst versions
- Subscription model
- Marketing/landing pages

> **HCD note:** Every "out of scope" item is *deliberately deferred*, not forgotten. The design system that ships in v1 is the seed for v2 — pomodoro (a separate app, same visual DNA) and a watchOS companion for StillBox are the planned expansions.

## 6. Design Tokens (the system)

### Color — one mode (dark), the principle is *low-arousal*

| Token | Value | Role |
|---|---|---|
| `brand/background` | `#0E1116` | The room — near-black, slight blue undertone, never pure black |
| `brand/box-stroke` | `#E6E1D7` | The box edge — warm off-white, never `#FFFFFF` |
| `brand/accent` | `#7BA7BC` | The breath glow — desaturated, morning-light blue, *not* the "Calm app blue" |
| `brand/text-primary` | `#F2EFE9` | Headings, breath labels |
| `brand/text-secondary` | `#8C847A` | Phase words, settings labels — deliberately low contrast |
| `brand/destructive` | `#C57B6A` | Used once — the "reset custom pattern" action |

> **HCD note:** The accent is *morning sky through a curtain*, not a brand color you'd pitch a logo in. The aesthetic-integrity principle (Apple HIG) says brand colors shouldn't fight the experience. The color earns its place inside the breath cycle, not on the home screen.

### Typography — one family, two roles

| Role | Family | Weight | Size |
|---|---|---|---|
| Display / phase word | SF Pro Rounded | Heavy (700) | 48pt with Dynamic Type scaling |
| Body / settings | SF Pro | Regular (400) | 17pt with Dynamic Type scaling |

> **HCD note:** Single-family typography is an Aesthetic-Usability Effect trade-off — we forfeit visual variety for tightness of system. SF Pro Rounded is chosen for the *quiet joy* of its curves; they're not playful, they're kind.

### Motion vocabulary — three primitives, repeated exactly

| Primitive | Easing | Duration |
|---|---|---|
| Breath scale | `cubic-bezier(0.4, 0.0, 0.2, 1)` | matches phase length |
| Phase hold | static | 100ms cushion before next breath |
| Completion pulse | ease-out | 800ms single pulse, then fade to dark |

> **HCD note:** The cubic-bezier matches Apple's `standard` timing curve. Repeating it exactly across the app is the *Consistency* heuristic (Nielsen #4) — the breath transition, settings sheet, and tip-jar fade all use it. Users develop a single, accurate timing model.

### Spacing — 8pt grid

- Safe-area inset: always honored
- Tap targets: minimum 44×44pt (Apple HIG)
- Settings rows: 56pt minimum height
- Inner padding around the box: 24pt from screen edge to box edge

## 7. Screen Architecture

### Main screen — "The Room"

```
┌─────────────────────────────────────┐
│                                     │
│              breathe                │  ← word, only when idle
│                                     │
│                                     │
│        ┌───────────────┐            │
│        │               │            │
│        │               │            │
│        │               │            │  ← bordered box, scales with breath
│        │               │            │
│        │               │            │
│        └───────────────┘            │
│                                     │
│                                     │
│    Patterns & settings   About      │  ← two links, low contrast
└─────────────────────────────────────┘
```

When breathing, the box is the only thing happening on screen. The phase word (in/hold/out/hold) appears inside the box in low-contrast text.

### Settings sheet (modal, drag-to-dismiss)

- Pattern picker (4-4-4-4 / 4-7-8 / 3-4-5-3 / Custom…)
- Round count (4 / 8 / 12 / continuous)
- Sound toggle
- Haptics toggle
- Reduce Motion toggle (system default + override)
- Tip jar
- About (version, build, attribution, privacy link)

### Pattern creator (sub-screen inside settings)

For each phase (inhale, hold-in, exhale, hold-out):
- Slider 1s–12s, snap to whole seconds
- Plain-English summary that updates live: "Inhale 4, hold 4, exhale 4, hold 4 — a balanced reset."
- Save / cancel

> **HCD note:** The pattern creator lives *one tap inside settings*, never one tap from the main screen. Hick's Law still applies: every additional tap costs the user, but the *use case* — "I want a custom pattern" — is rare enough that one extra tap pays for itself in main-screen calm.

## 8. Interaction Details

| Action | Affordance |
|---|---|
| Start breathing | Tap anywhere on "the room" |
| Stop breathing | Tap the room again |
| Open settings | Tap "Patterns & settings" link |
| Dismiss settings | Drag down or swipe from left edge (system back gesture) |
| Phase audio | Soft chime on each phase change if enabled |
| Phase haptic | Single light tap on each phase change if enabled |
| Phase text | Always visible (in/hold/out/hold) inside the box |
| Background → backgrounding | Pause the session, persist nothing (no data at risk) |

> **HCD note:** "Tap anywhere" is a *deliberate* disregard of the standard-button pattern. Here, the entire screen IS the affordance — the box is the visual focal point, and the full-screen tap target honors *Fitts's Law* while honoring Apple's *direct manipulation* principle. The room is the button.

## 9. Reduced Motion / Reduced Transparency

When the system Reduce Motion setting is on, the box does *not* scale — it stays static and a small text "in / hold / out / hold" updates at phase boundaries. When the user overrides the system setting via the Settings sheet, that override is preserved across launches (UserDefaults).

## 10. Monetization

- **Free:** 4-4-4-4 pattern, 4/8/12 round counts, all sound/haptics/Reduce Motion settings, no tip jar visible
- **One-time unlock ($2.99) — "StillBox Patterns":** 4-7-8, 3-4-5-3, custom pattern creator, continuous round mode
- **Tip jar (optional, $1 / $3 / $5 tier buttons):** unlocked by the same IAP; never required, never nagged

### StoreKit 2 specifics

- Product ID: `com.cerminara.stillbox.patterns` (configured in App Store Connect)
- Tip jar products: `com.cerminara.stillbox.tip.1`, `tip.3`, `tip.5`
- All IAPs are non-consumable so they persist across reinstall via the Apple ID
- Restore Purchases button in Settings → About

> **HCD note:** IAPs as one-time unlocks, not subscriptions, honor both the *Aesthetic Integrity* principle (no recurring paywalls in a calm app) and the *user control* principle (Nielsen #3 — users can stop spending without losing features). Apple's cut is 30% on the first $1M of revenue per year per developer, dropping to 15% for small-business-program participants — both well within Cerminara's expected first-year range.

## 11. Privacy

- The app does not collect any data. No analytics, no telemetry, no remote logging.
- App Store privacy nutrition label: **"Data Not Collected"** in every category.
- Privacy policy URL: a public markdown document at a stable URL (spec'd separately; not blocking v1 development).
- No HealthKit integration in v1.

## 12. Accessibility (WCAG 2.2 AA floor, Apple HIG principles)

- [x] **Perceivable:** VoiceOver labels on the box describe current phase ("inhaling, hold for 4 seconds"). Subtle glow does not carry meaning — text always does. Color is a single dark theme with AA contrast on all text (≥4.5:1).
- [x] **Operable:** Full-screen tap target = no motor-precision requirement. Reduce Motion honored. Voice Control: each control has a unique spoken name.
- [x] **Understandable:** Labels in plain English ("Patterns & settings", not "Preferences"). Phase words always spelled out, never abbreviated.
- [x] **Robust:** Built with the SwiftUI standard controls where possible. Tested in Dynamic Type at the largest accessibility size.

> **HCD note:** Accessibility is structural, not bolt-on. The screen was designed for full-screen tapping *because* Fitts's Law and motor accessibility converge on the same answer. The phase word is always visible *because* deaf users and audio-off users have the same need. Constraints that look like design rules often turn out to be *multiple* design rules satisfied at once.

## 13. The "Pride Test"

> "Would we put our name on this?"

Before any release, before any screenshot, before any App Store submission, the build is held against these specific criteria:

1. **The 5-second test.** A first-time visitor who has never opened the app *gets the value* within 5 seconds, with no explanation.
2. **The Peak-End test.** The very last thing they see before the app closes (or before they leave the screen) is the most calm they felt during the session.
3. **The creditable-test.** Every visible choice — color, type, motion, haptics, sound — is *specific*, never stock. The user could not mistake this for a different product.
4. **The empty-handed-test.** If a prospect opens this at the end of a sales call, it does the talking. The prospect closes the loop. We win the deal.

If any of the four fail, the build doesn't ship. We iterate.

## 14. Definition of Done (v1.0.0)

- [ ] All UI states designed and implemented: idle, breathing (per phase), completing, settings (open/dismissed), pattern creator, IAP-locked patterns, tip jar.
- [ ] All cue modalities work: visual + audio + haptic + on-screen text.
- [ ] Reduce Motion respected.
- [ ] Dynamic Type scales without clipping, overlap, or hidden actions.
- [ ] VoiceOver reads current phase.
- [ ] WCAG AA contrast on all text (verified with VoiceOver).
- [ ] Privacy manifest (`PrivacyInfo.xcprivacy`) included.
- [ ] App Store metadata complete (subtitle, description, keywords, screenshots).
- [ ] TestFlight beta at least one external user (Cerminara internal).
- [ ] Final HCD review pass (30-second checklist).
- [ ] Build on physical iPhone shows the calm from cold start.

## 15. Open questions for v2+ (not blocking v1)

- Live Activity / Dynamic Island for an in-progress breath session?
- Apple Watch app with wrist-haptic-only breathing?
- Second app in the family — `StillFocus` (Pomodoro)? Or a single StillBox umbrella?
- Localization (Spanish, German, Japanese first)?

---

*Last updated: 2026-07-22.*
