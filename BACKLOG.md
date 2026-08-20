# StillBox — Backlog (v1.1+)

Per the ship-spec v2 scope-freeze rule: anything deferred goes here, not the spec. No new v1 work is justified from backlog items — they exist so we don't forget them, not so we work on them now.

## v1.1 — Soft launch follow-up

- [ ] **Tip jar.** Restore `TipJarView` + the three suggested tiers ($1 / $3 / $5). Was deferred from v1 ship-spec to keep the v1 surface minimal and Apple review surface zero. StoreKit integration returns; product IDs `com.cerminara.stillbox.tip.{1,3,5}`.
- [ ] **"StillBox Patterns" one-time unlock.** Restore the $2.99 IAP. Product ID `com.cerminara.stillbox.patterns`. Re-gate the custom-pattern creator + the additional breathing patterns (4-7-8, 3-4-5-3) behind it. (v1 ships these free for everyone; v1.1 may decide whether to gate again.)
- [ ] **Restore Purchases.** When IAP returns, the button needs to come back in `AboutView`.

## v1.2 — Platform expansion

- [ ] **iPad layout.** Was explicitly cut to ship v1 as iPhone-only. Re-add universal layout when there's bandwidth.
- [ ] **Apple Watch app** with wrist-haptic-only breathing. From §15 (original spec).
- [ ] **Live Activity / Dynamic Island** for an in-progress breath session. From §15.
- [ ] **Mac Catalyst version** for macOS desktop.

## v2 — Family expansion

- [ ] **`StillFocus` (Pomodoro)** as a second app in the family, sharing the StillBox visual DNA. From §15.
- [ ] **HealthKit integration.** Was explicitly deferred in v1 because no data is collected; needs a re-think about what (if anything) to write back to Health.
- [ ] **Audio-guided voice sessions** for users who want a coach's voice over the breath cycle.
- [ ] **Localization.** Spanish, German, Japanese first.

## Non-shipping items (meta)

- [ ] **Hosted privacy policy URL.** SPEC §11 says "a public markdown document at a stable URL (spec'd separately; not blocking v1 development)." Need to pick a host (Cloudflare Pages, same setup as `cerminaraconsulting.com`) and write the policy text. App Store submission needs this URL — **must ship before the binary uploads**, but doesn't gate v1 development. **Owner: John.** The privacy policy content is a single page: "StillBox does not collect any data. No analytics, no telemetry, no remote logging. Network requests, if any, are TLS-only to Apple Push Notification service endpoints or App Store receipt validation; no third-party endpoints." Three paragraphs. The page doesn't need to be pretty.

---

*Created: 2026-08-19, ship-spec v2 amendment.*