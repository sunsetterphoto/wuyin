#!/usr/bin/env python3
"""Raw beta images (build/beta_raw, from tools/comfyui/beta_generate.py) -> game assets.

  ~/Documents/ComfyUI/.venv/bin/python tools/postprocess/beta_postprocess.py [section ...] [--only id,id]

  lingshou     -> game/assets/sprites/lingshou/<id>.png  (48x48, qinglong 96x96, palette, outline)
  derived      -> qinglong_silenced (grey, closed eyes, silence threads; post-process of qinglong)
  chars        -> game/assets/sprites/chars/<id>.png     (32x48, jinli 32x32)
  backgrounds  -> game/assets/backgrounds/<id>.png       (320x180 pixel grid, 2x nearest -> 640x360)
  ui           -> game/assets/ui/title.png (640x360), icon.png (512x512)
Uses the seed from tools/comfyui/beta_assets.json to pick the raw file.
--batch tools/comfyui/full_assets.json: same steps for the full batch (raw files from build/full_raw).
Derived items there may name "dir" (lingshou/chars) and "op" (silence, ashes, order_robe, see below).
"""
import argparse
import json
import os

import numpy as np
from PIL import Image, ImageEnhance, ImageFilter

from pixelize import load_palette, sprite

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
RAW = os.path.join(ROOT, "build", "beta_raw")
ASSETS = os.path.join(ROOT, "game", "assets")
BG_COLORS = 64   # adaptive palette per background (gradients survive better than with the 32 master colors)
BG_GRID = 2      # every background pixel is 2x2 screen pixels (320x180 -> 640x360)


def raw_dir(batch_path):
    """beta_assets.json -> build/beta_raw, full_assets.json -> build/full_raw (as in beta_generate.py)."""
    name = os.path.basename(batch_path).split("_assets")[0]
    return os.path.join(ROOT, "build", f"{name}_raw")


def raw(section, item, seed=None):
    img = Image.open(os.path.join(RAW, section, f'{item["id"]}_s{seed or item["seed"]}.png'))
    if "tint" in item:  # per-channel multipliers, e.g. warm up a cool grey robe so it maps to stone, not mist blue
        a = np.array(img.convert("RGB")).astype(np.float32) * np.array(item["tint"], dtype=np.float32)
        img = Image.fromarray(a.clip(0, 255).astype(np.uint8), "RGB")
    return img


def save(img, *parts):
    dst = os.path.join(ASSETS, *parts)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    img.save(dst)
    print(os.path.relpath(dst, ROOT), img.size)


