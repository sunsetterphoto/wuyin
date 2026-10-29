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


SPRITES = {"wind_chime": WIND_CHIME}


def handmade(pid):
    return draw(SPRITES[pid])
