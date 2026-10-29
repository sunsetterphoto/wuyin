#!/usr/bin/env python3
"""Preview sheets for the full batch (tools/comfyui/full_assets.json).

  full_preview.py lingshou     -> build/full_preview_lingshou.png  (new Lingshou 4x (96 px ones 2x) + 1x row,
                                  three beta sprites at the start for comparison)
  full_preview.py chars        -> build/full_preview_chars.png     (new characters 4x + 1x, hero/yao/meister for comparison)
  full_preview.py backgrounds  -> build/full_preview_backgrounds.png (new backgrounds, a creature pair at game scale)
  full_preview.py raw <section> [glob] -> build/full_preview_raw_<section>.png (raw generations from build/full_raw)

Run with ~/Documents/ComfyUI/.venv/bin/python.
"""
import glob
import json
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
A = os.path.join(ROOT, "game", "assets")
BG = (92, 104, 112, 255)
BATCH = json.load(open(os.path.join(ROOT, "tools", "comfyui", "full_assets.json")))


def label(d, xy, text):
    d.text(xy, text, fill=(230, 220, 200, 255))


def ids(section):
    return [i["id"] for i in BATCH.get(section, [])]


def grid_sheet(paths, out, scale, cols, cell_w, cell_h):
    paths = [p for p in paths if os.path.exists(p)]
    rows = (len(paths) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cell_w + 20, rows * (cell_h + 18) + 20), BG)
    d = ImageDraw.Draw(sheet)
    for i, p in enumerate(paths):
        im = Image.open(p).convert("RGBA")
        s = scale if im.width <= 48 else max(1, scale // 2)
        big = im.resize((im.width * s, im.height * s), Image.NEAREST)
        x, y = 10 + (i % cols) * cell_w, 10 + (i // cols) * (cell_h + 18)
        sheet.alpha_composite(big, (x, y + (cell_h - 104) - big.height))
        sheet.alpha_composite(im, (x, y + cell_h - 100))  # 1x
        label(d, (x, y + cell_h + 2), os.path.basename(p)[:-4])
    sheet.save(out)
    print(out, sheet.size)


def lingshou():
    names = ["bambaer", "glutfasan", "qinglong"] + ids("lingshou") + [i["id"] for i in BATCH["derived"] if i.get("dir", "lingshou") == "lingshou"]
    paths = [os.path.join(A, "sprites", "lingshou", n + ".png") for n in names]
    grid_sheet(paths, os.path.join(ROOT, "build", "full_preview_lingshou.png"), 4, 7, 210, 310)


def chars():
    names = ["hero", "yao", "meister"] + ids("chars") + [i["id"] for i in BATCH["derived"] if i.get("dir") == "chars"]
    paths = [os.path.join(A, "sprites", "chars", n + ".png") for n in names]
    grid_sheet(paths, os.path.join(ROOT, "build", "full_preview_chars.png"), 4, 9, 150, 310)


def backgrounds():
    bgs = [os.path.join(A, "backgrounds", n + ".png") for n in ids("backgrounds")]
    bgs = [p for p in bgs if os.path.exists(p)]
    pair = [os.path.join(A, "sprites", "lingshou", n + ".png") for n in ("bambaer", "firnleopard")]
    W, H = 640, 360
    sheet = Image.new("RGBA", (2 * W + 30, ((len(bgs) + 1) // 2) * (H + 10) + 10), BG)
    for i, p in enumerate(bgs):
        im = Image.open(p).convert("RGBA")
        for j, sp in enumerate(pair):
            s = Image.open(sp).convert("RGBA")
            s = s.resize((s.width * 2, s.height * 2), Image.NEAREST)
            if j == 0:
                im.alpha_composite(s.transpose(Image.FLIP_LEFT_RIGHT), (120, 300 - s.height))
            else:
                im.alpha_composite(s, (430, 230 - s.height))
        sheet.alpha_composite(im, (10 + (i % 2) * (W + 10), 10 + (i // 2) * (H + 10)))
        label(ImageDraw.Draw(sheet), (16 + (i % 2) * (W + 10), 14 + (i // 2) * (H + 10)), os.path.basename(p)[:-4])
    out = os.path.join(ROOT, "build", "full_preview_backgrounds.png")
    sheet.save(out)
    print(out, sheet.size)


def raw(section, pattern="*"):
    files = sorted(glob.glob(os.path.join(ROOT, "build", "full_raw", section, pattern + ".png")))
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
    out = os.path.join(ROOT, "build", f"full_preview_raw_{section}.png")
    sheet.save(out)
    print(out, sheet.size)


if __name__ == "__main__":
    {"lingshou": lingshou, "chars": chars, "backgrounds": backgrounds}.get(sys.argv[1], lambda: raw(*sys.argv[2:]))()
