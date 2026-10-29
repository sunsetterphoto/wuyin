"""Maps after the Bamboo Sea: the crossroads hub, the four regions of the
middle game, the farm in Willowdale and the Phoenix Temple.

Imported by build_maps.py (shares Grid and save). Region ids: river (water,
Yu), ridge (fire, Zhi), dunes (metal, Shang), pillars (earth, Gong); the
tone of a region decides whether it is still silent (World.region_silent).
Event ids refer to tools/story/chapter2-4.py and systems.py.
"""
from grid import Grid, save


def town_services(prefix, inn_door, shop_door, tea_door, food_door, keeper_at, shop_at, tea_at, food_at, chime_at):
    """People and invisible door objects of the standard town buildings."""
    npcs = [
        {"id": prefix + "_wirt", "sprite": "innkeeper", "at": keeper_at, "event": prefix + "_inn"},
        {"id": prefix + "_haendler", "sprite": "shopkeeper", "at": shop_at, "event": prefix + "_shop"},
        {"id": prefix + "_teemeister", "sprite": "teahouse", "at": tea_at, "event": prefix + "_tea"},
        {"id": prefix + "_koch", "sprite": "cook", "at": food_at, "event": prefix + "_food"},
    ]
    objects = [
        {"id": prefix + "_inn_door", "kind": "invisible", "at": inn_door, "event": prefix + "_inn"},
        {"id": prefix + "_shop_door", "kind": "invisible", "at": shop_door, "event": prefix + "_shop"},
        {"id": prefix + "_tea_door", "kind": "invisible", "at": tea_door, "event": prefix + "_tea"},
        {"id": prefix + "_food_door", "kind": "invisible", "at": food_door, "event": prefix + "_food"},
        {"id": prefix + "_chime", "kind": "chime", "at": chime_at, "event": prefix + "_inn"},
    ]
    return npcs, objects


# --- Kreuzweg: crossroads at the foot of the Cloud Pillars ------------------------
g = Grid(36, 26)
g.rect(1, 1, 34, 3, "Q")
g.rect(16, 1, 4, 3, "c")                             # stone stairs up to the pillars
g.rect(4, 1, 4, 3, ".")                              # gap towards the misty river
g.rect(1, 4, 3, 6, "n"); g.rect(31, 4, 4, 5, "n")
g.hl(0, 35, 12); g.hl(0, 35, 13)                     # west-east road
g.vl(17, 0, 25); g.vl(18, 0, 25)                     # north-south road
g.vl(5, 0, 12); g.vl(6, 0, 12)                       # road north-west to the river
rest = g.house(21, 7, 5, 3, 2, "R")                  # rest house, door (23,9)
g.vl(23, 10, 11)
g.rect(8, 15, 6, 4, ","); g.rect(24, 16, 7, 4, ","); g.rect(8, 6, 5, 4, ","); g.rect(26, 20, 5, 3, ",")
g.dots([(3, 17), (14, 21), (30, 14), (11, 23), (22, 23)], "T")
g.dots([(2, 15), (20, 16), (33, 18), (13, 9), (28, 11)], "f")
g.dots([(16, 11), (19, 11)], "L")
save("kreuzweg", g, {
    "name": "MAP_KREUZWEG", "region": "hub", "time": "day", "music": "route", "battle_bg": "pillars", "border": "grass",
    "inn_spawn": "inn",
    "spawns": {"from_teeufer": [34, 12], "inn": [23, 10], "from_river": [5, 1], "from_ridge": [17, 24],
               "from_dunes": [1, 13], "from_pillars": [17, 4]},
    "warps": [
        {"rect": [35, 12, 1, 2], "to": "teeufer", "spawn": "from_crossroads"},
        {"rect": [5, 0, 2, 1], "to": "karstufer", "spawn": "from_crossroads"},
        {"rect": [17, 25, 2, 1], "to": "danxiapfad", "spawn": "from_crossroads"},
        {"rect": [0, 12, 1, 2], "to": "duenenweg", "spawn": "from_crossroads", "when": "nian_driven", "blocked_event": "order_block_west"},
        {"rect": [17, 0, 2, 1], "to": "saeulenpfad", "spawn": "from_crossroads", "when": "nian_driven", "blocked_event": "order_block_north"},
    ],
    "on_enter": {"event": "kreuzweg_arrive", "unless": "kreuzweg_arrived"},
    "npcs": [
        {"id": "rast_wirt", "sprite": "monk", "at": [25, 10], "event": "kreuzweg_inn"},
        {"id": "order_west", "sprite": "order_a", "at": [2, 12], "event": "order_block_west", "unless": "nian_driven"},
        {"id": "order_north", "sprite": "order_b", "at": [18, 4], "event": "order_block_north", "unless": "nian_driven"},
        {"id": "kreuz_haendler", "sprite": "trader", "at": [20, 14], "event": "kreuzweg_trader", "wander": 2},
    ],
    "objects": [
        {"id": "rest_door", "kind": "invisible", "at": [23, 9], "event": "kreuzweg_inn"},
        {"id": "kreuz_chime", "kind": "chime", "at": [20, 10], "event": "kreuzweg_inn"},
        {"id": "kreuz_sign", "kind": "sign", "at": [15, 11], "event": "kreuzweg_sign", "solid": False},
    ],
    "encounters": {"rate": 0.1, "table": [
        {"species": "nebelaffe", "levels": [10, 13], "weight": 2},
        {"species": "zirpo", "levels": [10, 13], "weight": 2},
        {"species": "goldkroete", "levels": [10, 13], "weight": 2},
        {"species": "lampionfalter", "levels": [10, 13], "weight": 1},
        {"species": "schattenmotte", "levels": [11, 13], "weight": 2, "night": True}]},
})

