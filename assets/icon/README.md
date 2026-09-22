# Block Puzzle launcher icon

Original artwork: `block_puzzle.png`, generated with the built-in imagegen tool.
The source is kept here; Android density variants are generated with:

```bash
source scripts/env.sh
dart run flutter_launcher_icons
```

`flutter_launcher_icons.yaml` configures legacy icons and adaptive icons.
The adaptive foreground uses 16% inset to protect the jewel cluster when the
launcher applies a circular or rounded mask. No Flutter logo remains.

## Final generation prompt

Use case: logo-brand. Create a finished square Android launcher icon for an original offline Block Puzzle game. A compact, distinctive interlocking cluster of exactly nine beveled square jewel tiles, arranged as a 3 by 3 grid with tiny even gaps, grouped by color into recognizable puzzle shapes: violet L on left, turquoise pair upper right, warm amber corner lower right. Bold clean readable silhouette, polished subtle facets, premium casual puzzle aesthetic matching dark navy #101021, violet #9A7BFF, turquoise #48D6D2 and amber #FFBA62. Full bleed flat dark navy background reaching all four edges, no outer icon frame and no rounded outer corners. Place the whole jewel cluster inside the central 58 percent of the square so Android circular adaptive masks never cut the tiles. Straight-on orthographic view, no perspective. Very crisp high contrast, modest highlights, elegant and simple at tiny size. No letters, no text, no numbers, no watermark, no Flutter logo, no extra ornaments. Output one 1024x1024 image. Save the generated image as a local file and provide the path so it can be installed in the project.
