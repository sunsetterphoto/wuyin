#!/usr/bin/env python3
"""Procedural pixel-art tiles (64x64, seamless by construction: every noise field, Voronoi cell,
stamp and course wraps around the tile edges). Colours come only from palette_env64.hex.

Why procedural: downscaled diffusion textures turned into blotchy camouflage at 64 px (grass tufts,
mortar lines and roof rows dissolved). Hand-built SNES-style motifs (tufts, clovers, pebbles,
slabs, barrel tiles, nodes) stay crisp and clustered. Each tile is seeded (env_assets.json 'seed'),
so the output is reproducible.

  ~/Documents/ComfyUI/.venv/bin/python tools/postprocess/env_tiles_proc.py grass out.png   # one tile, for testing
"""
import sys

import numpy as np
from PIL import Image

N = 64


def C(h):
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.uint8)


# ---------------------------------------------------------------- helpers

class Tile:
    def __init__(self, base, seed):
        self.a = np.zeros((N, N, 3), np.uint8)
        self.a[:] = C(base)
        self.rng = np.random.default_rng(seed)
        self.seed = seed

    def px(self, x, y, col):
        self.a[int(y) % N, int(x) % N] = C(col) if isinstance(col, str) else col

    def get(self, x, y):
        return self.a[int(y) % N, int(x) % N]

    def stamp(self, x, y, rows, cmap):
        """rows: list of strings, '.' = keep; other chars looked up in cmap (hex)."""
        for dy, row in enumerate(rows):
            for dx, ch in enumerate(row):
                if ch != "." and ch != " ":
                    self.px(x + dx, y + dy, cmap[ch])

    def where(self, mask, col):
        self.a[mask] = C(col)

    def image(self):
        return Image.fromarray(self.a, "RGB")


def noise(seed, cells, octaves=((1.0, 1),)):
    """Periodic smooth value noise in 0..1. cells = grid cells across the tile for the first octave;
    octaves = ((amplitude, cell multiplier), ...)."""
    rng = np.random.default_rng(seed)
    y, x = np.mgrid[0:N, 0:N].astype(np.float32)
    total = np.zeros((N, N), np.float32)
    norm = 0
    cx, cy = (cells, cells) if isinstance(cells, int) else cells
    for amp, mul in octaves:
        gx, gy = cx * mul, cy * mul
        grid = rng.random((gy, gx)).astype(np.float32)
        u, v = x * gx / N, y * gy / N
        i0, j0 = np.floor(u).astype(int) % gx, np.floor(v).astype(int) % gy
        i1, j1 = (i0 + 1) % gx, (j0 + 1) % gy
        fu, fv = u - np.floor(u), v - np.floor(v)
        fu, fv = fu * fu * (3 - 2 * fu), fv * fv * (3 - 2 * fv)
        top = grid[j0, i0] * (1 - fu) + grid[j0, i1] * fu
        bot = grid[j1, i0] * (1 - fu) + grid[j1, i1] * fu
        total += amp * (top * (1 - fv) + bot * fv)
        norm += amp
    t = total / norm
    return (t - t.min()) / max(1e-6, t.max() - t.min())


def wrapd(a, b):
    d = np.abs(a - b)
    return np.minimum(d, N - d)


def voronoi(points, sx=1.0, sy=1.0):
    """Wrap-around Voronoi: returns (index of nearest point, d1, d2) per pixel. sx/sy stretch distances."""
    y, x = np.mgrid[0:N, 0:N].astype(np.float32)
    ds = np.stack([np.sqrt((wrapd(x, px) * sx) ** 2 + (wrapd(y, py) * sy) ** 2) for px, py in points], 0)
    order = np.argsort(ds, 0)
    d_sorted = np.take_along_axis(ds, order[:2], 0)
    return order[0], d_sorted[0], d_sorted[1]


def jitter_grid(rng, nx, ny, jit=0.35, stagger=False):
    pts = []
    for j in range(ny):
        for i in range(nx):
            ox = 0.5 if stagger and j % 2 else 0.0
            pts.append((((i + ox + 0.5 + rng.uniform(-jit, jit)) * N / nx) % N,
                        ((j + 0.5 + rng.uniform(-jit, jit)) * N / ny) % N))
    return pts


def scatter(rng, n, min_dist, avoid=(), tries=4000):
    """Wrap-aware Poisson-ish scatter."""
    pts = list(avoid)
    out = []
    for _ in range(tries):
        if len(out) >= n:
            break
        p = (rng.uniform(0, N), rng.uniform(0, N))
        if all(np.hypot(wrapd(p[0], q[0]), wrapd(p[1], q[1])) >= min_dist for q in pts):
            pts.append(p)
            out.append(p)
    return out


