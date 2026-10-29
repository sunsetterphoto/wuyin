#!/usr/bin/env python3
"""Preview sheets for the environment assets (build/env_preview_*.png).

  env_preview.py tiles      -> each tile 3x3 tiled at 2x (seams would show as lines) + 1x single tile
  env_preview.py props      -> every prop at 3x and 1x on a grass-coloured ground
  env_preview.py portraits  -> every portrait at 3x and 1x beside its overworld sprite (4x)
  env_preview.py scene      -> small mock village (tiles + props + characters at 1x and 2x)
  env_preview.py raw <sec>  -> raw generations, small
"""
import glob
import json
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
A = os.path.join(ROOT, "game", "assets")
BATCH = json.load(open(os.path.join(ROOT, "tools", "comfyui", "env_assets.json")))
BG = (92, 104, 112, 255)


def label(d, xy, text):
    d.text(xy, text, fill=(240, 232, 210, 255))


def ids(sec):
    return [i["id"] for i in BATCH[sec] if not i.get("skip")]


def tiles(only=None):
    names = [n for n in ids("tiles") if os.path.exists(os.path.join(A, "tiles", n + ".png")) and (not only or n in only)]
    cell_w, cell_h = 64 * 3 * 2 + 64 + 30, 64 * 3 * 2 + 24
    cols = 4
    rows = (len(names) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cell_w + 10, rows * cell_h + 10), BG)
    d = ImageDraw.Draw(sheet)
    for i, n in enumerate(names):
        t = Image.open(os.path.join(A, "tiles", n + ".png")).convert("RGBA")
        big = Image.new("RGBA", (192, 192))
        for y in range(3):
            for x in range(3):
                big.paste(t, (x * 64, y * 64))
        x0, y0 = 10 + (i % cols) * cell_w, 10 + (i // cols) * cell_h
        sheet.alpha_composite(big.resize((384, 384), Image.NEAREST), (x0, y0))
        sheet.alpha_composite(t, (x0 + 392, y0))
        label(d, (x0 + 392, y0 + 70), n)
    out = os.path.join(ROOT, "build", "env_preview_tiles.png")
    sheet.save(out)
    print(out, sheet.size)


def props(only=None):
    names = [n for n in ids("props") if os.path.exists(os.path.join(A, "props", n + ".png")) and (not only or n in only)]
    S = 3
    ims = [(n, Image.open(os.path.join(A, "props", n + ".png")).convert("RGBA")) for n in names]
    W = 1800
    x, y, rowh = 10, 10, 0
    pos = []
    for n, im in ims:
        w, h = im.width * S + im.width + 18, im.height * S + 16
        if x + w > W:
            x, y = 10, y + rowh + 8
            rowh = 0
        pos.append((n, im, x, y))
        x += w
        rowh = max(rowh, h)
    sheet = Image.new("RGBA", (W, y + rowh + 20), (150, 140, 124, 255))
    d = ImageDraw.Draw(sheet)
    for n, im, x, y in pos:
        sheet.alpha_composite(im.resize((im.width * S, im.height * S), Image.NEAREST), (x, y))
        sheet.alpha_composite(im, (x + im.width * S + 6, y + im.height * S - im.height))
        d.text((x, y + im.height * S + 2), n, fill=(20, 20, 30, 255))
    out = os.path.join(ROOT, "build", "env_preview_props.png" if not only else "env_preview_props_part.png")
    sheet.save(out)
    print(out, sheet.size)


def portraits():
    names = [n for n in ids("portraits") if os.path.exists(os.path.join(A, "portraits", n + ".png"))]
    S = 3
    cw = 96 * S + 96 + 32 * 4 + 40
    cols = 3
    rows = (len(names) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cw + 10, rows * (96 * S + 24) + 10), BG)
    d = ImageDraw.Draw(sheet)
    for i, n in enumerate(names):
        im = Image.open(os.path.join(A, "portraits", n + ".png")).convert("RGBA")
        x0, y0 = 10 + (i % cols) * cw, 10 + (i // cols) * (96 * S + 24)
        sheet.alpha_composite(im.resize((96 * S, 96 * S), Image.NEAREST), (x0, y0))
        sheet.alpha_composite(im, (x0 + 96 * S + 8, y0 + 96 * S - 96))
        sp = os.path.join(A, "sprites", "chars", n + ".png")
        if os.path.exists(sp):
            s = Image.open(sp).convert("RGBA")
            sheet.alpha_composite(s.resize((s.width * 4, s.height * 4), Image.NEAREST), (x0 + 96 * S + 110, y0))
        label(d, (x0, y0 + 96 * S + 4), n)
    out = os.path.join(ROOT, "build", "env_preview_portraits.png")
    sheet.save(out)
    print(out, sheet.size)


def scene():
    """Mock village 20x12 game tiles (32 px each, textures repeat every 2 tiles) to judge everything together."""
    T = lambda n: Image.open(os.path.join(A, "tiles", n + ".png")).convert("RGBA")
    P = lambda n: Image.open(os.path.join(A, "props", n + ".png")).convert("RGBA")
    W, H = 640, 384
    img = Image.new("RGBA", (W, H))

    def fill(name, x0, y0, x1, y1):
        t = T(name)
        for y in range(y0, y1, 64):
            for x in range(x0, x1, 64):
                img.alpha_composite(t.crop((0, 0, min(64, x1 - x), min(64, y1 - y))), (x, y))

    have = lambda n, d: os.path.exists(os.path.join(A, d, n + ".png"))
    fill("grass", 0, 0, W, H)
    if have("grass_flowers", "tiles"):
        fill("grass_flowers", 448, 256, 640, 384)
    if have("path", "tiles"):
        fill("path", 256, 0, 320, H)
    if have("plaza", "tiles"):
        fill("plaza", 64, 192, 256, 320)
    if have("water", "tiles"):
        fill("water", 448, 0, 640, 128)
    if have("roof_grey", "tiles") and have("wall_timber", "tiles"):
        fill("roof_grey", 64, 32, 256, 96)
        fill("wall_timber", 64, 96, 256, 160)
    if have("wood", "tiles"):
        fill("wood", 384, 32, 448, 96)
    placements = [("tree_willow", 470, 230), ("tree_round", 0, 150), ("tree_plum", 330, 130), ("tree_pine", 560, 230),
                  ("bamboo_clump", 10, 0), ("bush_round", 230, 200), ("bush_flowering", 330, 300), ("rock_moss", 600, 340),
                  ("lantern_stone", 70, 200), ("barrel", 200, 160), ("crate", 222, 166), ("jars_group", 120, 290),
                  ("stall", 330, 180), ("signpost", 290, 300), ("flowers_red", 500, 340), ("flowers_yellow", 530, 350),
                  ("lotus_pads", 500, 60), ("boat_small", 560, 70), ("reeds", 450, 110), ("chicken", 160, 340), ("duck", 470, 140),
                  ("lantern_red", 100, 140), ("lantern_red", 200, 140), ("laundry_line", 380, 300), ("well_bucket", 300, 350)]
    for n, x, y in sorted(placements, key=lambda p: p[2] + P(p[0]).height if have(p[0], "props") else 0):
        if have(n, "props"):
            im = P(n)
            img.alpha_composite(im, (x, y))
    chars = ["hero", "jinli", "villager_a", "meister"]
    for i, c in enumerate(chars):
        p = os.path.join(A, "sprites", "chars", c + ".png")
        if os.path.exists(p):
            im = Image.open(p).convert("RGBA")
            img.alpha_composite(im, (150 + i * 36, 250 - im.height + 48))
    out = os.path.join(ROOT, "build", "env_preview_scene.png")
    img.resize((W * 2, H * 2), Image.NEAREST).save(out)
    print(out)


def raw(sec):
    files = sorted(glob.glob(os.path.join(ROOT, "build", "env_raw", sec, "*.png")))
    th = 200
    cols = 8
    sheet = Image.new("RGBA", (cols * (th + 6) + 6, ((len(files) + cols - 1) // cols) * (th + 20) + 6), BG)
    d = ImageDraw.Draw(sheet)
    for i, f in enumerate(files):
        im = Image.open(f).convert("RGBA")
        im.thumbnail((th, th))
        x, y = 6 + (i % cols) * (th + 6), 6 + (i // cols) * (th + 20)
        sheet.alpha_composite(im, (x, y))
        label(d, (x, y + th + 4), os.path.basename(f)[:-4])
    out = os.path.join(ROOT, "build", f"env_preview_raw_{sec}.png")
    sheet.save(out)
    print(out, sheet.size)


if __name__ == "__main__":
    mode = sys.argv[1]
    rest = set(sys.argv[2:])
    if mode == "raw":
        raw(sys.argv[2])
    else:
        {"tiles": tiles, "props": props, "portraits": lambda only=None: portraits(), "scene": lambda only=None: scene()}[mode](rest or None)
