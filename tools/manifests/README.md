# compose_artwork.py manifests

Each `*.json` here rebuilds one flattened background PNG under `artwork/`
from the small editable source pieces under `artwork/sources/` (PNG, SVG
and solid-color pieces). Run with:

    python3 tools/compose_artwork.py tools/manifests/<name>.json

Requires ImageMagick (`magick`, or `convert` for ImageMagick 6), plus Chrome or
Chromium for `.svg` pieces. Chrome is looked up on PATH; set the `CHROME`
environment variable to point at a specific executable.

`artwork/wc_tl_bg.png` and `artwork/wc_lp_panel.png` have no manifest and are
edited directly. `artwork/sources/wc_lp_cat.png` (the cat) and
`artwork/sources/wc_lp_paws.svg` (its paws, in `wc_lp_panel.png` pixel
coordinates, drawn at +780+320) are the pieces used in `wc_lp_panel.png`.

- `cp_bg.json` -> `artwork/wc_cp_bg.png` (control panel fascia)
- `panel_bg.json` -> `artwork/wc_panel_bg.png` (glass panel background, including the
  reel window frame/shade/paylines - see below)

### Reel window and z-order

The reel strips (`rw_strip1..3`) are drawn *before* `panel_bg` in the view, and
`panel_bg` has a genuine transparent cutout (`type: "cutout"` pieces) punched
through its wallpaper exactly where each reel's symbols must show, so the
frame/shade/payline art baked on top of that cutout sits over the live reels
instead of hiding them. If you rearrange the view order, or add anything to
the "panel" group that must be visible on top of the reels, either keep this
draw order (reels -> panel_bg -> other overlays) or reintroduce a separate
overlay element drawn after the reel strips.

Edit a source piece under `artwork/sources/`, then re-run the matching
manifest to regenerate the composited background used by `wildcats_artwork.lay`.
