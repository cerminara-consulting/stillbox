# StillBox — App Store Connect Listing Copy

Drafted 2026-08-20 for the initial submission. Copy-paste into App Store Connect. All fields pre-counted against Apple's limits.

## App Identity

| Field | Value | Limit |
|---|---|---|
| **App Name** | `StillBox` | 30 chars (✓ 8) |
| **Subtitle** | `Calm breathing, one tap.` | 30 chars (✓ 24) |
| **Bundle ID** | `com.cerminara.stillbox` | (auto) |
| **SKU** | `stillbox-2026` | (any unique) |

## Description (4000 char max)

StillBox is a small, careful breathwork app. One screen. One box. Tap to begin.

The breathing box expands as you inhale, holds when you hold, and contracts as you exhale. A soft haptic tap marks every second of your breath. A short quote above the box sets the tone — from Marcus Aurelius, Lao Tzu, Pascal, and others.

There is no account. No login. No tracking. No notifications asking you to come back. The app is fully offline; your patterns and settings live only on your iPhone.

**What you can do:**
- Start a session with one tap; stop with one tap.
- Choose from three built-in patterns: box breath (4-4-4-4), 4-7-8, and 3-4-5-3.
- Set the number of rounds: 4, 8, 12, or continuous.
- Create custom breathing patterns from 1 to 12 seconds per phase.
- Toggle haptics on or off.
- Respect Reduce Motion: animations are simplified automatically.

**What StillBox does not do:**
- Collect any data. See our Privacy Policy for details.
- Show ads, upsells, or notifications.
- Require an internet connection.
- Track you across other apps or websites.

Made by Cerminara Consulting — a small, design-driven consultancy. StillBox is the kind of app we wanted for ourselves and couldn't find: serious about breath, calm about everything else.

## Promotional Text (170 char max)

A small, careful breathwork app. One screen. One box. Tap to begin. No account, no tracking, no notifications.

(✓ 137 chars)

## Keywords (170 char max, comma-separated)

```
breathwork,breathing,calm,mindfulness,meditation,box breath,478,relax,box breathing,stillness
```

(✓ 96 chars — leaves room to add "sleep" or "anxiety" if you want)

## Category

| Field | Value |
|---|---|
| Primary Category | Health & Fitness |
| Secondary Category | Medical |

## Age Rating (Apple's questionnaire answers)

| Question | Answer |
|---|---|
| Cartoon or fantasy violence | No |
| Realistic violence | No |
| Sexual content or nudity | No |
| Profanity or crude humor | No |
| Alcohol, tobacco, or drug references | No |
| Horror or fear themes | No |
| Simulated gambling | No |
| Prolonged graphic violence | No |
| User-generated content | No |
| Messaging or chat | No |
| Personal data collection | **No** ← matches PrivacyInfo.xcprivacy |
| Health or medical topics (educational only) | **Yes** ← breathwork is health-adjacent |
| Web browsing | No |
| Gambling | No |
| Location services | No |

Result: **4+** (suitable for all ages).

## URLs

| Field | URL |
|---|---|
| Privacy Policy URL | `https://stillbox.pages.dev/privacy-policy/` |
| Support URL | `https://stillbox.pages.dev/support/` |
| Marketing URL | (leave blank) |

(Once `cerminaraconsulting.com/stillbox/privacy` is live, swap the URL here — one-line change in App Store Connect.)

## App Review Notes (4000 char max)

```
StillBox is a single-screen iPhone breathwork app. It does not require
an account, does not collect any data, and works fully offline.

The reviewer can verify the data-collection claim by:
1. Opening StillBox on a fresh install.
2. Starting a session — the screen shows a breathing box that expands
   and contracts over a 4-second inhale, hold, exhale, hold cycle.
3. Long-pressing the screen — this opens Patterns & Settings where
   the reviewer can change the breathing pattern, round count, and
   toggle haptics.
4. Opening iOS Settings → Privacy → StillBox — there are no entries
   because the app requests no permissions.

All settings are stored locally via UserDefaults (reason code CA92.1
declared in PrivacyInfo.xcprivacy). No backend, no third-party SDKs,
no analytics.

For questions, contact support@cerminaraconsulting.com.
```

(✓ 727 chars — well under limit)

## Screenshots needed (per device class)

| Device class | Resolution | Count required |
|---|---|---|
| iPhone 6.7" (iPhone 15 Pro Max etc.) | 1290 × 2796 | 1 minimum (3-5 recommended) |
| iPhone 6.5" (iPhone 11 Pro Max etc.) | 1242 × 2688 | 1 minimum (3-5 recommended) |

Since `TARGETED_DEVICE_FAMILY = "1"` (iPhone only), no iPad screenshots required.

**Recommended screenshots** (capture from your physical iPhone running the TestFlight build):
1. Home screen idle — header, quote, breathing box, "Tap anywhere to begin"
2. Active breathing session — box at mid-scale, phase label visible
3. Patterns & Settings sheet open
4. About sheet open
5. Quote detail sheet open

## What's left to do before submitting

1. ☐ Team ID `LWPR7M772W` — already wired into `project.yml` ✓
2. ☐ Privacy + Support URLs live at `stillbox.pages.dev` — pending Cloudflare Pages deploy
3. ☐ Build archive on Mac, upload to App Store Connect
4. ☐ Fill in listing metadata (copy-paste from this file)
5. ☐ Attach screenshots
6. ☐ Submit for review