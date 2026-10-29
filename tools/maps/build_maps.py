#!/usr/bin/env python3
"""Builds the beta maps (game/data/maps/*.json) from drawing commands.

The game reads only the JSON (rule 4); this script keeps the ASCII grids
consistent (equal row widths, doors in walls, paths connected) and prints
each grid for a visual check.  python3 tools/maps/build_maps.py [--print]
Legend: see MapData.LEGEND in game/scripts/world/map_data.gd.
"""
import os, sys

sys.path.insert(0, os.path.dirname(__file__))


from grid import Grid, save, OUT


# --- Weidendorf: home village, Lantern Festival night ---------------------------
g = Grid(32, 22)
g.rect(1, 1, 3, 2, "B"); g.rect(12, 1, 3, 1, "B")
home = g.house(4, 2, 4, 3, 2)                       # door (6,4) -> front (6,5)
work = g.house(13, 2, 5, 3, 2, "R")                 # door (15,4) -> front (15,5)
east = g.house(27, 9, 3, 3, 1)                      # door (28,11)
south = g.house(3, 14, 3, 2, 1)                     # door (4,15)
g.rect(9, 8, 16, 5, "_")                            # festival plaza
g.set(16, 10, "W")
for p in [(8, 8), (24, 8), (8, 12), (24, 12), (10, 4), (22, 4)]:
    g.set(*p, "L")
for p in [(9, 9), (24, 9), (9, 11), (24, 11)]:
    g.set(*p, "t")
g.vl(6, 5, 6); g.hl(6, 15, 6); g.vl(15, 5, 6); g.hl(15, 29, 6)
g.vl(28, 0, 6); g.vl(29, 0, 6)                        # north road
g.vl(10, 6, 8); g.vl(26, 6, 14); g.hl(26, 31, 14); g.hl(26, 31, 15)
g.vl(10, 12, 15); g.hl(4, 10, 15)
g.set(4, 15, "D")
g.vl(18, 12, 18)
g.rect(1, 19, 30, 2, "~")
g.dots([(5, 1), (20, 3), (3, 8), (27, 16), (3, 17)], "T")
g.dots([(2, 6), (11, 3), (2, 13), (17, 15), (26, 17)], "f")
g.rect(24, 1, 2, 2, ","); g.rect(12, 17, 3, 2, ",")
g.hl(0, 8, 10); g.set(8, 9, "="); g.vl(8, 9, 10)     # west road to the farm
save("weidendorf", g, {
    "name": "MAP_WEIDENDORF", "region": "bamboo", "time": "night", "music": "village", "music_when_silent": "silence",
    "battle_bg": "village_night", "inn_spawn": "home",
    "spawns": {"start": [6, 5], "home": [6, 5], "inn": [6, 5], "from_river": [29, 14], "from_north": [28, 2], "from_farm": [1, 10]},
    "warps": [
        {"rect": [31, 14, 1, 2], "to": "flussufer", "spawn": "from_village", "when": "silence_fell",
         "blocked_event": "blocked_river"},
        {"rect": [28, 0, 2, 1], "to": "bambuspfad", "spawn": "from_village", "when": "prologue_done",
         "blocked_event": "blocked_north"},
        {"rect": [0, 10, 1, 1], "to": "hof", "spawn": "from_village", "when": "prologue_done",
         "blocked_event": "blocked_north"},
    ],
    "on_enter": [{"event": "intro", "unless": "intro_done"},
                 {"event": "meister_voice", "when": "three_tones", "unless": "meister_spoke"}],
    "npcs": [
        {"id": "meister", "at": [15, 5], "event": "meister_gift", "unless": "has_fengling"},
        {"id": "meister_free", "sprite": "meister_free", "at": [15, 5], "event": "meister_home", "when": "meister_spoke"},
        {"id": "nian", "lingshou": "nian", "at": [16, 12], "event": "nian_battle", "when": "nian_here", "scale": 1.2},
        {"id": "kind_nian", "sprite": "villager_b", "at": [12, 13], "event": "kind_nian", "when": "nian_here"},
        {"id": "oma_nian", "sprite": "innkeeper", "at": [27, 12], "event": "oma_nian", "when": "nian_here"},
        {"id": "order_ying", "sprite": "order_b", "at": [19, 10], "event": "order_ying_idle", "when": "order_visit", "unless": "order_left"},
        {"id": "yao_order", "sprite": "yao_order", "at": [20, 11], "event": "order_ying_idle", "when": "order_visit", "unless": "order_left"},
        {"id": "yao_home", "sprite": "yao", "at": [21, 13], "event": "yao_after", "when": "yao_returned"},
        {"id": "meister_plaza", "sprite": "meister", "at": [13, 9], "event": "meister_plaza", "when": "has_fengling", "unless": "voice_taken"},
        {"id": "meister_mute", "sprite": "meister", "at": [15, 5], "event": "meister_mute", "when": "voice_taken", "unless": "meister_spoke"},
        {"id": "yao", "at": [20, 9], "event": "yao_festival", "unless": "silence_fell"},
        {"id": "wusheng", "at": [17, 9], "event": "wusheng_idle", "when": "wusheng_here"},
        {"id": "dorf_frau", "sprite": "villager_a", "at": [12, 11], "event": "dorf_frau"},
        {"id": "dorf_kind", "sprite": "villager_b", "at": [20, 12], "event": "dorf_kind", "wander": 2, "unless": "nian_here"},
        {"id": "dorf_oma", "sprite": "innkeeper", "at": [27, 12], "event": "dorf_oma", "unless": "nian_here"},
    ],
    "objects": [
        {"id": "home_door", "kind": "invisible", "at": [6, 4], "event": "home_door"},
        {"id": "work_door", "kind": "invisible", "at": [15, 4], "event": "work_door"},
        {"id": "sign_north", "kind": "sign", "at": [27, 3], "event": "sign_north", "solid": False},
        {"id": "festival_chime", "kind": "chime", "at": [16, 9], "event": "festival_chime"},
    ],
    "triggers": [
        {"rect": [13, 9, 7, 3], "event": "silence_falls", "when": "has_fengling", "unless": "silence_fell"},
        {"rect": [25, 13, 6, 4], "event": "wusheng_scene", "when": "prologue_tamed", "unless": "voice_taken"},
    ],
    "silent": True,
})

