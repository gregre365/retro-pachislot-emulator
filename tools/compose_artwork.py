#!/usr/bin/env python3
# license:CC0
# copyright-holders:gregre365
"""Compose several small artwork pieces (PNG or SVG) into one flattened PNG.

Generic tool: not tied to any particular element group (cp_*, panel_bg, etc).
Positions/sizes are given in the same logical units as the .lay <bounds>,
and are scaled up to the canvas's native (supersampled) resolution before
compositing, then the result is downscaled once at the end.

.svg pieces are rasterized on the fly with headless Chrome/Chromium, directly
at the exact target pixel size (ImageMagick's built-in SVG renderer draws
many of these pieces incorrectly).

Usage:
    tools/compose_artwork.py manifest.json

Requirements:
    - ImageMagick (`magick`, or `convert` for ImageMagick 6)
    - Chrome or Chromium, only for .svg pieces.  Found on PATH as
      google-chrome, chromium, chromium-browser or chrome; set the CHROME
      environment variable to use a specific executable.

All visible content must come from an image piece (PNG/SVG) or a plain "rect"/
"cutout" fill - there is no "text" piece type, on purpose: every piece here
must be something a user can see and edit directly in the source PNG/SVG
under artwork/sources/, never a label drawn invisibly only by this script.
If a group needs a number or word, bake it into that piece's own image
(see e.g. artwork/sources/wc_tp_paytable.png) instead of adding one here.

Manifest JSON schema:
{
  "asset_dir": "artwork",              // optional, default: manifest's own dir
  "scale": 3,                          // logical-unit -> canvas-pixel factor
  "canvas": {
      "file": "wc_cp_face.png"         // start from an existing image (png or svg), OR:
      // "width": 1000, "height": 202, "color": "none"   // blank canvas
  },
  "pieces": [
      {"file": "wc_cp_knob.png", "x": 57.6, "y": 19.0, "w": 120, "h": 120},
      {"file": "cp_stepring.svg", "x": 108.3, "y": 152.9, "w": 42, "h": 42},
      // x/y/w/h are logical units, same coordinate space as canvas width/height
      {"type": "rect", "x": 437.0, "y": 339.0, "w": 114, "h": 272, "color": [30, 30, 30]}
  ],
  "final_size": {"width": 1000, "height": 202},  // optional downscale target
  "output": "wc_cp_bg.png"
}
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile


def find_imagemagick():
    # ImageMagick 7 installs `magick`; ImageMagick 6 only has `convert`.  On
    # Windows, a bare `convert` may be the unrelated system tool, so prefer
    # `magick` wherever it exists.
    for name in ("magick", "convert"):
        path = shutil.which(name)
        if path:
            return path
    sys.exit("error: ImageMagick not found (need `magick` or `convert` on PATH)")


def find_chrome():
    env = os.environ.get("CHROME")
    if env:
        return env
    for name in ("google-chrome", "google-chrome-stable", "chromium", "chromium-browser", "chrome"):
        path = shutil.which(name)
        if path:
            return path
    sys.exit("error: Chrome/Chromium not found for rendering .svg pieces; "
             "put it on PATH or set the CHROME environment variable")


IMAGEMAGICK = find_imagemagick()
_chrome = None


def chrome():
    global _chrome
    if _chrome is None:
        _chrome = find_chrome()
    return _chrome


def run(cmd):
    if cmd[0] == "convert":
        cmd = [IMAGEMAGICK] + cmd[1:]
    subprocess.run(cmd, check=True)


def is_svg(path):
    return path.lower().endswith(".svg")


def render_html_to_png(body_html, out_png, w, h):
    """Rasterize an HTML snippet at an exact WxH pixel size via headless Chrome."""
    html = tempfile.NamedTemporaryFile(suffix=".html", delete=False)
    try:
        html.write(f"""<!doctype html><html><body style="margin:0;padding:0">
{body_html}
</body></html>""".encode())
        html.close()
        run([
            chrome(), "--headless", "--no-sandbox", "--disable-gpu",
            "--disable-dev-shm-usage", "--hide-scrollbars",
            f"--window-size={w},{h}",
            "--default-background-color=00000000",
            f"--screenshot={out_png}",
            "file://" + html.name,
        ])
    finally:
        os.unlink(html.name)


def render_svg_to_png(svg_path, out_png, w, h):
    """Rasterize an SVG at an exact WxH pixel size via headless Chrome."""
    svg_uri = "file://" + os.path.abspath(svg_path)
    render_html_to_png(f'<img src="{svg_uri}" style="display:block;width:{w}px;height:{h}px">', out_png, w, h)


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)

    manifest_path = sys.argv[1]
    with open(manifest_path) as f:
        m = json.load(f)

    manifest_dir = os.path.dirname(os.path.abspath(manifest_path))
    asset_dir = m.get("asset_dir", manifest_dir)
    if not os.path.isabs(asset_dir):
        asset_dir = os.path.join(manifest_dir, asset_dir)

    def resolve(p):
        return p if os.path.isabs(p) else os.path.join(asset_dir, p)

    tmp_dir = tempfile.mkdtemp(prefix="compose_artwork_")
    try:
        def as_png(src_path, w, h):
            """Return a PNG path usable by `convert`, rasterizing SVG sources first."""
            if not is_svg(src_path):
                return src_path
            out_png = os.path.join(tmp_dir, f"svg_{len(os.listdir(tmp_dir))}.png")
            render_svg_to_png(src_path, out_png, w, h)
            return out_png

        scale = m.get("scale", 1)
        canvas = m["canvas"]
        out = resolve(m["output"])

        if "file" in canvas:
            src = resolve(canvas["file"])
            if is_svg(src):
                cw = round(canvas["width"] * scale)
                ch = round(canvas["height"] * scale)
                render_svg_to_png(src, out, cw, ch)
            else:
                shutil.copyfile(src, out)
        else:
            w = round(canvas["width"] * scale)
            h = round(canvas["height"] * scale)
            color = canvas.get("color", "none")
            run(["convert", "-size", f"{w}x{h}", f"xc:{color}", out])

        # Keep a real RGBA alpha channel through every intermediate save (PNG
        # otherwise silently drops it, e.g. to a palette/RGB encoding, whenever a
        # step's result looks fully opaque or low-color) so a later "cutout"
        # piece can actually clear pixels to transparent instead of just
        # painting them black.
        PNG_RGBA = ["-alpha", "on", "-define", "png:color-type=6"]
        run(["convert", out, *PNG_RGBA, out])

        for piece in m["pieces"]:
            pw = round(piece["w"] * scale)
            ph = round(piece["h"] * scale)
            px = round(piece["x"] * scale)
            py = round(piece["y"] * scale)
            ptype = piece.get("type", "image")

            if ptype == "rect":
                r, g, b = piece["color"]
                run([
                    "convert", out,
                    "(", "-size", f"{pw}x{ph}", f"xc:rgb({r},{g},{b})", ")",
                    "-geometry", f"+{px}+{py}",
                    "-compose", "over", "-composite",
                    *PNG_RGBA,
                    out,
                ])
                continue

            if ptype == "cutout":
                # Punch a fully-transparent hole through everything drawn so far
                # (e.g. a reel window that must show a live element drawn behind
                # this composite, not whatever background/wallpaper was painted
                # across that area).
                run([
                    "convert", out,
                    "(", "-size", f"{pw}x{ph}", "xc:black", ")",
                    "-geometry", f"+{px}+{py}",
                    "-compose", "Dst_Out", "-composite",
                    *PNG_RGBA,
                    out,
                ])
                continue

            src = resolve(piece["file"])
            png_src = as_png(src, pw, ph)
            resize_args = [] if is_svg(src) else ["-resize", f"{pw}x{ph}!"]

            run([
                "convert", out,
                "(", png_src, *resize_args, ")",
                "-geometry", f"+{px}+{py}",
                "-compose", "over", "-composite",
                *PNG_RGBA,
                out,
            ])

        final = m.get("final_size")
        resize_args = []
        if final:
            resize_args = ["-filter", "Lanczos", "-resize", f"{final['width']}x{final['height']}"]

        run([
            "convert", out, *resize_args,
            "-depth", "8",
            "-define", "png:bit-depth=8",
            "-define", "png:color-type=6",
            out,
        ])
    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)

    print("done:", out)


if __name__ == "__main__":
    main()