def shift(m, dx, dy):
    return np.roll(m, (dy, dx), axis=(0, 1))


def edge_of(mask):
    """Pixels of mask that touch a non-mask pixel (4-neighbourhood, wrapping)."""
    inner = mask & shift(mask, 1, 0) & shift(mask, -1, 0) & shift(mask, 0, 1) & shift(mask, 0, -1)
    return mask & ~inner


def smooth_mask(mask, passes=2):
    """Majority filter (wrap) to round off blob edges and kill single pixels."""
    m = mask.astype(np.int32)
    for _ in range(passes):
        s = sum(shift(m, dx, dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1))
        m = (s >= 5).astype(np.int32)
    return m.astype(bool)


# ---------------------------------------------------------------- motifs

TUFTS = [
    ["L...L", "D.L.D", ".DDD."],
    ["L.L...", "D.D.L.", ".DDLD.", "..DD.."],
    ["..L..", "L.D.L", "D.D.D", ".DDD."],
    [".L.L.", ".D.D.", "DD.DD"],
    ["L..", "D.L", ".DD"],
    ["..L", "L.D", "DD."],
]
CLOVER = [".ll.", "lHll", "llld", ".dd."]
CLOVER2 = [".l.", "lHl", ".d."]
FLOWER = [".p.", "pcp", ".p."]
FLOWER_SMALL = ["p.", ".p"]


def paint_grass(t, seed):
    """Two greens in soft patches, small sun flecks, blade tufts and clover clusters."""
    n = noise(seed, 4, ((1.0, 1), (0.5, 2)))
    t.where(smooth_mask(n < 0.33, 2), "4e8b3a")
    t.where(smooth_mask(n > 0.80, 2), "7db24e")
    # short dark strokes in the base (2 px, clustered, never single)
    for x, y in scatter(t.rng, 22, 6):
        t.stamp(x, y, ["d", "d"] if t.rng.random() < .6 else ["d.", ".d"], {"d": "4e8b3a"})
    tufts = scatter(t.rng, 15, 10)
    for i, (x, y) in enumerate(tufts):
        pat = TUFTS[i % len(TUFTS)]
        on_dark = (t.get(x + 2, y + 2) == C("4e8b3a")).all()
        t.stamp(x, y, pat, {"D": "2b4a2f" if on_dark else "3f7232", "L": "9cc26a" if not on_dark else "7db24e"})
    for x, y in scatter(t.rng, 5, 12, avoid=tufts):
        t.stamp(x, y, CLOVER if t.rng.random() < .6 else CLOVER2, {"l": "7db24e", "H": "d6e29a", "d": "3f7232"})
    return tufts


def paint_flowers(t, avoid, colors, count=9):
    for i, (x, y) in enumerate(scatter(t.rng, count, 9, avoid=avoid)):
        petal, centre = colors[i % len(colors)]
        t.stamp(x, y, FLOWER, {"p": petal, "c": centre})
        # little companion bloom
        t.stamp(x + 3 + int(t.rng.integers(0, 2)), y + 2 + int(t.rng.integers(0, 2)), FLOWER_SMALL, {"p": petal})
        t.px(x + 1, y + 3, "3f7232")


def pebble(t, x, y, w, h, base, light, dark, outline="5e584c"):
    for yy in range(h):
        for xx in range(w):
            corner = (xx in (0, w - 1)) and (yy in (0, h - 1))
            if corner and w > 2 and h > 1:
                continue
            col = base
            if yy == 0 or (xx == 0 and yy < h - 1):
                col = light
            if yy == h - 1 or xx == w - 1:
                col = dark
            t.px(x + xx, y + yy, col)
    # contact shadow under the pebble
    for xx in range(1, w):
        t.px(x + xx, y + h, outline)


# ---------------------------------------------------------------- tiles

def grass(seed):
    t = Tile("5f9c46", seed)
    paint_grass(t, seed)
    return t


def grass_flowers(seed, grass_seed=None):
    t = Tile("5f9c46", grass_seed or seed)
    tufts = paint_grass(t, grass_seed or seed)
    t.rng = np.random.default_rng(seed)
    paint_flowers(t, tufts, [("ffffff", "f6c453"), ("f7c9d4", "cd5f86"), ("f6c453", "f08a3a"), ("c9b2e0", "fff2a8"),
                             ("ffffff", "f6c453"), ("e8a3b5", "fff2a8")], 10)
    return t