# --- Flussufer: river bank east of the village ------------------------------
g = Grid(28, 18)
g.rect(1, 1, 4, 2, "B"); g.rect(1, 3, 1, 1, "B")
g.rect(18, 1, 3, 1, "^"); g.set(19, 2, "^"); g.rect(23, 13, 2, 1, "^")
g.rect(1, 14, 4, 1, "~"); g.rect(1, 15, 9, 1, "~"); g.rect(1, 16, 26, 1, "~")
g.rect(22, 14, 5, 1, "~"); g.rect(20, 15, 7, 1, "~")
g.set(0, 7, "="); g.set(0, 8, "=")
g.hl(0, 8, 7); g.hl(0, 16, 8); g.hl(16, 19, 9)
g.rect(9, 2, 3, 1, ","); g.rect(8, 3, 5, 1, ","); g.rect(9, 4, 3, 1, ",")
g.rect(21, 5, 6, 1, ","); g.rect(25, 4, 2, 1, ","); g.rect(25, 6, 2, 1, ",")
g.rect(6, 11, 3, 1, ","); g.rect(5, 12, 5, 1, ",")
g.dots([(10, 1), (24, 1), (18, 4), (3, 6), (19, 11)], "T")
g.dots([(22, 2), (6, 5), (26, 3), (19, 7), (8, 9), (15, 13)], "f")
save("flussufer", g, {
    "name": "MAP_FLUSSUFER", "region": "bamboo", "time": "night", "music": "silence", "battle_bg": "river",
    "spawns": {"from_village": [1, 8]},
    "warps": [{"rect": [0, 7, 1, 2], "to": "weidendorf", "spawn": "from_river"}],
    "on_enter": {"event": "river_arrive", "unless": "river_arrived"},
    "npcs": [
        {"id": "yao", "at": [15, 9], "event": "yao_river", "when": "river_arrived", "unless": "prologue_tamed"},
    ],
    "lingshou": [
        {"id": "shy_bambaer", "species": "bambaer", "at": [3, 4], "event": "prolog_bambaer", "unless": ["gone_shy_bambaer", "prologue_tamed"]},
        {"id": "shy_wawalurch", "species": "wawalurch", "at": [6, 13], "event": "prolog_wawalurch", "unless": ["gone_shy_wawalurch", "prologue_tamed"]},
        {"id": "shy_zirpo", "species": "zirpo", "at": [21, 3], "event": "prolog_zirpo", "unless": ["gone_shy_zirpo", "prologue_tamed"]},
        {"id": "shy_nebelaffe", "species": "nebelaffe", "at": [24, 7], "event": "prolog_nebelaffe", "unless": ["gone_shy_nebelaffe", "prologue_tamed"]},
    ],
    "encounters": {"when": "prologue_done", "rate": 0.12, "table": [
        {"species": "wawalurch", "levels": [3, 5], "weight": 3},
        {"species": "reisquak", "levels": [3, 5], "weight": 2},
        {"species": "zirpo", "levels": [3, 5], "weight": 2}]},
})

