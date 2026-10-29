"""Interiors: every inn, shop, teahouse, restaurant, home and some houses get
a cosy room behind their door. Runs after all outdoor maps are written
(build_maps.py calls apply()): reads the door tiles of the towns, writes one
interior map per door and rewires the town (door object enters the room, the
keeper standing outside moves in behind the counter, a spawn in front of the
door for leaving).

Furniture is data ("furniture": kind + rect) built by MapBuilder; small things
are props. Rooms are drawn in a cut-away view: back and side walls are high,
the front wall is low so the camera looks inside.
"""
import json, os
from grid import Grid, save, OUT

# Door event of the town -> (template, interior id suffix, keeper npc id moving inside)
SERVICE = {"_inn": "inn", "_shop": "shop", "_tea": "teahouse", "_food": "restaurant"}
TEMPLATES = {}


def template(name, w, h, furniture, props, keeper=None, objects=(), lights=((2, 1), (-3, 1))):
    TEMPLATES[name] = {"w": w, "h": h, "furniture": furniture, "props": props, "keeper": keeper, "objects": list(objects), "lights": lights}


# x, z are inside the room (walls at 0 and w-1 / h-1); negative x counts from the right wall.
template("inn", 13, 9,
         [("counter", 1, 2, 3, 1), ("shelf", 5, 1, 2, 1), ("bed", 9, 1, 2, 2), ("bed", 9, 4, 2, 2), ("rug", 4, 4, 4, 3), ("cushion", 4, 5, 1, 1)],
         [("tea_table", 5.5, 5.0), ("jar", 1.0, 6.0), ("bush_flowering", 11.0, 6.5, 0.8), ("lantern_stone", 7.6, 1.2, 0.8), ("wind_chime", 3.0, 1.2, 1.0, 1.1)],
         keeper=(2, 1), objects=[("chime", 7, 1)])
template("shop", 11, 8,
         [("shelf", 1, 1, 3, 1), ("shelf", 6, 1, 4, 1), ("counter", 2, 3, 7, 1)],
         [("barrel", 1.0, 5.5), ("crate", 9.0, 5.5), ("jars_group", 9.0, 6.4), ("basket_veg", 1.4, 6.4), ("jar", 4.5, 1.2, 0.8, 0.9),
          ("basket_veg", 2.5, 1.3, 0.8, 0.9)],
         keeper=(5, 2))
template("teahouse", 13, 9,
         [("counter", 1, 2, 4, 1), ("shelf", 1, 1, 4, 1), ("table", 7, 3, 1, 1), ("table", 10, 3, 1, 1), ("table", 7, 6, 1, 1),
          ("table", 10, 6, 1, 1), ("scroll", 7, 0, 1, 1), ("scroll", 10, 0, 1, 1), ("rug", 6, 2, 6, 6),
          ("cushion", 6, 3, 1, 1), ("cushion", 11, 3, 1, 1), ("cushion", 6, 6, 1, 1), ("cushion", 11, 6, 1, 1)],
         [("tea_table", 7.0, 3.0, 1.0, 0.55), ("tea_table", 10.0, 3.0, 1.0, 0.55), ("tea_table", 7.0, 6.0, 1.0, 0.55), ("tea_table", 10.0, 6.0, 1.0, 0.55),
          ("bush_tea", 1.0, 6.5), ("bush_flowering", 11.5, 1.4, 0.8), ("jars_group", 3.0, 1.3, 0.7, 0.95), ("bamboo_clump", 4.6, 6.8, 0.6),
          ("lantern_red", 8.5, 0.7, 0.7, 1.5), ("wind_chime", 5.5, 1.1, 1.0, 1.2)],
         keeper=(2, 1))
template("restaurant", 13, 9,
         [("stove", 9, 1, 3, 1), ("counter", 7, 3, 5, 1), ("table", 2, 3, 1, 1), ("table", 4, 5, 1, 1), ("table", 2, 6, 1, 1), ("shelf", 1, 1, 3, 1)],
         [("tea_table", 2.0, 3.0, 1.0, 0.55), ("tea_table", 4.0, 5.0, 1.0, 0.55), ("tea_table", 2.0, 6.0, 1.0, 0.55), ("jars_group", 6.5, 1.3),
          ("basket_veg", 11.5, 6.4), ("firewood", 7.0, 1.4, 0.8), ("barrel", 11.6, 5.2, 0.8), ("jar", 7.4, 6.6),
          ("lantern_red", 5.5, 0.7, 0.7, 1.5), ("bush_flowering", 1.0, 7.2, 0.7)],
         keeper=(10, 2))
template("home", 11, 8,
         [("bed", 8, 1, 2, 2), ("stove", 1, 1, 2, 1), ("chest", 4, 1, 1, 1), ("shelf", 5, 1, 2, 1), ("table", 2, 4, 2, 1), ("rug", 4, 3, 3, 3)],
         [("bush_flowering", 9.5, 5.6, 0.8), ("jar", 1.0, 5.8), ("wind_chime", 3.2, 1.2, 1.0, 1.15), ("cushion_jinli", 6.6, 2.3)],
         objects=[("bed", 8, 1)])