# --- Nebelfluss (water, Yu) ------------------------------------------------------
g = Grid(40, 22)
g.rect(1, 1, 38, 4, "~")                             # the still river along the north
g.rect(28, 1, 3, 4, "#")                             # wooden bridge towards the harbour
for x, y in [(3, 6), (7, 9), (12, 6), (15, 15), (22, 8), (26, 17), (33, 10), (36, 15), (4, 16), (10, 19), (35, 6)]:
    g.rect(x, y, 2, 2, "k")
g.vl(20, 9, 21); g.hl(20, 29, 9); g.vl(29, 0, 9); g.vl(30, 0, 9)
g.rect(1, 5, 9, 2, "q"); g.rect(14, 5, 6, 2, "q"); g.rect(31, 5, 7, 1, "q")
g.rect(5, 11, 6, 4, ","); g.rect(23, 12, 6, 4, ","); g.rect(31, 17, 5, 3, ","); g.rect(12, 16, 3, 4, ",")
g.dots([(18, 13), (25, 6), (2, 13), (37, 12)], "T")
g.dots([(17, 7), (34, 13), (8, 15)], "f")
g.rect(8, 3, 3, 2, "k"); g.set(9, 5, ".")            # the cormorant's cliff
save("karstufer", g, {
    "name": "MAP_KARSTUFER", "region": "river", "time": "day", "music": "river", "battle_bg": "karst", "border": "karst",
    "spawns": {"from_crossroads": [20, 20], "from_harbour": [29, 1]},
    "warps": [
        {"rect": [20, 21, 1, 1], "to": "kreuzweg", "spawn": "from_river"},
        {"rect": [29, 0, 2, 1], "to": "nebelhafen", "spawn": "from_route"},
    ],
    "on_enter": {"event": "karstufer_arrive", "unless": "karstufer_arrived"},
    "lingshou": [
        {"id": "silent_kormoran", "species": "perlkormoran", "role": "silenced", "at": [9, 5], "event": "silent_kormoran",
         "when": "quest_kormoran", "unless": "kormoran_done", "static": True},
        {"id": "w_bueffel", "species": "nebelbueffel", "at": [24, 14], "levels": [13, 14], "unless": "gone_w_bueffel"},
        {"id": "w_delfin", "species": "stromdelfin", "at": [16, 5], "levels": [12, 14], "unless": "gone_w_delfin"},
    ],
    "objects": [
        {"id": "chest_karst", "kind": "chest", "at": [37, 19], "event": "chest_karst", "unless": "chest_karst"},
    ],
    "encounters": {"rate": 0.12, "table": [
        {"species": "perlkormoran", "levels": [11, 14], "weight": 3},
        {"species": "stromdelfin", "levels": [11, 14], "weight": 2},
        {"species": "nebelbueffel", "levels": [12, 15], "weight": 2},
        {"species": "goldkroete", "levels": [11, 14], "weight": 2},
        {"species": "reisquak", "levels": [11, 13], "weight": 1},
        {"species": "schattenmotte", "levels": [12, 14], "weight": 2, "night": True}]},
})