# --- Bambuspfad: bamboo forest route -----------------------------------------
g = Grid(36, 20, "B")
g.rect(0, 0, 36, 1, "S"); g.rect(0, 19, 36, 1, "S")
g.rect(2, 12, 20, 6, "."); g.rect(2, 8, 8, 4, "."); g.rect(3, 3, 14, 5, ".")
g.rect(14, 4, 8, 3, "."); g.rect(20, 2, 10, 5, "."); g.rect(26, 4, 9, 3, ".")
g.rect(16, 7, 7, 5, "."); g.rect(18, 11, 4, 2, ".")
g.vl(6, 5, 19)                                       # south road to the village
g.hl(6, 13, 5); g.hl(13, 21, 5); g.vl(21, 5, 6); g.hl(21, 35, 6)
g.set(35, 5, "=")
g.rect(9, 3, 6, 2, ","); g.rect(3, 9, 3, 3, ","); g.rect(7, 9, 2, 3, ",")
g.rect(11, 13, 5, 3, ","); g.rect(22, 3, 5, 2, ","); g.rect(24, 5, 3, 1, ",")
g.dots([(9, 16), (19, 14)], "T"); g.dots([(6, 4), (20, 11), (19, 16)], "f")
save("bambuspfad", g, {
    "name": "MAP_BAMBUSPFAD", "region": "bamboo", "border": "bamboo", "time": "day", "music": "route", "music_when_silent": "silence", "battle_bg": "bamboo",
    "spawns": {"from_village": [6, 18], "from_town": [34, 6]},
    "warps": [
        {"rect": [6, 19, 1, 1], "to": "weidendorf", "spawn": "from_north"},
        {"rect": [35, 5, 1, 2], "to": "teeufer", "spawn": "from_bamboo"},
    ],
    "npcs": [
        {"id": "yao", "at": [31, 5], "event": "yao_bamboo_idle", "when": "yao_bamboo_waiting", "unless": "yao_battle2"},
    ],
    "objects": [
        {"id": "sign_bamboo", "kind": "sign", "at": [7, 16], "event": "sign_bamboo", "solid": False},
        {"id": "chest_bamboo", "kind": "chest", "at": [17, 8], "event": "chest_bamboo", "unless": "chest_bamboo"},
    ],
    "lingshou": [
        {"id": "w_libelle", "species": "jadelibelle", "at": [24, 3], "levels": [5, 6], "unless": "gone_w_libelle"},
        {"id": "w_affe", "species": "nebelaffe", "at": [4, 10], "levels": [4, 6], "unless": "gone_w_affe"},
        {"id": "w_baer", "species": "bambaer", "at": [16, 14], "levels": [5, 6], "unless": "gone_w_baer"},
    ],
    "triggers": [
        {"rect": [28, 4, 3, 3], "event": "yao_bamboo", "when": "prologue_done", "unless": "yao_battle2"},
    ],
    "encounters": {"rate": 0.12, "table": [
        {"species": "nebelaffe", "levels": [4, 6], "weight": 3},
        {"species": "jadelibelle", "levels": [4, 6], "weight": 3},
        {"species": "bambaer", "levels": [4, 6], "weight": 2},
        {"species": "zirpo", "levels": [4, 6], "weight": 2},
        {"species": "rollschupp", "levels": [6, 7], "weight": 1}]},
})

