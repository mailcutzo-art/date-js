# Components

## Reused from the Synk design system (`lib/design_system`, untouched)

`SynkButton`, `SynkText`, `SynkTextField`, `SynkBirthdayField`, `SynkChip`, `SynkBadge`, `SynkCard`,
`PastelCard`, `SynkSwitch`, `SynkSegmentedTabs`, `SynkProgressBar`, `SynkSeparator`, `SynkSpinner`,
`Skeleton`, `InlineState` / `EmptyState`, `SubpageHeader`, `SectionLabel`, `CircleIconButton`,
`SynkPressable`, `showSynkBottomSheet` and sheet parts, `showConfirmSheet`, `ToastHost` /
`ToastController`, `Confetti`, `DotLogo`, `DotGridBackground`, `SynkIcon`, `SynkHapticsScope`,
tokens (colours, radius, spacing, motion, typography, theme).

## Added for the dating app (`lib/shared/widgets`)

| Widget | Purpose |
|---|---|
| `PhotoArt` | Generated placeholder artwork from a seed (stands in for photos) |
| `ProfileCard` | Full-bleed card: photo stack, scrims, name/age/distance, verified tick, drag stamps |
| `SwipeDeck` + `SwipeDeckController` | Draggable card stack with physics; programmatic swipes; accessibility actions |
| `SwipeActionBar` | Pass / super like / like round buttons |
| `PhotoCarousel`, `PhotoProgressBars` | Profile photo pager with segmented indicator |
| `InterestChips` | Selectable or read-only interest list, shared interests highlighted |
| `PhotosGrid` | 3 x 2 photo slots with add / remove / "Main" |
| `MatchOverlay` + `showMatchOverlay` | "It's a match" celebration |
| `MessageBubble`, `TypingIndicator` | Text, image and voice-note bubbles; delivery ticks; typing dots |
| `OtpField` | Six-box code input over one hidden text field (autofill, paste) |
| `StepProgressHeader` | Back button + progress bar for the setup |
| `PreferenceSlider`, `PreferenceRangeSlider` | Themed slider and range slider with label |
| `MainNavBar` | Bottom navigation with sliding pill and unread badge |
| `SettingsSection`, `SettingsTile` | Grouped settings rows (chevron, switch, destructive) |
| `ProfileAvatar`, `VerifiedBadge` | Round photo avatar (optional ring); blue verified tick |
| `BrandColors.brandText` | Text-safe brand colour (the dark theme's `primary` is too dark for text) |

Tests: `test/shared/components_test.dart`, `test/shared/swipe_deck_test.dart`.