g = Grid(34, 24)
g.rect(1, 1, 32, 6, "~")                             # the mist lake
g.vl(16, 1, 6, "#"); g.vl(17, 1, 6, "#")             # pier
inn = g.house(3, 9, 5, 3, 2, "R")                    # door (5,11)
shop = g.house(11, 9, 4, 3, 2)                       # door (13,11)
tea = g.house(23, 9, 5, 3, 2, "R")                   # door (25,11)
food = g.house(28, 15, 5, 3, 2)                      # door (30,17)
fisher = g.house(3, 15, 4, 3, 2)                     # door (5,17)
g.rect(12, 13, 11, 5, "_"); g.set(17, 15, "W")
g.hl(1, 32, 7); g.hl(1, 32, 8)
g.vl(5, 12, 12); g.vl(13, 12, 12); g.vl(25, 12, 12); g.vl(5, 18, 18); g.hl(5, 12, 18); g.vl(30, 18, 19); g.hl(22, 30, 19)
g.vl(17, 18, 23); g.vl(16, 18, 23)
g.dots([(12, 13), (22, 13), (12, 17), (22, 17), (9, 8), (21, 8)], "L")
g.dots([(2, 20), (10, 21), (24, 21), (31, 22)], "T")
g.dots([(8, 12), (19, 20), (27, 13)], "f")
npcs, objects = town_services("nebelhafen", [5, 11], [13, 11], [25, 11], [30, 17], [7, 12], [15, 12], [27, 12], [32, 18], [8, 11])
save("nebelhafen", g, {
    "name": "MAP_NEBELHAFEN", "region": "river", "time": "day", "music": "river", "battle_bg": "karst", "border": "karst",
    "inn_spawn": "inn", "town": True,
    "spawns": {"from_route": [16, 22], "inn": [5, 12], "dock": [16, 7]},
    "warps": [
        {"rect": [16, 23, 2, 1], "to": "karstufer", "spawn": "from_harbour"},
        {"rect": [16, 1, 2, 1], "to": "schildkroetenbucht", "spawn": "from_boat", "when": "has_boat", "blocked_event": "boat_missing"},
    ],
    "on_enter": {"event": "nebelhafen_arrive", "unless": "nebelhafen_arrived"},
    "npcs": npcs + [
        {"id": "fischer", "sprite": "fisher", "at": [7, 17], "event": "fischer"},
        {"id": "bootsfrau", "sprite": "boatwoman", "at": [18, 7], "event": "bootsfrau"},
        {"id": "hafen_kind", "sprite": "girl_c", "at": [19, 16], "event": "hafen_kind", "wander": 2},
        {"id": "hafen_alter", "sprite": "elder", "at": [10, 15], "event": "hafen_alter"},
    ],
    "objects": objects + [
        {"id": "fisher_door", "kind": "invisible", "at": [5, 17], "event": "fischer"},
    ],
})

g = Grid(30, 20, "s")
g.rect(1, 1, 28, 2, "~"); g.rect(1, 3, 3, 15, "~"); g.rect(26, 3, 3, 15, "~"); g.rect(1, 18, 12, 1, "~"); g.rect(17, 18, 12, 1, "~")
g.vl(14, 16, 19, "#"); g.vl(15, 16, 19, "#")         # landing stage
for x, y in [(5, 4), (8, 8), (20, 4), (22, 9), (5, 13), (23, 14)]:
    g.rect(x, y, 2, 2, "k")
g.rect(10, 3, 10, 6, "_")                             # tortoise terrace
g.rect(12, 10, 6, 1, "k"); g.rect(12, 10, 2, 1, "k"); g.set(14, 10, "="); g.set(15, 10, "=")
g.vl(14, 11, 15); g.vl(15, 11, 15)
g.dots([(10, 3), (19, 3)], "L")
g.rect(5, 15, 4, 2, "q"); g.rect(20, 11, 4, 2, "q")
save("schildkroetenbucht", g, {
    "name": "MAP_SCHILDKROETENBUCHT", "region": "river", "time": "day", "music": "river", "battle_bg": "karst", "border": "karst",
    "spawns": {"from_boat": [14, 15]},
    "warps": [{"rect": [14, 19, 2, 1], "to": "nebelhafen", "spawn": "dock"}],
    "on_enter": {"event": "bucht_arrive", "unless": "bucht_arrived"},
    "npcs": [
        {"id": "order_bucht", "sprite": "order_a", "at": [14, 11], "event": "order_bucht", "unless": "order_bucht_done"},
        {"id": "muschelfrau", "sprite": "villager_a", "at": [18, 14], "event": "muschelfrau"},
        {"id": "xuanwu_free", "lingshou": "xuanwu", "at": [14, 5], "event": "xuanwu_free", "when": "tone_yu", "scale": 1.3},
    ],
    "lingshou": [
        {"id": "boss_xuanwu", "species": "xuanwu", "role": "silenced", "at": [14, 5], "event": "boss_xuanwu", "unless": "tone_yu",
         "scale": 1.3, "static": True},
    ],
    "triggers": [{"rect": [11, 7, 8, 2], "event": "boss_xuanwu", "unless": "tone_yu"},
                 {"rect": [13, 12, 4, 1], "event": "order_bucht", "unless": "order_bucht_done", "once": False}],
})

# --- Regenbogengrat (fire, Zhi) ---------------------------------------------------
g = Grid(40, 22, "h")
for x, y, w, h in [(1, 1, 8, 3), (12, 1, 6, 2), (24, 1, 15, 3), (1, 7, 3, 6), (8, 8, 5, 2), (27, 7, 4, 4), (35, 8, 4, 6),
                   (1, 16, 6, 5), (14, 13, 4, 3), (30, 17, 9, 4), (22, 15, 3, 3)]:
    g.rect(x, y, w, h, "y")