# --- Teeufer: tea terrace town -----------------------------------------------
g = Grid(34, 22)
g.rect(1, 1, 3, 2, "^"); g.rect(30, 1, 3, 2, "^")
inn = g.house(4, 2, 5, 3, 2, "R")                   # inn door (6,4)
shop = g.house(15, 2, 4, 3, 2)                      # shop door (17,4)
tea = g.house(24, 9, 5, 3, 2, "R")                  # teahouse door (26,11)
h1 = g.house(3, 14, 4, 3, 1)
h2 = g.house(12, 15, 4, 3, 2)
g.rect(10, 7, 11, 5, "_"); g.set(15, 9, "W")
for p in [(10, 7), (20, 7), (10, 11), (20, 11), (11, 3), (22, 3)]:
    g.set(*p, "L")
g.dots([(13, 8), (17, 8)], "t")
g.vl(6, 5, 6); g.vl(17, 5, 6); g.hl(6, 27, 6)
g.vl(26, 0, 6); g.vl(27, 0, 6)                        # north road to the terraces
g.hl(0, 10, 9); g.hl(0, 10, 10)                       # west road from the bamboo path
g.vl(21, 7, 13); g.hl(21, 26, 12); g.vl(26, 12, 12)
g.vl(4, 17, 17); g.hl(4, 14, 18); g.vl(14, 12, 14); g.hl(14, 21, 14, "=") if False else None
g.rect(29, 13, 4, 7, "~"); g.rect(25, 18, 4, 2, "~")
g.dots([(2, 6), (31, 5), (8, 12), (23, 15), (19, 19)], "T")
g.dots([(5, 1), (6, 1), (7, 1), (30, 6), (2, 12), (9, 16), (20, 16)], "f")
g.rect(17, 14, 5, 3, "B")
g.vl(9, 11, 21); g.hl(9, 10, 11)                    # south road to the crossroads
save("teeufer", g, {
    "name": "MAP_TEEUFER", "region": "bamboo", "time": "day", "music": "town", "music_when_silent": "silence", "battle_bg": "terraces",
    "inn_spawn": "inn",
    "spawns": {"from_bamboo": [1, 9], "inn": [6, 5], "from_terraces": [26, 1], "from_crossroads": [9, 20]},
    "warps": [
        {"rect": [0, 9, 1, 2], "to": "bambuspfad", "spawn": "from_town"},
        {"rect": [26, 0, 2, 1], "to": "reisterrassen", "spawn": "from_town"},
        {"rect": [9, 21, 1, 1], "to": "kreuzweg", "spawn": "from_teeufer", "when": "tone_jue", "blocked_event": "blocked_south_teeufer"},
    ],
    "on_enter": {"event": "teeufer_arrive", "unless": "teeufer_arrived"},
    "npcs": [
        {"id": "wirtin", "sprite": "innkeeper", "at": [8, 5], "event": "inn_door"},
        {"id": "haendler", "sprite": "shopkeeper", "at": [19, 5], "event": "shop_door"},
        {"id": "teemeister", "sprite": "teahouse", "at": [23, 11], "event": "teahouse"},
        {"id": "stille_frau", "sprite": "villager_a", "at": [12, 10], "event": "stille_frau"},
        {"id": "teeufer_kind", "sprite": "villager_b", "at": [18, 10], "event": "teeufer_kind", "wander": 2},
        {"id": "pilger", "sprite": "monk", "at": [25, 3], "event": "pilger"},
    ],
    "objects": [
        {"id": "inn_door_obj", "kind": "invisible", "at": [6, 4], "event": "inn_door"},
        {"id": "shop_door_obj", "kind": "invisible", "at": [17, 4], "event": "shop_door"},
        {"id": "tea_door_obj", "kind": "invisible", "at": [26, 11], "event": "teahouse"},
        {"id": "shrine_chime", "kind": "chime", "at": [9, 5], "event": "inn_door"},
    ],
})

# --- Reisterrassen: rice terraces up to the shrine ---------------------------
g = Grid(34, 24, ".")
# Terraces: paddy bands separated by grass ledges, a winding path up the middle.
for top in [3, 8, 13, 18]:
    g.rect(2, top, 30, 3, "r")
    g.rect(1, top + 3, 32, 1, ".")
