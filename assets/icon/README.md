# Game Day App launcher icon

Source artwork: `game_day.png`, generated with the built-in image_gen tool.
A generic game controller represents the collection of games, using the app's
violet, turquoise and amber palette on a dark navy background.

Generate the Android density variants and adaptive icon with:

```bash
source scripts/env.sh
dart run flutter_launcher_icons
```

The adaptive foreground uses a 16% inset to keep the controller inside launcher
masks. `block_puzzle.png` is the previous artwork, retained for reference only.

## Final generation prompt

Use case: logo-brand. Asset type: finished Android launcher icon for Game Day App, an offline collection of different casual games. Create one polished square 1024x1024 icon. Subject: a bold, friendly generic game controller symbol with a violet body, a clearly readable turquoise directional cross on the left and two warm amber circular buttons on the right. Premium casual game aesthetic with restrained beveled jewel-like highlights matching the existing app, strong simple silhouette, straight-on view. Background: full-bleed solid dark navy #101021 reaching all four edges. Palette: violet #9A7BFF, turquoise #48D6D2, amber #FFBA62. Keep the entire controller within the central 60 percent of the square, centered optically, with generous clean navy space around it for Android adaptive masks. No text, no letters, no watermark, no surrounding rounded-square frame, no puzzle tiles, no tiny decorative objects, no brand logos. This must be a production icon asset, not a phone mockup or presentation sheet. Save the output locally and provide the file path.