def adaptive(img, colors):
    """Median-cut palette of the image itself, no dithering, then pull colours a bit
    towards the Wuyin master palette so the scenes stay in one family."""
    q = img.convert("RGB").quantize(colors=colors, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    pal = np.array(q.getpalette()[:colors * 3], dtype=np.float32).reshape(-1, 3)
    master = np.array(load_palette(), dtype=np.float32)
    d = ((pal[:, None, :] - master[None, :, :]) ** 2).sum(-1)
    nearest = master[d.argmin(1)]
    pal = pal * 0.8 + nearest * 0.2
    flat = pal.clip(0, 255).astype(np.uint8).flatten().tolist()
    q.putpalette(flat + [0] * (768 - len(flat)))
    return q.convert("RGB")


def pixel_scene(img, w, h, grid, colors, sharpen=True):
    small = img.convert("RGB").resize((w // grid, h // grid), Image.LANCZOS)
    if sharpen:
        small = small.filter(ImageFilter.UnsharpMask(radius=1, percent=60, threshold=2))
        small = ImageEnhance.Color(small).enhance(1.1)
    q = adaptive(small, colors)
    return q.resize((w, h), Image.NEAREST)


def silence(src):
    """qinglong -> qinglong_silenced: grey, darker, eyes closed, faint threads wrapped around."""
    a = np.array(src).astype(np.float32)
    alpha = a[:, :, 3] > 0
    rgb = a[:, :, :3]
    lum = rgb @ np.array([0.299, 0.587, 0.114])
    # Eyes: bright warm (gold/yellow) pixels -> closed lid line in dark stone.
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    eyes = alpha & (r > 180) & (g > 140) & (b < 120) & (r - b > 90)
    cols = load_palette()
    hexes = ("5e584c", "8c8577", "bfb6a4", "f2ede0")  # dark stone .. rice paper
    greys = [tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) for h in hexes]
    t = (lum - lum[alpha].min()) / max(1, lum[alpha].max() - lum[alpha].min())
    idx = np.clip((np.clip(t, 0, 1) ** 0.9 * len(greys)).astype(int), 0, len(greys) - 1)
    out = np.array(greys, dtype=np.uint8)[idx]
    outline = alpha & (lum < 40)
    out[outline] = np.array(cols[0], dtype=np.uint8)
    out[eyes] = np.array(cols[0], dtype=np.uint8)  # closed lid = dark line
    # Threads: thin diagonal sine lines in light stone, only on the body.
    h, w = alpha.shape
    yy, xx = np.mgrid[0:h, 0:w]
    thread_col = np.array(greys[2], dtype=np.uint8)
    threads = np.zeros_like(alpha)
    for k, off in enumerate((14, 38, 62, 86)):
        line = (yy - (xx * 0.55 + off + 3 * np.sin(xx / 7.0 + k))).astype(int)
        threads |= (line == 0)
    threads &= alpha & ~outline
    out[threads] = thread_col
    res = np.dstack([out, (alpha * 255).astype(np.uint8)])
    return Image.fromarray(res, "RGBA"), int(eyes.sum())


def ashes(src):
    """fenghuang -> fenghuang_ashes: same silhouette as dim grey ash with an orange ember glow.
    Dark/mid tones become ash greys; the brightest pixels and a speckle of interior pixels glow."""
    a = np.array(src).astype(np.float32)
    alpha = a[:, :, 3] > 0
    rgb = a[:, :, :3]
    lum = rgb @ np.array([0.299, 0.587, 0.114])
    hexes = ("3a3046", "5e584c", "8c8577")  # ink violet .. stone: dim ash
    greys = np.array([tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) for h in hexes], dtype=np.uint8)
    # rank-based brightness (0..1, ties share the lower rank) so bright and dark sprites get the same share of glow
    vals = np.sort(lum[alpha])
    t = np.searchsorted(vals, lum, "left") / max(1, len(vals))
    out = greys[np.clip((t * len(greys)).astype(int), 0, len(greys) - 1)]
    cols = load_palette()
    outline = alpha & (lum < 40)
    out[outline] = np.array(cols[0], dtype=np.uint8)
    ember = np.array((0xd8, 0x56, 0x2f), dtype=np.uint8)   # ember orange
    glow = np.array((0xf0, 0x8a, 0x3a), dtype=np.uint8)    # lantern orange
    core = np.array((0xf6, 0xc4, 0x53), dtype=np.uint8)    # imperial gold
    body = alpha & ~outline
    # rim: body pixels next to the outline or the transparent edge glow where the original was lit
    edge = np.zeros_like(alpha)
    nb = ~alpha | outline
    edge[1:, :] |= nb[:-1, :]
    edge[:-1, :] |= nb[1:, :]
    edge[:, 1:] |= nb[:, :-1]
    edge[:, :-1] |= nb[:, 1:]
    rim = body & edge & (t > 0.45)
    out[rim] = ember
    out[body & (t > 0.96)] = ember
    # sparse glowing embers, fixed random pattern (reproducible)
    rnd = np.random.default_rng(7).random(alpha.shape)
    out[body & (t > 0.35) & (rnd < 0.07)] = glow
    out[body & (t > 0.35) & (rnd < 0.012)] = core
    res = np.dstack([out, (alpha * 255).astype(np.uint8)])
    return Image.fromarray(res, "RGBA")


def order_robe(src):
    """yao -> yao_order: same figure, red jacket and black clothes become the grey robe of the
    Order of Silence with a white sash. Head (hair, face) stays untouched."""
    a = np.array(src)
    alpha = a[:, :, 3] > 0
    rgb = a[:, :, :3].astype(int)

    def is_(hexcode):
        c = [int(hexcode[i:i + 2], 16) for i in (0, 2, 4)]
        return alpha & (rgb[:, :, 0] == c[0]) & (rgb[:, :, 1] == c[1]) & (rgb[:, :, 2] == c[2])

    def col(hexcode):
        return np.array([int(hexcode[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.uint8)

    jacket_rows = np.where(is_("a8382b").any(1))[0]
    top, bottom = jacket_rows.min(), jacket_rows.max()
    h, w = alpha.shape
    rows = np.arange(h)[:, None] >= top - 1
    inner = alpha.copy()  # pixels whose 4 neighbours are all opaque (not the outline)
    inner[1:, :] &= alpha[:-1, :]
    inner[:-1, :] &= alpha[1:, :]
    inner[:, 1:] &= alpha[:, :-1]
    inner[:, :-1] &= alpha[:, 1:]
    out = a.copy()
    for src_hex, dst_hex in (("a8382b", "bfb6a4"), ("6a2a22", "8c8577"), ("553520", "8c8577")):
        out[is_(src_hex) & rows, :3] = col(dst_hex)
    out[is_("1a1620") & rows & inner, :3] = col("8c8577")
    out[is_("3a3046") & rows & inner, :3] = col("5e584c")
    # robe skirt: close the gap between the legs from the hem down to 4 rows above the soles
    ink = col("1a1620")
    for y in range(bottom + 1, h - 4):
        xs = np.where(alpha[y])[0]
        if len(xs) < 2:
            continue
        x0, x1 = xs.min(), xs.max()
        for x in range(x0 + 1, x1):
            if not alpha[y, x] or (out[y, x, :3] == ink).all():
                out[y, x] = (*col("5e584c"), 255)
    # white sash two rows below the jacket hem, emblem = one dark pixel in the middle
    for y in (bottom - 1, bottom):
        line = inner[y] & (np.arange(w) > 0)
        out[y, line, :3] = col("f2ede0")
    xs = np.where(inner[bottom])[0]
    if len(xs):
        out[bottom - 1:bottom + 1, (xs.min() + xs.max()) // 2, :3] = col("5e584c")
    return Image.fromarray(out, "RGBA")


def glow_eyes(img):
    """Pale, low-saturation light pixels on a dark sprite (the moth's eyes) -> glowing mist white."""
    a = np.array(img)
    rgb = a[:, :, :3].astype(int)
    sat = rgb.max(2) - rgb.min(2)
    lum = rgb @ np.array([299, 587, 114]) // 1000
    eyes = (a[:, :, 3] > 0) & (lum > 90) & (sat < 60)
    grow = eyes.copy()  # widen each eye by one pixel so it reads at 48 px
    grow[:, 1:] |= eyes[:, :-1]
    grow[:, :-1] |= eyes[:, 1:]
    eyes = grow & (a[:, :, 3] > 0) & (lum < 60)  | eyes
    a[eyes, :3] = (0xf2, 0xed, 0xe0)
    print("  glowing eye pixels:", int(eyes.sum()))
    return Image.fromarray(a, "RGBA")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sections", nargs="*", default=["lingshou", "derived", "chars", "backgrounds", "ui"])
    ap.add_argument("--only", default="")
    ap.add_argument("--batch", default=os.path.join(ROOT, "tools", "comfyui", "beta_assets.json"))
    args = ap.parse_args()
    global RAW
    RAW = raw_dir(args.batch)
    batch = json.load(open(args.batch))
    only = set(filter(None, args.only.split(",")))
    cols = load_palette()
    for sec in args.sections:
        for item in batch.get(sec, []):
            if only and item["id"] not in only:
                continue
            if sec == "lingshou":
                size = item.get("size", 48)
                img = sprite(raw(sec, item), size, cols, bg_thresh=item.get("bg_thresh", 70), trim_shadow=item.get("trim_shadow", False))
                if item.get("glow_eyes"):
                    img = glow_eyes(img)
                save(img, "sprites", "lingshou", item["id"] + ".png")
            elif sec == "derived":
                folder = item.get("dir", "lingshou")
                src = Image.open(os.path.join(ASSETS, "sprites", folder, item["from"] + ".png"))
                op = item.get("op", "silence")
                if op == "silence":
                    img, n_eye = silence(src)
                    print("  eye pixels closed:", n_eye)
                elif op == "ashes":
                    img = ashes(src)
                elif op == "order_robe":
                    img = order_robe(src)
                save(img, "sprites", folder, item["id"] + ".png")
            elif sec == "chars":
                if item.get("size") == 32:
                    img = sprite(raw(sec, item), 32, cols)
                else:
                    # fill < 1: smaller figure (child) standing on the same baseline.
                    h = round(48 * item.get("fill", 1.0))
                    img = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
                    img.paste(sprite(raw(sec, item), 32, cols, True, h, trim_shadow=item.get("trim_shadow", False)), (0, 48 - h))
                save(img, "sprites", "chars", item["id"] + ".png")
            elif sec == "backgrounds":
                save(pixel_scene(raw(sec, item), 640, 360, BG_GRID, BG_COLORS), "backgrounds", item["id"] + ".png")
            elif sec == "ui" and item["id"] == "title":
                save(pixel_scene(raw(sec, item), 640, 360, BG_GRID, BG_COLORS), "ui", "title.png")
            elif sec == "ui" and item["id"] == "icon":
                save(pixel_scene(raw(sec, item), 512, 512, 4, 32), "ui", "icon.png")


if __name__ == "__main__":
    main()