g.vl(26, 19, 23); g.hl(16, 26, 19); g.vl(16, 16, 19)
g.hl(7, 16, 16); g.vl(7, 11, 16); g.hl(7, 22, 11); g.vl(22, 6, 11)
g.hl(14, 22, 6); g.vl(14, 1, 6); g.set(14, 0, "=")
g.set(26, 23, "=")
g.rect(11, 1, 3, 2, "^"); g.rect(15, 1, 3, 2, "^")    # narrow pass below the shrine
g.rect(1, 1, 2, 2, "T"); g.rect(30, 1, 3, 2, "T")
g.dots([(4, 7), (29, 12), (3, 17), (30, 22), (9, 22)], "T")
g.dots([(20, 22), (5, 22), (31, 7)], "f")
save("reisterrassen", g, {
    "name": "MAP_REISTERRASSEN", "region": "bamboo", "time": "day", "music": "route", "music_when_silent": "silence", "battle_bg": "terraces",
    "spawns": {"from_town": [26, 22], "from_shrine": [14, 2]},
    "warps": [
        {"rect": [26, 23, 1, 1], "to": "teeufer", "spawn": "from_terraces"},
        {"rect": [14, 0, 1, 1], "to": "drachenschrein", "spawn": "from_terraces"},
    ],
    "on_enter": {"event": "terraces_arrive", "unless": "terraces_arrived"},
    "lingshou": [
        {"id": "silent_leopard", "species": "firnleopard", "role": "silenced", "at": [14, 2], "event": "silent_leopard", "unless": "gone_silent_leopard", "scale": 1.0, "static": True},
        {"id": "moth_a", "species": "schattenmotte", "at": [10, 11], "event": "moth_a", "unless": "gone_moth_a"},
        {"id": "moth_b", "species": "schattenmotte", "at": [20, 16], "event": "moth_b", "unless": "gone_moth_b"},
    ],
    "encounters": {"rate": 0.11, "table": [
        {"species": "reisquak", "levels": [6, 8], "weight": 4},
        {"species": "wawalurch", "levels": [6, 8], "weight": 2},
        {"species": "jadelibelle", "levels": [6, 8], "weight": 2},
        {"species": "glutfasan", "levels": [7, 9], "weight": 1}]},
})

# --- Drachenschrein: the Azure Dragon's shrine -------------------------------
g = Grid(26, 20, "^")
g.rect(3, 2, 20, 16, "_")
g.rect(1, 17, 24, 2, "^")
g.vl(13, 17, 19); g.set(13, 19, "=")
for x in [5, 9, 16, 20]:
    for y in [6, 10, 14]:
        g.set(x, y, "P")
g.rect(10, 2, 7, 2, "^"); g.dots([(9, 3), (17, 3)], "L")
g.dots([(4, 15), (21, 15)], "L")
g.dots([(3, 2), (22, 2), (3, 16), (22, 16)], "T")
save("drachenschrein", g, {
    "name": "MAP_DRACHENSCHREIN", "region": "bamboo", "border": "rock", "time": "dusk", "music": "silence", "battle_bg": "shrine",
    "spawns": {"from_terraces": [13, 16]},
    "warps": [{"rect": [13, 19, 1, 1], "to": "reisterrassen", "spawn": "from_shrine"}],
    "on_enter": {"event": "shrine_arrive", "unless": "shrine_arrived"},
    "npcs": [
        {"id": "moench", "sprite": "monk", "at": [11, 15], "event": "moench"},
        {"id": "qinglong_free", "lingshou": "qinglong", "at": [13, 5], "event": "qinglong_free", "when": "tone_jue", "scale": 1.3},
    ],
    "lingshou": [
        {"id": "boss_qinglong", "species": "qinglong", "role": "silenced", "at": [13, 5], "event": "boss_qinglong", "unless": "tone_jue", "scale": 1.3, "static": True},
    ],
    "triggers": [
        {"rect": [9, 7, 9, 2], "event": "boss_qinglong", "unless": "tone_jue"},
    ],
})
import regions  # noqa: E402,F401  (all maps after the Bamboo Sea)
import interiors  # noqa: E402
interiors.apply()
print("maps written to", os.path.normpath(OUT))