g.vl(20, 0, 21); g.vl(19, 0, 21)
g.rect(4, 4, 5, 3, "v"); g.rect(23, 5, 4, 4, "v"); g.rect(9, 15, 4, 4, "v"); g.rect(31, 13, 3, 3, "v"); g.rect(25, 19, 4, 2, "v")
g.rect(9, 11, 6, 2, "b")                              # saplings in the burnt forest
g.dots([(10, 10), (13, 10), (16, 11)], ".")
g.dots([(33, 5), (14, 4), (6, 14)], "f")
save("danxiapfad", g, {
    "name": "MAP_DANXIAPFAD", "region": "ridge", "time": "day", "music": "ridge", "battle_bg": "danxia", "border": "redrock",
    "spawns": {"from_crossroads": [19, 1], "from_town": [19, 20]},
    "warps": [
        {"rect": [19, 0, 2, 1], "to": "kreuzweg", "spawn": "from_ridge"},
        {"rect": [19, 21, 2, 1], "to": "rotfels", "spawn": "from_route"},
    ],
    "on_enter": {"event": "danxiapfad_arrive", "unless": "danxiapfad_arrived"},
    "npcs": [
        {"id": "foerster", "sprite": "man_c", "at": [12, 13], "event": "foerster"},
    ],
    "lingshou": [
        {"id": "w_panda", "species": "glutpanda", "at": [24, 6], "levels": [12, 14], "unless": "gone_w_panda"},
        {"id": "w_falter", "species": "lampionfalter", "at": [6, 5], "levels": [12, 13], "unless": "gone_w_falter"},
    ],
    "objects": [{"id": "chest_danxia", "kind": "chest", "at": [37, 15], "event": "chest_danxia", "unless": "chest_danxia"}],
    "encounters": {"rate": 0.12, "table": [
        {"species": "glutpanda", "levels": [11, 14], "weight": 3},
        {"species": "funkenechse", "levels": [11, 14], "weight": 3},
        {"species": "lampionfalter", "levels": [11, 14], "weight": 2},
        {"species": "glutfasan", "levels": [12, 15], "weight": 1},
        {"species": "rollschupp", "levels": [12, 15], "weight": 1},
        {"species": "schattenmotte", "levels": [12, 14], "weight": 2, "night": True}]},
})

g = Grid(34, 22, "h")
g.rect(1, 1, 32, 2, "y"); g.rect(1, 3, 2, 18, "y"); g.rect(31, 3, 2, 18, "y")
inn = g.house(4, 4, 5, 3, 2, "R")                    # door (6,6)
shop = g.house(11, 4, 4, 3, 2)                       # door (13,6)
tea = g.house(21, 4, 5, 3, 2, "R")                   # door (23,6)
food = g.house(26, 12, 4, 3, 1)                      # door (27,14)
mayor = g.house(4, 13, 5, 3, 2, "R")                 # door (6,15)
g.rect(11, 9, 12, 5, "_"); g.set(16, 11, "W")
g.hl(3, 30, 7); g.hl(3, 30, 8)
g.vl(16, 0, 8); g.vl(17, 0, 8); g.vl(16, 14, 21); g.vl(17, 14, 21)
g.vl(6, 16, 17); g.hl(6, 16, 17); g.vl(27, 15, 16); g.hl(17, 27, 16)
g.rect(20, 17, 4, 2, "y")                             # the old kiln
g.dots([(11, 9), (22, 9), (11, 13), (22, 13)], "L")
g.dots([(9, 19), (25, 19), (29, 9)], "f")
npcs, objects = town_services("rotfels", [6, 6], [13, 6], [23, 6], [27, 14], [8, 7], [15, 7], [25, 7], [29, 15], [9, 6])
save("rotfels", g, {
    "name": "MAP_ROTFELS", "region": "ridge", "time": "day", "music": "town", "battle_bg": "danxia", "border": "redrock",
    "inn_spawn": "inn", "town": True,
    "spawns": {"from_route": [16, 1], "inn": [6, 7], "from_peak": [16, 20]},
    "warps": [
        {"rect": [16, 0, 2, 1], "to": "danxiapfad", "spawn": "from_town"},
        {"rect": [16, 21, 2, 1], "to": "feuergipfel", "spawn": "from_town"},
    ],
    "on_enter": {"event": "rotfels_arrive", "unless": "rotfels_arrived"},
    "npcs": npcs + [
        {"id": "buergermeisterin", "sprite": "villager_a", "at": [8, 16], "event": "buergermeisterin"},
        {"id": "toepfer", "sprite": "man_c", "at": [19, 17], "event": "toepfer"},
        {"id": "rotfels_kind", "sprite": "villager_b", "at": [14, 12], "event": "rotfels_kind", "wander": 2},
    ],
    "objects": objects + [{"id": "mayor_door", "kind": "invisible", "at": [6, 15], "event": "buergermeisterin"}],
})

