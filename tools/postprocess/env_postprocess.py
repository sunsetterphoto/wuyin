#!/usr/bin/env python3
"""Raw environment images (build/env_raw, from tools/comfyui/env_generate.py) -> game assets.

  ~/Documents/ComfyUI/.venv/bin/python tools/postprocess/env_postprocess.py [section ...] [--only id,id]

  tiles      -> game/assets/tiles/<id>.png      64x64, seamless (min-error boundary cut, both axes)
  props      -> game/assets/props/<id>.png      w x h from the batch, alpha cut, 1-px ink outline
  portraits  -> game/assets/portraits/<id>.png  96x96 bust, flush with the bottom edge

All three reduce colours the same way: k clusters of the image itself (median cut), every cluster
snapped to the nearest colour of palette_env64.hex (CIE Lab), then isolated single pixels are
replaced by their most common neighbour, so shapes stay clustered and readable.
Per-item options in tools/comfyui/env_assets.json:
  tiles:  crop (share of the 1024 image that becomes one tile, default 0.5), colors (default 10),
          sat / bright / contrast (tone tweaks before reduction), proc (procedural, see env_tiles_proc.py)
  props / portraits: colors (props: 10..22 by area / portraits 32), alpha (cut threshold 0..1, default 0.5),
          min_share (keep blobs >= share of the biggest, default 0.08), soft_alpha (keep 50 % alpha
          on edge pixels, for clouds), bg_thresh (background distance, default 60),
          sat / bright / contrast (tone tweaks before the palette), holes (also
          remove enclosed background pockets, for nets), raw_box [x0,y0,x1,y1] (crop the raw
          image first, e.g. above a generated frame)
"""
import argparse
import json
import os

import numpy as np
from PIL import Image, ImageEnhance
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
RAW = os.path.join(ROOT, "build", "env_raw")
ASSETS = os.path.join(ROOT, "game", "assets")
BATCH = os.path.join(ROOT, "tools", "comfyui", "env_assets.json")
PALETTE = os.path.join(HERE, "palette_env64.hex")
INK = (0x1a, 0x16, 0x20)


def load_palette(path=PALETTE):
    cols = []
    for line in open(path):
        parts = line.split()
        if parts and not line.startswith("#") and len(parts[0]) == 6:
            cols.append(tuple(int(parts[0][i:i + 2], 16) for i in (0, 2, 4)))
    return np.array(cols, dtype=np.float32)


PAL = load_palette()


def to_lab(rgb):
    """sRGB (0..255, shape (...,3)) -> CIE Lab (D65)."""
    c = np.asarray(rgb, dtype=np.float32) / 255.0
    c = np.where(c > 0.04045, ((c + 0.055) / 1.055) ** 2.4, c / 12.92)
    m = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]], dtype=np.float32)
    xyz = c @ m.T / np.array([0.95047, 1.0, 1.08883], dtype=np.float32)
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)


PAL_LAB = to_lab(PAL)


LAB_W = np.array([1.6, 1.0, 1.0], dtype=np.float32)  # lightness counts more: keeps light/dark ramps apart


def snap(rgb):
    """Nearest palette colour (weighted Lab distance) for an (N,3) array."""
    d = ((((to_lab(rgb)[:, None, :] - PAL_LAB[None, :, :]) * LAB_W) ** 2)).sum(-1)
    return PAL[d.argmin(1)]


