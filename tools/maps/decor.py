"""Hand-placed decoration per map (props from game/assets/props, see Props in
game/scripts/world/props.gd): the little things that give each place its
character. Coordinates in tiles (floats allowed), "y" lifts a prop (hanging
lanterns, boats on water)."""


def d(prop, x, z, scale=1.0, y=0.0):
    e = {"prop": prop, "at": [x, z]}
    if scale != 1.0:
        e["scale"] = scale
    if y:
        e["y"] = y
    return e


DECOR = {
    "weidendorf": [
        d("laundry_line", 9.5, 2.7), d("jars_group", 8.4, 4.6), d("firewood", 3.4, 4.7), d("wind_chime", 14.0, 4.8, 1.0, 0.95),
        d("wind_chime", 16.9, 4.8, 1.0, 0.95), d("banner_red", 11.0, 7.4), d("banner_red", 21.0, 7.4),
        d("drum", 23.2, 13.5),
        d("haystack", 2.6, 11.7), d("tea_table", 6.6, 16.0), d("boat_small", 10.0, 19.5, 1.0, -0.3), d("duck", 6.0, 19.4, 1.0, -0.25),
        d("duck", 7.0, 19.8, 1.0, -0.25), d("basket_veg", 25.5, 12.6), d("tree_plum", 11.2, 15.4), d("stone_lion", 26.3, 11.6, 0.9),
    ],
    "teeufer": [
        d("bush_tea", 29, 7), d("bush_tea", 30, 7), d("bush_tea", 31, 7), d("bush_tea", 29, 9), d("bush_tea", 30, 9),
        d("bush_tea", 31, 9), d("bush_tea", 29.5, 11), d("bush_tea", 30.5, 11), d("tea_table", 24.2, 12.7),
        d("basket_veg", 9.6, 5.6),
        d("jars_group", 19.6, 5.6), d("banner_red", 21.4, 7.4),
    ],
    "kreuzweg": [
        d("cart", 26.6, 10.6), d("barrel", 20.3, 10.4), d("jar", 25.7, 10.4), d("lantern_stone", 15.6, 12.4, 0.9),
        d("lantern_stone", 19.4, 12.4, 0.9), d("stone_lion", 16.2, 4.5), d("stone_lion", 19.8, 4.5), d("incense_burner", 22.6, 10.6),
    ],
    "nebelhafen": [
        d("boat_small", 14.4, 3.6, 1.0, -0.3), d("boat_small", 19.6, 4.6, 1.0, -0.3), d("boat_small", 8.0, 2.6, 1.0, -0.3),
        d("fishing_net", 7.6, 16.3), d("fishing_net", 2.6, 16.6), d("crate", 15.3, 7.6), d("barrel", 18.5, 7.5),
        d("jars_group", 27.4, 16.6),
        d("laundry_line", 9.5, 16.5), d("duck", 10.0, 4.0, 1.0, -0.25), d("duck", 11.0, 4.4, 1.0, -0.25), d("tree_willow", 1.8, 12.6),
    ],
    "schildkroetenbucht": [d("boat_small", 12.6, 17.5, 1.0, -0.3), d("fishing_net", 17.6, 15.6), d("incense_burner", 14.5, 9.2),
                           d("lantern_stone", 9.4, 8.6), d("lantern_stone", 19.6, 8.6)],
    "rotfels": [
        d("drum", 22.6, 10.4), d("jars_group", 19.5, 16.6), d("jars_group", 24.4, 17.6), d("jar", 22.2, 16.4),
        d("banner_red", 10.4, 9.2), d("banner_red", 23.6, 9.2), d("firewood", 19.0, 18.7),
        d("tree_maple", 3.2, 10.6), d("tree_maple", 29.4, 18.0), d("cart", 9.5, 16.8),
    ],
    "feuergipfel": [d("brazier", 9.0, 4.5), d("brazier", 16.0, 4.5), d("incense_burner", 12.5, 9.4), d("tree_maple", 6.0, 18.2, 0.9)],
    "mondquell": [
        d("tree_datepalm", 10.0, 6.0), d("tree_datepalm", 13.2, 12.2), d("tree_datepalm", 17.2, 7.0), d("tree_datepalm", 10.2, 10.4),
        d("tent_yurt", 28.5, 9.6), d("camel_saddle_pile", 26.0, 10.7), d("banner_white", 17.4, 17.7), d("banner_white", 24.6, 17.7),
        d("jars_group", 8.4, 7.0), d("stall", 9.5, 16.8),
    ],
    "singender_kamm": [d("prayer_flags", 13.5, 3.4, 1.2, 1.2), d("tent_yurt", 7.5, 14.6, 0.9), d("camel_saddle_pile", 18.6, 17.0)],
    "kiefernhang": [
        d("prayer_flags", 14.0, 8.3, 1.0, 1.4), d("prayer_flags", 19.0, 8.3, 1.0, 1.4), d("lantern_stone", 12.6, 8.4),
        d("lantern_stone", 21.4, 8.4), d("tree_cloudpine", 3.4, 9.2), d("tree_cloudpine", 29.6, 14.2), d("incense_burner", 17.0, 3.5),
        d("tea_table", 23.6, 7.6), d("wind_chime", 6.0, 4.8, 1.0, 0.95),
    ],
    "qilin_plateau": [d("incense_burner", 14.0, 10.5), d("lantern_stone", 9.6, 10.6), d("lantern_stone", 18.4, 10.6), d("tree_cloudpine", 4.0, 16.0)],
    "phoenixtempel": [
        d("banner_green", 6.6, 6.6), d("banner_red", 23.4, 6.6), d("banner_yellow", 6.6, 13.6), d("banner_white", 23.4, 13.6),
        d("banner_black", 17.6, 15.6), d("brazier", 11.4, 3.5), d("brazier", 18.6, 3.5), d("brazier", 12.0, 10.6), d("brazier", 17.0, 10.6),
        d("incense_burner", 15.0, 11.0),
    ],
    "hof": [
        d("haystack", 10.5, 4.2), d("firewood", 8.6, 5.6), d("laundry_line", 11.6, 3.3), d("cart", 13.6, 5.5), d("chicken", 14.0, 6.6),
        d("chicken", 15.3, 6.2), d("chicken", 24.6, 6.4), d("basket_veg", 9.6, 6.6), d("rice_sheaf", 24.6, 4.0), d("rice_sheaf", 25.2, 5.0),
        d("well_bucket", 3.4, 7.0), d("wind_chime", 6.0, 6.8, 1.0, 0.95), d("tree_plum", 31.0, 3.6),
    ],
}