g = Grid(26, 20, "h")
g.rect(1, 1, 24, 2, "y"); g.rect(1, 3, 4, 16, "y"); g.rect(21, 3, 4, 16, "y")
g.rect(8, 3, 10, 6, "_")
g.rect(5, 12, 3, 3, "y"); g.rect(18, 12, 3, 3, "y")
g.vl(12, 9, 19); g.vl(13, 9, 19)
g.dots([(8, 3), (17, 3)], "L")
g.rect(6, 16, 4, 2, "v"); g.rect(16, 16, 4, 2, "v")
save("feuergipfel", g, {
    "name": "MAP_FEUERGIPFEL", "region": "ridge", "time": "dusk", "music": "ridge", "battle_bg": "danxia", "border": "redrock",
    "spawns": {"from_town": [12, 18]},
    "warps": [{"rect": [12, 19, 2, 1], "to": "rotfels", "spawn": "from_peak"}],
    "on_enter": {"event": "gipfel_arrive", "unless": "gipfel_arrived"},
    "npcs": [
        {"id": "order_gipfel", "sprite": "order_b", "at": [12, 11], "event": "order_gipfel", "unless": "order_gipfel_done"},
        {"id": "einsiedler", "sprite": "monk", "at": [15, 15], "event": "einsiedler"},
        {"id": "bifang_free", "lingshou": "bifang", "at": [12, 5], "event": "bifang_free", "when": "tone_zhi", "scale": 1.3},
    ],
    "lingshou": [
        {"id": "boss_bifang", "species": "bifang", "role": "silenced", "at": [12, 5], "event": "boss_bifang", "unless": "tone_zhi",
         "scale": 1.3, "static": True},
    ],
    "triggers": [{"rect": [9, 7, 8, 2], "event": "boss_bifang", "unless": "tone_zhi"},
                 {"rect": [11, 12, 4, 1], "event": "order_gipfel", "unless": "order_gipfel_done", "once": False}],
})

# --- Singende Dünen (metal, Shang) ------------------------------------------------
g = Grid(40, 22, "s")
for x, y, w, h in [(2, 2, 6, 3), (12, 1, 9, 2), (26, 2, 7, 3), (3, 15, 5, 4), (14, 16, 6, 3), (30, 15, 8, 4), (21, 7, 4, 3)]:
    g.rect(x, y, w, h, "m")
g.hl(0, 39, 10); g.hl(0, 39, 11)
g.rect(9, 5, 6, 4, "z"); g.rect(28, 7, 5, 3, "z"); g.rect(8, 13, 5, 3, "z"); g.rect(22, 13, 6, 3, "z")
g.dots([(35, 4), (18, 5)], "T")
save("duenenweg", g, {
    "name": "MAP_DUENENWEG", "region": "dunes", "time": "day", "music": "dunes", "battle_bg": "dunes", "border": "sand",
    "spawns": {"from_crossroads": [38, 10], "from_town": [1, 10]},
    "warps": [
        {"rect": [39, 10, 1, 2], "to": "kreuzweg", "spawn": "from_dunes"},
        {"rect": [0, 10, 1, 2], "to": "mondquell", "spawn": "from_route"},
    ],
    "on_enter": {"event": "duenenweg_arrive", "unless": "duenenweg_arrived"},
    "npcs": [{"id": "karawane", "sprite": "trader", "at": [20, 12], "event": "karawane"}],
    "lingshou": [
        {"id": "w_kamel", "species": "glockenkamel", "at": [30, 12], "levels": [23, 24], "unless": "gone_w_kamel"},
        {"id": "w_adler", "species": "messingadler", "at": [12, 7], "levels": [23, 25], "unless": "gone_w_adler"},
    ],
    "objects": [{"id": "chest_duenen", "kind": "chest", "at": [36, 20], "event": "chest_duenen", "unless": "chest_duenen"}],
    "encounters": {"rate": 0.12, "table": [
        {"species": "glockenkamel", "levels": [22, 25], "weight": 2},
        {"species": "duenenspringer", "levels": [22, 25], "weight": 3},
        {"species": "messingadler", "levels": [23, 26], "weight": 2},
        {"species": "firnleopard", "levels": [23, 26], "weight": 1},
        {"species": "goldkroete", "levels": [22, 24], "weight": 1},
        {"species": "schattenmotte", "levels": [23, 25], "weight": 2, "night": True}]},
})

g = Grid(34, 24, "s")
g.rect(1, 1, 32, 2, "m"); g.rect(1, 21, 32, 2, "m")
# the crescent spring
for x, y, w in [(14, 5, 3), (12, 6, 3), (11, 7, 2), (11, 8, 2), (11, 9, 2), (12, 10, 3), (14, 11, 3)]:
    g.rect(x, y, w, 1, "~")
