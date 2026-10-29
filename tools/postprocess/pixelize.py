#!/usr/bin/env python3
"""Turn generated concept images into game-ready pixel art (GDD: palette, grid, clean edges).

  sprite: remove white background, drop small loose blobs, crop, downscale to SIZE (48 for
          Lingshou), reduce to the Wuyin palette, binary alpha, 1 px dark outline.
  tile:   center crop, downscale to SIZE (32), reduce to the palette, make edges wrap.

Run with the ComfyUI venv (has Pillow + numpy):
  ~/Documents/ComfyUI/.venv/bin/python tools/postprocess/pixelize.py sprite in.png out.png --size 48
  ~/Documents/ComfyUI/.venv/bin/python tools/postprocess/pixelize.py tile in.png out.png --size 32
"""
import argparse
import os

import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

PALETTE_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "palette_wuyin32.hex")


def load_palette(path=PALETTE_FILE):
    cols = []
    for line in open(path):
        parts = line.split()
        if not parts or line.startswith("#"):
            continue
        hexcode = parts[0]
        if len(hexcode) == 6 and all(c in "0123456789abcdefABCDEF" for c in hexcode):
            cols.append(tuple(int(hexcode[i:i + 2], 16) for i in (0, 2, 4)))
    return cols


def palette_image(cols):
    pal = Image.new("P", (1, 1))
    flat = [c for rgb in cols for c in rgb]
    flat += flat[:3] * (256 - len(cols))
    pal.putpalette(flat)
    return pal


def quantize(img_rgb, cols):
    return img_rgb.quantize(palette=palette_image(cols), dither=Image.Dither.NONE).convert("RGB")