# Small animals that walk around (no events): {"prop", "at", "wander"}.
CRITTERS = {
    "hof": [{"prop": "chicken", "at": [14, 7], "wander": 3}, {"prop": "chicken", "at": [20, 7], "wander": 3},
            {"prop": "chicken", "at": [26, 8], "wander": 2}, {"prop": "duck", "at": [12, 13], "wander": 2}],
    "weidendorf": [{"prop": "chicken", "at": [3, 7], "wander": 2}, {"prop": "chicken", "at": [22, 15], "wander": 3}],
    "teeufer": [{"prop": "chicken", "at": [8, 13], "wander": 2}],
    "nebelhafen": [{"prop": "duck", "at": [20, 7], "wander": 3}, {"prop": "duck", "at": [9, 7], "wander": 3}],
    "rotfels": [{"prop": "chicken", "at": [15, 15], "wander": 2}],
    "kiefernhang": [{"prop": "chicken", "at": [8, 10], "wander": 2}],
}

# Terraces, platforms and stairs (MapData.height_at): rect [x, z, w, h], "h" top height,
# "ramp" side that is highest, "from" height at the low end of a ramp.
HEIGHTS = {
    "teeufer": [{"rect": [29, 9, 4, 4], "h": 0.5}, {"rect": [29, 6, 4, 3], "h": 1.0}, {"rect": [29, 3, 4, 3], "h": 1.5},
                {"rect": [28, 3, 1, 10], "h": 1.5, "ramp": "n"}],
    "kiefernhang": [{"rect": [3, 3, 28, 5], "h": 0.7}, {"rect": [14, 8, 6, 2], "h": 0.7, "ramp": "n"},
                    {"rect": [14, 0, 6, 3], "h": 1.6, "from": 0.7, "ramp": "n"}],
    "drachenschrein": [{"rect": [8, 2, 11, 5], "h": 0.6}, {"rect": [10, 7, 7, 2], "h": 0.6, "ramp": "n"}],
    "phoenixtempel": [{"rect": [9, 3, 12, 5], "h": 0.6}, {"rect": [11, 8, 8, 2], "h": 0.6, "ramp": "n"}],
    "rotfels": [{"rect": [3, 3, 28, 6], "h": 0.6}, {"rect": [12, 9, 11, 1], "h": 0.6, "ramp": "n"}, {"rect": [16, 0, 2, 3], "h": 0.6}],
    "qilin_plateau": [{"rect": [9, 4, 10, 4], "h": 0.6}, {"rect": [9, 8, 10, 2], "h": 0.6, "ramp": "n"}],
    "mondquell": [{"rect": [18, 14, 6, 4], "h": 0.3}],
}
