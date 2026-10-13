# QA report

Run on Flutter 3.47.6 (Linux container, no emulator or device available).

## Results

- `flutter analyze`: no issues.
- `flutter test`: **682 passed** (583 existing design-system tests + 99 new).

| Suite | Tests | Covers |
|---|---|---|
| `test/app/` | 6 | Redirect rules per session stage, chat time formatting |
| `test/shared/swipe_deck_test.dart` | 10 | Like / pass / super like by drag, fling, controller; spring-back; stamps; photo taps; accessibility actions |
| `test/shared/components_test.dart` | 14 | OTP, bubbles, ticks, voice note, nav bar, photos grid, chips, match overlay choices |
| `test/features/auth_flow_test.dart` | 4 | Splash, phone + wrong/right code, Google shortcut, resend countdown |
| `test/features/setup_flow_test.dart` | 3 | Age gate, all seven steps to Discover, verification |
| `test/features/main_flow_test.dart` | 18 | Swipe, match overlay and jump to chat, super-like limit, filters, Premium locks and unlock, chats, unread, send + reply, block, report, edit profile, sign out, privacy |
| `test/features/screens_golden_test.dart` | 20 | Light + dark screenshots of 10 screens (420 x 900) |
| `test/features/responsive_test.dart` | 24 | Every main screen, sign-in and all setup steps at 320x568, 360x740, 412x915 and 800x1280, at text scale 1.0 and 1.4, with no overflow or build error |

## Defects found by QA and fixed

1. **Photo taps did nothing on the swipe card.** Gradient overlays sat above the tap zones and
   swallowed taps (caught by a test, would have hit real users).
2. **OTP boxes overflowed on a 320 dp phone** (276 + padding > 320). Boxes now share the width.
3. **Welcome cards were pinned to the top edge**, cropped (screenshot review).
4. **Stacked cards overlapped the action buttons** on Discover (screenshot review).
5. **Chat message field rendered four lines tall** when empty.
6. **Floating like/pass bar sat on top of profile text** with no backing.
7. **Dark mode: selected tab and accents were too dim** (low contrast on near-black).
8. **Looping animations ignored "remove animations"** (Premium glow, typing dots, recording dot).
9. **Photo-grid buttons merged into one screen-reader node**; each now has its own.
10. **Demo data matched people already in a chat**; seeded matches no longer appear in the deck.
11. **Flaky screenshots**: seeded chat times followed the real clock; a `clockProvider` fixes them.
12. Premium hero shortened so the three plans fit above the button on a 900 dp screen.

## Not done / limits

- **No run on an emulator or physical device.** Everything was verified with widget tests and
  golden screenshots of the app's own screens. Real gestures, haptics, keyboard behaviour on
  hardware, and performance are untested.
- **No comparison against any reference app.** None was used for visuals (see
  `implementation-status.md`).
- Goldens are taken at 420 x 900 only; other sizes are checked for overflow, not pixel-compared.
- Keyboard handling is covered for sign-in and chat input only through flows, not per-screen.
- Accessibility: labels, roles, custom swipe actions and reduced motion were added and tested at
  a basic level; no TalkBack/VoiceOver pass and no contrast audit beyond the dark-accent fix.
- iOS and Android native projects are the default `flutter create` output; no builds were run.
- Deleting an account, push, deep links, real media and billing are stubs (see status file).