template("workshop", 13, 9,
         [("workbench", 2, 2, 4, 1), ("shelf", 1, 1, 4, 1), ("shelf", 8, 1, 4, 1), ("table", 9, 4, 2, 1)],
         [("wind_chime", 3.0, 1.1, 1.0, 1.4), ("wind_chime", 5.0, 1.1, 1.0, 1.4), ("wind_chime", 7.0, 1.1, 1.0, 1.4), ("wind_chime", 9.5, 1.1, 1.0, 1.4),
          ("wind_chime", 2.2, 5.0, 1.0, 1.3), ("wind_chime", 11.0, 5.5, 1.0, 1.3), ("firewood", 1.4, 6.5), ("crate", 11.2, 6.6), ("drum", 6.0, 6.0, 0.8)],
         objects=[("chimes", 4, 2)])
template("house", 10, 8,
         [("bed", 7, 1, 2, 2), ("table", 2, 3, 2, 1), ("shelf", 1, 1, 2, 1), ("stove", 4, 1, 2, 1)],
         [("bush_round", 8.4, 5.6, 0.7), ("jar", 1.0, 5.8), ("basket_veg", 2.0, 5.8)])
template("fisher", 10, 8,
         [("bed", 7, 1, 2, 2), ("table", 2, 3, 2, 1), ("stove", 1, 1, 2, 1)],
         [("fishing_net", 4.5, 1.2), ("barrel", 8.4, 5.4), ("jars_group", 1.2, 5.8), ("crate", 3.0, 6.2)])

template("hall", 15, 11,
         [("bells", 2, 1, 11, 1), ("cushion", 3, 4, 1, 1), ("cushion", 5, 4, 1, 1), ("cushion", 9, 4, 1, 1), ("cushion", 11, 4, 1, 1),
          ("cushion", 3, 6, 1, 1), ("cushion", 5, 6, 1, 1), ("cushion", 9, 6, 1, 1), ("cushion", 11, 6, 1, 1), ("pillar_grey", 1, 3, 1, 1),
          ("pillar_grey", 13, 3, 1, 1), ("pillar_grey", 1, 7, 1, 1), ("pillar_grey", 13, 7, 1, 1)],
         [("incense_burner", 7.0, 2.4), ("banner_white", 2.0, 1.3), ("banner_white", 12.0, 1.3), ("lantern_stone", 6.0, 8.6, 0.8),
          ("lantern_stone", 8.0, 8.6, 0.8)],
         lights=((4, 2), (-5, 2)))

# Map door object event -> template. Doors without an object get a plain house.
DOOR_KIND = {"hof_hut": "home", "home_door": "home", "work_door": "workshop", "inn_door": "inn", "shop_door": "shop",
             "teahouse": "teahouse", "kreuzweg_inn": "inn", "fischer": "fisher", "buergermeisterin": "house", "halle_tuer": "hall"}
# Keepers standing outside the service doors (they move inside).
KEEPERS = {"inn_door": "wirtin", "shop_door": "haendler", "teahouse": "teemeister", "kreuzweg_inn": "rast_wirt"}
NO_INTERIOR = set()
TOWN_MUSIC = {"hof": "farm", "weidendorf": "village"}
# People living in the houses (events in tools/story/systems.py).
RESIDENTS = {
    "weidendorf_house2": {"id": "opa_hu", "sprite": "elder", "at": [3, 3], "event": "res_opa_hu"},
    "weidendorf_house3": {"id": "herr_fang", "sprite": "man_c", "at": [5, 4], "event": "res_herr_fang"},
    "teeufer_house3": {"id": "pflueckerin_mei", "sprite": "girl_c", "at": [5, 4], "event": "res_pflueckerin"},
    "teeufer_house4": {"id": "opa_liu", "sprite": "elder", "at": [4, 5], "event": "res_opa_liu"},
    "rotfels_house": {"id": "hong_jun", "sprite": "villager_b", "at": [5, 5], "event": "res_hong_jun"},
    "nebelhafen_fisher": {"id": "frau_zhou", "sprite": "villager_a", "at": [5, 4], "event": "res_frau_zhou"},
    "mondquell_hall": {"id": "yao_order", "sprite": "yao_order", "at": [7, 5], "event": "halle_tuer", "unless": "yao_hall_done"},
}
# Rooms with an arrival scene.
ON_ENTER = {"mondquell_hall": {"event": "halle_tuer", "unless": "yao_hall_done"}}


def _kind_for(event):
    if event is None:
        return "house"
    if event in DOOR_KIND:
        return DOOR_KIND[event]
    for suffix, kind in SERVICE.items():
        if event.endswith(suffix):
            return kind
    return None