def remove_white_background(img, thresh=70):
    """Flood fill near-white from the borders; returns RGBA with the background transparent."""
    work = img.convert("RGB").copy()
    marker = (255, 0, 255)
    w, h = work.size
    for x, y in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1), (w // 2, 0), (w // 2, h - 1), (0, h // 2), (w - 1, h // 2)]:
        if sum(work.getpixel((x, y))) > 3 * (255 - thresh):
            ImageDraw.floodfill(work, (x, y), marker, thresh=thresh)
    a = np.array(work)
    mask = ~((a[:, :, 0] == 255) & (a[:, :, 1] == 0) & (a[:, :, 2] == 255))
    rgba = np.dstack([np.array(img.convert("RGB")), (mask * 255).astype(np.uint8)])
    return Image.fromarray(rgba, "RGBA")


def keep_main_blob(rgba, min_share=0.2):
    """Drops loose fragments (stray icons, sparkles) smaller than min_share of the biggest blob."""
    alpha = np.array(rgba)[:, :, 3] > 0
    h, w = alpha.shape
    labels = np.zeros((h, w), dtype=np.int32)
    sizes = [0]
    current = 0
    for y in range(h):
        for x in range(w):
            if alpha[y, x] and labels[y, x] == 0:
                current += 1
                stack = [(y, x)]
                labels[y, x] = current
                n = 0
                while stack:
                    cy, cx = stack.pop()
                    n += 1
                    for ny, nx in ((cy + 1, cx), (cy - 1, cx), (cy, cx + 1), (cy, cx - 1)):
                        if 0 <= ny < h and 0 <= nx < w and alpha[ny, nx] and labels[ny, nx] == 0:
                            labels[ny, nx] = current
                            stack.append((ny, nx))
                sizes.append(n)
    if current == 0:
        return rgba
    biggest = max(sizes)
    keep = {i for i, s in enumerate(sizes) if i > 0 and s >= biggest * min_share}
    a = np.array(rgba)
    a[:, :, 3] = np.where(np.isin(labels, list(keep)), a[:, :, 3], 0)
    return Image.fromarray(a, "RGBA")


def _trim_ground_shadow(a, band=0.15):
    """Pale, unsaturated pixels in the lowest `band` of the opaque area become transparent
    (the soft grey ground shadow), then everything connected only through them stays as is."""
    alpha = a[:, :, 3] > 0
    ys = np.where(alpha.any(1))[0]
    if not len(ys):
        return a
    top, bottom = ys.min(), ys.max()
    rgb = a[:, :, :3].astype(int)
    sat = rgb.max(2) - rgb.min(2)
    lum = rgb @ np.array([299, 587, 114]) // 1000
    rows = np.arange(a.shape[0])[:, None] >= bottom - (bottom - top) * band
    shadow = alpha & rows & (lum > 150) & (sat < 40)
    a = a.copy()
    a[shadow, 3] = 0
    return a


def sprite(img, size, cols, outline=True, height=None, bg_thresh=70, trim_shadow=False):
    """size = width; height defaults to size (square). Non-square sprites (32x48 overworld
    characters) are scaled to fit the canvas, centred horizontally, feet at the bottom.
    bg_thresh: flood-fill tolerance for the white background; lower it for white creatures whose
    outline has gaps (otherwise the fill leaks into a white face).
    trim_shadow: drop a pale grey ground-shadow ellipse the model sometimes paints under the creature."""
    width, height = size, height or size
    rgba = remove_white_background(img, bg_thresh)
    small_work = rgba.resize((rgba.width // 4, rgba.height // 4), Image.NEAREST)  # blob analysis on a quarter
    cleaned_small = keep_main_blob(small_work)
    keep_mask = np.array(cleaned_small.resize(rgba.size, Image.NEAREST))[:, :, 3] > 0
    a = np.array(rgba)
    a[:, :, 3] = np.where(keep_mask, a[:, :, 3], 0)
    if trim_shadow:
        a = _trim_ground_shadow(a)
    rgba = Image.fromarray(a, "RGBA")
    bbox = rgba.getbbox()
    rgba = rgba.crop(bbox)
    pad = 2 if outline else 0
    iw, ih = width - pad, height - pad
    # Pad to the target aspect ratio, feet at the bottom, leaving room for the outline.
    scale = max(rgba.width / iw, rgba.height / ih)
    cw, ch = round(iw * scale), round(ih * scale)
    canvas = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    canvas.paste(rgba, ((cw - rgba.width) // 2, ch - rgba.height))
    small = canvas.resize((iw, ih), Image.BOX)
    arr = np.array(small)
    alpha = arr[:, :, 3] >= 128
    rgb = quantize(Image.fromarray(arr[:, :, :3], "RGB"), cols)
    out = np.zeros((height, width, 4), dtype=np.uint8)
    off = pad // 2
    out[off:off + ih, off:off + iw, :3] = np.array(rgb)
    out[off:off + ih, off:off + iw, 3] = alpha * 255
    if outline:
        darkest = min(cols, key=lambda c: sum(c))
        a2 = out[:, :, 3] > 0
        border = np.zeros_like(a2)
        border[1:, :] |= a2[:-1, :]
        border[:-1, :] |= a2[1:, :]
        border[:, 1:] |= a2[:, :-1]
        border[:, :-1] |= a2[:, 1:]
        border &= ~a2
        out[border] = (*darkest, 255)
    return Image.fromarray(out, "RGBA")


def make_seamless(a):
    """Classic offset trick: the half-shifted copy wraps perfectly at its edges;
    blend it in towards the borders, keep the original in the middle."""
    h, w = a.shape[:2]
    shifted = np.roll(a, (h // 2, w // 2), axis=(0, 1))
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.maximum(np.abs(yy - h / 2) / (h / 2), np.abs(xx - w / 2) / (w / 2))
    weight = np.clip((d - 0.45) / 0.5, 0, 1)[:, :, None]
    return a * (1 - weight) + shifted * weight


def tile(img, size, cols, crop=0.375):
    """crop: share of the generated image that becomes one tile (keeps patterns at a readable scale)."""
    img = img.convert("RGB")
    side = int(min(img.size) * crop)
    cx, cy = img.width // 2, img.height // 2
    img = img.crop((cx - side // 2, cy - side // 2, cx + side // 2, cy + side // 2))
    a = make_seamless(np.array(img).astype(np.float32))
    small = Image.fromarray(a.clip(0, 255).astype(np.uint8)).resize((size, size), Image.LANCZOS)
    small = small.filter(ImageFilter.UnsharpMask(radius=1, percent=120, threshold=0))
    small = ImageEnhance.Contrast(small).enhance(1.4)
    q = quantize(small, cols)
    if len(np.unique(np.array(q).reshape(-1, 3), axis=0)) >= 4:
        return q
    return ramp_quantize(small.filter(ImageFilter.GaussianBlur(0.7)), cols)


def _hue_sat_lum(rgb):
    import colorsys
    r, g, b = (c / 255.0 for c in rgb)
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    return h, s, l


def ramp_quantize(img, cols, steps=4, quantiles=(0.15, 0.5, 0.85)):
    """Maps a flat-looking tile onto a light-to-dark ramp of palette colors of
    the same hue family, split by brightness quantiles, so texture survives."""
    a = np.array(img.convert("RGB")).astype(np.float32)
    mean = a.reshape(-1, 3).mean(axis=0)
    mh, ms, ml = _hue_sat_lum(mean)

    def family_distance(c):
        h, s_, l = _hue_sat_lum(c)
        dh = min(abs(h - mh), 1 - abs(h - mh))
        return dh * 4 + abs(s_ - ms)

    if ms < 0.15:
        # Neutral (stone, ash): hue is meaningless, use the least saturated colors.
        family = sorted(cols, key=lambda c: _hue_sat_lum(c)[1])[:6]
    else:
        family = sorted(cols, key=family_distance)[:6]
    family = sorted(family, key=lambda c: _hue_sat_lum(c)[2])
    # Keep the ramp around the mean brightness.
    centre = min(range(len(family)), key=lambda i: abs(_hue_sat_lum(family[i])[2] - ml))
    lo = max(0, min(centre - steps // 2, len(family) - steps))
    ramp = family[lo:lo + steps]
    lum = a @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
    cuts = np.quantile(lum, quantiles[:len(ramp) - 1])
    idx = np.searchsorted(cuts, lum)
    out = np.array(ramp, dtype=np.uint8)[np.clip(idx, 0, len(ramp) - 1)]
    return Image.fromarray(out, "RGB")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("mode", choices=["sprite", "tile"])
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--size", type=int, default=32, help="width (and height unless --height)")
    ap.add_argument("--height", type=int, help="sprite: height for non-square sprites, e.g. --size 32 --height 48")
    ap.add_argument("--palette", default=PALETTE_FILE)
    ap.add_argument("--no-outline", action="store_true")
    ap.add_argument("--crop", type=float, default=0.375, help="tile: share of the image used for one tile")
    args = ap.parse_args()
    cols = load_palette(args.palette)
    img = Image.open(args.src)
    out = sprite(img, args.size, cols, not args.no_outline, args.height) if args.mode == "sprite" else tile(img, args.size, cols, args.crop)
    out.save(args.dst)
    print(args.dst, out.size, len(np.unique(np.array(out.convert("RGB")).reshape(-1, 3), axis=0)), "colors")


if __name__ == "__main__":
    main()
