# Design system

The app runs on the Synk components and tokens (`lib/design_system`), restyled to the brand:

| Token | Light | Dark |
|---|---|---|
| background | white | near-black `#0C0B0D` |
| primary (buttons, your bubbles, selected chips) | ink `#0C0B0D` | cream `#EFDDB6` |
| muted / soft fills | soft cream `#F6EEDC` | `#262125` |
| brand text (`primaryText`, `brandText`) | deep magenta `#C2009B` (5.5:1) | `#FF5BDC` (6.6:1+) |

Fixed brand colours live in `SynkPalette`: `hotMagenta`, `flameOrange`, `electricViolet` (the wave
bands), `cream`, `nightInk`, `royalPurple` (profile "about" panel) and `plum`.

Typography (`SynkTypography`): Manrope for UI text, **Permanent Marker** for `h1`/`h2` and the new
`poster` / `posterSmall` variants, **Young Serif** for the `bio` / `bioSmall` variants (bios and
quotes). All three are bundled under `assets/fonts` with their licences.

Icons: the Hugeicons set plus four brand glyphs drawn on the same grid: `discover` (eye),
`chats` (two bubbles), `cards` (card stack with a heart), `gem`.

Brand art (`lib/shared/brand`):

- `WavyBackdrop`: ripple, stripes or warped-checker bands, seeded and deterministic.
- `InkPanel` / `WavyEdgeClipper`: black panel with a wavy top edge.
- `PosterTitle`: stacked, tilted uppercase lines of different sizes.
- `HeartSticker`, `CrownDoodle`, `Starburst`, `SwallowDoodle`, `SparkleDoodle`.
- `FramedPhoto`: photo in a thick cream frame with a name tag.

Where it shows: welcome (five swipeable poster slides + black sign-in panel), splash, swipe card
(cream frame, marker name, serif quote, ink square X / gem / heart buttons), matches grid (framed
tiles, heart stickers), chat (black / cream bubbles), profile detail (royal-purple about panel with a
crown), paywall and profile-tab upsell (wave posters), match overlay, icon-only bottom bar with a
magenta dot.
