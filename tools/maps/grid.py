"""Grid drawing helpers for the map builders (see build_maps.py)."""
import json, os, sys

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "game", "data", "maps")


class Grid:
    def __init__(self, w, h, fill="."):
        self.w, self.h = w, h
        self.g = [[fill] * w for _ in range(h)]
        self.rect(0, 0, w, 1, "S"); self.rect(0, h - 1, w, 1, "S")
        self.rect(0, 0, 1, h, "S"); self.rect(w - 1, 0, 1, h, "S")

    def set(self, x, y, c):
        self.g[y][x] = c

    def rect(self, x, y, w, h, c):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.g[yy][xx] = c

    def house(self, x, y, w, h, door, kind="H"):
        self.rect(x, y, w, h, kind)
        self.set(x + door, y + h - 1, "D")
        return (x + door, y + h)  # tile in front of the door

    def hl(self, x1, x2, y, c="="):
        for x in range(min(x1, x2), max(x1, x2) + 1):
            self.g[y][x] = c

    def vl(self, x, y1, y2, c="="):
        for y in range(min(y1, y2), max(y1, y2) + 1):
            self.g[y][x] = c

    def dots(self, pts, c):
        for x, y in pts:
            self.g[y][x] = c

    def rows(self):
        return ["".join(r) for r in self.g]


def save(mid, grid, data):
    from decor import DECOR, CRITTERS, HEIGHTS
    data = dict(data)
    data["id"] = mid
    if mid in DECOR:
        data["decor"] = DECOR[mid]
    if mid in HEIGHTS:
        data["heights"] = HEIGHTS[mid]
    if mid in CRITTERS:
        data["npcs"] = data.get("npcs", []) + [dict(c, id="critter_%d" % i, solid=False) for i, c in enumerate(CRITTERS[mid])]
    data["rows"] = grid.rows()
    with open(os.path.join(OUT, mid + ".json"), "w") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
    if "--print" in sys.argv:
        print(f"== {mid} ({grid.w}x{grid.h})")
        for i, r in enumerate(data["rows"]):
            print(f"{i:2d} {r}")