g.dots([(15, 7), (16, 8), (15, 9)], "T")
inn = g.house(3, 4, 5, 3, 2, "R")                    # door (5,6)
shop = g.house(3, 13, 4, 3, 2)                       # door (5,15)
tea = g.house(20, 4, 5, 3, 2, "R")                   # door (22,6)
food = g.house(26, 13, 4, 3, 1)                      # door (27,15)
hall = g.house(18, 14, 6, 4, 3, "O")                 # the Hall of Silence, door (21,17)
g.hl(1, 32, 11) if False else None
g.hl(1, 33, 18); g.hl(1, 33, 19)
g.vl(5, 7, 12); g.hl(5, 10, 12); g.vl(22, 7, 13); g.vl(5, 16, 17); g.vl(27, 16, 17); g.vl(21, 18, 18)
g.vl(17, 3, 4); g.vl(17, 0, 2); g.vl(18, 0, 2); g.hl(17, 22, 3)
g.dots([(9, 17), (30, 9), (25, 9)], "f")
g.dots([(10, 4), (25, 11)], "L")
npcs, objects = town_services("mondquell", [5, 6], [5, 15], [22, 6], [27, 15], [7, 7], [7, 16], [24, 7], [29, 16], [8, 6])
save("mondquell", g, {
    "name": "MAP_MONDQUELL", "region": "dunes", "time": "day", "music": "dunes", "battle_bg": "dunes", "border": "sand",
    "inn_spawn": "inn", "town": True,
    "spawns": {"from_route": [32, 18], "inn": [5, 7], "from_crest": [17, 1], "hall": [21, 18]},
    "warps": [
        {"rect": [33, 18, 1, 2], "to": "duenenweg", "spawn": "from_town"},
        {"rect": [17, 0, 2, 1], "to": "singender_kamm", "spawn": "from_town"},
    ],
    "on_enter": {"event": "mondquell_arrive", "unless": "mondquell_arrived"},
    "npcs": npcs + [
        {"id": "ordensmeisterin", "sprite": "order_b", "at": [23, 18], "event": "hall_greet"},
        {"id": "quell_haendlerin", "sprite": "trader", "at": [14, 15], "event": "quell_haendlerin"},
        {"id": "quell_kind", "sprite": "girl_c", "at": [9, 9], "event": "quell_kind", "wander": 2},
        {"id": "yao_free", "sprite": "yao", "at": [20, 19], "event": "yao_after", "when": "yao_returned"},
    ],
    "objects": objects + [{"id": "hall_door", "kind": "invisible", "at": [21, 17], "event": "halle_tuer"}],
})

g = Grid(28, 20, "s")
g.rect(1, 1, 26, 2, "m"); g.rect(1, 3, 4, 16, "m"); g.rect(23, 3, 4, 16, "m")
g.rect(9, 3, 10, 6, "c")
g.rect(6, 11, 3, 2, "m"); g.rect(19, 11, 3, 2, "m")
g.vl(13, 9, 19); g.vl(14, 9, 19)
g.rect(6, 15, 4, 3, "z"); g.rect(18, 15, 4, 3, "z")
save("singender_kamm", g, {
    "name": "MAP_SINGENDER_KAMM", "region": "dunes", "time": "dusk", "music": "dunes", "battle_bg": "dunes", "border": "sand",
    "spawns": {"from_town": [13, 18]},
    "warps": [{"rect": [13, 19, 2, 1], "to": "mondquell", "spawn": "from_crest"}],
    "on_enter": {"event": "kamm_arrive", "unless": "kamm_arrived"},
    "npcs": [
        {"id": "order_kamm", "sprite": "order_a", "at": [13, 11], "event": "order_kamm", "unless": "order_kamm_done"},
        {"id": "karawanenaelteste", "sprite": "elder", "at": [16, 16], "event": "karawanenaelteste"},
        {"id": "baihu_free", "lingshou": "baihu", "at": [13, 5], "event": "baihu_free", "when": "tone_shang", "scale": 1.3},
    ],
    "lingshou": [
        {"id": "boss_baihu", "species": "baihu", "role": "silenced", "at": [13, 5], "event": "boss_baihu", "unless": "tone_shang",
         "scale": 1.3, "static": True},
    ],
    "triggers": [{"rect": [9, 7, 10, 2], "event": "boss_baihu", "unless": "tone_shang"},
                 {"rect": [12, 12, 4, 1], "event": "order_kamm", "unless": "order_kamm_done", "once": False}],
})

# --- Wolkensäulen (earth, Gong) ---------------------------------------------------
g = Grid(40, 24, "u")
g.rect(14, 18, 12, 6, "c"); g.rect(18, 9, 5, 10, "c"); g.rect(6, 9, 14, 5, "c"); g.rect(20, 3, 14, 7, "c")
g.rect(16, 0, 5, 4, "c"); g.rect(4, 3, 6, 7, "c")
for x, y in [(7, 10), (12, 11), (22, 4), (28, 7), (31, 4), (15, 20), (24, 21), (19, 13), (5, 4)]:
    g.set(x, y, "Q")
g.dots([(9, 12), (25, 8), (32, 8), (6, 6)], "n")
g.rect(10, 9, 4, 2, ","); g.rect(26, 4, 4, 3, ","); g.rect(16, 19, 4, 3, ","); g.rect(5, 6, 3, 3, ",")
g.vl(20, 0, 23); g.vl(19, 0, 3)
save("saeulenpfad", g, {
    "name": "MAP_SAEULENPFAD", "region": "pillars", "time": "day", "music": "pillars", "battle_bg": "pillars", "border": "cloud",
    "spawns": {"from_crossroads": [20, 22], "from_town": [20, 1]},
    "warps": [
        {"rect": [20, 23, 1, 1], "to": "kreuzweg", "spawn": "from_pillars"},
        {"rect": [19, 0, 2, 1], "to": "kiefernhang", "spawn": "from_route"},
    ],
    "on_enter": {"event": "saeulenpfad_arrive", "unless": "saeulenpfad_arrived"},
    "lingshou": [
        {"id": "w_takin", "species": "felstakin", "at": [27, 5], "levels": [23, 25], "unless": "gone_w_takin"},
        {"id": "w_loewe", "species": "steinloewe", "at": [8, 11], "levels": [24, 25], "unless": "gone_w_loewe"},
    ],
    "objects": [{"id": "chest_saeulen", "kind": "chest", "at": [5, 4], "event": "chest_saeulen", "unless": "chest_saeulen"}],
    "encounters": {"rate": 0.12, "table": [
        {"species": "felstakin", "levels": [22, 25], "weight": 2},
        {"species": "wolkenpfeifer", "levels": [22, 25], "weight": 3},
        {"species": "steinloewe", "levels": [23, 26], "weight": 2},
        {"species": "nebelaffe", "levels": [22, 24], "weight": 1},
        {"species": "messingadler", "levels": [23, 26], "weight": 1},
        {"species": "schattenmotte", "levels": [23, 25], "weight": 2, "night": True}]},
})