def _keeper_for(event, town):
    if event in KEEPERS:
        return KEEPERS[event]
    for suffix, role in [("_inn", "_wirt"), ("_shop", "_haendler"), ("_tea", "_teemeister"), ("_food", "_koch")]:
        if event and event.endswith(suffix):
            return event[: -len(suffix)] + role
    return None


def build_room(room_id, kind, parent, out_spawn, event, keeper_npc, region, music):
    tp = TEMPLATES[kind]
    w, h = tp["w"], tp["h"]
    g = Grid(w, h, "w")
    door_x = w // 2
    g.set(door_x, h - 1, "w")
    furniture = []
    for fk, fx, fz, fw, fd in tp["furniture"]:
        furniture.append({"kind": fk, "rect": [fx, fz, fw, fd]})
        if fk not in ("rug", "scroll", "cushion"):
            g.rect(fx, fz, fw, fd, "Y")
    decor = []
    for p in tp["props"]:
        e = {"prop": p[0], "at": [p[1], p[2]]}
        if len(p) > 3:
            e["scale"] = p[3]
        if len(p) > 4:
            e["y"] = p[4]
        decor.append(e)
    npcs, objects = [], []
    if keeper_npc and tp["keeper"]:
        kx, kz = tp["keeper"]
        npcs.append(dict(keeper_npc, at=[kx, kz]))
    for ok, ox, oz in tp["objects"]:
        if ok == "chime":
            objects.append({"id": room_id + "_chime", "kind": "chime", "at": [ox, oz], "event": event})
        elif ok == "bed":
            objects.append({"id": room_id + "_bed", "kind": "invisible", "at": [ox, oz + 1], "event": event})
        elif ok == "chimes":
            objects.append({"id": room_id + "_chimes", "kind": "invisible", "at": [ox, oz], "event": "furn_chimes"})
    for f in furniture:
        if f["kind"] == "shelf" and not any(o["at"] == f["rect"][:2] for o in objects):
            objects.append({"id": "%s_shelf_%d" % (room_id, f["rect"][0]), "kind": "invisible", "at": f["rect"][:2], "event": "furn_shelf_" + kind})
            break
    if kind == "home":
        objects.append({"id": room_id + "_cushion", "kind": "invisible", "at": [6, 2], "event": "furn_cushion", "solid": False})
    if room_id in RESIDENTS:
        npcs.append(dict(RESIDENTS[room_id]))
    lights = []
    for lx, lz in tp["lights"]:
        lights.append([lx if lx >= 0 else w + lx, lz])
    save(room_id, g, {
        "name": "MAP_ROOM_" + kind.upper(), "region": region, "indoor": True, "fixed_time": True, "time": "indoor",
        "music": music, "parent": parent,
        "spawns": {"door": [door_x, h - 2]},
        "warps": [{"rect": [door_x, h - 1, 1, 1], "to": parent, "spawn": out_spawn}],
        "furniture": furniture, "decor": decor, "npcs": npcs, "objects": objects, "lights": lights,
        "on_enter": ON_ENTER.get(room_id, []),
    })


def apply():
    made = []
    for path in sorted(os.listdir(OUT)):
        if not path.endswith(".json"):
            continue
        town = path[:-5]
        data = json.load(open(os.path.join(OUT, path)))
        if data.get("indoor"):
            continue
        rows = data["rows"]
        doors = [(x, z) for z, r in enumerate(rows) for x, c in enumerate(r) if c == "D"]
        if not doors:
            continue
        objects = data.setdefault("objects", [])
        npcs = data.setdefault("npcs", [])
        changed = False
        for i, (dx, dz) in enumerate(doors):
            obj = next((o for o in objects if o["at"] == [dx, dz]), None)
            event = obj["event"] if obj else None
            if event in NO_INTERIOR:
                continue
            kind = _kind_for(event)
            if kind is None:
                continue
            room_id = "%s_%s" % (town, kind if event else "house%d" % i)
            if any(m == room_id for m in made):
                room_id += str(i)
            out_spawn = room_id + "_out"
            data.setdefault("spawns", {})[out_spawn] = [dx, dz + 1]
            keeper_id = _keeper_for(event, town)
            keeper = None
            if keeper_id:
                keeper = next((n for n in npcs if n["id"] == keeper_id), None)
                if keeper:
                    npcs.remove(keeper)
            room_event = event or "furn_house"
            build_room(room_id, kind, town, out_spawn, room_event, keeper, data.get("region", "bamboo"),
                       TOWN_MUSIC.get(town, data.get("music", "town")))
            if obj is None:
                obj = {"id": "door_%d_%d" % (dx, dz), "kind": "invisible", "at": [dx, dz]}
                objects.append(obj)
            obj["enter"] = room_id
            obj["event"] = "enter_room"
            made.append(room_id)
            changed = True
        if changed:
            with open(os.path.join(OUT, path), "w") as f:
                json.dump(data, f, ensure_ascii=False, indent=1)
    print("interiors:", len(made))