def path(seed):
    t = Tile("a07a52", seed)
    n = noise(seed, 5, ((1.0, 1), (0.5, 2)))
    t.where(smooth_mask(n < 0.3, 2), "9b6b40")
    t.where(smooth_mask(n > 0.78, 2), "b8865a")
    # cracks: short wandering dark lines
    for x, y in scatter(t.rng, 4, 16):
        for k in range(int(t.rng.integers(4, 8))):
            t.px(x, y, "7a4e2d")
            x += 1
            y += int(t.rng.integers(-1, 2))
    stones = [("bfb6a4", "f2ede0", "8c8577"), ("8c8577", "bfb6a4", "5e584c"), ("d9b98a", "f7dcae", "b8865a"),
              ("9aa4ab", "d0d6d6", "6e7a86")]
    for i, (x, y) in enumerate(scatter(t.rng, 12, 8)):
        b, l, d = stones[i % len(stones)]
        w, h = [(3, 2), (4, 3), (3, 3), (5, 3), (2, 2)][i % 5]
        pebble(t, x, y, w, h, b, l, d, "7a4e2d")
    for x, y in scatter(t.rng, 10, 6):
        t.stamp(x, y, ["dd"] if t.rng.random() < .5 else ["d.", ".d"], {"d": "9b6b40"})
    for x, y in scatter(t.rng, 6, 9):
        t.stamp(x, y, ["ll"], {"l": "b8865a"})
    return t


