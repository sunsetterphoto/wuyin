#!/usr/bin/env python3
"""Preview sheets for the beta assets.
  beta_preview.py sprites  -> build/beta_preview_sprites.png (Lingshou 4x + chars 1x and 4x)
  beta_preview.py backgrounds -> build/beta_preview_backgrounds.png (backgrounds + title + icon, half size,
                                 one creature pair at game scale on each to judge the horizon)
  beta_preview.py raw <section> -> build/beta_preview_raw_<section>.png (raw generations, small)
"""
import glob
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
A = os.path.join(ROOT, "game", "assets")
BG = (92, 104, 112, 255)


def label(d, xy, text):
    d.text(xy, text, fill=(230, 220, 200, 255))


def sprites():
    ls = sorted(glob.glob(os.path.join(A, "sprites", "lingshou", "*.png")))
    ch = sorted(glob.glob(os.path.join(A, "sprites", "chars", "*.png")))
    S = 4
    cell = 96 * S // 2 + 16
    cols = 7
    rows_l = (len(ls) + cols - 1) // cols
    W = cols * cell + 20
    H = 20 + rows_l * (cell + 14) + 48 * S + 70 + 60
    sheet = Image.new("RGBA", (max(W, 20 + len(ch) * (32 * S + 12)), H), BG)
    d = ImageDraw.Draw(sheet)
    for i, p in enumerate(ls):
        im = Image.open(p).convert("RGBA")
        s = S if im.width <= 48 else S // 2
        im = im.resize((im.width * s, im.height * s), Image.NEAREST)
        x, y = 10 + (i % cols) * cell, 10 + (i // cols) * (cell + 14)
        sheet.alpha_composite(im, (x, y))
        label(d, (x, y + cell - 12), os.path.basename(p)[:-4])
    y0 = 20 + rows_l * (cell + 14)
    for i, p in enumerate(ch):
        im = Image.open(p).convert("RGBA")
        x = 10 + i * (32 * S + 12)
        sheet.alpha_composite(im.resize((im.width * S, im.height * S), Image.NEAREST), (x, y0 + 48 * S - im.height * S))
        sheet.alpha_composite(im, (x, y0 + 48 * S + 8))  # 1x
        label(d, (x, y0 + 48 * S + 60), os.path.basename(p)[:-4])
    out = os.path.join(ROOT, "build", "beta_preview_sprites.png")
    sheet.save(out)
    print(out, sheet.size)


def backgrounds():
    bgs = sorted(glob.glob(os.path.join(A, "backgrounds", "*.png"))) + [os.path.join(A, "ui", "title.png")]
    bgs = [p for p in bgs if os.path.exists(p)]
    pair = [os.path.join(A, "sprites", "lingshou", n + ".png") for n in ("bambaer", "firnleopard")]
    W, H = 640, 360
    sheet = Image.new("RGBA", (2 * W + 30, ((len(bgs) + 2) // 2) * (H + 10) + 10), BG)
    for i, p in enumerate(bgs):
        im = Image.open(p).convert("RGBA")
        if "backgrounds" in p:
            for j, sp in enumerate(pair):
                if os.path.exists(sp):
                    s = Image.open(sp).convert("RGBA")
                    s = s.resize((s.width * 2, s.height * 2), Image.NEAREST)
                    if j == 0:
                        s = s.transpose(Image.FLIP_LEFT_RIGHT)
                        im.alpha_composite(s, (120, 300 - s.height))
                    else:
                        im.alpha_composite(s, (430, 230 - s.height))
        sheet.alpha_composite(im, (10 + (i % 2) * (W + 10), 10 + (i // 2) * (H + 10)))
    icon = os.path.join(A, "ui", "icon.png")
    if os.path.exists(icon):
        ic = Image.open(icon).convert("RGBA")
        i = len(bgs)
        x, y = 10 + (i % 2) * (W + 10), 10 + (i // 2) * (H + 10)
        sheet.alpha_composite(ic.resize((256, 256), Image.LANCZOS), (x, y))
        sheet.alpha_composite(ic.resize((96, 96), Image.LANCZOS), (x + 270, y))
        sheet.alpha_composite(ic.resize((48, 48), Image.LANCZOS), (x + 380, y))
    out = os.path.join(ROOT, "build", "beta_preview_backgrounds.png")
    sheet.save(out)
    print(out, sheet.size)


def raw(section, pattern="*"):
    files = sorted(glob.glob(os.path.join(ROOT, "build", "beta_raw", section, pattern + ".png")))
    th = 256
    ims = []
    for p in files:
        im = Image.open(p).convert("RGBA")
        im.thumbnail((th * 2, th))
        ims.append((p, im))
    cols = 6 if section != "backgrounds" else 3
    cw = max(im.width for _, im in ims) + 8
    sheet = Image.new("RGBA", (cols * cw + 8, ((len(ims) + cols - 1) // cols) * (th + 22) + 8), BG)
    d = ImageDraw.Draw(sheet)
    for i, (p, im) in enumerate(ims):
        x, y = 8 + (i % cols) * cw, 8 + (i // cols) * (th + 22)
        sheet.alpha_composite(im, (x, y))
        label(d, (x, y + th + 4), os.path.basename(p)[:-4])
    out = os.path.join(ROOT, "build", f"beta_preview_raw_{section}.png")
    sheet.save(out)
    print(out, sheet.size)


if __name__ == "__main__":
    {"sprites": sprites, "backgrounds": backgrounds}.get(sys.argv[1], lambda: raw(*sys.argv[2:]))()
