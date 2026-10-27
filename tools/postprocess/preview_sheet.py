#!/usr/bin/env python3
"""Contact sheet: sprites at 6x, tiles tiled 3x3 at 2x, on a dark background.
Usage: python preview_sheet.py <dir> <out.png> --sprites a b c --tiles grass path ..."""
import argparse, os
from PIL import Image

ap = argparse.ArgumentParser()
ap.add_argument("dir"); ap.add_argument("out")
ap.add_argument("--sprites", nargs="*", default=[]); ap.add_argument("--tiles", nargs="*", default=[])
args = ap.parse_args()
S = 6
w = max(20 + len(args.sprites) * (48 * S + 20), 20 + len(args.tiles) * 202)
sheet = Image.new("RGBA", (w, 48 * S + 192 + 60), (40, 34, 48, 255))
for i, s in enumerate(args.sprites):
    im = Image.open(os.path.join(args.dir, s + ".png")).resize((48 * S, 48 * S), Image.NEAREST)
    sheet.alpha_composite(im, (20 + i * (48 * S + 20), 10))
for i, t in enumerate(args.tiles):
    im = Image.open(os.path.join(args.dir, f"tile_{t}.png")).convert("RGBA")
    big = Image.new("RGBA", (96, 96))
    for x in range(3):
        for y in range(3):
            big.paste(im, (x * 32, y * 32))
    sheet.alpha_composite(big.resize((192, 192), Image.NEAREST), (20 + i * 202, 48 * S + 40))
sheet.save(args.out)
