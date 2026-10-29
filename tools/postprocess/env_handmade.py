#!/usr/bin/env python3
"""Hand-drawn pixel sprites for props the diffusion route could not deliver at their tiny size
(items with "hand": true in tools/comfyui/env_assets.json). Colours from palette_env64.hex.

wind_chime 16x32: the Fengling of the story. Generated chimes became one green blob at 16 px
(tubes only 1-2 px apart), so it is drawn by hand: wooden disc, three bamboo tubes of different
lengths with nodes, a gold clapper and a red tassel.
"""
import numpy as np
from PIL import Image

CMAP = {
    "D": "1a1620", "s": "5e584c", "W": "d9b98a", "w": "9b6b40", "G": "9cc26a", "g": "5f9c46",
    "d": "3f7232", "n": "d6e29a", "c": "f6c453", "C": "fff2a8", "r": "a8382b", "R": "d8562f",
}

WIND_CHIME = [
    ".......DD.......",
    ".......s........",
    "..DDDDDDDDDDDD..",
    ".DWWWWWWWWWWWWD.",
    ".DwwwwwwwwwwwwD.",
    "..DDDDDDDDDDDD..",
    "...s...s....s...",
    "...s...s....s...",
    ".DDDD.DDDD.DDDD.",
    ".DGgD.DGgD.DGgD.",
    ".DGgD.DGgD.DGgD.",
    ".DGgD.DGgD.DGdD.",
    ".DnnD.DGgD.DnnD.",
    ".DGgD.DGgD.DGgD.",
    ".DGgD.DnnD.DGdD.",
    ".DGdD.DGgD.DDDD.",
    ".DnnD.DGgD......",
    ".DGgD.DGgD......",
    ".DDDD.DGdD......",
    "......DnnD......",
    "......DGgD......",
    "......DGdD......",
    "......DDDD......",
    ".......s........",
    "......DDDD......",
    "......DCcD......",
    "......DDDD......",
    "......DrrD......",
    ".....DRrrrD.....",
    ".....DRrrrD.....",
    ".....DRrRrD.....",
    "......DDDD......",
]


def draw(rows, cmap=CMAP):
    h, w = len(rows), len(rows[0])
    a = np.zeros((h, w, 4), np.uint8)
    for y, row in enumerate(rows):
        assert len(row) == w, (y, len(row))
        for x, ch in enumerate(row):
            if ch != ".":
                hx = cmap[ch]
                a[y, x] = (int(hx[0:2], 16), int(hx[2:4], 16), int(hx[4:6], 16), 255)
    return Image.fromarray(a, "RGBA")


def prayer_flags(w=64, h=24):
    """A sagging cord with eight small square flags in the five colours (blue, white, red, green,
    yellow), each with a light left edge, a dark right edge and a tiny emblem dot; cord loops on the
    ends so it can hang between two posts."""
    a = np.zeros((h, w, 4), np.uint8)

    def put(x, y, hx):
        if 0 <= x < w and 0 <= y < h:
            a[y, x] = (int(hx[0:2], 16), int(hx[2:4], 16), int(hx[4:6], 16), 255)

    sag = 8.0
    cord = lambda x: 2 + sag * (1 - ((x - (w - 1) / 2) / ((w - 1) / 2)) ** 2)
    for x in range(w):
        put(x, int(round(cord(x))), "5e584c")
    for x, y in ((0, 1), (0, 2), (1, 1), (w - 1, 1), (w - 1, 2), (w - 2, 1)):
        put(x, y, "3e2a1c")
    flags = [("6fa3d6", "b9dcf2", "3b6ea5"), ("f2ede0", "ffffff", "bfb6a4"), ("d8562f", "f08a3a", "a8382b"),
             ("5f9c46", "9cc26a", "3f7232"), ("f6c453", "fff2a8", "f08a3a")]
    n = 8
    for i in range(n):
        x0 = 3 + i * 7 + (1 if i >= n // 2 else 0)
        fw, fh = 6, 8
        fill, light, dark = flags[i % 5]
        top = int(round(cord(x0 + fw / 2))) + 1
        for yy in range(fh):
            for xx in range(fw):
                edge = xx in (0, fw - 1) or yy == fh - 1
                col = "1a1620" if edge else (light if xx == 1 else dark if xx == fw - 2 else fill)
                put(x0 + xx, top + yy, col)
        put(x0 + 2, top + 3, dark)
        put(x0 + 3, top + 3, dark)
        put(x0 + 2, top + 4, dark)
        put(x0 + 3, top + 4, dark)
        put(x0 + 1, top - 1, "1a1620")
        put(x0 + fw - 2, top - 1, "1a1620")
    return Image.fromarray(a, "RGBA")


SPRITES = {"wind_chime": WIND_CHIME, "prayer_flags": prayer_flags}


def handmade(pid):
    s = SPRITES[pid]
    return s() if callable(s) else draw(s)


# Five temple banners as one matching set: the silhouette of banner_yellow (side pole, swallowtail)
# with the flat cloth recoloured and given light/dark sides, an inner trim and a small round emblem.
BANNER_COLOURS = {
    "green": ("9cc26a", "5f9c46", "3f7232", "f6c453"),
    "red": ("d8562f", "a8382b", "6a2a22", "f6c453"),
    "yellow": ("fff2a8", "f6c453", "f08a3a", "a8382b"),
    "white": ("ffffff", "f2ede0", "bfb6a4", "f6c453"),
    "black": ("4a5560", "3a3046", "1a1620", "f6c453"),
}


def _rgb(h):
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], np.uint8)


def banner_recolor(src, colour, cloth_hex="f6c453"):
    a = np.array(src.convert("RGBA"))
    cloth = (a[:, :, 3] > 0) & (a[:, :, :3] == _rgb(cloth_hex)).all(-1)
    light, base, dark, trim = (_rgb(h) for h in BANNER_COLOURS[colour])
    out = a.copy()
    out[cloth, :3] = base
    ys = np.nonzero(cloth.any(1))[0]
    top = ys.min()
    for y in ys:
        xs = np.nonzero(cloth[y])[0]
        x0, x1 = xs.min(), xs.max()
        out[y, x0, :3] = light
        out[y, max(x0, x1 - 1):x1 + 1, :3] = dark
        if y > top + 1 and x1 - x0 >= 6:   # inner trim, 2 px inside the edges
            out[y, x0 + 2, :3] = trim
            out[y, x1 - 2, :3] = trim
    # trim line under the top hem and a round emblem in the upper third
    for y in (top + 2,):
        xs = np.nonzero(cloth[y])[0]
        out[y, xs.min() + 2:xs.max() - 1, :3] = trim
    h = ys.max() - top
    cy = top + h // 3
    xs = np.nonzero(cloth[cy])[0]
    cx = (xs.min() + xs.max()) // 2
    for dy, row in enumerate([".t.", "tlt", ".t."]):
        for dx, ch in enumerate(row):
            if ch != "." and cloth[cy - 1 + dy, cx - 1 + dx]:
                out[cy - 1 + dy, cx - 1 + dx, :3] = trim if ch == "t" else light
    return Image.fromarray(out, "RGBA")
