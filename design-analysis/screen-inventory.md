# Screen inventory

Every screen below exists in code and has a light and dark golden screenshot unless marked.
Goldens live in `test/features/goldens/`.

| Screen | Route | File | Reached from | Golden |
|---|---|---|---|---|
| Splash | `/` | `features/auth/splash_screen.dart` | App start | - |
| Welcome | `/welcome` | `features/auth/welcome_screen.dart` | Splash | `welcome_*` |
| Phone sign-in | `/sign-in` | `features/auth/sign_in_screen.dart` | Welcome | `sign_in_*` |
| OTP | `/otp` | `features/auth/otp_screen.dart` | Phone sign-in | - |
| Setup (7 steps) | `/setup` | `features/onboarding/setup_screen.dart` + `steps/` | OTP or Google | `setup_gender_*` (step 2) |
| Discover | `/discover` | `features/discover/discover_screen.dart` | Tab 1 | `discover_*` |
| Filters (sheet) | - | `features/discover/filters_sheet.dart` | Discover | - |
| Profile detail | `/profile/:id` | `features/discover/profile_detail_screen.dart` | Card info button, matches, chat header | `profile_detail_*` |
| Match overlay | - | `shared/widgets/match_overlay.dart` | A mutual like | - |
| Matches / Likes you | `/matches` | `features/matches/matches_screen.dart` | Tab 2 | `matches_*` |
| Chats | `/chats` | `features/chat/chats_screen.dart` | Tab 3 | `chats_*` |
| Chat | `/chats/:id` | `features/chat/chat_screen.dart` | Chats, matches, match overlay | `chat_*` |
| My profile | `/me` | `features/profile/me_screen.dart` | Tab 4 | `me_*` |
| Edit profile | `/me/edit` | `features/profile/edit_profile_screen.dart` | Profile | - |
| Settings | `/me/settings` | `features/profile/settings_screen.dart` | Profile | - |
| Privacy and safety | `/me/privacy` | `features/profile/privacy_screen.dart` | Profile, settings | - |
| Notifications | `/me/notifications` | `features/profile/notifications_screen.dart` | Settings | - |
| Premium | `/premium` | `features/premium/premium_screen.dart` | Profile, locks, prompts | `premium_*` |
| Report / block / unmatch (sheets) | - | `features/chat/safety_actions.dart` | Chat, profile detail | - |

Alternative states covered by tests: loading skeletons (matches, chats, discover), empty states
(no matches, no chats, deck exhausted), error with retry (discover, likes), locked content (Likes
you, verified-only, incognito, super-like limit), under-18 age gate, wrong OTP.