g = Grid(34, 22, "c")
g.rect(1, 1, 32, 2, "u"); g.rect(1, 3, 2, 18, "u"); g.rect(31, 3, 2, 7, "u"); g.rect(31, 12, 2, 9, "u")
g.rect(14, 1, 6, 2, "c"); g.rect(15, 0, 4, 1, "c")   # cloud stairs to the temple
g.dots([(14, 1), (19, 1)], "Q")
inn = g.house(4, 4, 5, 3, 2, "R")                    # door (6,6)
shop = g.house(11, 4, 4, 3, 2)                       # door (13,6)
tea = g.house(21, 4, 5, 3, 2, "R")                   # door (23,6)
food = g.house(25, 13, 4, 3, 1)                      # door (26,15)
g.rect(11, 9, 12, 5, "_")
g.dots([(4, 14), (8, 17), (27, 18), (29, 8), (10, 19)], "n")
g.rect(4, 17, 3, 3, ","); g.rect(20, 17, 4, 2, ",")
g.dots([(11, 9), (22, 9), (11, 13), (22, 13)], "L")
g.hl(17, 32, 10); g.hl(17, 32, 11)
npcs, objects = town_services("kiefernhang", [6, 6], [13, 6], [23, 6], [26, 15], [8, 7], [15, 7], [25, 7], [28, 16], [9, 6])
g.vl(16, 14, 21); g.vl(17, 14, 21)
save("kiefernhang", g, {
    "name": "MAP_KIEFERNHANG", "region": "pillars", "time": "day", "music": "pillars", "battle_bg": "pillars", "border": "cloud",
    "inn_spawn": "inn", "town": True,
    "spawns": {"from_route": [17, 20], "inn": [6, 7], "from_temple": [16, 3], "from_plateau": [32, 10]},
    "warps": [
        {"rect": [16, 21, 2, 1], "to": "saeulenpfad", "spawn": "from_town"},
        {"rect": [33, 10, 1, 2], "to": "qilin_plateau", "spawn": "from_town"},
        {"rect": [15, 0, 4, 1], "to": "phoenixtempel", "spawn": "from_town", "when": "five_tones", "blocked_event": "temple_closed"},
    ],
    "on_enter": {"event": "kiefernhang_arrive", "unless": "kiefernhang_arrived"},
    "npcs": npcs + [
        {"id": "kiefer_aelteste", "sprite": "elder", "at": [17, 4], "event": "kiefer_aelteste"},
        {"id": "kiefer_kind", "sprite": "villager_b", "at": [15, 11], "event": "kiefer_kind", "wander": 2},
        {"id": "kiefer_frau", "sprite": "girl_c", "at": [20, 15], "event": "kiefer_frau"},
    ],
    "objects": objects,
})

g = Grid(28, 20, "u")
g.rect(3, 3, 22, 15, "c")
g.rect(9, 4, 10, 6, "_")
g.dots([(5, 5), (22, 5), (5, 14), (22, 14), (8, 11), (19, 11)], "Q")
g.rect(1, 9, 3, 2, "c")
g.rect(6, 15, 5, 2, ","); g.rect(17, 15, 5, 2, ",")
g.dots([(9, 4), (18, 4)], "L")
g.vl(13, 10, 17); g.vl(14, 10, 17); g.hl(1, 13, 10)
save("qilin_plateau", g, {
    "name": "MAP_QILIN_PLATEAU", "region": "pillars", "time": "dusk", "music": "pillars", "battle_bg": "pillars", "border": "cloud",
    "spawns": {"from_town": [2, 10]},
    "warps": [{"rect": [0, 9, 1, 2], "to": "kiefernhang", "spawn": "from_plateau"}],
    "on_enter": {"event": "plateau_arrive", "unless": "plateau_arrived"},
    "npcs": [
        {"id": "order_plateau", "sprite": "order_a", "at": [12, 11], "event": "order_plateau", "unless": "order_plateau_done"},
        {"id": "eremitin", "sprite": "monk", "at": [17, 13], "event": "eremitin"},
        {"id": "qilin_free", "lingshou": "qilin", "at": [14, 6], "event": "qilin_free", "when": "tone_gong", "scale": 1.3},
    ],
    "lingshou": [
        {"id": "boss_qilin", "species": "qilin", "role": "silenced", "at": [14, 6], "event": "boss_qilin", "unless": "tone_gong",
         "scale": 1.3, "static": True},
    ],
    "triggers": [{"rect": [9, 8, 10, 2], "event": "boss_qilin", "unless": "tone_gong"},
                 {"rect": [12, 12, 4, 1], "event": "order_plateau", "unless": "order_plateau_done", "once": False}],
})