def slab_floor(t, rows, greys, mortar, hi, lo, chips=True):
    """rows: list of (height, [widths]) summing to N each way; offsets come from the widths."""
    y = 0
    rng = t.rng
    for r, (h, widths) in enumerate(rows):
        x = int(rng.integers(0, 16)) if r else 0
        for w in widths:
            base = greys[int(rng.integers(0, len(greys)))]
            for yy in range(h):
                for xx in range(w):
                    col = base
                    if yy == h - 1 or xx == w - 1:
                        col = mortar
                    elif yy == 0 or xx == 0:
                        col = hi
                    elif yy == h - 2 or xx == w - 2:
                        col = lo
                    t.px(x + xx, y + yy, col)
            # wear: a chip on a corner or a short crack
            if chips and rng.random() < 0.5:
                cx, cy = x + int(rng.integers(2, max(3, w - 4))), y + int(rng.integers(2, max(3, h - 4)))
                for k in range(int(rng.integers(2, 5))):
                    t.px(cx + k, cy + (k // 2), lo)
            x += w
        y += h


def plaza(seed):
    t = Tile("d0d6d6", seed)
    rows = [(22, [22, 21, 21]), (21, [21, 22, 21]), (21, [21, 21, 22])]
    slab_floor(t, rows, ["d0d6d6", "d0d6d6", "c6d4e4", "c6d4e4", "bfb6a4"], "8c8577", "e4eef4", "9aa4ab")
    n = noise(seed + 1, 6)
    t.where(smooth_mask(n > 0.8, 1) & (t.a == C("d0d6d6")).all(-1), "c6d4e4")
    # moss in a few mortar joints
    for x, y in scatter(t.rng, 8, 10):
        if (t.get(x, y) == C("8c8577")).all():
            t.px(x, y, "9aa05a")
            t.px(x + 1, y, "6b7a3a")
    return t


def cobble(seed):
    t = Tile("5e584c", seed)
    pts = jitter_grid(t.rng, 6, 6, 0.3, stagger=True)
    idx, d1, d2 = voronoi(pts)
    stones = [("bfb6a4", "e4eef4", "8c8577"), ("9aa4ab", "d0d6d6", "6e7a86"), ("d9b98a", "f7dcae", "b8865a"),
              ("8c8577", "bfb6a4", "5e584c"), ("c6d4e4", "e4eef4", "9aa4ab")]
    y, x = np.mgrid[0:N, 0:N]
    for i, (px, py) in enumerate(pts):
        b, l, d = stones[int(t.rng.integers(0, len(stones)))]
        m = (idx == i) & (d2 - d1 > 1.6)
        dx = ((x - px + N / 2) % N) - N / 2
        dy = ((y - py + N / 2) % N) - N / 2
        t.where(m, b)
        t.where(m & ((dx + dy) < -3.5), l)
        t.where(m & ((dx + dy) > 3.5), d)
        t.where(m & (np.hypot(dx + 2, dy + 2) < 1.2), l)
    return t


def wood(seed):
    t = Tile("9b6b40", seed)
    rng = t.rng
    tones = [("9b6b40", "b8865a", "7a4e2d"), ("7a4e2d", "9b6b40", "553520"), ("a07a52", "b8865a", "7a4e2d")]
    for r in range(8):
        y0 = r * 8
        off = int(rng.integers(0, 64))
        for seg in range(2):
            x0 = off + seg * 32 + int(rng.integers(-4, 5)) * (seg)
            b, l, d = tones[int(rng.integers(0, len(tones)))]
            w = 32 if seg == 0 else 64 - (x0 - off)
            for yy in range(8):
                for xx in range(w):
                    col = b
                    if yy == 0:
                        col = l
                    if yy == 7:
                        col = "3e2a1c"
                    elif yy == 6:
                        col = d
                    t.px(x0 + xx, y0 + yy, col)
            t.px(x0, y0, "3e2a1c")
            for yy in range(1, 7):
                t.px(x0, y0 + yy, "553520")
            # grain streaks
            for _ in range(3):
                gx, gy = x0 + int(rng.integers(2, max(3, w - 10))), y0 + int(rng.integers(2, 6))
                for k in range(int(rng.integers(5, 12))):
                    t.px(gx + k, gy, d)
            # knot
            if rng.random() < 0.4:
                kx, ky = x0 + int(rng.integers(4, max(5, w - 6))), y0 + 3
                t.stamp(kx, ky - 1, [".d.", "dDd", ".d."], {"d": d, "D": "553520"})
            # nails near the plank start
            t.px(x0 + 2, y0 + 2, "3e2a1c")
            t.px(x0 + 2, y0 + 5, "3e2a1c")
    return t


def plaster(seed):
    t = Tile("f2ede0", seed)
    n = noise(seed, 5, ((1.0, 1), (0.5, 2)))
    t.where(smooth_mask(n < 0.12, 2), "f7dcae")
    for x, y in scatter(t.rng, 14, 8):
        t.stamp(x, y, ["ss"] if t.rng.random() < .5 else ["s", "s"], {"s": "e4eef4" if t.rng.random() < .5 else "f7dcae"})
    # hairline cracks
    for x, y in scatter(t.rng, 2, 26):
        for k in range(int(t.rng.integers(5, 9))):
            t.px(x, y, "d0d6d6")
            y += 1
            x += int(t.rng.integers(-1, 2)) if k % 2 else 0
    # one worn patch showing two bricks
    x, y = scatter(t.rng, 1, 1)[0]
    t.stamp(x, y, [".eeeee.", "ebbbdbbe", "ebdbbbde", ".eeeeee."], {"e": "e8d2a8", "b": "d9b98a", "d": "b8865a"})
    return t


def wall_timber(seed):
    """One storey of facade: thick lacquered beam on top, post on the left (repeats every 64 px =
    two game tiles), lime plaster panel, a little splash dirt at the bottom."""
    t = plaster(seed)
    lac_l, lac, lac_d, lac_dd = "d8562f", "a8382b", "6a2a22", "3e2a1c"
    beam = [lac_dd, lac_l, lac, lac, lac, lac_d, lac_d, lac_dd]
    for x in range(N):
        for y, col in enumerate(beam):
            t.px(x, y, col)
        t.px(x, 8, "bfb6a4")
        t.px(x, 9, "e8d2a8")
    post = [lac_dd, lac_l, lac, lac, lac, lac_d, lac_d, lac_dd]
    for y in range(8, N):
        for x, col in enumerate(post):
            t.px(x, y, col)
        t.px(8, y, "bfb6a4")
    # bracket under the beam, joint pins
    t.stamp(0, 8, ["DdddddddD.", ".DddddddD.", "..DDDDDD.."], {"D": lac_dd, "d": lac_d})
    for x in range(14, N, 16):
        t.stamp(x, 3, ["gG", "GG"], {"g": "fff2a8", "G": "f6c453"})
    # grain streaks on post and beam
    for y in range(12, N, 9):
        t.px(3, y, lac_d)
        t.px(3, y + 1, lac_d)
    for x in range(20, N, 13):
        t.px(x, 4, lac_d)
        t.px(x + 1, 4, lac_d)
    n = noise(seed + 9, 8)
    yy = np.arange(N)[:, None] * np.ones((1, N))
    xx = np.ones((N, 1)) * np.arange(N)[None, :]
    t.where(smooth_mask((yy > 57) & (n > 0.4), 1) & (xx > 8), "e8d2a8")
    return t


def roof(seed, ramp, glint=None, period=16, course=16):
    """Chinese barrel tiles, seen from above-front: an 11-px convex cover tile (lit left, dark right)
    and a 5-px concave pan channel per column; each 16-px course ends in a rounded tile lip with a
    shadow on the tile below, courses aligned so the roof reads in rows."""
    deep, dark, mid, light = ramp
    hi = glint or light
    t = Tile(dark, seed)
    rng = t.rng
    cover = [
        "DDDDDDDDDDD",
        "DdddddddddD",
        "DmlhmmmmmdD",
        "DmlhmmmmmdD",
        "DmllmmmmmdD",
        "DmllmmmmmdD",
        "DmllmmmmddD",
        "DmlmmmmmddD",
        "DmlmmmmmddD",
        "DmlmmmmmddD",
        "DmlmmmmmddD",
        "DmlmmmmmddD",
        "DmmmmmmmddD",
        "DmmmmmmdddD",
        ".DmmmmmddD.",
        "..DDDDDDD..",
    ]
    pan = ["DDDDD", "DdmdD", "DdmdD", "ddmdd", "ddmdd", "ddmdd", "ddmdd", "ddddd",
           "DDDDD", "ddmdd", "ddmdd", "ddmdd", "ddmdd", "ddmdd", "ddddd", "ddddd"]
    cmap = {"D": deep, "d": dark, "m": mid, "l": light, "h": hi}
    for c in range(N // period):
        x0 = c * period
        for y0 in range(0, N, course):
            t.stamp(x0, y0, pan, cmap)
            t.stamp(x0 + 5, y0, cover, cmap)
    # weathering: a few tiles slightly darker on the right half, a few chipped lips
    for x, y in scatter(rng, 5, 14):
        c, r = int(x) // period, int(y) // course
        for k in range(3, 9):
            t.px(c * period + 5 + 7, r * course + k, dark)
    return t


def roof_grey(seed):
    return roof(seed, ["3a3046", "4a5560", "6e7a86", "9aa4ab"], glint="d0d6d6")


def roof_red(seed):
    return roof(seed, ["3e2a1c", "6a2a22", "8f4632", "b5583c"], glint="e07a4e")


def roof_green(seed):
    return roof(seed, ["1d4f4a", "2a7d6f", "3fa894", "7fd1b9"], glint="c4ecd9")


def stone(seed):
    t = Tile("3a3046", seed)
    rng = t.rng
    heights = [11, 10, 12, 10, 11, 10]
    y = 0
    tones = [("bfb6a4", "e4eef4", "8c8577"), ("8c8577", "bfb6a4", "5e584c"), ("d9b98a", "f7dcae", "b8865a"),
             ("9aa4ab", "d0d6d6", "6e7a86"), ("a9b59c", "d0d6d6", "7f8f7a")]
    for r, h in enumerate(heights):
        x = int(rng.integers(0, 20))
        total = 0
        while total < N:
            w = int(rng.integers(10, 20))
            if N - total - w < 8:
                w = N - total
            b, l, d = tones[int(rng.integers(0, len(tones)))]
            hh = h - int(rng.integers(0, 2))
            for yy in range(hh - 1):
                for xx in range(w - 1):
                    corner = (xx in (0, w - 2)) and (yy in (0, hh - 2))
                    if corner:
                        continue
                    col = b
                    if yy == 0 or (xx == 0 and yy < hh - 3):
                        col = l
                    if yy >= hh - 3 or xx >= w - 2:
                        col = d
                    t.px(x + xx, y + yy, col)
            # moss on top of some stones
            if rng.random() < 0.3:
                mx = x + int(rng.integers(1, max(2, w - 6)))
                t.stamp(mx, y, ["gGGg", ".gg."], {"g": "6b7a3a", "G": "9aa05a"})
            x += w
            total += w
        y += h
    return t


def water(seed):
    t = Tile("4f9bb0", seed)
    n = noise(seed, (3, 8), ((1.0, 1), (0.4, 2)))
    t.where(smooth_mask(n < 0.27, 1), "2f6f8a")
    # ripple pairs: a long light dash with a shorter one below
    for x, y in scatter(t.rng, 12, 10):
        L = int(t.rng.integers(4, 8))
        on_dark = (t.get(x + 2, y) == C("2f6f8a")).all()
        for k in range(L):
            t.px(x + k, y, "4f9bb0" if on_dark else "7fd1b9")
        for k in range(2, L - 1):
            t.px(x + k + 2, y + 2, "6fa3d6" if on_dark else "b9dcf2")
    for x, y in scatter(t.rng, 3, 20):
        t.stamp(x, y, [".w.", "wWw", ".w."], {"w": "b9dcf2", "W": "ffffff"})
    return t


def sand(seed):
    t = Tile("d9b98a", seed)
    n = noise(seed, (3, 4), ((1.0, 1), (0.4, 2)))
    t.where(smooth_mask(n > 0.78, 2), "e8d2a8")
    rng = t.rng
    for i in range(7):
        y0 = i * (N / 7) + rng.uniform(-1, 1)
        ph = rng.uniform(0, 2 * np.pi)
        amp = rng.uniform(1.2, 2.2)
        k = int(rng.integers(1, 3))
        start = int(rng.integers(0, N))
        length = int(rng.integers(24, 50))
        for s in range(length):
            x = (start + s) % N
            y = y0 + amp * np.sin(2 * np.pi * k * x / N + ph)
            t.px(x, y, "b8865a")
            t.px(x, y + 1, "fbe9b7")
    for x, y in scatter(t.rng, 5, 12):
        t.stamp(x, y, ["oO"], {"o": "b8865a", "O": "9b6b40"})
    return t


def plates(t, pts, tones, gap, crack_p=0.0, inner=1.4):
    idx, d1, d2 = voronoi(pts)
    y, x = np.mgrid[0:N, 0:N]
    for i, (px, py) in enumerate(pts):
        b, l, d = tones[int(t.rng.integers(0, len(tones)))]
        m = (idx == i) & (d2 - d1 > inner)
        dx = ((x - px + N / 2) % N) - N / 2
        dy = ((y - py + N / 2) % N) - N / 2
        t.where(m, b)
        e = edge_of(m)
        t.where(e & (dy < 0), l)
        t.where(e & (dy > 0), d)
    t.where((d2 - d1) <= inner, gap)


def redrock(seed):
    t = Tile("b5583c", seed)
    pts = jitter_grid(t.rng, 4, 4, 0.4)
    plates(t, pts, [("b5583c", "e07a4e", "8f4632"), ("a8382b", "d8562f", "6a2a22"), ("b5583c", "f2b27a", "8f4632")],
           "6a2a22", inner=1.2)
    for x, y in scatter(t.rng, 12, 8):
        pebble(t, x, y, 2 + int(t.rng.integers(0, 2)), 2, "8f4632", "e07a4e", "6a2a22", "6a2a22")
    for x, y in scatter(t.rng, 8, 8):
        t.stamp(x, y, ["ll"], {"l": "e07a4e"})
    return t


def danxia(seed):
    """Horizontal rainbow strata (periodic in both axes), wavy band edges, erosion streaks."""
    t = Tile("b5583c", seed)
    rng = t.rng
    bands = [("a8382b", 6), ("b5583c", 5), ("d8562f", 4), ("e07a4e", 6), ("f2b27a", 4), ("f6c453", 3),
             ("f7dcae", 5), ("f2b27a", 3), ("e07a4e", 5), ("d8562f", 4), ("b5583c", 7), ("8f4632", 3),
             ("a8382b", 9)]
    total = sum(h for _, h in bands)
    scale = N / total
    x = np.arange(N)
    edges = []
    y = 0.0
    phases = [(rng.uniform(0, 6.28), rng.uniform(0.6, 1.6), int(rng.integers(1, 3))) for _ in bands]
    for (col, h), (ph, amp, k) in zip(bands, phases):
        edges.append((y, col, ph, amp, k))
        y += h * scale
    yy = np.arange(N)[:, None].astype(np.float32)
    # a pixel belongs to the last band whose wavy top edge lies above it
    lab = np.zeros((N, N), int)
    for i, (y0, col, ph, amp, k) in enumerate(edges):
        top = (y0 + amp * np.sin(2 * np.pi * k * x / N + ph))[None, :]
        lab = np.where(yy >= top, i, lab)
    # wrap: rows above the first wavy edge belong to the last band
    first_top = (edges[0][0] + edges[0][3] * np.sin(2 * np.pi * edges[0][4] * x / N + edges[0][2]))[None, :]
    lab = np.where(yy < first_top, len(edges) - 1, lab)
    for i, (_, col, *_r) in enumerate(edges):
        t.where(lab == i, col)
    # darker seam on each band's top edge
    up = shift(lab, 0, 1)
    seam = lab != up
    t.where(seam, "8f4632")
    # vertical erosion streaks and pits
    for sx, sy in scatter(rng, 6, 12):
        L = int(rng.integers(4, 10))
        for k in range(L):
            t.px(sx, sy + k, "8f4632" if k < L - 2 else "6a2a22")
    for sx, sy in scatter(rng, 6, 10):
        t.stamp(sx, sy, ["DD", "dD"], {"D": "6a2a22", "d": "8f4632"})
    for sx, sy in scatter(rng, 8, 9):
        t.stamp(sx, sy, ["ll"], {"l": "f2b27a"})
    return t


def karst(seed):
    t = Tile("a9b59c", seed)
    pts = jitter_grid(t.rng, 4, 4, 0.4)
    plates(t, pts, [("a9b59c", "d0d6d6", "7f8f7a"), ("bfb6a4", "d0d6d6", "8c8577"), ("9aa4ab", "d0d6d6", "7f8f7a")],
           "5e584c", inner=1.2)
    gap = (t.a == C("5e584c")).all(-1)
    n = noise(seed + 5, 4)
    # moss grows out of the cracks: dilate the gap where the noise is high
    grow = gap.copy()
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1)):
        grow |= shift(gap, dx, dy)
    moss = smooth_mask(grow & (n > 0.58), 1)
    t.where(moss, "6b7a3a")
    t.where(moss & ~shift(moss, 0, 1), "9aa05a")
    for x, y in scatter(t.rng, 6, 12):
        t.stamp(x, y, ["g.g", ".G."], {"g": "7db24e", "G": "6b7a3a"})
    return t


def cloudstone(seed):
    t = Tile("d0d6d6", seed)
    pts = jitter_grid(t.rng, 3, 3, 0.4)
    plates(t, pts, [("d0d6d6", "e4eef4", "9aa4ab"), ("d0d6d6", "e4eef4", "9aa4ab"), ("c6d4e4", "e4eef4", "9aa4ab")],
           "8c8577", inner=1.0)
    for x, y in scatter(t.rng, 30, 5):
        t.stamp(x, y, ["fF"] if t.rng.random() < .5 else ["f", "F"], {"f": "9aa4ab", "F": "bfb6a4"})
    for i, (x, y) in enumerate(scatter(t.rng, 9, 12)):
        col, rim = [("d6e29a", "9aa05a"), ("f2ede0", "a9b59c"), ("d6e29a", "9cc26a")][i % 3]
        big = [".rrr.", "rcccr", "rcRcr", "rcccr", ".rr.."]
        small = [".r.", "rcr", ".r."]
        t.stamp(x, y, big if i % 2 == 0 else small, {"r": rim, "c": col, "R": rim})
    return t


def paddy(seed):
    t = Tile("6fa3d6", seed)
    n = noise(seed, (2, 4), ((1.0, 1), (0.5, 2)))
    t.where(smooth_mask(n < 0.35, 2), "4f9bb0")
    for x, y in scatter(t.rng, 8, 10):
        for k in range(4):
            t.px(x + k, y, "b9dcf2")
    # seedling rows every 8 px, plants every 8 px, alternating offset
    for r in range(8):
        y0 = r * 8 + 1
        for c in range(8):
            x0 = c * 8 + (4 if r % 2 else 0) + int(t.rng.integers(0, 2))
            v = int(t.rng.integers(0, 3))
            pat = [["L.L.L", ".LgL.", ".dgd.", "..d.."], ["L..L.", ".LgLL", ".dgd.", "..d.."],
                   [".L..L", "LLgL.", ".dgd.", "..d.."]][v]
            t.stamp(x0, y0, pat, {"L": "9cc26a", "g": "5f9c46", "d": "3f7232"})
            t.stamp(x0 + 1, y0 + 4, ["rrr"], {"r": "4f9bb0"})  # reflection under the plant
    return t


def moss(seed):
    t = Tile("4e8b3a", seed)
    pts = jitter_grid(t.rng, 5, 5, 0.4)
    idx, d1, d2 = voronoi(pts)
    y, x = np.mgrid[0:N, 0:N]
    for i, (px, py) in enumerate(pts):
        dx = ((x - px + N / 2) % N) - N / 2
        dy = ((y - py + N / 2) % N) - N / 2
        m = (idx == i)
        t.where(m & (d2 - d1 < 1.5), "3f7232")
        t.where(m & (dy > 3) & (d2 - d1 >= 1.5), "3f7232")
        t.where(m & (np.hypot(dx + 1.5, dy + 1.5) < 3.2), "5f9c46")
        t.where(m & (np.hypot(dx + 2, dy + 2) < 1.6), "7db24e")
    for x0, y0 in scatter(t.rng, 7, 10):
        t.stamp(x0, y0, [".s.", "sSs"], {"s": "9cc26a", "S": "d6e29a"} if t.rng.random() < .5 else {"s": "9aa05a", "S": "9cc26a"})
    return t


def bamboo(seed):
    t = Tile("2b4a2f", seed)
    rng = t.rng
    for s in range(4):
        x0 = s * 16
        cols = ["1a1620", "2b4a2f", "3f7232", "9cc26a", "7db24e", "5f9c46", "5f9c46", "5f9c46", "4e8b3a", "4e8b3a",
                "3f7232", "3f7232", "2b4a2f", "1d4f4a", "1a1620", "1a1620"]
        for y in range(N):
            for k, col in enumerate(cols):
                t.px(x0 + k, y, col)
        y0 = int(rng.integers(0, 22))
        for ny in range(y0, y0 + N, 22):
            # node ring: bulge (light) over a dark groove
            for k in range(1, 14):
                t.px(x0 + k, ny, "d6e29a" if 2 < k < 8 else "9cc26a")
                t.px(x0 + k, ny + 1, "2b4a2f")
                t.px(x0 + k, ny - 1, "3f7232" if k > 9 else "7db24e")
            t.px(x0 + 0, ny, "2b4a2f")
            t.px(x0 + 14, ny, "2b4a2f")
        # faint vertical lines on the culm
        for _ in range(2):
            fx, fy = x0 + int(rng.integers(5, 10)), int(rng.integers(0, N))
            for k in range(int(rng.integers(5, 12))):
                t.px(fx, fy + k, "4e8b3a")
    return t


def clumps(t, pts, rad, ramp, edge_dark, sparkle=None, needle=False):
    """Canopy: round leaf clumps drawn from back (top) to front (bottom), lit from top-left.
    needle=True: radiating needle strokes instead of a smooth highlight."""
    deep, dark, mid, light = ramp
    y, x = np.mgrid[0:N, 0:N]
    for px, py in sorted(pts, key=lambda p: p[1]):
        r = rad + t.rng.uniform(-1.2, 1.5)
        dx = ((x - px + N / 2) % N) - N / 2
        dy = ((y - py + N / 2) % N) - N / 2
        ang = np.arctan2(dy, dx)
        scallop = 1 + (0.22 if needle else 0.12) * np.sin(ang * (11 if needle else 7) + t.rng.uniform(0, 6))
        d = np.hypot(dx, dy) / scallop
        m = d < r
        t.where(m, dark)
        t.where(m & (np.hypot(dx + r * 0.3, dy + r * 0.3) < r * 0.72), mid)
        if needle:
            for a in np.linspace(0, 2 * np.pi, 8, endpoint=False) + t.rng.uniform(0, 0.7):
                lit = np.sin(a) < 0.1
                for rr in np.arange(r * 0.25, r * 0.85, 1.0):
                    t.px(px + rr * np.cos(a), py + rr * np.sin(a), light if lit else deep)
        else:
            t.where(m & (np.hypot(dx + r * 0.42, dy + r * 0.42) < r * 0.34), light)
            if sparkle and t.rng.random() < 0.7:
                t.px(px - r * 0.45, py - r * 0.5, sparkle)
                t.px(px - r * 0.45 + 1, py - r * 0.5, sparkle)
        t.where(m & (d > r - 1.3) & (dy > 0), edge_dark)


def leaves(seed):
    t = Tile("2b4a2f", seed)
    pts = jitter_grid(t.rng, 5, 5, 0.35, stagger=True)
    clumps(t, pts, 7.0, ["1d4f4a", "3f7232", "5f9c46", "7db24e"], "2b4a2f", sparkle="9cc26a")
    # second pass of smaller clumps on top for depth
    clumps(t, scatter(t.rng, 7, 14), 4.5, ["1d4f4a", "4e8b3a", "7db24e", "9cc26a"], "3f7232", sparkle="d6e29a")
    return t


def pine(seed):
    t = Tile("2b4a2f", seed)
    pts = jitter_grid(t.rng, 5, 5, 0.35, stagger=True)
    clumps(t, pts, 7.5, ["2b4a2f", "1d4f4a", "2b4a2f", "3f7232"], "1a1620", needle=True)
    clumps(t, scatter(t.rng, 6, 15), 5.0, ["1d4f4a", "2b4a2f", "1d4f4a", "4e8b3a"], "1a1620", needle=True)
    return t


def snow(seed):
    t = Tile("e4eef4", seed)
    # drift crests: white rim above a soft blue shadow arc
    for x, y in scatter(t.rng, 7, 14):
        L = int(t.rng.integers(6, 11))
        for k in range(L):
            t.px(x + k, y + (1 if k in (0, L - 1) else 0), "c6d4e4")
            t.px(x + k, y - 1, "ffffff")
    for x, y in scatter(t.rng, 6, 10):
        t.stamp(x, y, ["ss"], {"s": "c6d4e4"})
    for x, y in scatter(t.rng, 4, 18):
        t.stamp(x, y, [".w.", "wWw", ".w."], {"w": "ffffff", "W": "b9dcf2"})
    return t


TILES = {f.__name__: f for f in [grass, grass_flowers, path, plaza, cobble, wood, plaster, wall_timber, roof_grey,
                                 roof_red, roof_green, stone, water, sand, redrock, danxia, karst, cloudstone, paddy,
                                 moss, bamboo, leaves, pine, snow]}


def procedural(tid, raw_img, item):
    seed = item.get("proc_seed", item["seed"])
    if tid == "grass_flowers":
        return grass_flowers(seed, item.get("grass_seed")).image()
    return TILES[tid](seed).image()


if __name__ == "__main__":
    tid = sys.argv[1]
    procedural(tid, None, {"seed": int(sys.argv[3]) if len(sys.argv) > 3 else 1}).save(sys.argv[2])