def reduce_colors(rgb, k, mask=None, ramp=None, accent_dist=28.0):
    """rgb uint8 (H,W,3). k median-cut clusters of the (masked) pixels, each snapped to the palette."""
    h, w, _ = rgb.shape
    px = rgb.reshape(-1, 3) if mask is None else rgb[mask]
    strip = Image.fromarray(px.reshape(1, -1, 3).astype(np.uint8), "RGB")
    q = strip.quantize(colors=k, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    idx = np.array(q).reshape(-1)
    cent = np.array(q.getpalette()[:3 * k], dtype=np.float32).reshape(-1, 3)
    cent = cent[: max(idx.max() + 1, 1)]
    if ramp:
        mapped = ramp_map(cent, np.bincount(idx, minlength=len(cent)), ramp, accent_dist)[idx]
    else:
        mapped = snap(cent)[idx]
    out = rgb.copy()
    if mask is None:
        out = mapped.reshape(h, w, 3)
    else:
        out[mask] = mapped
    return out.astype(np.uint8)


def hexrgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def ramp_map(cent, counts, ramp, accent_dist):
    """Clusters whose hue (Lab a/b) lies near the ramp are spread over the ramp by lightness rank
    (pixel-weighted quantiles), so a flat texture keeps its light/dark clusters; other clusters
    (accents such as flowers or pebbles) snap to the full palette."""
    r = np.array([hexrgb(h) for h in ramp], dtype=np.float32)
    r = r[np.argsort(to_lab(r)[:, 0])]
    lab, rlab = to_lab(cent), to_lab(r)
    dab = np.sqrt(((lab[:, None, 1:] - rlab[None, :, 1:]) ** 2).sum(-1)).min(1)
    fam = dab < accent_dist
    out = snap(cent)
    if fam.any():
        order = np.argsort(lab[fam, 0])
        idxs = np.nonzero(fam)[0][order]
        c = counts[idxs].astype(np.float64)
        pos = (np.cumsum(c) - c / 2) / c.sum()
        out[idxs] = r[np.clip((pos * len(r)).astype(int), 0, len(r) - 1)]
    return out


def despeckle(rgb, mask=None, wrap=False, passes=2):
    """A pixel none of whose 8 neighbours shares its colour takes the most common neighbour colour."""
    a = rgb.copy()
    h, w, _ = a.shape
    if mask is None:
        mask = np.ones((h, w), bool)
    key = lambda arr: (arr[..., 0].astype(np.int64) << 16) | (arr[..., 1].astype(np.int64) << 8) | arr[..., 2]
    offs = [(dy, dx) for dy in (-1, 0, 1) for dx in (-1, 0, 1) if dy or dx]
    for _ in range(passes):
        k = key(a)
        k = np.where(mask, k, -1)
        mode = "wrap" if wrap else "edge"
        kp = np.pad(k, 1, mode=mode) if wrap else np.pad(k, 1, constant_values=-1)
        neigh = np.stack([kp[1 + dy:1 + dy + h, 1 + dx:1 + dx + w] for dy, dx in offs], 0)
        same = (neigh == k[None]).sum(0)
        lonely = (same == 0) & mask
        changed = 0
        for y, x in zip(*np.nonzero(lonely)):
            vals = neigh[:, y, x]
            vals = vals[vals >= 0]
            if len(vals) < 3:
                continue
            u, c = np.unique(vals, return_counts=True)
            best = u[c.argmax()]
            if c.max() >= 2:
                a[y, x] = ((best >> 16) & 255, (best >> 8) & 255, best & 255)
                changed += 1
        if not changed:
            break
    return a


# ---------------------------------------------------------------- tiles

def min_cut_wrap_h(a, ov):
    """a: (H, T+ov, C) float. Returns (H, T, C) whose left/right edges wrap: the first ov columns are
    stitched from the trailing overlap (cols T..T+ov) and the leading cols along a min-error path."""
    h, wtot, _ = a.shape
    t = wtot - ov
    left, right = a[:, :ov], a[:, t:t + ov]
    e = ((left - right) ** 2).sum(-1)
    m = e.copy()
    for i in range(1, h):
        prev = m[i - 1]
        best = np.minimum(prev, np.minimum(np.r_[np.inf, prev[:-1]], np.r_[prev[1:], np.inf]))
        m[i] += best
    path = np.zeros(h, int)
    path[-1] = int(m[-1].argmin())
    for i in range(h - 2, -1, -1):
        j = path[i + 1]
        lo, hi = max(0, j - 1), min(ov, j + 2)
        path[i] = lo + int(m[i, lo:hi].argmin())
    out = a[:, :t].copy()
    cols = np.arange(ov)[None, :]
    use_right = cols < path[:, None]
    out[:, :ov] = np.where(use_right[:, :, None], right, left)
    return out


def tone(img, item):
    if item.get("sat"):
        img = ImageEnhance.Color(img).enhance(item["sat"])
    if item.get("bright"):
        img = ImageEnhance.Brightness(img).enhance(item["bright"])
    if item.get("contrast"):
        img = ImageEnhance.Contrast(img).enhance(item["contrast"])
    return img


def make_tile(img, item, size=64, ov=16, work=4):
    img = img.convert("RGB")
    crop = item.get("crop", 0.5)
    side = int(min(img.size) * crop * (size + ov) / size)
    side = min(side, min(img.size))
    cx, cy = img.width // 2 + item.get("dx", 0), img.height // 2 + item.get("dy", 0)
    x0 = max(0, min(img.width - side, cx - side // 2))
    y0 = max(0, min(img.height - side, cy - side // 2))
    reg = img.crop((x0, y0, x0 + side, y0 + side)).resize((work * (size + ov),) * 2, Image.LANCZOS)
    reg = tone(reg, item)
    a = np.array(reg).astype(np.float32)
    a = min_cut_wrap_h(a, work * ov)                                     # left/right
    a = min_cut_wrap_h(a.transpose(1, 0, 2), work * ov).transpose(1, 0, 2)  # top/bottom
    small = Image.fromarray(a.clip(0, 255).astype(np.uint8)).resize((size, size), Image.BOX)
    # contrast before the palette snap: neighbouring clusters must not collapse into one colour
    for boost in (1.0, 1.25, 1.5, 1.8, 2.2):
        src = ImageEnhance.Contrast(small).enhance(boost * item.get("pre_contrast", 1.15))
        rgb = reduce_colors(np.array(src), item.get("colors", 10), ramp=item.get("ramp"),
                            accent_dist=item.get("accent_dist", 28.0))
        if len(np.unique(rgb.reshape(-1, 3), axis=0)) >= item.get("min_colors", 5):
            break
    return Image.fromarray(despeckle(rgb, wrap=True), "RGB")


# ---------------------------------------------------------------- sprites (props, portraits)

def cut_background(img, thresh=60, holes=False):
    """Background = median colour of the outer frame; remove everything near it that touches the border."""
    a = np.array(img.convert("RGB")).astype(np.float32)
    frame = np.concatenate([a[:6].reshape(-1, 3), a[-6:].reshape(-1, 3), a[:, :6].reshape(-1, 3), a[:, -6:].reshape(-1, 3)])
    bg = np.median(frame, 0)
    dist = np.sqrt(((a - bg) ** 2).sum(-1))
    near = dist < thresh
    lab, _ = ndimage.label(near)
    border = np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))
    border = border[border > 0]
    bgmask = np.isin(lab, border)
    if holes:
        # see-through objects (nets, lattices): enclosed background-coloured pockets go too
        sizes = ndimage.sum(np.ones_like(near), lab, range(1, lab.max() + 1))
        big = [i + 1 for i, s_ in enumerate(sizes) if s_ >= 12]
        bgmask |= np.isin(lab, big)
    # soft edge: pixels just inside the cut that are still close to bg get partial alpha
    alpha = np.where(bgmask, 0.0, 1.0)
    return a, alpha, bg, dist


def keep_blobs(alpha, min_share):
    lab, n = ndimage.label(alpha > 0.5)
    if n <= 1:
        return alpha
    sizes = ndimage.sum(np.ones_like(alpha), lab, range(1, n + 1))
    keep = [i + 1 for i, s in enumerate(sizes) if s >= sizes.max() * min_share]
    return np.where(np.isin(lab, keep), alpha, 0.0)


def make_sprite(img, w, h, item, default_colors=14, flush_bottom=False):
    if item.get("raw_box"):
        # cut the raw first, e.g. a portrait above a generated frame / text box
        img = img.crop(tuple(item["raw_box"]))
    a, alpha, bg, dist = cut_background(img, item.get("bg_thresh", 60), item.get("holes", False))
    if item.get("soft_alpha"):
        # clouds: alpha from the distance to the background colour (soft, semi-transparent edges)
        soft = np.clip(dist / (item.get("bg_thresh", 60) * 2.5), 0, 1)
        alpha = np.where(alpha > 0, np.maximum(soft, 0.0), 0.0)
        alpha = np.where(dist > item.get("bg_thresh", 60) * 2.5, 1.0, alpha)
    alpha = keep_blobs(alpha, item.get("min_share", 0.08))
    ys, xs = np.nonzero(alpha > 0.05)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    a, alpha = a[y0:y1, x0:x1], alpha[y0:y1, x0:x1]
    pad = 2
    iw, ih = w - pad, (h - 1 if flush_bottom else h - pad)
    scale = max(a.shape[1] / iw, a.shape[0] / ih)
    cw, ch = int(round(iw * scale)), int(round(ih * scale))
    canvas = np.zeros((ch, cw, 4), np.float32)
    ox = (cw - a.shape[1]) // 2
    oy = ch - a.shape[0]
    canvas[oy:oy + a.shape[0], ox:ox + a.shape[1], :3] = a * alpha[:, :, None]   # premultiplied
    canvas[oy:oy + a.shape[0], ox:ox + a.shape[1], 3] = alpha
    rs = lambda ch_: np.array(Image.fromarray(ch_.astype(np.float32), "F").resize((iw, ih), Image.BOX))
    al = rs(canvas[:, :, 3])
    rgb = np.stack([rs(canvas[:, :, c]) for c in range(3)], -1) / np.maximum(al, 1e-4)[:, :, None]
    rgb = rgb.clip(0, 255).astype(np.uint8)
    if item.get("sat") or item.get("bright") or item.get("contrast"):
        rgb = np.array(tone(Image.fromarray(rgb, "RGB"), item))
    cut = item.get("alpha", 0.5)
    mask = al >= cut
    rgb = reduce_colors(rgb, item.get("colors", default_colors), mask)
    rgb = despeckle(rgb, mask)
    out = np.zeros((h, w, 4), np.uint8)
    oy = 1
    out[oy:oy + ih, 1:1 + iw, :3] = rgb
    if item.get("soft_alpha"):
        lv = np.where(al >= 0.75, 255, np.where(al >= cut, 150, 0))
        out[oy:oy + ih, 1:1 + iw, 3] = np.where(mask, lv, 0)
    else:
        out[oy:oy + ih, 1:1 + iw, 3] = mask * 255
    solid = out[:, :, 3] > 0
    border = np.zeros_like(solid)
    border[1:, :] |= solid[:-1, :]
    border[:-1, :] |= solid[1:, :]
    border[:, 1:] |= solid[:, :-1]
    border[:, :-1] |= solid[:, 1:]
    border &= ~solid
    if item.get("holes"):
        # no ink inside see-through pockets: outline only where the transparent area reaches the edge
        lab, _ = ndimage.label(~solid)
        edge_ids = np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))
        border &= np.isin(lab, edge_ids[edge_ids > 0])
    if item.get("soft_alpha"):
        out[border] = (*[int(c) for c in item.get("outline_rgb", (0x9a, 0xa4, 0xab))], 120)
    else:
        out[border] = (*INK, 255)
    return Image.fromarray(out, "RGBA")


def save(img, *parts):
    dst = os.path.join(ASSETS, *parts)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    img.save(dst)
    n = len(np.unique(np.array(img.convert("RGBA")).reshape(-1, 4), axis=0))
    print(os.path.relpath(dst, ROOT), img.size, n, "colours", flush=True)


def raw(sec, item):
    return Image.open(os.path.join(RAW, sec, f'{item["id"]}_s{item["seed"]}.png'))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sections", nargs="*", default=["tiles", "props", "portraits"])
    ap.add_argument("--only", default="")
    args = ap.parse_args()
    batch = json.load(open(BATCH))
    only = set(filter(None, args.only.split(",")))
    for sec in args.sections:
        for item in batch[sec]:
            if only and item["id"] not in only:
                continue
            if item.get("skip"):
                continue
            try:
                if sec == "tiles":
                    if item.get("proc"):
                        from env_tiles_proc import procedural
                        img = procedural(item["id"], None, item)
                    else:
                        img = make_tile(raw(sec, item), item)
                    save(img, "tiles", item["id"] + ".png")
                elif sec == "props" and item.get("hand"):
                    from env_handmade import handmade
                    save(handmade(item["id"]), "props", item["id"] + ".png")
                elif sec == "props" and item.get("recolor"):
                    from env_handmade import banner_recolor
                    src = next(i for i in batch["props"] if i["id"] == item["from"])
                    k = max(10, min(22, src["w"] * src["h"] // 450))
                    base = make_sprite(raw(sec, src), src["w"], src["h"], src, src.get("colors", k))
                    save(banner_recolor(base, item["recolor"]), "props", item["id"] + ".png")
                elif sec == "props":
                    k = max(10, min(22, item["w"] * item["h"] // 450))   # more colours for big props
                    save(make_sprite(raw(sec, item), item["w"], item["h"], item, k), "props", item["id"] + ".png")
                elif sec == "portraits":
                    save(make_sprite(raw(sec, item), 96, 96, item, 32, flush_bottom=True), "portraits", item["id"] + ".png")
            except FileNotFoundError as e:
                print("missing raw", item["id"], e)


if __name__ == "__main__":
    main()