# --- Phönixtempel: the finale -----------------------------------------------------
g = Grid(30, 24, "u")
g.rect(4, 2, 22, 21, "c")
g.rect(9, 3, 12, 8, "_")
g.rect(13, 3, 4, 2, "N")                              # the nest with the ashes
for x, y in [(6, 6), (23, 6), (6, 13), (23, 13), (14, 19)]:
    g.set(x, y, "P")
g.set(14, 19, "c")
g.dots([(9, 3), (20, 3), (9, 10), (20, 10)], "L")
g.vl(14, 11, 23); g.vl(15, 11, 23)
save("phoenixtempel", g, {
    "name": "MAP_PHOENIXTEMPEL", "region": "temple", "time": "dusk", "music": "order", "battle_bg": "phoenix_temple", "border": "cloud",
    "spawns": {"from_town": [14, 22], "nest": [14, 8]},
    "warps": [{"rect": [14, 23, 2, 1], "to": "kiefernhang", "spawn": "from_temple"}],
    "on_enter": {"event": "temple_arrive", "unless": "temple_arrived"},
    "npcs": [
        {"id": "wusheng", "at": [14, 9], "event": "wusheng_temple", "unless": "finale_done"},
        {"id": "kranich", "lingshou": "silberkranich", "at": [16, 9], "event": "kranich_temple", "unless": "finale_done"},
        {"id": "yao", "sprite": "yao_order", "at": [11, 12], "event": "yao_temple", "unless": ["yao_returned", "yao_left", "finale_done"]},
        {"id": "yao_ally", "sprite": "yao", "at": [11, 14], "event": "yao_ally", "when": "yao_returned", "unless": "finale_done"},
        {"id": "phoenix_ashes", "lingshou": "fenghuang_ashes", "at": [14, 4], "event": "phoenix_ashes", "unless": "finale_done", "scale": 1.2},
        {"id": "meister_temple", "sprite": "meister_free", "at": [12, 14], "event": "meister_temple", "when": "finale_done"},
        {"id": "wusheng_after", "sprite": "wusheng", "at": [17, 8], "event": "wusheng_after", "when": ["finale_done", "ending_reconcile"]},
    ],
    "triggers": [{"rect": [10, 11, 10, 2], "event": "finale", "unless": "finale_done", "once": False}],
})

# --- Hof: the farm west of Willowdale (GDD "Heimat") -------------------------------
g = Grid(34, 30)
g.rect(1, 1, 32, 2, "B"); g.rect(1, 3, 2, 26, "B")
hut = g.house(4, 4, 5, 3, 2)                          # the hut, door (6,6)
g.hl(6, 33, 7); g.hl(6, 33, 8)
g.vl(6, 7, 28); g.vl(7, 7, 28)
# 16 pens in a 4 x 4 grid: fence ring 5 x 4 with a 3 x 2 inside, paths between, sign below.
PENS = []
for row in range(4):
    for col in range(4):
        x0, y0 = 9 + col * 6, 9 + row * 5
        g.rect(x0, y0, 5, 4, "F")
        g.rect(x0 + 1, y0 + 1, 3, 2, ".")
        PENS.append({"rect": [x0 + 1, y0 + 1, 3, 2], "sign": [x0 + 2, y0 + 4]})
for row in range(4):
    g.hl(8, 32, 13 + row * 5)
g.dots([(12, 4), (28, 4), (2, 28)], "T")
g.rect(16, 3, 8, 3, "f")
g.rect(26, 3, 6, 3, ",")
save("hof", g, {
    "name": "MAP_HOF", "region": "bamboo", "time": "day", "music": "farm", "battle_bg": "farm", "border": "bamboo",
    "inn_spawn": "home",
    "spawns": {"from_village": [32, 7], "home": [6, 7]},
    "warps": [{"rect": [33, 7, 1, 2], "to": "weidendorf", "spawn": "from_farm"}],
    "on_enter": {"event": "hof_arrive", "unless": "hof_arrived"},
    "pens": PENS,
    "npcs": [
        {"id": "zimmermann", "sprite": "carpenter", "at": [10, 7], "event": "zimmermann"},
    ],
    "objects": [
        {"id": "hut_door", "kind": "invisible", "at": [6, 6], "event": "hof_hut"},
        {"id": "farm_chime", "kind": "chime", "at": [9, 6], "event": "hof_hut"},
        {"id": "farm_sign", "kind": "sign", "at": [31, 9], "event": "hof_sign", "solid": False},
    ],
})
