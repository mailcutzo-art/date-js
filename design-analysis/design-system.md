# Design system

The dating app uses the Synk tokens unchanged: colours (`SynkColors` light/dark), Manrope type scale
(`SynkTextVariant`), spacing (`SynkSpace`), radii (`SynkRadius`), motion (`SynkMotion`) and theme
(`SynkThemeData`). The theme follows the system brightness.

Additions made on top, in app code only:

- `BrandColors.brandText`: the dark theme's `primary` (`#A3004C`) is for filled surfaces; as text or
  an icon on the near-black background it was too dim, so tab labels, selected borders, counters and
  rings use `SynkPalette.brandPinkText` in dark mode (found in screenshot review).
- Action colours for swipes reuse existing palette entries: pass `youtubeRed`, like `success`,
  super like `indigo`, verified tick `indigo`, Premium `amber`.
- Generated photo gradients in `PhotoArt` (eight original palettes) are the only new colour set.

The brand is a placeholder: change `SynkColors`/`SynkPalette` to restyle the whole app.
