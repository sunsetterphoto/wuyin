#!/usr/bin/env python3
"""Raw beta images (build/beta_raw, from tools/comfyui/beta_generate.py) -> game assets.

  ~/Documents/ComfyUI/.venv/bin/python tools/postprocess/beta_postprocess.py [section ...] [--only id,id]

  lingshou     -> game/assets/sprites/lingshou/<id>.png  (48x48, qinglong 96x96, palette, outline)
  derived      -> qinglong_silenced (grey, closed eyes, silence threads; post-process of qinglong)
  chars        -> game/assets/sprites/chars/<id>.png     (32x48, jinli 32x32)
  backgrounds  -> game/assets/backgrounds/<id>.png       (320x180 pixel grid, 2x nearest -> 640x360)
  ui           -> game/assets/ui/title.png (640x360), icon.png (512x512)
Uses the seed from tools/comfyui/beta_assets.json to pick the raw file.
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


def raw(section, item, seed=None):
    return Image.open(os.path.join(RAW, section, f'{item["id"]}_s{seed or item["seed"]}.png'))


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
    batch = json.load(open(args.batch))
    only = set(filter(None, args.only.split(",")))
    cols = load_palette()
    for sec in args.sections:
        for item in batch[sec]:
            if only and item["id"] not in only:
                continue
            if sec == "lingshou":
                size = item.get("size", 48)
                img = sprite(raw(sec, item), size, cols)
                if item.get("glow_eyes"):
                    img = glow_eyes(img)
                save(img, "sprites", "lingshou", item["id"] + ".png")
            elif sec == "derived":
                src = Image.open(os.path.join(ASSETS, "sprites", "lingshou", item["from"] + ".png"))
                img, n_eye = silence(src)
                print("  eye pixels closed:", n_eye)
                save(img, "sprites", "lingshou", item["id"] + ".png")
            elif sec == "chars":
                if item.get("size") == 32:
                    img = sprite(raw(sec, item), 32, cols)
                else:
                    # fill < 1: smaller figure (child) standing on the same baseline.
                    h = round(48 * item.get("fill", 1.0))
                    img = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
                    img.paste(sprite(raw(sec, item), 32, cols, True, h), (0, 48 - h))
                save(img, "sprites", "chars", item["id"] + ".png")
            elif sec == "backgrounds":
                save(pixel_scene(raw(sec, item), 640, 360, BG_GRID, BG_COLORS), "backgrounds", item["id"] + ".png")
            elif sec == "ui" and item["id"] == "title":
                save(pixel_scene(raw(sec, item), 640, 360, BG_GRID, BG_COLORS), "ui", "title.png")
            elif sec == "ui" and item["id"] == "icon":
                save(pixel_scene(raw(sec, item), 512, 512, 4, 32), "ui", "icon.png")


if __name__ == "__main__":
    main()
