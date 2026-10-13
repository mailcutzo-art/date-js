# Implementation status

Branch `claude/zealous-maxwell-kmmxfk`. Flutter 3.47.6, Riverpod 3 + go_router, Synk design system.

## Provenance (read this first)

- **All screens, components, copy and animations are original.** They are built on the Synk design
  system that was copied from `synk-app` (`lib/design_system`).
- A third-party Android APK (`com.getpure.pure_3.34.557`) was inspected **statically only** (manifest,
  permissions, bundled SDK list). It informed one thing: the *feature list* of a dating app (phone
  and Google sign-in, selfie verification, swipe discovery, matches, chat with photos and voice,
  location, paywall, push). Nothing from it was copied: no Lottie files, images, fonts, strings,
  layouts or branding. Its Play Store screenshots were deliberately not used as a visual spec.
- The APK was removed from the product tree (`git rm`, commit `623cfd8`); `*.apk` and `*.aab` are
  git-ignored. It still exists in git history (`d57f3b7`). Removing it from history would need a
  force-push and has not been done.
- If you own the app this was meant to match, port from its **source or design files** instead; that
  is the accurate route and nothing here blocks it.
- **Brand restyle (branch `claude/ecstatic-meitner-6hch80`).** The owner supplied five promo
  screenshots as the visual spec (magenta / orange / violet waves, black ink shapes, cream chips,
  bubbles and photo frames, hand-lettered headings). They were recreated in code by eye: colours,
  layouts and the doodles (crown, hearts, starburst, swallow, sparkle) are new vector drawings, the
  photos are generated placeholders (`PhotoArt`), and the character illustrations (leopard, cat mask)
  were not reproduced. The lettering font is Permanent Marker (Apache 2.0) and the bio serif is Young
  Serif (OFL), the closest open fonts; swap in the original font files if the design uses its own.

## Done

| Area | State |
|---|---|
| Sign-in: splash, welcome, phone, OTP (resend timer, wrong-code shake), Google shortcut | Working on demo data |
| Setup: name + age gate, gender/preferences, photos, bio + interests, location, selfie verification, done | Working on demo data |
| Discover: swipe deck (physics, stamps, haptics), action bar, filters sheet, profile detail, empty/error/loading | Working |
| Match: overlay animation, "send a message" jump into chat | Working |
| Matches tab (matches grid, Likes you with Premium lock) | Working |
| Chats tab + chat (text, photo, voice note UI, typing, read ticks, openers, unread counts) | Working |
| Safety: report (reasons), block, unmatch | Working |
| Profile tab, edit profile, settings, privacy, notifications | Working |
| Premium paywall (plans, benefits, locks across the app) | UI + demo unlock only |
| Dark and light themes, reduced-motion support, screen-reader labels | Working |

## Awaiting a backend or native integration (demo stand-ins are marked in code)

| Need | Stand-in today | Where to plug in |
|---|---|---|
| Real OTP / auth | `MockAuthRepository`, code `123456` | `authRepositoryProvider` |
| People, swipes, likes | `MockDiscoveryRepository` over `kDemoProfiles` | `discoveryRepositoryProvider` |
| Realtime chat, reports, blocks | `MockChatRepository` (canned replies) | `chatRepositoryProvider` |
| Photo picking | "Add photo" adds a generated sample (`photo_source_sheet.dart`) | `image_picker` |
| Real photos | `PhotoArt` generated from a seed | swap `ProfilePhoto.seed` for a URL |
| GPS location | "Use my location" fills a sample city (`location_step.dart`) | `geolocator` + geocoding |
| Selfie verification | Animation only, then marks verified (`verify_step.dart`) | verification SDK |
| Voice recording | Timer UI, sends a note of that length | `record` |
| Billing | "Unlock for demo" (`premium_screen.dart`) | `in_app_purchase` |
| Push, deep links | not started | `firebase_messaging`, `app_links` |
| Account deletion | signs out (`settings_screen.dart`) | delete-account API |

All demo data is in `lib/data/mock/`. `kAppName` (`lib/core/config/app_info.dart`) is a working name.
